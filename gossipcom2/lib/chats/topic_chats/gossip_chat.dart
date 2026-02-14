import 'dart:typed_data';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:gossipcom/profile/others_profile/other_profile.dart';

class GossipGroupChatScreen extends StatefulWidget {
  final String chatId;
  final String groupName;
  final List<String> groupMembers;
  final bool isTrendingTopic;

  const GossipGroupChatScreen({
    required this.chatId,
    required this.groupName,
    required this.groupMembers,
    this.isTrendingTopic = false,
    super.key,
  });

  @override
  State<GossipGroupChatScreen> createState() => _GossipGroupChatScreenState();
}

class _GossipGroupChatScreenState extends State<GossipGroupChatScreen>
    with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  late final DocumentReference _mainChatRef;
  late final CollectionReference _messagesRef;
  late final DocumentReference _userChatRef;
  final Map<String, String> _memberNames = {};
  final Map<String, String> _memberAvatars = {};
  bool _isInitialized = false;
  bool _isLoadingNames = true;
  List<XFile> _selectedImages = [];
  bool _isSendingImages = false;
  bool _showMembers = false;

  // For auto-clearing functionality
  Timer? _cleanupTimer;
  final int _autoDeleteDays = 7;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFirestoreReferences();

    // Defer initialization slightly to avoid UI jank
    Future.microtask(() {
      _loadInitialData();
      _scheduleCleanupCheck();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Mark as read when screen comes into view
    if (_isInitialized) {
      _markMessagesAsRead();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Mark as read when app comes to foreground
    if (state == AppLifecycleState.resumed && _isInitialized) {
      _markMessagesAsRead();
    }
  }

  void _scheduleCleanupCheck() {
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

        await batch.commit();
      }
    } catch (e) {
      debugPrint('Error updating chat metadata after cleanup: $e');
    }
  }

  Future<void> _loadInitialData() async {
    try {
      // Load group data first
      await _loadGroupMembers();

      // Then load member names and avatars
      await _loadMemberData();

      // Finally mark messages as read
      await _markMessagesAsRead();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error during initialization: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isLoadingNames = false;
        });
      }
    }
  }

  Future<void> _loadMemberData() async {
    if (!mounted) return;

    setState(() {
      _isLoadingNames = true;
    });

    try {
      // Create temporary maps to avoid UI rebuilds
      final Map<String, String> tempNames = {};
      final Map<String, String> tempAvatars = {};

      // Get names and avatars for all members in parallel
      final futures = widget.groupMembers.map((memberId) async {
        try {
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .get();

          if (userDoc.exists) {
            return MapEntry(
              memberId,
              {
                'name': userDoc.get('userName') ?? 'Unknown',
                'avatar': userDoc.get('avatar') ?? '',
              },
            );
          } else {
            return MapEntry(
              memberId,
              {
                'name': 'Unknown',
                'avatar': '',
              },
            );
          }
        } catch (e) {
          debugPrint('Error loading data for member $memberId: $e');
          return MapEntry(
            memberId,
            {
              'name': 'Unknown',
              'avatar': '',
            },
          );
        }
      });

      // Wait for all futures to complete
      final results = await Future.wait(futures);

      // Add all results to the temporary maps
      for (final entry in results) {
        tempNames[entry.key] = entry.value['name']!;
        tempAvatars[entry.key] = entry.value['avatar']!;
      }

      // Update state only once with all data
      if (mounted) {
        setState(() {
          _memberNames.clear();
          _memberNames.addAll(tempNames);
          _memberAvatars.clear();
          _memberAvatars.addAll(tempAvatars);
          _isLoadingNames = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading member data: $e');
      if (mounted) {
        setState(() {
          _isLoadingNames = false;
        });
      }
    }
  }

  Future<void> _loadGroupMembers() async {
    try {
      final chatDoc = await _mainChatRef.get();
      if (chatDoc.exists) {
        final data = chatDoc.data() as Map<String, dynamic>?;
        if (data != null && data.containsKey('participants')) {
          final participants = List<String>.from(data['participants']);

          if (mounted && participants.isNotEmpty) {
            setState(() {
              // Clear and add instead of reassigning to maintain reference
              widget.groupMembers.clear();
              widget.groupMembers.addAll(participants);
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading group members: $e');
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _userChatRef.update({'unreadCount': 0});
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  void _initializeFirestoreReferences() {
    if (widget.isTrendingTopic) {
      _mainChatRef =
          FirebaseFirestore.instance.collection('trending_topic_chats').doc(widget.chatId);
      _messagesRef = _mainChatRef.collection('messages');
      _userChatRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('trending_group_chats')
          .doc(widget.chatId);
    } else {
      _mainChatRef =
          FirebaseFirestore.instance.collection('group_chats').doc(widget.chatId);
      _messagesRef = _mainChatRef.collection('messages');
      _userChatRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('group_chats')
          .doc(widget.chatId);
    }
  }

  Future<void> pickImages() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile> pickedFiles = await picker.pickMultiImage();

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages = pickedFiles;
        });

        // Show image preview dialog
        if (mounted) {
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

    setState(() {
      _isSendingImages = true;
    });

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
            '${DateTime.now().millisecondsSinceEpoch}_${uploadedUrls.length}';
        final Reference storageRef = FirebaseStorage.instance
            .ref()
            .child('group_images')
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

      // Update for all other members
      for (String memberId in widget.groupMembers) {
        if (memberId != uid) {
          final memberChatRef = FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .collection('group_chats')
              .doc(widget.chatId);

          batch.update(memberChatRef, {
            'lastMessage': '[${uploadedUrls.length} Image(s)]',
            'lastMessageTime': FieldValue.serverTimestamp(),
            'lastMessageSender': uid,
            'unreadCount': FieldValue.increment(1),
          });
        }
      }

      await batch.commit();

      // Clear selected images and dismiss the loading indicator
      setState(() {
        _selectedImages = [];
        _isSendingImages = false;
      });

      if (mounted) {
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
      setState(() {
        _isSendingImages = false;
      });

      if (mounted) {
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

      // Add the new message
      final newMessageRef = _messagesRef.doc();
      batch.set(newMessageRef, messageData);

      // Update the main group chat document
      batch.update(_mainChatRef, {
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': uid,
      });

      // Update user's chat reference
      batch.update(_userChatRef, {
        'lastMessage': messageText,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastMessageSender': uid,
        'unreadCount': 0,
      });

      // Update for all other members
      for (String memberId in widget.groupMembers) {
        if (memberId != uid) {
          final memberChatRef = FirebaseFirestore.instance
              .collection('users')
              .doc(memberId)
              .collection('group_chats')
              .doc(widget.chatId);

          batch.update(memberChatRef, {
            'lastMessage': messageText,
            'lastMessageTime': FieldValue.serverTimestamp(),
            'lastMessageSender': uid,
            'unreadCount': FieldValue.increment(1),
          });
        }
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Send message error: ${e.toString()}');

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
    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () => _showGroupInfoDialog(),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: _memberAvatars[uid]?.isNotEmpty == true
                    ? NetworkImage(_memberAvatars[uid]!)
                    : null,
                backgroundColor: Colors.green[100],
                child: _memberAvatars[uid]?.isEmpty == true
                    ? Text(
                        widget.groupName.isNotEmpty ? widget.groupName[0] : 'G')
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.groupName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Messages auto-delete after $_autoDeleteDays days',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          if (widget.isTrendingTopic)
            IconButton(
              onPressed: () {
                setState(() {
                  _showMembers = !_showMembers;
                });
              },
              icon: Icon(
                _showMembers ? Icons.visibility_off : Icons.visibility,
                color: Colors.white,
              ),
              tooltip: _showMembers ? 'Hide Members' : 'Show Members',
            ),
        ],
      ),
      body: !_isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const Divider(thickness: 1, color: Colors.grey),
                // Members List for Trending Topic
                if (widget.isTrendingTopic && _showMembers)
                  Container(
                    height: 120,
                    margin: EdgeInsets.all(8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade300, width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Group Members (${widget.groupMembers.length})",
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.groupMembers.length,
                            itemBuilder: (context, index) {
                              final memberId = widget.groupMembers[index];
                              final memberName = _memberNames[memberId] ?? 'Loading...';
                              final isCurrentUser = memberId == uid;
                              
                              return Container(
                                margin: EdgeInsets.only(right: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 20,
                                      backgroundColor: isCurrentUser ? Colors.blue : Colors.grey.shade400,
                                      child: _memberAvatars[memberId]?.isNotEmpty == true
                                          ? ClipOval(
                                              child: Image.network(
                                                _memberAvatars[memberId]!,
                                                width: 40,
                                                height: 40,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error, stackTrace) {
                                                  return Text(
                                                    memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  );
                                                },
                                              ),
                                            )
                                          : Text(
                                              memberName.isNotEmpty ? memberName[0].toUpperCase() : '?',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                    SizedBox(height: 4),
                                    Container(
                                      constraints: BoxConstraints(maxWidth: 60),
                                      child: Text(
                                        isCurrentUser ? 'You' : memberName,
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
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
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.data == null ||
                          snapshot.data!.docs.isEmpty) {
                        return const Center(
                            child: Text('Start the conversation!'));
                      }

                      return ListView.builder(
                        reverse: true,
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final senderId = data['senderId'] as String? ?? '';
                          final isMe = senderId == uid;

                          final timestamp = data['timestamp'] != null
                              ? (data['timestamp'] as Timestamp).toDate()
                              : DateTime.now();

                          final senderName = isMe
                              ? 'You'
                              : _memberNames[senderId] ?? 'Unknown';

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
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        _memberAvatars[senderId]?.isNotEmpty ==
                                                true
                                            ? NetworkImage(
                                                _memberAvatars[senderId]!)
                                            : null,
                                    backgroundColor: Colors.green[100],
                                    child: _memberAvatars[senderId]?.isEmpty ==
                                            true
                                        ? Text(
                                            _memberNames[senderId]
                                                        ?.isNotEmpty ==
                                                    true
                                                ? _memberNames[senderId]![0]
                                                : '?',
                                            style:
                                                const TextStyle(fontSize: 14),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 5),
                                ],
                                Flexible(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8,
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isMe
                                          ? Colors.blue[100]
                                          : Colors.grey[300],
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(12),
                                        topRight: const Radius.circular(12),
                                        bottomLeft:
                                            Radius.circular(isMe ? 12 : 0),
                                        bottomRight:
                                            Radius.circular(isMe ? 0 : 12),
                                      ),
                                      // Add a red border if the message is expiring today
                                      border: expiringToday
                                          ? Border.all(
                                              color: Colors.red, width: 1)
                                          : null,
                                    ),
                                    child: Stack(
                                      children: [
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 16),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (!isMe)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 4),
                                                  child: Text(
                                                    senderName,
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 12,
                                                      color: Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                              if (data['imageUrl'] != null)
                                                GestureDetector(
                                                  onTap: () =>
                                                      _openFullScreenImage(
                                                          data['imageUrl']),
                                                  child: Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
                                                      border: Border.all(
                                                        color: Colors
                                                            .grey.shade300,
                                                        width: 1,
                                                      ),
                                                    ),
                                                    child: ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              12),
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
                                                                null)
                                                              return child;
                                                            return Container(
                                                              height: 200,
                                                              width: 200,
                                                              color: Colors
                                                                  .grey[200],
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
                                                          errorBuilder:
                                                              (context, error,
                                                                  stackTrace) {
                                                            return Container(
                                                              height: 200,
                                                              width: 200,
                                                              color: Colors
                                                                  .grey[200],
                                                              child:
                                                                  const Center(
                                                                child: Icon(
                                                                    Icons.error,
                                                                    color: Colors
                                                                        .red),
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
                                                  style: TextStyle(
                                                      fontSize: 14,
                                                  color: Theme.of(context).colorScheme.surface
                                                  ),
                                                ),
                                              // Add expiry indicator for messages nearing expiration
                                              if (daysRemaining <= 2)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          top: 4),
                                                  child: Text(
                                                    expiringToday
                                                        ? 'Expires today'
                                                        : 'Expires in $daysRemaining day${daysRemaining > 1 ? "s" : ""}',
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: expiringToday
                                                          ? Colors.red
                                                          : Colors.orange,
                                                      fontStyle:
                                                          FontStyle.italic,
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
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage:
                                        _memberAvatars[uid]?.isNotEmpty == true
                                            ? NetworkImage(_memberAvatars[uid]!)
                                            : null,
                                    backgroundColor: Colors.blue[100],
                                    child: _memberAvatars[uid]?.isEmpty == true
                                        ? const Text(
                                            'Y',
                                            style: TextStyle(fontSize: 14),
                                          )
                                        : null,
                                  ),
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
                InkWell(
                  child: Material(
                    elevation: 5,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 8.0),
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey, width: 1)),
                      child: Text(
                        "Suggested Questions",
                        style: GoogleFonts.abhayaLibre(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                )
              ],
            ),
    );
  }

  void _showGroupInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(widget.groupName),
        content: _isLoadingNames
            ? const Center(child: CircularProgressIndicator())
            : SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.groupMembers.length,
                  itemBuilder: (context, index) {
                    final memberId = widget.groupMembers[index];
                    final isMe = memberId == uid;
                    final memberName = isMe
                        ? 'You (${_memberNames[memberId] ?? 'Unknown'})'
                        : _memberNames[memberId] ?? 'Unknown';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage:
                            _memberAvatars[memberId]?.isNotEmpty == true
                                ? NetworkImage(_memberAvatars[memberId]!)
                                : null,
                        backgroundColor:
                            isMe ? Colors.blue[100] : Colors.grey[300],
                        child: _memberAvatars[memberId]?.isEmpty == true
                            ? Text(memberName.isNotEmpty ? memberName[0] : '?')
                            : null,
                      ),
                      title: Text(memberName),
                      onTap: isMe
                          ? null
                          : () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => OtherProfile(
                                    otherUserId: memberId,
                                    otherUserName: _memberNames[memberId],
                                  ),
                                ),
                              );
                            },
                    );
                  },
                ),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _controller.dispose();
    _cleanupTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
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
    super.key,
  });

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
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain,
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
              },
              errorBuilder: (context, error, stackTrace) {
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
              },
            ),
          ),
        ),
      ),
    );
  }
}
