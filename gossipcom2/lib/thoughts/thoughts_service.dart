import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:gossipcom/auth/auth_service.dart';
import 'package:image_picker/image_picker.dart';

class ThoughtsService {
  final String? collectionCall;

  ThoughtsService({this.collectionCall});
  final AuthService authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late String thoughtRef;
  late String thoughtRefid;

  Future<List<String>> uploadImages(List<XFile> images) async {
    List<String> imageurls = [];
    for (XFile image in images) {
      String fileName = DateTime.now().microsecondsSinceEpoch.toString();
      Reference storageRef =
          FirebaseStorage.instance.ref().child("uploads/$fileName");

      UploadTask uploadTask = storageRef.putFile(File(image.path));
      TaskSnapshot snapshot = await uploadTask;
      String downloadurl = await snapshot.ref.getDownloadURL();
      imageurls.add(downloadurl);
      ;
    }
    return imageurls;
  }

  Future<void> createThought({
    required String thought,
    List<XFile>? images,
  }) async {
    try {
      final user = authService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      final username = await getCurrentUsername();
      if (username == null) throw Exception('Username not found');

      List<String> imageurls = [];
      if (images != null && images.isNotEmpty) {
        imageurls = await uploadImages(images);
      }

      final thoughtRef = _firestore.collection('Posts').doc();

      print(thoughtRef);
      final thoughtRefid = thoughtRef.id;
      print(thoughtRefid);

      final thoughtData = {
        'postId': thoughtRef.id,
        'userId': user.uid,
        'username': username,
        'thought': thought,
        'imagelink': imageurls,
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
      };
      await thoughtRef.set(thoughtData);
    } catch (e) {
      debugPrint('Error creating thought: $e');
      rethrow;
    }
  }

  Future<void> createGossipThought({
    required String thought,
    required String groupId,
    List<XFile>? images,
  }) async {
    try {
      final user = authService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      final username = await getCurrentUsername();
      if (username == null) throw Exception('Username not found');

      List<String> imageurls = [];
      if (images != null && images.isNotEmpty) {
        imageurls = await uploadImages(images);
      }

      final thoughtRef = _firestore.collection('GossipPosts').doc();

      print(thoughtRef);
      final thoughtRefid = thoughtRef.id;
      print(thoughtRefid);

      final thoughtData = {
        'postId': thoughtRef.id,
        'userId': user.uid,
        'username': username,
        'thought': thought,
        'imagelink': imageurls,
        'views': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likedBy': [],
        'groupId': groupId,
      };
      await thoughtRef.set(thoughtData);
    } catch (e) {
      debugPrint('Error creating thought: $e');
      rethrow;
    }
  }

  Future<void> createComment(String postId, String commentText, String challectionOfPost) async {
    try {
      // final postId = postId;
      final user = authService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');
      final username = await getCurrentUsername();

      var comments = _firestore
          .collection(challectionOfPost)
          .doc(postId)
          .collection('comments')
          .doc();

      final commentsData = {
        'userId': user.uid,
        'username': username,
        'commentId': comments.id,
        'postId': postId,
        'comments': commentText,
        'commentTime': FieldValue.serverTimestamp(),
      };

      await comments.set(commentsData);
    } catch (e) {
      debugPrint('Error adding comment: $e');
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> getCommentsStream(
      String postId, String collectionOfPost) {
    try {
      return _firestore
          .collection(collectionOfPost)
          .doc(postId)
          .collection('comments')
          .orderBy('commentTime', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => doc.data()).toList();
      });
    } catch (e) {
      debugPrint('Error fetching comments stream: $e');
      rethrow;
    }
  }

  Future<bool> toggleLike(String postId) async {
    try {
      final user = authService.getCurrentUser();
      if (user == null) throw Exception("User not logged in");

      final postDoc = await _firestore.collection('Posts').doc(postId).get();
      if (!postDoc.exists) throw Exception("Post not found");

      bool isLiked = false;
      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot freshPost =
            await transaction.get(_firestore.collection('Posts').doc(postId));

        int currentLikes = freshPost.get('likes') ?? 0;
        List<dynamic> likedBy = freshPost.get('likedBy') ?? [];

        if (likedBy.contains(user.uid)) {
          likedBy.remove(user.uid);
          currentLikes = currentLikes > 0 ? currentLikes - 1 : 0;
          isLiked = false;
        } else {
          likedBy.add(user.uid);
          currentLikes++;
          isLiked = true;
        }
        transaction.update(_firestore.collection('Posts').doc(postId), {
          'likes': currentLikes,
          'likedBy': likedBy,
        });
      });
      return isLiked;
    } catch (e) {
      debugPrint('Error toggling like $e');
      rethrow;
    }
  }

  Future<bool> checkIfLiked(String postId) async {
    try {
      final user = authService.getCurrentUser();
      if (user == null) return false;

      final postDoc = await _firestore.collection('Posts').doc(postId).get();
      if (!postDoc.exists) return false;

      List<dynamic> likedBy = postDoc.get('likedBy') ?? [];
      return likedBy.contains(user.uid);
    } catch (e) {
      debugPrint('Error checking like status: $e');
      return false;
    }
  }

  Future<int> getLikeCount(String postId) async {
    try {
      final postDoc = await _firestore.collection('Posts').doc(postId).get();
      if (!postDoc.exists) return 0;

      return postDoc.get('likes') ?? 0;
    } catch (e) {
      debugPrint('Error getting like count: $e');
      return 0;
    }
  }

  Future<DocumentSnapshot?> singleThought(String postId, String collectionCall
      // String collectionCall,
      ) async {
    try {
      return await _firestore.collection(collectionCall).doc(postId).get();
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<DocumentSnapshot?> GossipsingleThought(
    String postId,
  ) async {
    try {
      return await _firestore.collection('GossipPosts').doc(postId).get();
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<void> deleteComment(String postId, String commentId) async {
    try {
      final user = authService.getCurrentUser();
      if (user == null) throw Exception("User Not Logged In");

      final comment = await _firestore
          .collection('Posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId);
      // .get();
      var doccomment = await comment.get();
      if (!doccomment.exists || doccomment.data()?['userId'] != user.uid)
        throw Exception("comment not found");
      await comment.delete();
    } catch (e) {
      print(e.toString());
    }
  }

  // Future<void> like
  Stream<QuerySnapshot?> getComments(String postId) {
    try {
      return _firestore
          .collection('Posts')
          .doc(postId)
          .collection('comments')
          .snapshots();
    } catch (e) {
      debugPrint(e.toString());
      return Stream.error(e);
    }
  }

  Future<void> deleteThought(String postId) async {
    try {
      final user = authService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');
      final doc = await _firestore.collection('Posts').doc(postId).get();
      if (!doc.exists) throw Exception('Thought not found');
      if (doc.data()?['userId'] != user.uid) {
        throw Exception('You can only delete your own thoughts');
      }
      await _firestore.collection('Posts').doc(postId).delete();
    } catch (e) {
      debugPrint('Error deleting thought: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchThoughts({
    DocumentSnapshot? lastDoc,
    int limit = 10,
  }) async {
    try {
      Query querySnapshot = await _firestore
          .collection('Posts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        querySnapshot = querySnapshot.startAfterDocument(lastDoc);
      }

      QuerySnapshot snapshot = await querySnapshot.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return <String, dynamic>{
          'postId': doc.id,
          'doc': doc, // Include the document ID
          ...?data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching thoughts: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchGossipThoughts({
    DocumentSnapshot? lastDoc,
    int limit = 10,
  }) async {
    try {
      Query querySnapshot = await _firestore
          .collection('GossipPosts')
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (lastDoc != null) {
        querySnapshot = querySnapshot.startAfterDocument(lastDoc);
      }

      QuerySnapshot snapshot = await querySnapshot.get();

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>?;
        return <String, dynamic>{
          'postId': doc.id,
          'doc': doc, // Include the document ID
          ...?data,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error fetching thoughts: $e');
      rethrow;
    }
  }

  // replies
  Future<void> CreateReply(
      String postId, String commentId, String reply) async {
    try {
      final user = authService.getCurrentUser();
      if (user == null) return null;
      final username = await getCurrentUsername();

      var replyref = _firestore
          .collection('Posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc();
      print("reply ref $replyref");
      final replies = {
        'userId': user.uid,
        'userName': username,
        'postId': postId,
        'commentId': commentId,
        'replyId': replyref.id,
        'reply': reply,
        'likes': 0,
        'likedby': [],
        'createdAt': FieldValue.serverTimestamp(),
      };
      print("Replys $replies");
      final reply_save = await replyref.set(replies);
      // print(reply_save);
      reply_save;
      // print("replydef print${replyref.set(replies)}");
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<bool> toggleReplyLike(
      String postId, String commentId, String replyId) async {
    try {
      final user = authService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      // Get the current reply document
      final replyRef = _firestore
          .collection('Posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .doc(replyId);

      final replyDoc = await replyRef.get();
      if (!replyDoc.exists) throw Exception('Reply not found');

      // Handle the like/unlike operation in a transaction
      bool isLiked = false;
      await _firestore.runTransaction((transaction) async {
        // Get fresh data
        DocumentSnapshot freshReply = await transaction.get(replyRef);

        // Get current like count and liked users
        int currentLikes = freshReply.get('likes') ?? 0;
        List<dynamic> likedBy = freshReply.get('likedby') ?? [];

        // Check if user already liked the reply
        if (likedBy.contains(user.uid)) {
          // Unlike the reply
          likedBy.remove(user.uid);
          currentLikes = currentLikes > 0 ? currentLikes - 1 : 0;
          isLiked = false;
        } else {
          // Like the reply
          likedBy.add(user.uid);
          currentLikes++;
          isLiked = true;
        }

        // Update the reply document
        transaction
            .update(replyRef, {'likes': currentLikes, 'likedby': likedBy});
      });

      return isLiked;
    } catch (e) {
      debugPrint('Error toggling reply like: $e');
      rethrow;
    }
  }

  Stream<QuerySnapshot?> getReply(String postId, String commentId) {
    try {
      return _firestore
          .collection('Posts')
          .doc(postId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .snapshots();
    } catch (e) {
      debugPrint(e.toString());
      return Stream.error(e);
    }
  }

  Future<String?> getCurrentUsername() async {
    try {
      final user = authService.getCurrentUser();
      if (user == null) return null;
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?.containsKey('userName') == true) {
        return doc.data()!['userName'] as String;
      }

      return null;
    } catch (e) {
      debugPrint('Error getting username: $e');
      return null;
    }
  }

  //will work after the post is completed....
  //directly fetch the data from the collection
  Future<List<Map<String, dynamic>>> fetchUserPosts() async {
    try {
      final user = authService.getCurrentUser();
      if (user == null) throw Exception('User not logged in');

      print("DEBUG: Fetching posts for user: ${user.uid}");

      final querySnapshot = await _firestore
          .collection('Posts')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .get();

      print("DEBUG: Found ${querySnapshot.docs.length} posts in Firestore");

      return querySnapshot.docs.map((doc) {
        final data = {
          'id': doc.id,
          'postId': doc.id, // Add this for compatibility
          'doc': doc, // Add this for pagination
          ...doc.data() as Map<String, dynamic>,
        };
        print("DEBUG: Post data: $data");
        return data;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching user posts: $e');
      rethrow;
    }
  }
}
