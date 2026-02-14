import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/news/news_service.dart';
import 'package:timeago/timeago.dart' as timeago;

class NewsCommentsScreen extends StatefulWidget {
  final String articleId;
  final String articleTitle;

  const NewsCommentsScreen({
    super.key,
    required this.articleId,
    required this.articleTitle,
  });

  @override
  State<NewsCommentsScreen> createState() => _NewsCommentsScreenState();
}

class _NewsCommentsScreenState extends State<NewsCommentsScreen> {
  final NewsService _newsService = NewsService();
  final TextEditingController _commentController = TextEditingController();

  // PALETTE: Midnight Blue (Premium)
  final Color kBackground = const Color(0xFF0F172A); // Deep Navy
  final Color kSurface = const Color(0xFF1E293B); // Lighter Navy
  final Color kTextPrimary = const Color(0xFFF8FAFC); // Cool White
  final Color kTextSecondary = const Color(0xFF94A3B8); // Blue-Gray
  final Color kAccent = const Color(0xFF38BDF8); // Cyan/Sky Blue

  String? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSend() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    _commentController.clear();
    FocusScope.of(context).unfocus();

    try {
      if (_replyingToCommentId != null) {
        await _newsService.addNewsReply(
            widget.articleId, _replyingToCommentId!, text);
        setState(() {
          _replyingToCommentId = null;
          _replyingToUserName = null;
        });
      } else {
        await _newsService.addNewsComment(widget.articleId, text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to post: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: Text(
          "Comments",
          style: GoogleFonts.dmSerifText(
              color: kTextPrimary, fontSize: 22, letterSpacing: 0.5),
        ),
        centerTitle: true,
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: kTextPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFF334155), height: 1),
        ),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: kSurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TOPIC",
                  style: GoogleFonts.poppins(
                      color: kAccent,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.articleTitle,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: kTextPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.4),
                ),
              ],
            ),
          ),

          // 2. Comments List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _newsService.getNewsComments(widget.articleId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                      child: CircularProgressIndicator(color: kAccent));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined,
                            size: 50, color: kSurface.withValues(alpha: 1.0)),
                        const SizedBox(height: 16),
                        Text(
                          "Be the first to write comment",
                          style: GoogleFonts.poppins(
                              color: kTextSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final comment = snapshot.data!.docs[index];
                    return _buildCommentItem(comment);
                  },
                );
              },
            ),
          ),

          // 3. Input Area
          Container(
            decoration: BoxDecoration(
                color: kSurface,
                border: const Border(top: BorderSide(color: Color(0xFF334155))),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  )
                ]),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingToUserName != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: kBackground.withValues(alpha: 0.5),
                    child: Row(
                      children: [
                        Icon(Icons.subdirectory_arrow_right,
                            size: 16, color: kAccent),
                        const SizedBox(width: 8),
                        Text(
                          "Replying to ",
                          style: TextStyle(fontSize: 12, color: kTextSecondary),
                        ),
                        Text(
                          _replyingToUserName!,
                          style: TextStyle(
                              fontSize: 12,
                              color: kAccent,
                              fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _replyingToCommentId = null;
                              _replyingToUserName = null;
                            });
                          },
                          child: Icon(Icons.close,
                              size: 18, color: kTextSecondary),
                        )
                      ],
                    ),
                  ),

                // Input Field
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: kBackground,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF334155)),
                          ),
                          child: TextField(
                            controller: _commentController,
                            style: TextStyle(color: kTextPrimary),
                            decoration: InputDecoration(
                              hintText: _replyingToUserName != null
                                  ? "Type your reply..."
                                  : "Write a comment...",
                              hintStyle: TextStyle(
                                  color: kTextSecondary.withValues(alpha: 0.7)),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              isDense: true,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                            color: kAccent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                  color: kAccent.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4))
                            ]),
                        child: IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.black, size: 22),
                          onPressed: _handleSend,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentItem(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final commentId = doc.id;
    final timestamp = (data['timestamp'] as Timestamp?)?.toDate();
    final timeAgo = timestamp != null ? timeago.format(timestamp) : 'Just now';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: kSurface)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                    color: kAccent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: kAccent.withValues(alpha: 0.3))),
                child: ClipOval(
                  child: (data['userAvatar'] != null &&
                          data['userAvatar'] != '')
                      ? Image.network(data['userAvatar'], fit: BoxFit.cover)
                      : Center(
                          child: Icon(Icons.person, size: 18, color: kAccent)),
                ),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          data['username'] ?? 'Anonymous',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: kTextPrimary),
                        ),
                        Text(
                          timeAgo,
                          style: GoogleFonts.poppins(
                              fontSize: 11, color: kTextSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data['text'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: const Color(0xFFCBD5E1), // Softer white
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Actions
                    Row(
                      children: [
                        const SizedBox(width: 15),
                        InkWell(
                          onTap: () {
                            setState(() {
                              _replyingToCommentId = commentId;
                              _replyingToUserName = data['username'];
                            });
                          },
                          child: Text(
                            "Reply",
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kAccent,
                            ),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            ],
          ),

          // REPLIES SECTION
          StreamBuilder<QuerySnapshot>(
            stream: _newsService.getNewsReplies(widget.articleId, commentId),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(left: 48.0, top: 12),
                child: Column(
                  children: snapshot.data!.docs.map((replyDoc) {
                    final replyData = replyDoc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: kSurface,
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: (replyData['userAvatar'] != null &&
                                      replyData['userAvatar'] != '')
                                  ? Image.network(replyData['userAvatar'],
                                      fit: BoxFit.cover)
                                  : Icon(Icons.person,
                                      size: 14, color: kTextSecondary),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  replyData['username'] ?? 'Anonymous',
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                      color: kTextPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  replyData['text'] ?? '',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: const Color(0xFFCBD5E1),
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          )
        ],
      ),
    );
  }
}
