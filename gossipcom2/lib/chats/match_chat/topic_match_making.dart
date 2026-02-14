import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/profile/others_profile/other_profile.dart';
import 'package:gossipcom/chats/topic_chats/chats/chat_screen.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class TopicMatchMaking extends StatefulWidget {
  const TopicMatchMaking({super.key});

  @override
  State<TopicMatchMaking> createState() => _TopicMatchMakingState();
}

class _TopicMatchMakingState extends State<TopicMatchMaking>
    with WidgetsBindingObserver {
  String? uid;
  late FirebaseFirestore _firestore;
  late FirebaseAuth _firebaseAuth;
  late CollectionReference _matchRequests;
  late CollectionReference _users;
  late CollectionReference _tempMatches;
  late CollectionReference _topicChats;
  bool _isProcessing = false;
  bool _isDisposed = false;
  bool _isNavigating = false;
  List<String> _selectedTopics = [];

  bool isModalActive = true;
  Timer? timerInstance;
  // Track current active mode
  String _activeMode = 'one_to_one'; // 'none', 'one_to_one'

  // Track sent requests
  final Set<String> _sentRequests = {};
  final Set<String> _receivedRequests = {};

  Stream<QuerySnapshot>? _availableUsersStream;
  Stream<QuerySnapshot>? _receivedRequestsStream;
  StreamSubscription<QuerySnapshot>? _matchListener1;
  StreamSubscription<QuerySnapshot>? _matchListener2;
  Timestamp? _sessionStartTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _cleanupExistingMatches().then((_) {
      _initializeFirebase();
    });
  }

  Future<void> _cleanupExistingMatches() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestore = FirebaseFirestore.instance;

    try {
      // Clean up 1-to-1 matches
      final matchesAsUser1 = await firestore
          .collection('temp_matches')
          .where('user1', isEqualTo: user.uid)
          .get();

      final matchesAsUser2 = await firestore
          .collection('temp_matches')
          .where('user2', isEqualTo: user.uid)
          .get();

      final batch = firestore.batch();
      for (var doc in matchesAsUser1.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in matchesAsUser2.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Error cleaning up existing matches: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _updateUserStatus(false);
    } else if (state == AppLifecycleState.resumed) {
      _updateUserStatus(true);
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<void> _updateUserStatus(bool isActive) async {
    if (uid == null) return;
    debugPrint('Updating user status: isActive=$isActive, mode=$_activeMode');
    debugPrint('Current topics before update: $_selectedTopics');

    try {
      await _users.doc(uid).update({
        'uid': uid,
        'isInMatchmaking': _activeMode == 'one_to_one',
        'isInGroupMatchmaking': false,
        'selectedTopics': _selectedTopics,
        'lastActive': FieldValue.serverTimestamp(),
      });
      debugPrint(
          'User status updated successfully with topics: $_selectedTopics');
    } catch (e) {
      debugPrint('Error updating user status: $e');
    }
  }

  Future<void> _initializeFirebase() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please login first')),
          );
        }
        return;
      }

      uid = user.uid;
      _firestore = FirebaseFirestore.instance;
      _firebaseAuth = FirebaseAuth.instance;
      _matchRequests = _firestore.collection('match_requests');
      _users = _firestore.collection('users');
      _tempMatches = _firestore.collection('temp_matches');
      _topicChats = _firestore.collection('topic_chats');
      _sessionStartTime = Timestamp.now();

      final userDoc = await _users.doc(uid).get();
      debugPrint('Loading user data: ${userDoc.exists}');
      if (userDoc.exists) {
        final topics = List<String>.from(userDoc['selectedTopics'] ?? []);
        debugPrint('Loaded topics: $topics');
        if (mounted) {
          setState(() {
            _selectedTopics = topics;
          });
        }

        _setupStreams();
      } else {
        debugPrint('User document does not exist');
        if (mounted) {
          setState(() {
            _selectedTopics = [];
          });
        }
        _setupStreams();
      }

      _setupMatchListener();
      _loadSentRequests();

      await _updateUserStatus(true);
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing: $e')),
        );
      }
    }
  }

  void _setupStreams() {
    debugPrint('Setting up streams with topics: $_selectedTopics');

    // Filter users who have at least one common topic
    _availableUsersStream = _users
        .where('isInMatchmaking', isEqualTo: true)
        .where(FieldPath.documentId, isNotEqualTo: uid)
        .where('lastActive',
            isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(const Duration(minutes: 5))))
        .snapshots();

    _receivedRequestsStream = _matchRequests
        .where('targetUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots();
  }

  Future<void> _loadSentRequests() async {
    if (uid == null) return;

    try {
      final requests = await _matchRequests
          .where('senderUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();

      if (mounted) {
        setState(() {
          _sentRequests
              .addAll(requests.docs.map((doc) => doc['targetUid'] as String));
        });
      }
    } catch (e) {
      debugPrint('Error loading sent requests: $e');
    }
  }

  @override
  void dispose() {
    debugPrint('Matchmaking screen disposing');
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _matchListener1?.cancel();
    _matchListener2?.cancel();
    _cleanUpUserData();

    isModalActive = false;
    timerInstance?.cancel();

    super.dispose();
  }

  Future<void> _cleanUpUserData() async {
    if (uid == null) return;

    try {
      await _users.doc(uid).update({
        'isInMatchmaking': false,
        'isInGroupMatchmaking': false,
        'currentTopic': FieldValue.delete(),
      });

      final sentRequests = await _matchRequests
          .where('senderUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
      for (var doc in sentRequests.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      debugPrint('Cleanup error: $e');
    }
  }

  void _setupMatchListener() {
    if (uid == null) return;

    _matchListener1 = _tempMatches
        .where('user1', isEqualTo: uid)
        .where('status', isEqualTo: 'matched')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty &&
          !_isDisposed &&
          mounted &&
          !_isNavigating) {
        for (var doc in snapshot.docs) {
          final match = doc.data() as Map<String, dynamic>;
          if (match['createdAt'] != null &&
              _sessionStartTime != null &&
              (match['createdAt'] as Timestamp).compareTo(_sessionStartTime!) >=
                  0) {
            _handleMutualMatch(match['user2'], doc.id);
            break;
          }
        }
      }
    });

    _matchListener2 = _tempMatches
        .where('user2', isEqualTo: uid)
        .where('status', isEqualTo: 'matched')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.docs.isNotEmpty &&
          !_isDisposed &&
          mounted &&
          !_isNavigating) {
        for (var doc in snapshot.docs) {
          final match = doc.data() as Map<String, dynamic>;
          if (match['createdAt'] != null &&
              _sessionStartTime != null &&
              (match['createdAt'] as Timestamp).compareTo(_sessionStartTime!) >=
                  0) {
            _handleMutualMatch(match['user1'], doc.id);
            break;
          }
        }
      }
    });
  }

  String _generateChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '$uid1-$uid2' : '$uid2-$uid1';
  }

  Future<void> _sendRequest(String targetUid) async {
    if (_isProcessing ||
        _isDisposed ||
        uid == null ||
        _sentRequests.contains(targetUid)) {
      return;
    }

    if (mounted) {
      setState(() {
        _isProcessing = true;
        _activeMode = 'one_to_one';
      });
    }

    try {
      await _users.doc(uid!).update({
        'isInMatchmaking': true,
        'isInGroupMatchmaking': false,
        'selectedTopics': _selectedTopics,
        'lastActive': FieldValue.serverTimestamp(),
      });

      final existingMatch = await _tempMatches
          .where('status', isEqualTo: 'matched')
          .where(FieldPath.documentId, whereIn: [
            _generateChatId(uid!, targetUid),
            _generateChatId(targetUid, uid!),
          ])
          .limit(1)
          .get();

      if (existingMatch.docs.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('You already have an active match!')),
          );
        }
        return;
      }

      final targetUserDoc = await _users.doc(targetUid).get();
      final targetTopics =
          List<String>.from(targetUserDoc['selectedTopics'] ?? []);
      final commonTopics = _selectedTopics
          .where((topic) => targetTopics.contains(topic))
          .toList();

      if (commonTopics.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No matching topics found')),
          );
        }
        return;
      }

      final existingRequest = await _matchRequests
          .where('senderUid', isEqualTo: targetUid)
          .where('targetUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .limit(1)
          .get();

      if (existingRequest.docs.isNotEmpty) {
        await _clearAllPendingRequests();
        await _createTempMatch(targetUid, commonTopics.first);
      } else {
        await _matchRequests.add({
          'senderUid': uid,
          'targetUid': targetUid,
          'topics': commonTopics,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          setState(() => _sentRequests.add(targetUid));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text(
                    'Connection request sent! wait for response or start more gossip')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error sending request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _clearAllPendingRequests() async {
    if (uid == null) return;

    try {
      final sentRequests = await _matchRequests
          .where('senderUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();

      final receivedRequests = await _matchRequests
          .where('targetUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();

      final batch = _firestore.batch();
      for (var doc in sentRequests.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in receivedRequests.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();

      if (mounted) {
        setState(() {
          _sentRequests.clear();
          _receivedRequests.clear();
        });
      }
    } catch (e) {
      debugPrint('Error clearing requests: $e');
    }
  }

  Future<void> _createTempMatch(String otherUid, String topic) async {
    if (uid == null) return;

    try {
      final chatId = _generateChatId(uid!, otherUid);

      await _tempMatches.doc(chatId).set({
        'user1': uid,
        'user2': otherUid,
        'topic': topic,
        'status': 'matched',
        'createdAt': FieldValue.serverTimestamp(),
      });

      await _clearAllPendingRequests();
    } catch (e) {
      debugPrint('Error creating temp match: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error creating match')),
        );
      }
    }
  }

  Future<void> _handleMutualMatch(String otherUid, String matchId) async {
    if (uid == null || _isNavigating) return;

    _isNavigating = true;

    try {
      final chatId = _generateChatId(uid!, otherUid);
      final matchDoc = await _tempMatches.doc(matchId).get();
      final topic = matchDoc['topic'];

      final existingChat = await _topicChats.doc(chatId).get();
      if (existingChat.exists) {
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                chatId: chatId,
                otherUserId: otherUid,
              ),
            ),
          );
        }
        return;
      }

      await _topicChats.doc(chatId).set({
        'participants': [uid, otherUid],
        'topic': topic,
        'createdAt': FieldValue.serverTimestamp(),
        'lastMessage': '',
        'lastMessageTime': FieldValue.serverTimestamp(),
      });

      final batch = _firestore.batch();

      batch.set(
        _users.doc(uid!).collection('chats').doc(chatId),
        {
          'otherUserId': otherUid,
          'chatId': chatId,
          'topic': topic,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        },
      );

      batch.set(
        _users.doc(otherUid).collection('chats').doc(chatId),
        {
          'otherUserId': uid,
          'chatId': chatId,
          'topic': topic,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': 0,
        },
      );

      await batch.commit();
      await _tempMatches.doc(matchId).delete();
      await _clearAllPendingRequests();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              chatId: chatId,
              otherUserId: otherUid,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error handling mutual match: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating chat: ${e.toString()}')),
        );
      }
    } finally {
      _isNavigating = false;
    }
  }

  Widget _buildUserCard(DocumentSnapshot user, bool isRequest) {
    final userName = user['userName'] ?? 'Anonymous';
    final targetUid = user.id;
    final userTopics = List<String>.from(user['selectedTopics'] ?? []);
    final commonTopics =
        _selectedTopics.where((topic) => userTopics.contains(topic)).toList();
    final hasSentRequest = _sentRequests.contains(targetUid);
    final vibePoints = user['vibePoints'] ?? '0';
    final isProcessingRequest = _isProcessing && hasSentRequest;

    final avatarUrl = user['avatar'] as String?;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.grey[300],
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Text(userName.substring(0, 1)) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        userName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        InkWell(
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => OtherProfile(
                                        otherUserId: targetUid,
                                        otherUserName: userName)));
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0x33736F6F),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.all(5.0),
                            child: Text(
                              "View Profile",
                              style: GoogleFonts.abhayaLibre(
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                                color: const Color(0xFF828282),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0x33736F6F),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(5.0),
                          child: Text(
                            "$vibePoints Vibe Point 🔥",
                            style: GoogleFonts.abhayaLibre(
                              fontWeight: FontWeight.w800,
                              fontSize: 10,
                              color: const Color(0xFF828282),
                            ),
                          ),
                        )
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Common Topics: ${commonTopics.join(', ')}',
                  style: GoogleFonts.abhayaLibre(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: isProcessingRequest
                      ? const CircularProgressIndicator()
                      : isRequest
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _buildStyledButton(
                                  text: 'Accept',
                                  onPressed: () => _sendRequest(targetUid),
                                  backgroundColor: Colors.green[100]!,
                                  textColor: Colors.green,
                                ),
                                const SizedBox(width: 8),
                                _buildStyledButton(
                                  text: 'Decline',
                                  onPressed: () async {
                                    final requests = await _matchRequests
                                        .where('senderUid',
                                            isEqualTo: targetUid)
                                        .where('targetUid', isEqualTo: uid)
                                        .get();

                                    final batch = _firestore.batch();
                                    for (var doc in requests.docs) {
                                      batch.delete(doc.reference);
                                    }
                                    await batch.commit();

                                    if (mounted) {
                                      setState(() {
                                        _receivedRequests.remove(targetUid);
                                      });
                                    }
                                  },
                                  backgroundColor: Colors.red[100]!,
                                  textColor: Colors.red,
                                ),
                              ],
                            )
                          : hasSentRequest
                              ? Text(
                                  'Request Sent',
                                  style: GoogleFonts.abhayaLibre(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                )
                              : _buildStyledButton(
                                  text: 'Connect ✅',
                                  onPressed: () {
                                    Navigator.pop(context);
                                    _sendRequest(targetUid);
                                  },
                                ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStyledButton({
    required String text,
    required VoidCallback onPressed,
    Color backgroundColor = const Color(0xFFD9D9D9),
    Color textColor = Colors.black,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: GoogleFonts.abhayaLibre(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: textColor,
          ),
        ),
      ),
    );
  }

  void _showAvailableUsersBottomSheet(bool isHost) {
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('wait a second initializing your data')),
      );
      return;
    }

    debugPrint('Opening available users sheet. isHost: $isHost');
    if (!mounted) return; // Added mounted check
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border.all(
                color: Colors.blue,
                width: 2,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: 60,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.blue[200],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Text(
                  isHost ? 'Available Users to Connect' : 'Join a Discussion',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: isHost
                        ? _availableUsersStream
                        : _receivedRequestsStream,
                    builder: (context, snapshot) {
                      debugPrint(
                          'Stream state: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
                      if (snapshot.hasError) {
                        debugPrint('Stream error: ${snapshot.error}');
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        debugPrint('No data in stream or empty docs');
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isHost
                                    ? 'No users available currently'
                                    : 'No pending requests',
                                style: GoogleFonts.poppins(fontSize: 16),
                              ),
                              const SizedBox(height: 16),
                              if (isHost)
                                Text(
                                  'Make sure other users have selected matching topics and are active',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => setModalState(() {
                                  debugPrint('Manual refresh triggered');
                                }),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: Text(
                                  'Refresh',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      debugPrint(
                          'Found ${snapshot.data!.docs.length} documents');

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];

                          if (isHost) {
                            return _buildUserCard(doc, false);
                          } else {
                            return FutureBuilder<DocumentSnapshot>(
                              future: _users.doc(doc['senderUid']).get(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData) {
                                  return const SizedBox.shrink();
                                }
                                return _buildUserCard(userSnapshot.data!, true);
                              },
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _timerSelectionSheet(bool isHost) {
    int selectedIndex = -1; // Renamed from _selectedIndex
    // bool _tapStart = false; // Removed unused variable
    String userId = _firebaseAuth.currentUser!.uid;
    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SizedBox(
                    height: 20,
                  ),
                  Text(
                    'You Started Gossip for Profile Match',
                    style: GoogleFonts.dmSerifText(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Please wait people to respond',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    child: LottieBuilder.asset('assets/animation/logo.json'),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(width: 1, color: Colors.white),
                        color: selectedIndex == 0 // Used selectedIndex
                            ? Colors.blue
                            : Colors.transparent,
                      ),
                      child: Center(
                          child: Text(
                        " 30 minutes",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                    onTap: () {
                      setModalState(() {
                        selectedIndex = 0; // Used selectedIndex
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(width: 1, color: Colors.white),
                        color: selectedIndex == 1 // Used selectedIndex
                            ? Colors.blue
                            : Colors.transparent,
                      ),
                      child: Center(
                          child: Text(
                        "1 Hours 30 minutes",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                    onTap: () {
                      setModalState(() {
                        selectedIndex = 1; // Used selectedIndex
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.rectangle,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(width: 1, color: Colors.white),
                        color: selectedIndex == 2 // Used selectedIndex
                            ? Colors.blue
                            : Colors.transparent,
                      ),
                      child: Center(
                          child: Text(
                        "2 Hours",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                    onTap: () {
                      setModalState(() {
                        selectedIndex = 2; // Used selectedIndex
                      });
                    },
                  ),
                  const SizedBox(height: 40),
                  GestureDetector(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 40,
                      decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.rectangle,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(width: 1, color: Colors.white)),
                      child: Center(
                          child: Text(
                        "Start",
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      )),
                    ),
                    onTap: () async {
                      if (!mounted) return;
                      if (selectedIndex == 0) {
                        // Used selectedIndex
                        await _firestore
                            .collection('topic_timer')
                            .doc(userId)
                            .set({
                          'timerStartedAt': FieldValue.serverTimestamp(),
                          'durationInMinutes': 30,
                          'isRunning': true,
                        }, SetOptions(merge: true));
                        Navigator.pop(context); // Dismiss sheet
                        _timestartedUntilUsersCome(true, 30);
                      } else if (selectedIndex == 1) {
                        // Used selectedIndex
                        await _firestore
                            .collection('topic_timer')
                            .doc(userId)
                            .set({
                          'timerStartedAt': FieldValue.serverTimestamp(),
                          'durationInMinutes':
                              90, // Corrected duration for 1 hour 30 mins
                          'isRunning': true,
                        }, SetOptions(merge: true));
                        Navigator.pop(context); // Dismiss sheet
                        _timestartedUntilUsersCome(true, 90);
                      } else if (selectedIndex == 2) {
                        // Used selectedIndex
                        Navigator.pop(
                            context); // Dismiss sheet before showing dialog
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              actions: [
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      height: 10,
                                    ),
                                    Center(
                                        child:
                                            Text("Do you Want to Pay Premium")),
                                    SizedBox(
                                      height: 20,
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        GestureDetector(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  width: 1,
                                                  color: Colors.white),
                                            ),
                                            height: 20,
                                            width: 60,
                                            child: Center(child: Text("Yes")),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                        GestureDetector(
                                          child: Container(
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  width: 1,
                                                  color: Colors.white),
                                            ),
                                            height: 20,
                                            width: 60,
                                            child: Center(child: Text("NO")),
                                          ),
                                          onTap: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                      ],
                                    )
                                  ],
                                )
                              ],
                            );
                          },
                        );
                      }
                    },
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _timestartedUntilUsersCome(bool isHost, int minutess) async {
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Wait a second initializing your data')),
        );
      }
      return;
    }

    // Renamed from _timer
    String userId = _firebaseAuth.currentUser!.uid;
    Duration remainingT = Duration.zero; // Renamed from _remainingT

    // Removed unused variables:
    // Duration _remaining = Duration.zero;
    // bool _timerStarted = false;
    // Duration remaining = endTime.difference(now);

    if (!mounted) return; // Added mounted check
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) {
        // Changed context to modalContext to avoid conflict
        return StatefulBuilder(builder: (context, modalState) {
          void startCountdown(DateTime endTime) {
            timerInstance?.cancel();
            timerInstance = Timer.periodic(Duration(seconds: 1), (timer) {
              final currentRemaining = endTime.difference(DateTime.now());

              if (!mounted || !isModalActive) {
                timer.cancel();
                return;
              }

              if (currentRemaining.isNegative) {
                timer.cancel();
                modalState(() => remainingT = Duration.zero);
              } else {
                modalState(() => remainingT = currentRemaining);
              }
            });
          }

          void initTimer() async {
            if (!mounted) return;
            final snap = await FirebaseFirestore.instance
                .collection('topic_timer')
                .doc(userId)
                .get();
            if (!mounted) return;
            final data = snap.data();

            if (data == null || data['isRunning'] == false) return;

            final start = (data['timerStartedAt'] as Timestamp).toDate();
            final duration = Duration(minutes: data['durationInMinutes']);
            final firestoreEndTime = start.add(duration);

            startCountdown(firestoreEndTime);
          }

          WidgetsBinding.instance.addPostFrameCallback((_) {
            initTimer();
          });

          // Removed unused function _formatDuration

          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'You Started Gossip for Profile Match',
                  style: GoogleFonts.dmSerifText(
                    fontSize: 25,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Please wait people to respond',
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  child: LottieBuilder.asset('assets/animation/logo.json'),
                ),
                const SizedBox(height: 20),
                Text(
                  // Simplified remainingT display logic
                  "${remainingT.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remainingT.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                ElevatedButton(
                  onPressed: () {
                    timerInstance?.cancel();
                    FirebaseFirestore.instance
                        .collection('topic_timer')
                        .doc(userId)
                        .update({
                      'isRunning': false,
                    });
                    if (!mounted) return;
                    modalState(() {
                      remainingT = Duration.zero;
                    });
                    Navigator.pop(context); // Dismiss this bottom sheet
                  },
                  child: Text("Stop Timer"),
                ),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: isHost
                        ? _availableUsersStream
                        : _receivedRequestsStream,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        debugPrint('StreamBuilder error: ${snapshot.error}');
                        return Center(
                          child: Text('Error loading users: ${snapshot.error}'),
                        );
                      }
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      debugPrint(
                          'Available users data: ${snapshot.data?.docs.length}');
                      if (snapshot.hasData) {
                        for (var doc in snapshot.data!.docs) {
                          debugPrint('User: ${doc.id} - ${doc.data()}');
                        }
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        // Replaced Container with SizedBox.shrink()
                        return const SizedBox.shrink();
                      }

                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          final doc = snapshot.data!.docs[index];
                          if (doc.id == uid) {
                            return const SizedBox.shrink();
                          }

                          if (isHost) {
                            if (doc.exists && doc.data() != null) {
                              return _buildUserCard(doc, false);
                            } else {
                              return const SizedBox.shrink();
                            }
                          } else {
                            return FutureBuilder<DocumentSnapshot>(
                              future: _users.doc(doc['senderUid']).get(),
                              builder: (context, userSnapshot) {
                                if (!userSnapshot.hasData ||
                                    !userSnapshot.data!.exists) {
                                  return const SizedBox.shrink();
                                }
                                return _buildUserCard(userSnapshot.data!, true);
                              },
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Replaced WillPopScope with PopScope
    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) {
          return;
        }
        await _cleanUpUserData();
        if (mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                width: double.infinity,
                height: 400,
                child: ClipRect(
                  child: OverflowBox(
                    maxHeight: double.infinity,
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      "matchmaking_asset/upper.png",
                      width: double.infinity,
                      fit: BoxFit.fill,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: screenHeight * 0.35,
              child: ClipRRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                  child: Container(
                    color: Colors.transparent,
                    child: Column(
                      children: [
                        SizedBox(
                          height: screenHeight * 0.03,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: screenWidth * 0.04),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    // This pop will be handled by PopScope now
                                    Navigator.of(context).pop();
                                  },
                                  icon: Icon(Icons.arrow_back_ios,
                                      size: 24,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface),
                                ),
                                SizedBox(
                                  width: screenWidth * 0.03,
                                ),
                                Expanded(
                                  child: Text(
                                    "Profile Match",
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(
                          height: screenHeight * 0.01,
                        ),
                        // Display user's selected topics
                        if (_selectedTopics.isNotEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.blue.shade200, width: 1),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.topic,
                                      color: Colors.blue.shade700,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Your Topics:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: _selectedTopics
                                      .map((topic) => Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.blue.shade100,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              topic,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.blue.shade800,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 24, vertical: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              InkWell(
                                onTap: () {
                                  if (mounted) {
                                    setState(() {
                                      _activeMode = 'one_to_one';
                                    });
                                  }
                                },
                                child: Material(
                                  borderRadius: BorderRadius.circular(20),
                                  elevation: 5,
                                  child: Container(
                                    width: 160.w,
                                    height: 140.h,
                                    padding: EdgeInsets.symmetric(
                                        vertical: 30, horizontal: 10),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _activeMode == 'one_to_one' ||
                                                _activeMode == 'none'
                                            ? Colors.blue
                                            : Theme.of(context)
                                                .colorScheme
                                                .onSurface,
                                        width: _activeMode == 'one_to_one' ||
                                                _activeMode == 'none'
                                            ? 2
                                            : 1,
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: _activeMode == 'one_to_one'
                                          ? LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Colors.blue.shade50,
                                                Colors.white,
                                              ],
                                            )
                                          : null,
                                    ),
                                    child: Column(
                                      children: [
                                        Text(
                                          "One to One",
                                          style: GoogleFonts.dmSerifText(
                                            fontSize: 20.sp,
                                            fontWeight: FontWeight.w400,
                                            color: _activeMode == 'one_to_one'
                                                ? Colors.blue[800]
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                          ),
                                        ),
                                        SizedBox(height: screenHeight * 0.008),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.people,
                                              color: _activeMode == 'one_to_one'
                                                  ? Colors.blue
                                                  : Colors.blueGrey,
                                              size: 12,
                                            ),
                                            Text(
                                              "  1:1 Discussion",
                                              style: GoogleFonts.abhayaLibre(
                                                  color: _activeMode ==
                                                          'one_to_one'
                                                      ? Colors.blue[600]
                                                      : Color(0xFF828282),
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 12),
                                            )
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Centered alignment for single card
                            ],
                          ),
                        ),
                        if (_activeMode == 'one_to_one') ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: InkWell(
                              onTap: () {
                                _timerSelectionSheet(true);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    color: const Color(0xFF1976D2),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Center(
                                  child: Text("Start a Gossip",
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white)),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(24),
                            child: InkWell(
                              onTap: () {
                                _showAvailableUsersBottomSheet(false);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(18),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: Colors.black, width: 1),
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12)),
                                child: Center(
                                  child: Text("Join a Gossip",
                                      style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black)),
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: Text(
                              "TIPS : Can't find someone to Discuss with? Join an active Discussion and keep the Discussions going",
                              style: GoogleFonts.abhayaLibre(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: const Color(0xFF828282)),
                              textAlign: TextAlign.center,
                            ),
                          )
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
