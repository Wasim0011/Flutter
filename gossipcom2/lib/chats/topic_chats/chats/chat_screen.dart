import 'dart:typed_data';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/profile/others_profile/other_profile.dart';
import 'package:gossipcom/profile/others_profile/review_user.dart';
import 'package:image_picker/image_picker.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String? otherUserName;

  const ChatScreen({
    required this.chatId,
    required this.otherUserId,
    this.otherUserName,
    super.key,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _controller = TextEditingController();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  late final DocumentReference _mainChatRef;
  late final CollectionReference _messagesRef;
  late final DocumentReference _userChatRef;
  late final DocumentReference _otherUserChatRef;
  String _otherUserName = 'Anonymous';
  String _chatTopic = '';
  List<XFile> _selectedImages = [];
  bool _isSendingImages = false;
  bool _isInitialized = false;

  // User avatar URLs
  String? _currentUserAvatarUrl;
  String? _otherUserAvatarUrl;

  // For auto-clearing functionality
  Timer? _cleanupTimer;
  final int _autoDeleteDays = 7;

  // Stream subscriptions to properly manage and dispose
  StreamSubscription? _messagesSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _initializeFirestoreReferences();
    _loadInitialData();
  }

  void _initializeFirestoreReferences() {
    _mainChatRef =
        FirebaseFirestore.instance.collection('topic_chats').doc(widget.chatId);
    _messagesRef = _mainChatRef.collection('messages');
    _userChatRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats')
        .doc(widget.chatId);
    _otherUserChatRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.otherUserId)
        .collection('chats')
        .doc(widget.chatId);
  }

  void _scheduleCleanupCheck() {
    // Cancel any existing timer first
    _cleanupTimer?.cancel();

    // Check for old messages once when the chat opens
    _cleanupOldMessages();

    // Set up timer to periodically check for messages to clean up (every 24 hours)
    _cleanupTimer = Timer.periodic(const Duration(hours: 24), (timer) {
      _cleanupOldMessages();
    });
  }

  Future<void> _cleanupOldMessages() async {
    try {
      // Calculate cutoff date (7 days ago)
      final DateTime cutoffDate =
          DateTime.now().subtract(Duration(days: _autoDeleteDays));
      final Timestamp cutoffTimestamp = Timestamp.fromDate(cutoffDate);

      // Query for messages older than 7 days
      final QuerySnapshot oldMessages = await _messagesRef
          .where('timestamp', isLessThan: cutoffTimestamp)
          .get();

      if (oldMessages.docs.isEmpty) return;

      // Create a batch for deleting messages
      final batch = FirebaseFirestore.instance.batch();
      final List<String> imageUrlsToDelete = [];

      // Add each message to deletion batch
      for (final doc in oldMessages.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // If message has an image, add URL to list for deletion from storage
        if (data['imageUrl'] != null) {
          imageUrlsToDelete.add(data['imageUrl'] as String);
        }

        // Add document to deletion batch
        batch.delete(doc.reference);
      }

      // Commit the batch to delete messages
      await batch.commit();

      // Delete images from storage
      for (final imageUrl in imageUrlsToDelete) {
        try {
          // Extract reference path from URL
          final ref = FirebaseStorage.instance.refFromURL(imageUrl);
          await ref.delete();
        } catch (e) {
          debugPrint('Error deleting image $imageUrl: $e');
        }
      }

      debugPrint(
          'Cleaned up ${oldMessages.docs.length} old messages and ${imageUrlsToDelete.length} images');

      // Update chat metadata if needed
      await _updateChatMetadataAfterCleanup();
    } catch (e) {
      debugPrint('Error cleaning up old messages: $e');
    }
  }

  Future<void> _updateChatMetadataAfterCleanup() async {
    try {
      // Get the newest message after cleanup
      final QuerySnapshot remainingMessages = await _messagesRef
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (remainingMessages.docs.isEmpty) {
        // If no messages left, update metadata accordingly
        final batch = FirebaseFirestore.instance.batch();

        batch.update(_mainChatRef, {
          'lastMessage': 'No messages',
          'lastMessageTime': FieldValue.serverTimestamp(),
        });

        batch.update(_userChatRef, {
          'lastMessage': 'No messages',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        });

        batch.update(_otherUserChatRef, {
          'lastMessage': 'No messages',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        });

        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error updating chat metadata after cleanup: $e');
    }
  }

  Future<void> _loadInitialData() async {
    try {
      _otherUserName = widget.otherUserName ?? 'Anonymous';

      await Future.wait([
        _loadChatTopic(),
        widget.otherUserName == null ? _loadOtherUserName() : Future.value(),
        _markMessagesAsRead(),
        _loadUserAvatars(),
      ]);

      // Set initialized flag after all data is loaded
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });

        // Schedule cleanup only after initialization is complete
        _scheduleCleanupCheck();
      }
    } catch (e) {
      debugPrint('Error loading initial data: $e');
      // Set initialized even on error to avoid completely broken UI
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  Future<void> _loadUserAvatars() async {
    try {
      // Load current user's avatar
      final currentUserDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      String? currentUserAvatar;
      if (currentUserDoc.exists &&
          currentUserDoc.data()!.containsKey('avatar')) {
        currentUserAvatar = currentUserDoc.get('avatar');
      }

      // Load other user's avatar
      final otherUserDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      String? otherUserAvatar;
      if (otherUserDoc.exists && otherUserDoc.data()!.containsKey('avatar')) {
        otherUserAvatar = otherUserDoc.get('avatar');
      }

      // Update state only once with both avatars
      if (mounted) {
        setState(() {
          _currentUserAvatarUrl = currentUserAvatar;
          _otherUserAvatarUrl = otherUserAvatar;
        });
      }
    } catch (e) {
      debugPrint('Error loading user avatars: $e');
    }
  }

  Future<void> _loadChatTopic() async {
    try {
      final chatDoc = await _userChatRef.get();
      if (chatDoc.exists && mounted) {
        setState(() {
          _chatTopic = chatDoc.get('topic') ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading chat topic: $e');
    }
  }

  Future<void> _loadOtherUserName() async {
    try {
      final otherUser = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.otherUserId)
          .get();

      if (mounted && otherUser.exists) {
        setState(() {
          _otherUserName = otherUser.get('userName') ?? 'Anonymous';
        });
      }
    } catch (e) {
      debugPrint('Error loading other user name: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      batch.update(_userChatRef, {'unreadCount': 0});

      final chatData = await _userChatRef.get();
      if (chatData.exists &&
          chatData.get('lastMessageSender') == widget.otherUserId) {
        batch.update(_otherUserChatRef, {'unreadCount': 0});
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  // Widget to display user avatar from URL
  Widget _buildUserAvatar(String? avatarUrl, String userName) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        radius: 16,
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.grey[200],
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Error loading avatar image: $exception');
        },
      );
    } else {
      // Fallback to text avatar if no image available
      return CircleAvatar(
        radius: 16,
        backgroundColor: Colors.blue[100],
        child: Text(
          userName.isNotEmpty ? userName[0] : '?',
          style: const TextStyle(fontSize: 14),
        ),
      );
    }
  }

  // Widget to display larger user avatar in app bar
  Widget _buildAppBarAvatar(String? avatarUrl, String userName) {
    if (avatarUrl != null && avatarUrl.isNotEmpty) {
      return CircleAvatar(
        backgroundImage: NetworkImage(avatarUrl),
        backgroundColor: Colors.grey[200],
        onBackgroundImageError: (exception, stackTrace) {
          debugPrint('Error loading avatar image: $exception');
        },
      );
    } else {
      // Fallback to text avatar if no image available
      return CircleAvatar(
        backgroundColor: Colors.blue[100],
        child: Text(userName.isNotEmpty ? userName[0] : '?'),
      );
    }
  }

  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isNotEmpty && mounted) {
        setState(() {
          _selectedImages = pickedFiles;
        });

        // Show image preview dialog
        showDialog(
          context: context,
          builder: (context) => ImagePreviewDialog(
            images: _selectedImages,
            onSend: () {
              Navigator.pop(context);
              sendImages();
            },
            onCancel: () {
              setState(() {
                _selectedImages = [];
              });
              Navigator.pop(context);
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick images: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> sendImages() async {
    if (_selectedImages.isEmpty) return;

    if (mounted) {
      setState(() {
        _isSendingImages = true;
      });
    }

    try {
      // Show sending indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text('Sending ${_selectedImages.length} image(s)...'),
              ],
            ),
            duration: const Duration(seconds: 30),
          ),
        );
      }

      final batch = FirebaseFirestore.instance.batch();
      List<String> uploadedUrls = [];

      // Upload all images first
      for (final pickedFile in _selectedImages) {
        final String fileName =
            DateTime.now().millisecondsSinceEpoch.toString() +
                '_${uploadedUrls.length}';
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('chat_images')
            .child(widget.chatId)
            .child(fileName);

        // Upload file
        final UploadTask uploadTask =
            storageRef.putData(await pickedFile.readAsBytes());
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();
        uploadedUrls.add(downloadUrl);
      }

      // Create a message for each image
      for (final url in uploadedUrls) {
        final messageData = {
          'senderId': uid,
          'imageUrl': url,
          'timestamp': FieldValue.serverTimestamp(),
        };

        final newMessageRef = _messagesRef.doc();
        batch.set(newMessageRef, messageData);
      }

      // Update chat metadata with last message info
      batch.update(_mainChatRef, {
        'lastMessage': '[${uploadedUrls.length} Image(s)]',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': uid,
      });

      batch.update(_userChatRef, {
        'lastMessage': '[${uploadedUrls.length} Image(s)]',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': uid,
        'unreadCount': 0,
      });

      batch.update(_otherUserChatRef, {
        'lastMessage': '[${uploadedUrls.length} Image(s)]',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': uid,
        'unreadCount': FieldValue.increment(1),
      });

      await batch.commit();

      // Clear selected images and dismiss the loading indicator
      if (mounted) {
        setState(() {
          _selectedImages = [];
          _isSendingImages = false;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${uploadedUrls.length} image(s) sent successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSendingImages = false;
        });

        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send images: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> sendMessage() async {
    final messageText = _controller.text.trim();
    if (messageText.isEmpty) return;

    _controller.clear();

    try {
      final messageData = {
        'senderId': uid,
        'text': messageText,
        'timestamp': FieldValue.serverTimestamp(),
      };

      final batch = FirebaseFirestore.instance.batch();

      final newMessageRef = _messagesRef.doc();
      batch.set(newMessageRef, messageData);

      batch.update(_mainChatRef, {
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': uid,
      });

      batch.update(_userChatRef, {
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': uid,
        'unreadCount': 0,
      });

      batch.update(_otherUserChatRef, {
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': uid,
        'unreadCount': FieldValue.increment(1),
      });

      await batch.commit();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send message: ${e.toString()}')),
        );
      }
    }
  }

  // Open full-screen image view
  void _openFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => FullScreenImageView(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.otherUserName ?? 'Chat'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      // In your ChatScreen's build method, modify the app bar section
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            if (widget.otherUserId.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User information not available')),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => OtherProfile(
                  otherUserId: widget.otherUserId,
                  otherUserName: _otherUserName,
                ),
              ),
            );
          },
          child: Row(
            children: [
              _buildAppBarAvatar(_otherUserAvatarUrl, _otherUserName),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _otherUserName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Messages auto-delete after $_autoDeleteDays days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          const Divider(thickness: 1, color: Colors.grey),
          // Display the topic
          if (_chatTopic.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200, width: 1),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.topic,
                    color: Colors.blue.shade700,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Topic: $_chatTopic',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _messagesRef
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('Start the conversation!'));
                }

                return ListView.builder(
                  reverse: true,
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == uid;
                    final timestamp = data['timestamp'] != null
                        ? (data['timestamp'] as Timestamp).toDate()
                        : DateTime.now();

                    // Calculate days remaining before deletion
                    final DateTime expiryDate =
                        timestamp.add(Duration(days: _autoDeleteDays));
                    final int daysRemaining =
                        expiryDate.difference(DateTime.now()).inDays + 1;
                    final bool expiringToday = daysRemaining <= 1;

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: isMe
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isMe) ...[
                            _buildUserAvatar(
                                _otherUserAvatarUrl, _otherUserName),
                            const SizedBox(width: 5),
                          ],
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 12,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    isMe ? Colors.blue[100] : Colors.grey[300],
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(12),
                                  topRight: const Radius.circular(12),
                                  bottomLeft: Radius.circular(isMe ? 12 : 0),
                                  bottomRight: Radius.circular(isMe ? 0 : 12),
                                ),
                                // Add a red border if the message is expiring today
                                border: expiringToday
                                    ? Border.all(color: Colors.red, width: 1)
                                    : null,
                              ),
                              child: Stack(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (!isMe)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 4),
                                            child: Text(
                                              _otherUserName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                                color: Colors.black54,
                                              ),
                                            ),
                                          ),
                                        if (data['imageUrl'] != null)
                                          GestureDetector(
                                            onTap: () => _openFullScreenImage(
                                                data['imageUrl']),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color: Colors.grey.shade300,
                                                  width: 1,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                child: Hero(
                                                  tag: data['imageUrl'],
                                                  child: Image.network(
                                                    data['imageUrl'],
                                                    height: 200,
                                                    width: 200,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context,
                                                        child,
                                                        loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) return child;
                                                      return Container(
                                                        height: 200,
                                                        width: 200,
                                                        color: Colors.grey[200],
                                                        child: Center(
                                                          child:
                                                              CircularProgressIndicator(
                                                            value: loadingProgress
                                                                        .expectedTotalBytes !=
                                                                    null
                                                                ? loadingProgress
                                                                        .cumulativeBytesLoaded /
                                                                    loadingProgress
                                                                        .expectedTotalBytes!
                                                                : null,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          Text(
                                            data['text'] ?? '',
                                            style:
                                                 TextStyle(fontSize: 14 ,color: Theme.of(context).colorScheme.surface),
                                          ),
                                        // Add expiry indicator for messages nearing expiration
                                        if (daysRemaining <= 2)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Text(
                                              expiringToday
                                                  ? 'Expires today'
                                                  : 'Expires in $daysRemaining day${daysRemaining > 1 ? "s" : ""}',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: expiringToday
                                                    ? Colors.red
                                                    : Colors.orange,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    right: 0,
                                    bottom: 0,
                                    child: Text(
                                      _formatTimestamp(timestamp),
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 5),
                            _buildUserAvatar(
                                _currentUserAvatarUrl,
                                FirebaseAuth
                                        .instance.currentUser!.displayName ??
                                    'User'),
                          ],
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey, width: 1)),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.photo, color: Colors.grey),
                      onPressed: _isSendingImages ? null : pickImages,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Type Something',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        onSubmitted: (_) => sendMessage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.grey),
                      onPressed: sendMessage,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                child: InkWell(
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey, width: 1)),
                      child: Text(
                        "Suggested Questions",
                        style: GoogleFonts.abhayaLibre(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                child: InkWell(
                  onTap: () {
                    showDialog(
                        context: context,
                        builder: (context) {
                          return AlertDialog(
                            title: const Text(
                              'End Discussion',
                              style: TextStyle(color: Colors.red),
                            ),
                            content:
                                const Text('end the discussion and review the user'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context); // Close the alert box
                                },
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  // Close the alert box
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => ReviewUser(
                                              userId: widget.otherUserId,
                                              onTap: () {
                                                Navigator.pop(context);
                                                Navigator.pop(context);
                                              })));
                                },
                                child: const Text(
                                  'yes',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          );
                        });
                  },
                  child: Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.red, width: 1)),
                      child: Text(
                        "End Discussion",
                        style: GoogleFonts.abhayaLibre(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    // Clean up all resources when the widget is disposed
    _controller.dispose();
    _cleanupTimer?.cancel();
    _messagesSubscription?.cancel();
    super.dispose();
  }
}

// Image Preview Dialog Widget
class ImagePreviewDialog extends StatelessWidget {
  final List<XFile> images;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const ImagePreviewDialog({
    required this.images,
    required this.onSend,
    required this.onCancel,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Preview Images (${images.length})',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FutureBuilder<Uint8List>(
                      future: images[index].readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Container(
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        if (snapshot.hasError || !snapshot.hasData) {
                          return Container(
                            width: 150,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(Icons.error, color: Colors.red),
                            ),
                          );
                        }
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.memory(
                            snapshot.data!,
                            width: 150,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: onCancel,
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onSend,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Send'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Full Screen Image Viewer Widget
class FullScreenImageView extends StatelessWidget {
  final String imageUrl;

  const FullScreenImageView({
    required this.imageUrl,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: Hero(
            tag: imageUrl,
            child: Image.network(imageUrl, fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: Colors.white,
                ),
              );
            }, errorBuilder: (context, error, stackTrace) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Error loading image',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
