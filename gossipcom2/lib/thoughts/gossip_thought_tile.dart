import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/thoughts/add_comment.dart';
import 'package:gossipcom/thoughts/particular_thought/particular_thought.dart';
import 'package:shimmer/shimmer.dart';
import 'dart:developer';

class Gossipthoughttile extends StatefulWidget {
  final String userName;
  final String thought;
  final String thoughtid;
  final String userId;
  final List<dynamic>? imageUrls;
  final int views;
  final String groupId;

  const Gossipthoughttile({
    super.key,
    required this.userName,
    required this.thought,
    required this.thoughtid,
    required this.userId,
    this.imageUrls,
    required this.views,
    required this.groupId,
  });

  @override
  State<Gossipthoughttile> createState() => _GossipthoughttileState();
}

class _GossipthoughttileState extends State<Gossipthoughttile> {
  String? thoughtid;
  String? userId;
  String? username;
  String? groupId;
  late bool hasimages;
  late int numberofimages;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String? uid;

  Future<void> _sentRequestForJoin(String groupId) async {
    try {
      String? uid = _firebaseAuth.currentUser?.uid;
      if (uid == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login to send request')),
          );
        }
        return;
      }
      final docRef =
          _firestore.collection('gossipPendingRequests').doc(groupId);
      //Check request limit per gossip post (Max 3)
      final docSnap = await docRef.get();
      if (docSnap.exists) {
        List<dynamic> currentRequests = docSnap.data()?['requests'] ?? [];

        if (currentRequests.length >= 3) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                    'This gossip already has 3 pending requests. Please try later.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
          return;
        }

        // Check if already requested
        bool alreadyRequested =
            currentRequests.any((req) => req['requestBy'] == uid);
        if (alreadyRequested) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('You have already requested to join.')),
            );
          }
          return;
        }
      } else {
        await docRef.set({
          'groupId': groupId,
          'requests': [],
        }, SetOptions(merge: true));
      }

      await docRef.update({
        'requests': FieldValue.arrayUnion([
          {
            'requestBy': uid,
            'timeStamp': DateTime.now(),
            'approved': false,
            'requestId': DateTime.now().millisecondsSinceEpoch,
          }
        ])
      });

      // Also write an in-app notification for the group creator
      try {
        final groupDoc =
            await _firestore.collection('group_chats').doc(groupId).get();
        final creatorUid = groupDoc.data()?['creator'];

        log("creatorUid: $creatorUid null to nhi hai na $groupId k lie?");

        if (creatorUid != null) {
          await _firestore
              .collection('users')
              .doc(creatorUid)
              .collection('notifications')
              .add({
            'title': 'New Gossip Request',
            'message': 'Someone requested to join your gossip group',
            'type': 'gossip_request',
            'isRead': false,
            'isDeleted': false,
            'timestamp': FieldValue.serverTimestamp(),
            'senderId': uid,
            'groupId': groupId,
          });
          log("fired notification to creator");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Request Sent Successfully')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error Sending Request: Creator not found')),
          );
          log("Creator UID is null, cannot send notification");
        }
      } catch (e) {
        debugPrint('Error sending creator notification: $e');
      }
    } catch (e) {
      debugPrint('Error Sending Request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error Sending Request: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void initState() {
    super.initState();
    thoughtid = widget.thoughtid;
    userId = widget.userId;
    username = widget.userName;
    hasimages = widget.imageUrls?.isNotEmpty ?? false;
    numberofimages = widget.imageUrls!.length;
    groupId = widget.groupId;
    uid = _firebaseAuth.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onTertiary,
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ParticularThought(
                                  userName: username,
                                  userId: userId,
                                  thoughtid: thoughtid,
                                  views: widget.views,
                                  imageUrls: widget.imageUrls,
                                  collectionCall: 'GossipPosts',
                                )));
                  },
                  child: Column(
                    children: [
                      Row(
                        children: [
                          UserAvatar(
                              userId: userId, size: 40, firestore: _firestore),
                          const SizedBox(width: 12),
                          Text(
                            widget.userName,
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 20,
                            ),
                          )
                        ],
                      ),
                      const Divider(
                        thickness: 2,
                        color: Color(0x82979797),
                      ),
                      SingleChildScrollView(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            widget.thought,
                            style: GoogleFonts.dmSerifText(
                              fontWeight: FontWeight.w400,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const Divider(
                        thickness: 2,
                        color: Color(0x82979797),
                      ),
                      if (hasimages)
                        GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: widget.imageUrls!.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        (numberofimages == 1) ? 1 : 2,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 1,
                                    childAspectRatio: 1 / 0.9),
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                imageUrl: widget.imageUrls![index],
                                imageBuilder: (context, imageProvider) {
                                  return Image(
                                    image: imageProvider,
                                    fit: BoxFit
                                        .contain, // maintains original aspect ratio
                                  );
                                },
                                placeholder: (context, url) => Center(
                                  child: Shimmer.fromColors(
                                    baseColor: Colors.grey.shade300,
                                    highlightColor: Colors.grey.shade100,
                                    child: Container(
                                      color: Colors.white,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  ),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Icon(Icons.error),
                                fit: BoxFit.fill,
                              );
                            })
                    ],
                  ),
                ),
                Row(
                  children: [
                    Text("Date"),
                    Spacer(),
                    (widget.userId != uid)
                        ? TextButton(
                            onPressed: () async {
                              await _sentRequestForJoin(widget.groupId);
                              log("gossip Request tapped");
                            },
                            style: ButtonStyle(
                                backgroundColor:
                                    WidgetStatePropertyAll(Colors.grey)),
                            child: Text(
                              "Gossip Request,",
                              style: TextStyle(color: Colors.black),
                            ),
                          )
                        : Text("you are the creator"),
                  ],
                ),
                Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${widget.views} Views",
                      style: GoogleFonts.dmSerifText(
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 18,
                      ),
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('GossipPosts')
                          .doc(widget.thoughtid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const SizedBox();
                        }
                        final data =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        final likes = data?['likes'] ?? 0;
                        final List likedBy = data?['likedBy'] ?? [];
                        final isLiked = likedBy.contains(uid);

                        return Row(
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () async {
                                    final postRef = _firestore
                                        .collection('GossipPosts')
                                        .doc(widget.thoughtid);
                                    await _firestore
                                        .runTransaction((transaction) async {
                                      final snapshot =
                                          await transaction.get(postRef);
                                      if (!snapshot.exists) return;

                                      final data = snapshot.data()
                                          as Map<String, dynamic>;
                                      final List likedBy =
                                          List.from(data['likedBy'] ?? []);
                                      int likes = data['likes'] ?? 0;

                                      if (likedBy.contains(uid)) {
                                        likedBy.remove(uid);
                                        likes = likes > 0 ? likes - 1 : 0;
                                      } else {
                                        likedBy.add(uid);
                                        likes += 1;
                                      }

                                      transaction.update(postRef, {
                                        'likes': likes,
                                        'likedBy': likedBy,
                                      });
                                    });
                                  },
                                  icon: Icon(
                                    isLiked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isLiked ? Colors.red : Colors.white,
                                    size: 28,
                                  ),
                                ),
                                Text(
                                  "$likes",
                                  style: GoogleFonts.dmSerifText(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (context) => AddComment(
                                              username: username,
                                              userId: userId,
                                              thoughtId: thoughtid,
                                              collectionCall: "GossipPosts",
                                            )));
                              },
                              icon: const Icon(
                                Icons.chat_bubble_outline,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                            // Placeholder for comment count if needed, or just icon as per image
                            Text(
                              "0", // Placeholder as per image, or fetch real count
                              style: GoogleFonts.dmSerifText(
                                fontSize: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                // Share functionality placeholder
                                log("Share tapped");
                              },
                              icon: const Icon(
                                Icons.send,
                                color: Colors.white,
                                size: 26,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
