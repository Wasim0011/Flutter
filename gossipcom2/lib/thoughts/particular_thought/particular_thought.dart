import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:gossipcom/thoughts/thoughts_service.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../add_comment.dart';

class ParticularThought extends StatefulWidget {
  final String? userName;
  final String? thoughtid;
  final String? userId;
  final int? views;
  final List<dynamic>? imageUrls;
  final String? collectionCall;
  const ParticularThought({
    super.key,
    required this.userName,
    required this.thoughtid,
    required this.userId,
    required this.views,
    required this.imageUrls,
    required this.collectionCall,
  });

  @override
  State<ParticularThought> createState() => _ParticularThoughtState();
}

class _ParticularThoughtState extends State<ParticularThought> {
  final FirebaseAuth _fireAuth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, TextEditingController> _replyControllers = {};
  DocumentSnapshot? _cachedThought;
  bool isLiked = false;
  late bool hasimages;
  late int? numberofimages;

  @override
  void dispose() {
    for (var controller in _replyControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    hasimages = widget.imageUrls?.isNotEmpty ?? false;
    numberofimages = widget.imageUrls?.length;
  }

  TextEditingController _getReplyController(String commentId) {
    if (!_replyControllers.containsKey(commentId)) {
      _replyControllers[commentId] = TextEditingController();
    }
    return _replyControllers[commentId]!;
  }

  Future<DocumentSnapshot?> thought(
      String? thoughtId, String? collectionCall) async {
    if (_cachedThought != null) return _cachedThought;
    try {
      final result =
          await ThoughtsService(collectionCall: widget.collectionCall)
              .singleThought(thoughtId!, widget.collectionCall!);
      _cachedThought = result;
      return result;
    } catch (e) {
      debugPrint(e.toString());
      throw Exception("Thought issue: ${e.toString()}");
    }
  }

  Stream<QuerySnapshot?> comments(String postId) {
    try {
      return ThoughtsService().getComments(postId);
    } catch (e) {
      debugPrint(e.toString());
      return Stream.error("Comments issue: $e");
    }
  }

  Future<void> createReply(
      String postId, String commentId, String reply) async {
    try {
      await ThoughtsService().CreateReply(postId, commentId, reply);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reply posted successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to post reply'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
      throw Exception("Create reply issue: ${e.toString()}");
    }
  }

  Stream<QuerySnapshot?> getReply(String postId, String commentId) {
    try {
      return ThoughtsService().getReply(postId, commentId);
    } catch (e) {
      debugPrint(e.toString());
      return Stream.error(e);
    }
  }

  Future<DocumentSnapshot?> getUserData(String userId) async {
    try {
      return await _firestore.collection('users').doc(userId).get();
    } catch (e) {
      debugPrint("Error fetching user data: ${e.toString()}");
      return null;
    }
  }

  Future<void> likeThought(String thoughtId) async {
    try {
      isLiked = await ThoughtsService().toggleLike(thoughtId);
      setState(() {
        isLiked;
        _cachedThought = null;
      });

      String message = isLiked ? 'Liked thought' : 'unliked thought';

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating like: ${e.toString()}'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> likeComment(String thoughtId, String commentId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Liked comment'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    try {
      if (timestamp is Timestamp) {
        return timeago.format(timestamp.toDate());
      } else if (timestamp is DateTime) {
        return timeago.format(timestamp);
      } else if (timestamp is int) {
        return timeago.format(DateTime.fromMillisecondsSinceEpoch(timestamp));
      }
    } catch (e) {
      debugPrint('Error formatting timestamp: $e');
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Discussion",
          style: GoogleFonts.dmSerifText(
            fontWeight: FontWeight.w500,
            fontSize: 24,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder(
        future: thought(widget.thoughtid, widget.collectionCall),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 60, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    "Couldn't load this thought",
                    style: theme.textTheme.titleLarge,
                  ),
                  TextButton(
                    onPressed: () {
                      _cachedThought = null;
                      setState(() {});
                    },
                    child: const Text("Retry"),
                  )
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Thought not found"));
          }

          var thoughtData = snapshot.data!.data() as Map<String, dynamic>;
          bool isLikedByCurrentUser = false;
          if (thoughtData['likedBy'] is List) {
            final currentUser = _fireAuth.currentUser;
            if (currentUser != null) {
              isLikedByCurrentUser =
                  (thoughtData['likedBy'] as List).contains(currentUser.uid);
            }
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                // Original thought card
                Card(
                  margin: const EdgeInsets.all(12),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Author info
                        Row(
                          children: [
                            UserAvatar(
                              userId: thoughtData['userId'] ?? "",
                              size: 40,
                              firestore: _firestore,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    thoughtData['username'] ?? 'Anonymous',
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    formatTimestamp(
                                        thoughtData['createdAt'] as Timestamp?),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          thoughtData['thought'] ?? '',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 17,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                return Image.network(
                                  widget.imageUrls![index],
                                  fit: BoxFit.contain,
                                );
                              }),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Text(
                              "${widget.views} Views",
                              style: GoogleFonts.dmSerifText(
                                fontWeight: FontWeight.w400,
                                color:
                                    Theme.of(context).colorScheme.onSecondary,
                                fontSize: 18,
                              ),
                            ),
                            _buildActionButton(
                              onPressed: () {

print("collection call check: ----- 3");

                                if (widget.thoughtid != null &&
                                    widget.userId != null &&
                                    widget.userName != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddComment(
                                        thoughtId: widget.thoughtid!,
                                        userId: widget.userId!,
                                        username: widget.userName!,
                                        collectionCall:widget.collectionCall!,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: Icons.comment_outlined,
                              label: 'Comment',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                // Comments section
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        'Comments',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      StreamBuilder(
                        stream: comments(widget.thoughtid!),
                        builder: (context, snapshot) {
                          int commentCount = 0;
                          if (snapshot.hasData && snapshot.data != null) {
                            commentCount = snapshot.data!.docs.length;
                          }
                          return Text(
                            '($commentCount)',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.grey.shade600,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                // Comments list
                StreamBuilder(
                  stream: comments(widget.thoughtid!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          "Error loading comments",
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(color: Colors.red),
                        ),
                      );
                    } else if (!snapshot.hasData ||
                        snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                              Icon(Icons.chat_bubble_outline,
                                  size: 48, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                "No comments yet",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        var commentDoc = snapshot.data!.docs[index];
                        var commentData =
                            commentDoc.data() as Map<String, dynamic>;
                        String commentId =
                            commentData['commentId'] ?? commentDoc.id;

                        return CommentCard(
                          key: ValueKey(commentId), // Important for performance
                          commentData: commentData,
                          commentId: commentId,
                          thoughtId: widget.thoughtid!,
                          replyController: _getReplyController(commentId),
                          onReplySubmitted: (reply) {
                            createReply(widget.thoughtid!, commentId, reply);
                            _getReplyController(commentId).clear();
                          },
                          onLikeComment: () =>
                              likeComment(widget.thoughtid!, commentId),
                          formatTimestamp: formatTimestamp,
                          firestore: _firestore,
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    int? count,
    Color? iconColor,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey.shade700),
            const SizedBox(width: 6),
            Text(
              count != null ? '$label ($count)' : label,
              style: TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CommentCard extends StatefulWidget {
  final Map<String, dynamic> commentData;
  final String commentId;
  final String thoughtId;
  final TextEditingController replyController;
  final Function(String) onReplySubmitted;
  final VoidCallback onLikeComment;
  final String Function(dynamic) formatTimestamp;
  final FirebaseFirestore firestore;

  const CommentCard({
    super.key,
    required this.commentData,
    required this.commentId,
    required this.thoughtId,
    required this.replyController,
    required this.onReplySubmitted,
    required this.onLikeComment,
    required this.formatTimestamp,
    required this.firestore,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _isReplyOpen = false;
  bool _areRepliesExpanded = false;

  Stream<QuerySnapshot?> getReply(String postId, String commentId) {
    try {
      return ThoughtsService().getReply(postId, commentId);
    } catch (e) {
      debugPrint(e.toString());
      return Stream.error(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    UserAvatar(
                      userId: widget.commentData['userId'],
                      size: 36,
                      firestore: widget.firestore,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.commentData['username'] ?? 'Anonymous',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                widget.formatTimestamp(
                                    widget.commentData['createdAt'] ??
                                        widget.commentData['commentTime']),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.grey.shade500,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.commentData['comments'] ?? '',
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const SizedBox(width: 48),
                    TextButton.icon(
                      onPressed: widget.onLikeComment,
                      icon: Icon(Icons.thumb_up_outlined,
                          size: 16, color: Colors.grey.shade700),
                      label: Text(
                        'Like',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _isReplyOpen = !_isReplyOpen;
                        });
                      },
                      icon: Icon(Icons.reply,
                          size: 16, color: Colors.grey.shade700),
                      label: Text(
                        'Reply',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_isReplyOpen)
            ReplyWidget(
              replyController: widget.replyController,
              onReplySubmitted: widget.onReplySubmitted,
              onCancel: () {
                setState(() {
                  _isReplyOpen = false;
                });
              },
            ),
          RepliesSection(
            thoughtId: widget.thoughtId,
            commentId: widget.commentId,
            areRepliesExpanded: _areRepliesExpanded,
            formatTimestamp: widget.formatTimestamp,
            firestore: widget.firestore,
            onToggleExpand: () {
              setState(() {
                _areRepliesExpanded = !_areRepliesExpanded;
              });
            },
          ),
        ],
      ),
    );
  }
}

class UserAvatarCache {
  // Static cache to persist across widget instances
  static final Map<String, Future<DocumentSnapshot?>> _cache = {};

  // Method to get user data with caching
  static Future<DocumentSnapshot?> getUserData(
      String? userId, FirebaseFirestore firestore) {
    if (userId == null) return Future.value(null);

    // Return cached future if it exists
    if (!_cache.containsKey(userId)) {
      _cache[userId] = firestore.collection('users').doc(userId).get();
    }

    return _cache[userId]!;
  }
}

class UserAvatar extends StatelessWidget {
  final String? userId;
  final double size;
  final FirebaseFirestore firestore;

  const UserAvatar({
    super.key,
    required this.userId,
    required this.size,
    required this.firestore,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot?>(
      future: UserAvatarCache.getUserData(userId, firestore),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.grey.shade300,
            child: const CircularProgressIndicator(strokeWidth: 2),
          );
        }

final data = snapshot.data?.data() as Map<String, dynamic>?;
final imageUrl = data?['avatar'] as String? ?? '';

        if (imageUrl.isNotEmpty) {
          return CircleAvatar(
            radius: size / 2,
            backgroundColor: Colors.grey.shade200,
            // backgroundImage: CachedNetworkImage(
            //
            //     imageUrl: imageUrl);
            child: ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                width: size,
                height: size,
                cacheKey: "$userId-avatar",
                progressIndicatorBuilder: (context, url, downloadProgress) =>
                    Center(
                  child: CircularProgressIndicator(
                      value: downloadProgress.progress),
                ),
                errorWidget: (context, url, error) => Icon(
                  Icons.person,
                  size: size / 2,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        return CircleAvatar(
          radius: size / 2,
          backgroundColor: Colors.blue.shade200,
          child: Icon(
            Icons.person,
            size: size / 2,
            color: Colors.white,
          ),
        );
      },
    );
  }
}

class ReplyWidget extends StatelessWidget {
  final TextEditingController replyController;
  final Function(String) onReplySubmitted;
  final VoidCallback onCancel;

  const ReplyWidget({
    super.key,
    required this.replyController,
    required this.onReplySubmitted,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 48, right: 12, bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: replyController,
              decoration: InputDecoration(
                hintText: "Write a reply...",
                hintStyle: TextStyle(color: Colors.grey.shade500),
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              maxLines: 3,
              minLines: 1,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: () {
              if (replyController.text.trim().isNotEmpty) {
                onReplySubmitted(replyController.text.trim());
              }
            },
            icon: Icon(Icons.send_rounded, color: Colors.blue.shade500),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.shade50,
              padding: const EdgeInsets.all(8),
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: Icon(Icons.close, color: Colors.red.shade500),
            style: IconButton.styleFrom(
              backgroundColor: Colors.red.shade50,
              padding: const EdgeInsets.all(8),
            ),
          ),
        ],
      ),
    );
  }
}

class RepliesSection extends StatelessWidget {
  final String thoughtId;
  final String commentId;
  final bool areRepliesExpanded;
  final String Function(dynamic) formatTimestamp;
  final FirebaseFirestore firestore;
  final VoidCallback onToggleExpand;

  const RepliesSection({
    super.key,
    required this.thoughtId,
    required this.commentId,
    required this.areRepliesExpanded,
    required this.formatTimestamp,
    required this.firestore,
    required this.onToggleExpand,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot?>(
      stream: ThoughtsService().getReply(thoughtId, commentId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.only(left: 48, bottom: 12),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final replies = snapshot.data!.docs;
        final replyCount = replies.length;

        if (!areRepliesExpanded) {
          return Padding(
            padding: const EdgeInsets.only(left: 48, bottom: 12, top: 4),
            child: TextButton.icon(
              onPressed: onToggleExpand,
              icon: Icon(
                Icons.expand_more,
                size: 18,
                color: Colors.grey.shade700,
              ),
              label: Text(
                'View $replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 48, bottom: 8, top: 4),
              child: TextButton.icon(
                onPressed: onToggleExpand,
                icon: Icon(
                  Icons.expand_less,
                  size: 18,
                  color: Colors.grey.shade700,
                ),
                label: Text(
                  'Hide replies',
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: replies.length,
              itemBuilder: (context, index) {
                final replyData = replies[index].data() as Map<String, dynamic>;
                return Padding(
                  padding:
                      const EdgeInsets.only(left: 48, right: 12, bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      UserAvatar(
                        userId: replyData['userId'],
                        size: 28,
                        firestore: firestore,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    replyData['userName'] ?? 'Anonymous',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    formatTimestamp(replyData['createdAt']),
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(
                                          color: Colors.grey.shade600,
                                          fontSize: 11,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                replyData['reply'] ?? '',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
