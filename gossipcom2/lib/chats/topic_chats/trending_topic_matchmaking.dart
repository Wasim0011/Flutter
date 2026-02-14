import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'gossip_chat.dart';

class TrendingTopicMatchMaking extends StatefulWidget {
  final String topic;
  const TrendingTopicMatchMaking({super.key, required this.topic});

  @override
  State<TrendingTopicMatchMaking> createState() => _TrendingTopicMatchMakingState();
}

class _TrendingTopicMatchMakingState extends State<TrendingTopicMatchMaking>
    with WidgetsBindingObserver {
  String? uid;
  late FirebaseFirestore _firestore;
  late CollectionReference _users;
  late CollectionReference _trendingTopicChats;
  bool _isProcessing = false;
  bool _isTimerRunning = false;
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  String? _currentChatId;
  List<String> _groupMembers = [];
  bool _showMembers = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeFirebase();
    _checkExistingGroup();
  }

  void _initializeFirebase() {
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
      _users = _firestore.collection('users');
      _trendingTopicChats = _firestore.collection('trending_topic_chats');
    } catch (e) {
      debugPrint('Initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing: $e')),
        );
      }
    }
  }

  Future<void> _checkExistingGroup() async {
    try {
      // Check if there's already an active group chat for this topic
      final existingChats = await _trendingTopicChats
          .where('topic', isEqualTo: widget.topic)
          .where('isActive', isEqualTo: true)
          .get();

      if (existingChats.docs.isNotEmpty) {
        final chatDoc = existingChats.docs.first;
        final chatData = chatDoc.data() as Map<String, dynamic>;
        final members = List<String>.from(chatData['members'] ?? []);
        
        if (members.contains(uid)) {
          // User is already in the group, navigate directly to chat
          _navigateToGroupChat(chatDoc.id, members);
          return;
        } else {
          // Add user to existing group
          await _joinExistingGroup(chatDoc.id, members);
          return;
        }
      }
    } catch (e) {
      debugPrint('Error checking existing group: $e');
    }
  }

  Future<void> _joinExistingGroup(String chatId, List<String> existingMembers) async {
    try {
      final updatedMembers = [...existingMembers, uid!];
      
      await _trendingTopicChats.doc(chatId).update({
        'members': updatedMembers,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Add chat reference to user's document
      await _users.doc(uid).collection('trending_group_chats').doc(chatId).set({
        'chatId': chatId,
        'topic': widget.topic,
        'joinedAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      });

      _navigateToGroupChat(chatId, updatedMembers);
    } catch (e) {
      debugPrint('Error joining existing group: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining group: $e')),
        );
      }
    }
  }

  void _navigateToGroupChat(String chatId, List<String> members) {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => GossipGroupChatScreen(
            chatId: chatId,
            groupName: widget.topic,
            groupMembers: members,
            isTrendingTopic: true,
          ),
        ),
      );
    }
  }

  void _showTimerSelection() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            int selectedIndex = 0;
            return Container(
              height: MediaQuery.of(context).size.height * 0.4,
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Text(
                    "Select Chat Duration",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 30),
                  GestureDetector(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 50,
                      decoration: BoxDecoration(
                        color: selectedIndex == 0 ? Colors.blue : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(width: 1, color: Colors.white),
                      ),
                      child: Center(
                        child: Text(
                          "30 Minutes",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: selectedIndex == 0 ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      setModalState(() {
                        selectedIndex = 0;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: 50,
                      decoration: BoxDecoration(
                        color: selectedIndex == 1 ? Colors.blue : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(width: 1, color: Colors.white),
                      ),
                      child: Center(
                        child: Text(
                          "1 Hour 30 Minutes",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: selectedIndex == 1 ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    ),
                    onTap: () {
                      setModalState(() {
                        selectedIndex = 1;
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
                        border: Border.all(width: 1, color: Colors.white),
                      ),
                      child: Center(
                        child: Text(
                          "Start Group Chat",
                          style: GoogleFonts.poppins(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    onTap: () async {
                      Navigator.pop(context);
                      final duration = selectedIndex == 0 ? 30 : 90;
                      await _startGroupChat(duration);
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

  Future<void> _startGroupChat(int durationInMinutes) async {
    if (_isProcessing) return;
    
    setState(() => _isProcessing = true);
    
    try {
      // Create new group chat
      final chatRef = _trendingTopicChats.doc();
      final chatId = chatRef.id;
      
      await chatRef.set({
        'topic': widget.topic,
        'members': [uid],
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'durationInMinutes': durationInMinutes,
        'timerStartedAt': FieldValue.serverTimestamp(),
      });

      // Add chat reference to user's document
      await _users.doc(uid).collection('trending_group_chats').doc(chatId).set({
        'chatId': chatId,
        'topic': widget.topic,
        'joinedAt': FieldValue.serverTimestamp(),
        'unreadCount': 0,
      });

      // Start timer
      _startTimer(durationInMinutes);
      
      setState(() {
        _currentChatId = chatId;
        _groupMembers = [uid!];
        _isTimerRunning = true;
      });

      // Navigate to group chat
      _navigateToGroupChat(chatId, [uid!]);
      
    } catch (e) {
      debugPrint('Error starting group chat: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting chat: $e')),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _startTimer(int durationInMinutes) {
    _remainingTime = Duration(minutes: durationInMinutes);
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        });
      } else {
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _remainingTime = Duration.zero;
    });
    
    // Mark chat as inactive
    if (_currentChatId != null) {
      _trendingTopicChats.doc(_currentChatId).update({
        'isActive': false,
        'endedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return PopScope(
      canPop: false,
      onPopInvoked: (bool didPop) async {
        if (didPop) return;
        _timer?.cancel();
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
                height: 400,
                width: double.infinity,
                child: ClipRect(
                  child: OverflowBox(
                    maxHeight: double.infinity,
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      "matchmaking_asset/upper.png",
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              top: screenHeight * 0.35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                  child: Container(
                    color: Colors.transparent,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(height: screenHeight * 0.01),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      _timer?.cancel();
                                      if (mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    icon: Icon(Icons.arrow_back_ios,
                                        size: 24,
                                        color: Theme.of(context).colorScheme.onSurface),
                                  ),
                                  Expanded(
                                    child: Text(
                                      widget.topic,
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(context).colorScheme.onSurface,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        _showMembers = !_showMembers;
                                      });
                                    },
                                    icon: Icon(
                                      _showMembers ? Icons.visibility_off : Icons.visibility,
                                      size: 24,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Timer Display
                          if (_isTimerRunning)
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    "Time Remaining",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    _formatDuration(_remainingTime),
                                    style: GoogleFonts.poppins(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  ElevatedButton(
                                    onPressed: _stopTimer,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    child: Text("Stop Timer"),
                                  ),
                                ],
                              ),
                            ),
                          
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Members List
                          if (_showMembers && _groupMembers.isNotEmpty)
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                              padding: EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Group Members (${_groupMembers.length})",
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  ..._groupMembers.map((memberId) => 
                                    FutureBuilder<DocumentSnapshot>(
                                      future: _users.doc(memberId).get(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasData) {
                                          final userData = snapshot.data!.data() as Map<String, dynamic>?;
                                          final username = userData?['username'] ?? 'Unknown User';
                                          return ListTile(
                                            leading: CircleAvatar(
                                              backgroundColor: Colors.blue,
                                              child: Text(username[0].toUpperCase()),
                                            ),
                                            title: Text(username),
                                            subtitle: Text(memberId == uid ? 'You' : 'Member'),
                                          );
                                        }
                                        return ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor: Colors.grey,
                                            child: Icon(Icons.person),
                                          ),
                                          title: Text('Loading...'),
                                        );
                                      },
                                    ),
                                  ).toList(),
                                ],
                              ),
                            ),
                          
                          SizedBox(height: screenHeight * 0.05),
                          
                          // Start Chat Button
                          if (!_isTimerRunning)
                            Container(
                              margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                              child: ElevatedButton(
                                onPressed: _isProcessing ? null : _showTimerSelection,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isProcessing
                                    ? CircularProgressIndicator(color: Colors.white)
                                    : Text(
                                        "Start Trending Topic Chat",
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          
                          SizedBox(height: screenHeight * 0.02),
                          
                          // Description
                          Container(
                            margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                            padding: EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Text(
                              "Join the trending discussion about Big Boss! Connect with other fans and share your thoughts in real-time. The chat will automatically end when the timer expires.",
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
