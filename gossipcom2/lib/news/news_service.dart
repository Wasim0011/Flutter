import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';

class NewsService {
  //static const String _apiKey = 'pub_8097417e016b36249e13f15d16473c640fcf4';
  //static const String _url =
      //'https://newsdata.io/api/1/news?apikey=$_apiKey&language=en&country=in';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Map<String, dynamic>>> fetchNews(
      {DocumentSnapshot? lastdoc, int limit = 10}) async {
    try {
      Query querySnapshot = _firestore
          .collection("NEWS")
          .orderBy('timestamp', descending: true) // Add consistent ordering
          .limit(limit);

      if (lastdoc != null) {
        querySnapshot = querySnapshot.startAfterDocument(lastdoc);
      }

      QuerySnapshot snapshot = await querySnapshot.get();

      return snapshot.docs.map((doc) {
        return {
          'article_id': doc.id,
          'doc': doc,
          ...doc.data() as Map<String, dynamic>,
        };
      }).toList();
    } catch (e) {
      // print(e);
      debugPrint('Error fetching thoughts: $e');
      rethrow;
    }
  }

  // 1. Add News Comment
  Future<void> addNewsComment(String articleId, String text) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Fetch user data for avatar and username
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      await _firestore
          .collection('NEWS')
          .doc(articleId)
          .collection('comments')
          .add({
        'userId': user.uid,
        'username': userData?['userName'] ?? 'Anonymous',
        'userAvatar': userData?['avatar'] ?? '',
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding comment: $e');
    }
  }

  // 2. Add News Reply
  Future<void> addNewsReply(String articleId, String commentId, String text) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userData = userDoc.data();

      await _firestore
          .collection('NEWS')
          .doc(articleId)
          .collection('comments')
          .doc(commentId)
          .collection('replies')
          .add({
        'userId': user.uid,
        'username': userData?['userName'] ?? 'Anonymous',
        'userAvatar': userData?['avatar'] ?? '',
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error adding reply: $e');
    }
  }

  // 3. Get News Comments Stream
  Stream<QuerySnapshot> getNewsComments(String articleId) {
    return _firestore
        .collection('NEWS')
        .doc(articleId)
        .collection('comments')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  // 4. Get News Replies Stream
  Stream<QuerySnapshot> getNewsReplies(String articleId, String commentId) {
    return _firestore
        .collection('NEWS')
        .doc(articleId)
        .collection('comments')
        .doc(commentId)
        .collection('replies')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}
