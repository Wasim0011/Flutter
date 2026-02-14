import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../topic_chats/chats/chat_screen.dart';

class RecentChatsScreen extends StatefulWidget {
  const RecentChatsScreen({Key? key}) : super(key: key);

  @override
  _RecentChatsScreenState createState() => _RecentChatsScreenState();
}

class _RecentChatsScreenState extends State<RecentChatsScreen> {
  final String uid = FirebaseAuth.instance.currentUser!.uid;
  late final CollectionReference _userChats;
  late final Query _groupChatsQuery;

  // Combined data for display
  List<Map<String, dynamic>> _combinedChats = [];
  bool _isLoading = true;
  String? _error;
  final Map<String, String> _userAvatars = {}; // Cache for user avatars

  @override
  void initState() {
    super.initState();
    _userChats = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('chats');

    // Query group chats where current user is a participant
    _groupChatsQuery = FirebaseFirestore.instance
        .collection('group_chats')
        .where('participants', arrayContains: uid);

    _loadAllChats();
  }

  Future<void> _loadAllChats() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load direct chats
      final directChatsSnapshot =
          await _userChats.orderBy('lastMessageTime', descending: true).get();

      // Load group chats
      final groupChatsSnapshot = await _groupChatsQuery.get();

      // Process direct chats
      final List<Map<String, dynamic>> allChats = [];

      for (var doc in directChatsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['chatId'] != null) {
          // Only add valid chats
          allChats.add({
            ...data,
            'isGroupChat': false,
            'docId': doc.id,
          });
        }
      }

      // Process group chats
      for (var doc in groupChatsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        allChats.add({
          ...data,
          'isGroupChat': true,
          'chatId': doc.id,
          'docId': doc.id,
        });
      }

      // Sort by last message time
      allChats.sort((a, b) {
        final aTime = a['lastMessageTime'] as Timestamp?;
        final bTime = b['lastMessageTime'] as Timestamp?;

        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;

        return bTime.compareTo(aTime);
      });

      // Preload avatars for all unique users in direct chats
      await _preloadUserAvatars(allChats);

      setState(() {
        _combinedChats = allChats;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading chats: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _preloadUserAvatars(List<Map<String, dynamic>> chats) async {
    final Set<String> userIds = {};

    // Collect all unique user IDs from direct chats
    for (final chat in chats) {
      if (!chat['isGroupChat']) {
        userIds.add(chat['otherUserId']);
      }
    }

    // Fetch avatars in batch
    final futures = userIds.map((userId) async {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          _userAvatars[userId] = userDoc.get('avatar') ?? '';
        }
      } catch (e) {
        debugPrint('Error loading avatar for user $userId: $e');
      }
    });

    await Future.wait(futures);
  }
  // DELETE FUNCTIONS

  // Function to delete a direct chat
  Future<void> _deleteDirectChat(String chatId, String otherUserId) async {
    try {
      // Delete the chat reference from user's collection
      await _userChats.doc(chatId).delete();

      // Delete the actual chat messages
      final messagesRef = FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages');

      // Get all messages and delete them
      final messagesSnapshot = await messagesRef.get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Finally delete the chat document itself
      await FirebaseFirestore.instance.collection('chats').doc(chatId).delete();

      // Remove from local state
      setState(() {
        _combinedChats.removeWhere(
            (chat) => chat['isGroupChat'] == false && chat['chatId'] == chatId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chat deleted successfully')),
      );
    } catch (e) {
      debugPrint('Error deleting chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting chat: ${e.toString()}')),
      );
    }
  }

  // Function to leave a group chat (for current user)
  Future<void> _leaveGroupChat(
      String chatId, List<dynamic> participants) async {
    try {
      // Make a copy of participants and remove current user
      final List<String> updatedParticipants = List<String>.from(participants)
        ..remove(uid);

      if (updatedParticipants.isEmpty) {
        // If no members left, delete the entire group chat
        await _deleteEntireGroupChat(chatId);
      } else {
        // Update the group chat participants
        await FirebaseFirestore.instance
            .collection('group_chats')
            .doc(chatId)
            .update({'participants': updatedParticipants});

        // Remove the reference from user's chats collection
        final userChatRef = FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('chats')
            .doc(chatId);

        await userChatRef.delete();

        // Remove from local state
        setState(() {
          _combinedChats.removeWhere((chat) =>
              chat['isGroupChat'] == true && chat['chatId'] == chatId);
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Left group chat successfully')),
      );
    } catch (e) {
      debugPrint('Error leaving group chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error leaving group chat: ${e.toString()}')),
      );
    }
  }

  // Function to delete an entire group chat (if user is the last member)
  Future<void> _deleteEntireGroupChat(String chatId) async {
    try {
      // Delete all messages in the group chat
      final messagesRef = FirebaseFirestore.instance
          .collection('group_chats')
          .doc(chatId)
          .collection('messages');

      final messagesSnapshot = await messagesRef.get();
      final batch = FirebaseFirestore.instance.batch();

      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      // Delete the group chat document
      await FirebaseFirestore.instance
          .collection('group_chats')
          .doc(chatId)
          .delete();

      // Remove from local state
      setState(() {
        _combinedChats.removeWhere(
            (chat) => chat['isGroupChat'] == true && chat['chatId'] == chatId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Group chat deleted successfully')),
      );
    } catch (e) {
      debugPrint('Error deleting group chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting group chat: ${e.toString()}')),
      );
    }
  }

  // Show confirmation dialog before deleting
  Future<void> _showDeleteConfirmation(BuildContext context, String chatId,
      String name, bool isGroupChat, List<dynamic>? participants) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isGroupChat ? 'Leave Group Chat' : 'Delete Chat'),
        content: Text(isGroupChat
            ? 'Are you sure you want to leave the group chat "$name"?'
            : 'Are you sure you want to delete your chat with "$name"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              isGroupChat ? 'Leave' : 'Delete',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      if (isGroupChat) {
        await _leaveGroupChat(chatId, participants ?? []);
      } else {
        final otherUserId = _combinedChats
            .firstWhere((chat) => chat['chatId'] == chatId)['otherUserId'];
        await _deleteDirectChat(chatId, otherUserId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recent Discussion'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllChats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Error loading chats',
                        style: TextStyle(color: Colors.red),
                      ),
                      TextButton(
                        onPressed: _loadAllChats,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _combinedChats.isEmpty
                  ? const Center(
                      child: Text(
                        'No chats yet',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadAllChats,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: _combinedChats.length,
                        itemBuilder: (context, index) {
                          final chatData = _combinedChats[index];
                          final bool isGroupChat =
                              chatData['isGroupChat'] ?? false;

                          if (isGroupChat) {
                            return _buildGroupChatCard(
                              context,
                              chatData['chatId'] ?? '',
                              chatData['name'] ?? 'Unnamed Group',
                              chatData['lastMessage'] ?? 'No messages yet',
                              chatData['lastMessageTime']?.toDate(),
                              (chatData['unreadCount'] as num?)?.toInt() ?? 0,
                              chatData['lastMessageSender'] ==
                                  uid, // is my own message
                              chatData['participants'] ??
                                  [], // group members list
                            );
                          } else {
                            return _buildDirectChatCard(
                              context,
                              chatData['otherUserId'] ?? '',
                              chatData['chatId'] ?? '',
                              chatData['topic'] ?? 'No topic',
                              chatData['lastMessage'] ?? 'No messages yet',
                              chatData['lastMessageTime']?.toDate(),
                              (chatData['unreadCount'] as num?)?.toInt() ?? 0,
                              chatData['lastMessageSender'] ==
                                  uid, // is my own message
                            );
                          }
                        },
                      ),
                    ),
    );
  }

  Widget _buildGroupChatCard(
    BuildContext context,
    String chatId,
    String groupName,
    String lastMessage,
    DateTime? lastMessageTime,
    int unreadCount,
    bool isMyMessage,
    List<dynamic> groupMembers,
  ) {
    // Show unread count only if it's not from the current user
    final showUnread = unreadCount > 0 && !isMyMessage;
    final membersCount = groupMembers.length;
    final initials =
        groupName.isNotEmpty ? groupName.substring(0, 1).toUpperCase() : 'G';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Dismissible(
        key: Key(chatId),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20.0),
          color: Colors.red,
          child: const Icon(
            Icons.delete,
            color: Colors.white,
          ),
        ),
        confirmDismiss: (direction) async {
          await _showDeleteConfirmation(
              context, chatId, groupName, true, groupMembers);
          return false; // Don't dismiss automatically
        },
        child: ListTile(
          leading: CircleAvatar(
            child: Text(initials),
            backgroundColor:
                Colors.green[100], // Different color for group chats
          ),
          title: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(groupName),
                    const SizedBox(width: 5),
                    Icon(Icons.group, size: 16, color: Colors.grey[600]),
                  ],
                ),
              ),
              if (showUnread)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Row(
                    children: [
                      Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                        ),
                      ),
                      const Icon(Icons.chat_bubble_outline),
                    ],
                  ),
                ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                onPressed: () => _showDeleteConfirmation(
                  context,
                  chatId,
                  groupName,
                  true,
                  groupMembers,
                ),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$membersCount members',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              Text(
                lastMessage,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
          trailing: Text(
            lastMessageTime != null ? _formatTime(lastMessageTime) : '',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
          onTap: () async {
            // Immediately update the UI to remove the unread badge
            if (unreadCount > 0) {
              // Update the unread count in state
              setState(() {
                _combinedChats = _combinedChats.map((chat) {
                  if (chat['isGroupChat'] == true && chat['chatId'] == chatId) {
                    return {...chat, 'unreadCount': 0};
                  }
                  return chat;
                }).toList();
              });

              // Update the unread count in Firestore
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .collection('chats')
                    .doc(chatId)
                    .update({'unreadCount': 0});
              } catch (e) {
                debugPrint('Error updating unread count: $e');
              }
            }

            // Group chat functionality removed
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Group chat functionality has been removed')),
              );
            }

            // Refresh the list when returning
            if (mounted) {
              _loadAllChats();
            }
          },
        ),
      ),
    );
  }

  Widget _buildDirectChatCard(
    BuildContext context,
    String otherUserId,
    String chatId,
    String topic,
    String lastMessage,
    DateTime? lastMessageTime,
    int unreadCount,
    bool isMyMessage,
  ) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildChatCardSkeleton();
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return _buildErrorChatCard(otherUserId, chatId);
        }

        final otherUserName =
            snapshot.data?.get('userName')?.toString() ?? 'Unknown';
        final avatarUrl = snapshot.data?.get('avatar')?.toString() ?? '';
        final initials = otherUserName.isNotEmpty
            ? otherUserName.substring(0, 1).toUpperCase()
            : '?';

        // Don't show unread count if it's our own message
        final showUnread = unreadCount > 0 && !isMyMessage;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: Dismissible(
            key: Key(chatId),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            confirmDismiss: (direction) async {
              await _showDeleteConfirmation(
                  context, chatId, otherUserName, false, null);
              return false; // Don't dismiss automatically
            },
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage:
                    avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                backgroundColor: Colors.blue[100],
                child: avatarUrl.isEmpty ? Text(initials) : null,
              ),
              title: Row(
                children: [
                  Expanded(child: Text(otherUserName)),
                  if (showUnread)
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                      ),
                      child: Row(
                        children: [
                          Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 12,
                            ),
                          ),
                          const Icon(Icons.chat_bubble_outline),
                        ],
                      ),
                    ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[300]),
                    onPressed: () => _showDeleteConfirmation(
                      context,
                      chatId,
                      otherUserName,
                      false,
                      null,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    topic,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    lastMessage,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
              trailing: Text(
                lastMessageTime != null ? _formatTime(lastMessageTime) : '',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              onTap: () async {
                // Immediately update the UI to remove the unread badge
                if (unreadCount > 0) {
                  // Update the unread count in state
                  setState(() {
                    _combinedChats = _combinedChats.map((chat) {
                      if (chat['isGroupChat'] == false &&
                          chat['chatId'] == chatId) {
                        return {...chat, 'unreadCount': 0};
                      }
                      return chat;
                    }).toList();
                  });

                  // Update the unread count in Firestore
                  try {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(uid)
                        .collection('chats')
                        .doc(chatId)
                        .update({'unreadCount': 0});
                  } catch (e) {
                    debugPrint('Error updating unread count: $e');
                  }
                }

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChatScreen(
                      chatId: chatId,
                      otherUserId: otherUserId,
                      otherUserName: otherUserName,
                    ),
                  ),
                );

                // Refresh the list when returning
                if (mounted) {
                  _loadAllChats();
                }
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildChatCardSkeleton() {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.grey,
          child: SizedBox.shrink(),
        ),
        title: Container(
          height: 16,
          width: 100,
          color: Colors.grey[300],
        ),
        subtitle: Container(
          height: 12,
          width: 150,
          color: Colors.grey[200],
        ),
      ),
    );
  }

  Widget _buildErrorChatCard(String otherUserId, String chatId) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: Colors.red[50],
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.red,
          child: Icon(Icons.error, color: Colors.white),
        ),
        title: const Text('Error loading chat'),
        subtitle: Text('ID: $otherUserId'),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chatId,
                otherUserId: otherUserId,
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    if (date.day == now.day &&
        date.month == now.month &&
        date.year == now.year) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (date.year == now.year) {
      return '${date.day}/${date.month}';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
