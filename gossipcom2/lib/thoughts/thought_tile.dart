import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/thoughts/add_comment.dart';
import 'package:gossipcom/thoughts/particular_thought/global_share.dart';
import 'package:gossipcom/thoughts/particular_thought/particular_thought.dart';
import 'package:gossipcom/thoughts/thoughts_service.dart';
import 'package:shimmer/shimmer.dart';

class ThoughtTile extends StatefulWidget {
  final String userName;
  final String thought;
  final String thoughtid;
  final String UserId;
  final List<dynamic>? imageUrls;
  final int views;

  const ThoughtTile({
    super.key,
    required this.userName,
    required this.thought,
    required this.thoughtid,
    required this.UserId,
    this.imageUrls,
    required this.views,
  });

  @override
  State<ThoughtTile> createState() => _ThoughtTileState();
}

class _ThoughtTileState extends State<ThoughtTile> {
  String? thoughtid;
  String? userId;
  String? username;
  late bool hasimages;
  late int numberofimages;
  // bool _moreemoji = false; // Removed unused variable
  String? uid;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    thoughtid = widget.thoughtid;
    userId = widget.UserId;
    username = widget.userName;
    hasimages = widget.imageUrls?.isNotEmpty ?? false;
    numberofimages = widget.imageUrls!.length;
    uid = _firebaseAuth.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(22.0),
      child: Material(
        borderRadius: BorderRadius.circular(16),
        elevation: 3,
        child: Container(
          width: double.infinity,
          // height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.onTertiary,
            border: Border.all(color: Colors.grey, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
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
                                collectionCall: 'Posts')));
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
                              color: Theme.of(context).colorScheme.onBackground,
                              fontSize: 20,
                            ),
                          )
                        ],
                      ),
                      Container(
                        // height: 100,
                        child: SingleChildScrollView(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              widget.thought,
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w400,
                                color: Theme.of(context).colorScheme.onSurface,
                                fontSize: 16,
                              ),
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
                            // int items =
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        (numberofimages == 1) ? 1 : 2,
                                    crossAxisSpacing: 2,
                                    mainAxisSpacing: 1,
                                    childAspectRatio: 1 / 0.9),
                            itemBuilder: (context, index) {
                              return CachedNetworkImage(
                                // height: double.infinity,
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

                // Container(

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.remove_red_eye_outlined,
                          size: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "${widget.views}",
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    StreamBuilder<DocumentSnapshot>(
                      stream: _firestore
                          .collection('Posts')
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
                                        .collection('Posts')
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
                                    color: isLiked
                                        ? Colors.red
                                        : (Theme.of(context).brightness ==
                                                Brightness.light
                                            ? Colors.black
                                            : Colors.white),
                                    size: 28,
                                  ),
                                ),
                                Text(
                                  "$likes",
                                  style: GoogleFonts.dmSerifText(
                                    fontSize: 18,
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.black
                                        : Colors.white,
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
                                              collectionCall: "Posts",
                                            )));
                              },
                              icon: Icon(
                                Icons.chat_bubble_outline,
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.black
                                    : Colors.white,
                                size: 26,
                              ),
                            ),
                            StreamBuilder<List<Map<String, dynamic>>>(
                              stream: ThoughtsService()
                                  .getCommentsStream(widget.thoughtid, 'Posts'),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Text(
                                    "${snapshot.data!.length}",
                                    style: GoogleFonts.dmSerifText(
                                      fontSize: 18,
                                      color: Theme.of(context).brightness ==
                                              Brightness.light
                                          ? Colors.black
                                          : Colors.white,
                                    ),
                                  );
                                }
                                return Text(
                                  "0",
                                  style: GoogleFonts.dmSerifText(
                                    fontSize: 18,
                                    color: Theme.of(context).brightness ==
                                            Brightness.light
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                );
                              },
                            ),
                            const SizedBox(width: 16),
                            IconButton(
                              onPressed: () {
                                GlobalShare.shareThought(
                                  context: context,
                                  userName: widget.userName,
                                  thought: widget.thought,
                                  thoughtId: widget.thoughtid,
                                );
                              },
                              icon: Icon(
                                Icons.send,
                                color: Theme.of(context).brightness ==
                                        Brightness.light
                                    ? Colors.black
                                    : Colors.white,
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
