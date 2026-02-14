import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/thoughts/thoughts_service.dart';
import 'package:intl/intl.dart';

class AddComment extends StatefulWidget {
  final String? username;
  final String? thoughtId;
  final String? userId;
  final String? collectionCall;
  final _commentController = TextEditingController();

  AddComment({
    super.key,
    required this.thoughtId,
    required this.userId,
    required this.username,
    this.collectionCall,
  });

  @override
  State<AddComment> createState() => _AddCommentState();
}

class _AddCommentState extends State<AddComment> {
  late final Future<DocumentSnapshot?> _thoughtFuture;
  late final Future<DocumentSnapshot?> _userFuture;

  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLikeLoading = false;

  @override
  void initState() {
    super.initState();
    _thoughtFuture = getThoughtData(widget.thoughtId);

    debugPrint(
        "widget.thoughtId: ${widget.thoughtId} collectionCall: ${widget.collectionCall}");
    _userFuture = getUserData(widget.userId);
    _loadLikeStatus();
  }

  @override
  void dispose() {
    // If you decide to move controller to State, dispose here. It's on the widget currently.
    super.dispose();
  }

  Future<void> _loadLikeStatus() async {
    if (widget.thoughtId == null) return;
    try {
      final isLiked = await ThoughtsService().checkIfLiked(widget.thoughtId!);
      final likeCount = await ThoughtsService().getLikeCount(widget.thoughtId!);

      setState(() {
        _isLiked = isLiked;
        _likeCount = likeCount;
      });
    } catch (e) {
      debugPrint('Error loading like status : ${e.toString()}');
    }
  }

  Future<DocumentSnapshot?> getThoughtData(String? thoughtId) async {
    if ((widget.collectionCall == null) || (widget.collectionCall!.isEmpty)) {
      debugPrint("collectionCall is null/empty");
      return null;
    }
    try {
      if (thoughtId == null || thoughtId.isEmpty) {
        debugPrint("getThoughtData: thoughtId is null/empty");
        return null;
      }

      return await FirebaseFirestore.instance
          .collection(widget.collectionCall!)
          .doc(thoughtId)
          .get();
    } catch (e) {
      debugPrint(e.toString());
      throw Exception();
    }
  }

  Future<DocumentSnapshot?> getUserData(String? userId) async {
    try {
      if (userId == null) return null;
      return await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
    } catch (e) {
      debugPrint(e.toString());
      throw Exception();
    }
  }

  Future<void> addpostIdComment() async {
    try {
      await ThoughtsService().createComment(
        widget.thoughtId!,
        widget._commentController.text,
        widget.collectionCall!,
      );

      widget._commentController.clear();
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comment Posted Successfully')),
      );
    } catch (e) {
      debugPrint("error came for comment ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fail to post comment')),
      );
    }
  }

  String _getInitial(String? name) {
    if (name == null) return "?";
    final trimmed = name.trim();
    if (trimmed.isEmpty) return "?";
    try {
      final first = trimmed.characters.first;
      return first.toUpperCase();
    } catch (e) {
      final runes = trimmed.runes;
      if (runes.isEmpty) return "?";
      return String.fromCharCode(runes.first).toUpperCase();
    }
  }

  Widget _buildPostCard(DocumentSnapshot thoughtData, String? avatarUrl) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Author header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[700],
                  radius: 20,
                  child: avatarUrl != null && avatarUrl.isNotEmpty
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: avatarUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorWidget: (context, error, stackTrace) {
                              final initial = _getInitial(widget.username);
                              return Text(
                                initial,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        )
                      : Text(
                          _getInitial(widget.username),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.username ?? "Anonymous",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Original post",
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Text(
              thoughtData.data() != null &&
                      (thoughtData.data() as Map<String, dynamic>)
                          .containsKey('thought')
                  ? thoughtData['thought']
                  : "No content",
              style: GoogleFonts.poppins(
                fontSize: 16,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildReplyInfo() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      color: Theme.of(context).colorScheme.secondary,
      child: Text(
        "Replying to ${widget.username}",
        style: GoogleFonts.poppins(
          color: Colors.blue[700],
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold already had resizeToAvoidBottomInset: true in original; keep it.
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: Text(
          "Comments",
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder(
        future: Future.wait([_thoughtFuture, _userFuture]),
        builder: (context, AsyncSnapshot<List<DocumentSnapshot?>> snapshot) {
          if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.length < 2 ||
              snapshot.data![0] == null) {
            return const Center(child: Text("No data available"));
          }

          final thoughtData = snapshot.data![0]!;
          final userData = snapshot.data?[1];
          final data = userData?.data() as Map<String, dynamic>?;
          final String? avatarUrl = data?['avatar']?.toString();

          return Column(
            children: [
              // Use Expanded ListView to resize automatically when keyboard shows
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: ThoughtsService().getCommentsStream(
                      widget.thoughtId!, widget.collectionCall!),
                  builder: (context, commentsSnapshot) {
                    if (commentsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (commentsSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${commentsSnapshot.error}'));
                    }

                    final comments = commentsSnapshot.data ?? [];

                    // Build list children: post card, reply info, then comments (or "No comments yet")
                    final List<Widget> children = [
                      _buildPostCard(thoughtData, avatarUrl),
                      _buildReplyInfo(),
                      const SizedBox(height: 8),
                    ];

                    if (comments.isEmpty) {
                      children.add(
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24.0),
                            child: Text(
                              "No comments yet",
                              style:
                                  GoogleFonts.poppins(color: Colors.grey[600]),
                            ),
                          ),
                        ),
                      );
                    } else {
                      // Add comment widgets
                      for (var c in comments) {
                        children.add(CommentCardCommenter(comment: c));
                      }
                      // Add some bottom spacing so last comment isn't hidden by input
                      children.add(const SizedBox(height: 12));
                    }

                    return ListView(
                      padding: EdgeInsets.zero,
                      children: children,
                    );
                  },
                ),
              ),

              // Bottom input - use SafeArea and adjust padding by viewInsets (keyboard)
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 8,
                    top: 8,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -4),
                        ),
                      ],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: widget._commentController,
                            minLines: 1,
                            maxLines: 5,
                            decoration: InputDecoration(
                              hintText: "Write your reply...",
                              hintStyle: GoogleFonts.poppins(
                                  color: Theme.of(context).colorScheme.primary),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              filled: true,
                              fillColor:
                                  Theme.of(context).colorScheme.secondary,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(24),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Material(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.circular(24),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () {
                                if (widget._commentController.text
                                    .trim()
                                    .isNotEmpty) {
                                  addpostIdComment();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                child: const Icon(
                                  Icons.send_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class CommentCardCommenter extends StatelessWidget {
  final Map<String, dynamic> comment;

  const CommentCardCommenter({super.key, required this.comment});

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes} mins ago";
    if (diff.inHours < 24) return "${diff.inHours} hrs ago";
    return DateFormat('MMM d, yyyy').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final timestamp = comment['commentTime'];
    final commentTime =
        timestamp != null ? (timestamp.toDate() as DateTime) : DateTime.now();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          /// User info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: const AssetImage('assets/chat_icon.png'),
                backgroundColor: Colors.grey[300],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  comment['username'] ?? 'Unknown',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          /// Comment text
          Text(
            comment['commentText'] ?? comment['comments'] ?? '',
            style: GoogleFonts.poppins(fontSize: 15),
          ),

          const SizedBox(height: 12),

          /// Footer (time)
          Row(
            children: [
              Text(
                _timeAgo(commentTime),
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
