import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import '../../profile/others_profile/other_profile.dart';
import 'chats/chat_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';

class MatchMaking extends StatefulWidget {
  final String topic;
  const MatchMaking({super.key, required this.topic});

  @override
  State<MatchMaking> createState() => _MatchMakingState();
}

class _MatchMakingState extends State<MatchMaking> with WidgetsBindingObserver {
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
  String _activeMode = 'one_to_one';
  final Set<String> _sentRequests = {};
  final Set<String> _receivedRequests = {};
  Stream<QuerySnapshot>? _availableUsersStream;
  Stream<QuerySnapshot>? _receivedRequestsStream;
  StreamSubscription<QuerySnapshot>? _matchListener1;
  StreamSubscription<QuerySnapshot>? _matchListener2;
  Timestamp? _sessionStartTime;

  // bool _isTimerActive = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _isNavigating = false;
    _cleanupExistingMatches().then((_) {
      _initializeFirebase();
    });
  }

  Future<void> _cleanupExistingMatches() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final firestore = FirebaseFirestore.instance;
    try {
      final timerDoc =
          await firestore.collection('topic_timer').doc(user.uid).get();
      final data = timerDoc.data();
      if (timerDoc.exists && data?['isRunning'] == true) {
        return;
      }

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
      debugPrint('Error cleaning up: $e');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _checkIfTimerRunning().then((isRunning) {
        if (!isRunning) _updateUserStatus(false);
      });
    } else if (state == AppLifecycleState.resumed) {
      _checkIfTimerRunning().then((isRunning) {
        if (!isRunning) _updateUserStatus(true);
      });
    }
    super.didChangeAppLifecycleState(state);
  }

  Future<bool> _checkIfTimerRunning() async {
    if (uid == null) return false;
    try {
      final doc = await _firestore.collection('topic_timer').doc(uid!).get();
      final data = doc.data();
      return doc.exists && data?['isRunning'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _updateUserStatus(bool isActive) async {
    if (uid == null) return;
    try {
      Map<String, dynamic> updates = {
        'uid': uid,
        'isInMatchmaking': isActive && _activeMode == 'one_to_one',
        'isInGroupMatchmaking': false,
        'currentTopic': widget.topic,
      };
      if (isActive) updates['lastActive'] = FieldValue.serverTimestamp();
      await _users.doc(uid).update(updates);

      if (_activeMode == 'one_to_one') {
        _availableUsersStream = _users
            .where('currentTopic', isEqualTo: widget.topic)
            .where('isInMatchmaking', isEqualTo: true)
            .where('lastActive',
                isGreaterThan: Timestamp.fromDate(
                    DateTime.now().subtract(const Duration(minutes: 5))))
            .snapshots();
      }
    } catch (e) {
      log('Error updating user status: $e');
    }
  }

  void _initializeFirebase() async {
    try {
      _firebaseAuth = FirebaseAuth.instance;
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        if (mounted) Navigator.of(context).pop();
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
      _activeMode = 'one_to_one';

      _setupMatchListener();
      _loadSentRequests();

      _availableUsersStream = _users
          .where('currentTopic', isEqualTo: widget.topic)
          .where('isInMatchmaking', isEqualTo: true)
          .where('lastActive',
              isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(minutes: 5))))
          .snapshots();
      _receivedRequestsStream = _matchRequests
          .where('targetUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .snapshots();

      bool isRunning = await _checkIfTimerRunning();
      if (isRunning) {
        // setState(() => _isTimerActive = true);
        _timestartedUntilUsersCome(true, 0);
      } else {
        _updateUserStatus(true);
      }
    } catch (e) {
      log('Initialization error: $e');
    }
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
          _sentRequests.addAll(
              requests.docs.map((doc) => doc.get('targetUid') as String));
        });
      }
    } catch (e) {
      log('Error loading sent requests: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    WidgetsBinding.instance.removeObserver(this);
    _matchListener1?.cancel();
    _matchListener2?.cancel();
    _cleanUpUserData();
    super.dispose();
  }

  Future<void> _cleanUpUserData() async {
    if (uid == null) return;
    try {
      if (await _checkIfTimerRunning()) {
        return; // Prevent cleanup if timer is active
      }
      await _users.doc(uid).update({
        'isInMatchmaking': false,
        'isInGroupMatchmaking': false,
        'currentTopic': FieldValue.delete()
      });
      final sent = await _matchRequests
          .where('senderUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      final batch = _firestore.batch();
      for (var doc in sent.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      log('Cleanup error: $e');
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
          final data = doc.data() as Map<String, dynamic>;
          if (data['createdAt'] != null &&
              _sessionStartTime != null &&
              (data['createdAt'] as Timestamp).compareTo(_sessionStartTime!) >=
                  0) {
            _handleMutualMatch(data['user2'], doc.id);
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
          final data = doc.data() as Map<String, dynamic>;
          if (data['createdAt'] != null &&
              _sessionStartTime != null &&
              (data['createdAt'] as Timestamp).compareTo(_sessionStartTime!) >=
                  0) {
            _handleMutualMatch(data['user1'], doc.id);
            break;
          }
        }
      }
    });
  }

  String _generateChatId(String uid1, String uid2) {
    return uid1.hashCode <= uid2.hashCode ? '$uid1-$uid2' : '$uid2-$uid1';
  }

  Future<bool> _checkDailyJoinLimit() async {
    if (uid == null) return false;
    final userRef = _users.doc(uid);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return false;
      final data = snapshot.data() as Map<String, dynamic>;
      final lastReset = (data['lastJoinReset'] as Timestamp?)?.toDate();
      final now = DateTime.now();
      bool isNewDay = lastReset == null ||
          lastReset.year != now.year ||
          lastReset.month != now.month ||
          lastReset.day != now.day;
      int currentCount = isNewDay ? 0 : (data['dailyConversationsJoined'] ?? 0);
      if (currentCount >= 10) return false;
      Map<String, dynamic> updates = {
        'dailyConversationsJoined': currentCount + 1
      };
      if (isNewDay) updates['lastJoinReset'] = FieldValue.serverTimestamp();
      transaction.update(userRef, updates);
      return true;
    });
  }

  Future<String?> _getAccessToken() async {
    try {
      final jsonString =
          await rootBundle.loadString('assets/service_account.json');
      final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final authClient =
          await clientViaServiceAccount(accountCredentials, scopes);
      return authClient.credentials.accessToken.data;
    } catch (e) {
      return null;
    }
  }

  Future<void> sendPushNotification(String targetUid, String topicName) async {
    try {
      DocumentSnapshot userDoc = await _users.doc(targetUid).get();
      if (!userDoc.exists) return;
      final userData = userDoc.data() as Map<String, dynamic>;
      String? token = userData['fcmToken'];
      if (token == null || token.isEmpty) return;
      String? accessToken = await _getAccessToken();
      if (accessToken == null) return;
      String projectId = Firebase.app().options.projectId;
      await http.post(
        Uri.parse(
            'https://fcm.googleapis.com/v1/projects/$projectId/messages:send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken'
        },
        body: jsonEncode(<String, dynamic>{
          'message': {
            'token': token,
            'notification': {
              'title': 'New Join Request',
              'body': 'Someone wants to join your gossip on $topicName!'
            },
            'data': {
              'click_action': 'FLUTTER_NOTIFICATION_CLICK',
              'id': '1',
              'status': 'done',
              'type': 'join_request'
            }
          },
        }),
      );
    } catch (e) {
      log('Error sending push notifications: $e');
    }
  }

  Future<void> _sendRequest(String targetUid) async {
    if (_isProcessing ||
        _isDisposed ||
        uid == null ||
        _sentRequests.contains(targetUid)) {
      return;
    }
    setState(() {
      _isProcessing = true;
      _activeMode = 'one_to_one';
    });
    try {
      if (!await _checkDailyJoinLimit()) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Daily Limit Reached: You can only join 10 conversations per day.'),
              backgroundColor: Colors.red));
        }
        return;
      }
      final targetPending = await _matchRequests
          .where('targetUid', isEqualTo: targetUid)
          .where('status', isEqualTo: 'pending')
          .get();
      if (targetPending.docs.length >= 3) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'This user already has too many pending requests (Max 3).'),
              backgroundColor: Colors.orange));
        }
        return;
      }

      await _users.doc(uid).update({
        'isInMatchmaking': true,
        'currentTopic': widget.topic,
        'lastActive': FieldValue.serverTimestamp()
      });
      final chatId = _generateChatId(uid!, targetUid);
      final existingMatch = await _tempMatches.doc(chatId).get();

      if (existingMatch.exists && existingMatch.get('status') == 'matched') {
        await _clearAllPendingRequests();
        await _createTempMatch(targetUid);
      } else {
        await _matchRequests.add({
          'senderUid': uid,
          'targetUid': targetUid,
          'topic': widget.topic,
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp()
        });
        sendPushNotification(targetUid, widget.topic);
        if (mounted) {
          setState(() => _sentRequests.add(targetUid));
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Connection request sent! wait for response or start more gossip')));
        }
      }
    } catch (e) {
      log('Error sending request: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _clearAllPendingRequests() async {
    if (uid == null) return;
    try {
      final sent = await _matchRequests
          .where('senderUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      final received = await _matchRequests
          .where('targetUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .get();
      final batch = _firestore.batch();
      for (var doc in sent.docs) {
        batch.delete(doc.reference);
      }
      for (var doc in received.docs) {
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
      log('Error clearing requests: $e');
    }
  }

  Future<void> _createTempMatch(String otherUid) async {
    if (uid == null) return;
    try {
      final chatId = _generateChatId(uid!, otherUid);
      await _tempMatches.doc(chatId).set({
        'user1': uid,
        'user2': otherUid,
        'topic': widget.topic,
        'status': 'matched',
        'createdAt': FieldValue.serverTimestamp()
      });
      await _clearAllPendingRequests();
    } catch (e) {
      log('Error creating temp match: $e');
    }
  }

  // Depression cross-matching logic
  Future<void> _handleDepressionAction(String actionType) async {
    if (uid == null) return;
    try {
      // First assign the role (Helper or Seeker)
      await _users.doc(uid).update({
        'depressionAction': actionType,
      });
      // Instead of immediate user list, go to Time Selection (same as "Start Gossip")
      _timerSelectionSheet(true);
    } catch (e) {
      log('Error handling depression actions: $e');
    }
  }

  // void _showDepressionUsersBottomSheet(String actionType) {
  //   String oppositeAction = actionType == 'helper' ? 'seeker' : 'helper';
  //   String title = actionType == 'helper' ? 'People seeking help' : 'People available to help';
  //   showModalBottomSheet(
  //     context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
  //     builder: (context) => Container(
  //       height: MediaQuery.of(context).size.height * 0.8, padding: const EdgeInsets.all(16),
  //       decoration: BoxDecoration(color: Theme.of(context).scaffoldBackgroundColor, borderRadius: const BorderRadius.vertical(top: Radius.circular(20))),
  //       child: Column(children: [
  //         Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold)),
  //         const SizedBox(height: 16),
  //         Expanded(child: StreamBuilder<QuerySnapshot>(
  //           // CHANGE: Filter users for the opposite role
  //           stream: _users.where('currentTopic', isEqualTo: widget.topic).where('depressionAction', isEqualTo: oppositeAction).where('isInMatchmaking', isEqualTo: true).snapshots(),
  //           builder: (context, snapshot) {
  //             if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return Center(child: Text("No ${oppositeAction}s available right now"));
  //             return ListView.builder(
  //               itemCount: snapshot.data!.docs.length,
  //               itemBuilder: (context, index) {
  //                 final doc = snapshot.data!.docs[index];
  //                 return doc.id == uid ? const SizedBox.shrink() : _buildUserCard(doc, false);
  //               },
  //             );
  //           },
  //         )),
  //       ]),
  //     ),
  //   );
  // }

  Future<void> _handleMutualMatch(String otherUid, String matchId) async {
    if (uid == null || _isNavigating) return;
    _isNavigating = true;
    try {
      final otherDoc = await _users.doc(otherUid).get();
      final otherName = otherDoc.get('userName') ?? 'Anonymous';
      final chatId = _generateChatId(uid!, otherUid);
      final existingChat = await _topicChats.doc(chatId).get();
      if (!existingChat.exists) {
        await _topicChats.doc(chatId).set({
          'participants': [uid, otherUid],
          'topic': widget.topic,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp()
        });
        final batch = _firestore.batch();
        batch.set(_users.doc(uid).collection('chats').doc(chatId), {
          'otherUserId': otherUid,
          'chatId': chatId,
          'topic': widget.topic,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': 0
        });
        batch.set(_users.doc(otherUid).collection('chats').doc(chatId), {
          'otherUserId': uid,
          'chatId': chatId,
          'topic': widget.topic,
          'createdAt': FieldValue.serverTimestamp(),
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'unreadCount': 0
        });
        await batch.commit();
      }
      await _tempMatches.doc(matchId).delete();
      await _clearAllPendingRequests();
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => ChatScreen(
                    chatId: chatId,
                    otherUserId: otherUid,
                    otherUserName: otherName)));
      }
    } catch (e) {
      log('Error handling mutual match: $e');
    } finally {
      _isNavigating = false;
    }
  }

  // User card logic (Profile views + Vibe Points)
  Widget _buildUserCard(DocumentSnapshot user, bool isRequest) {
    final userData = user.data() as Map<String, dynamic>?;
    final userName = userData?['userName'] ?? 'Anonymous';
    final targetUid = user.id;
    final hasSent = _sentRequests.contains(targetUid);
    final vibePoints = userData?['vibePoints'] ?? '0';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        CircleAvatar(
          backgroundImage: (userData?['avatar'] != null &&
                  userData!['avatar'].toString().isNotEmpty)
              ? NetworkImage(userData['avatar'])
              : null,
          child: (userData?['avatar'] == null ||
                  userData!['avatar'].toString().isEmpty)
              ? Text(userName.substring(0, 1))
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(userName,
                    style: GoogleFonts.poppins(
                        fontSize: 16, fontWeight: FontWeight.w600))),
            InkWell(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => OtherProfile(
                            otherUserId: targetUid, otherUserName: userName))),
                child: _badgeContainer("View Profile")),
            const SizedBox(width: 8),
            _badgeContainer("$vibePoints Vibe Point 🔥"),
          ]),
          const SizedBox(height: 6),
          Text('Wanted to join a discussion',
              style: GoogleFonts.abhayaLibre(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          Align(
              alignment: Alignment.centerRight,
              child: isRequest
                  ? _buildAcceptDecline(targetUid)
                  : (hasSent
                      ? const Text('Request Sent',
                          style: TextStyle(color: Colors.grey))
                      : _buildStyledButton(
                          text: 'Connect ✅',
                          onPressed: () async {
                            Navigator.pop(context);
                            await _sendRequest(targetUid);
                          }))),
        ])),
      ]),
    );
  }

  Widget _badgeContainer(String text) {
    return Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
            color: const Color(0x33736F6F),
            borderRadius: BorderRadius.circular(10)),
        child: Text(text,
            style: GoogleFonts.abhayaLibre(
                fontWeight: FontWeight.w800,
                fontSize: 10,
                color: const Color(0xFF828282))));
  }

  Widget _buildAcceptDecline(String targetUid) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      _buildStyledButton(
          text: 'Accept',
          backgroundColor: Colors.green[100]!,
          textColor: Colors.green,
          onPressed: () async {
            if (await _checkDailyJoinLimit()) await _sendRequest(targetUid);
          }),
      const SizedBox(width: 8),
      _buildStyledButton(
          text: 'Decline',
          backgroundColor: Colors.red[100]!,
          textColor: Colors.red,
          onPressed: () async {
            final reqs = await _matchRequests
                .where('senderUid', isEqualTo: targetUid)
                .where('targetUid', isEqualTo: uid)
                .get();
            final batch = _firestore.batch();
            for (var doc in reqs.docs) {
              batch.delete(doc.reference);
            }
            await batch.commit();
            if (mounted) setState(() => _receivedRequests.remove(targetUid));
          }),
    ]);
  }

  Widget _buildStyledButton(
      {required String text,
      required VoidCallback onPressed,
      Color backgroundColor = const Color(0xFFD9D9D9),
      Color textColor = Colors.black}) {
    return InkWell(
        onTap: onPressed,
        child: Container(
            decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text(text,
                style: GoogleFonts.abhayaLibre(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: textColor))));
  }

  void _showAvailableUsersBottomSheet(bool isHost) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20))),
        child: Column(children: [
          Text(isHost ? 'Available Users to Connect' : 'Join a Discussion',
              style: GoogleFonts.poppins(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Expanded(
              child: StreamBuilder<QuerySnapshot>(
            stream: isHost ? _availableUsersStream : _receivedRequestsStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No user Found"));
              }
              return ListView.builder(
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  if (doc.id == uid) return const SizedBox.shrink();
                  if (isHost) return _buildUserCard(doc, false);
                  return FutureBuilder<DocumentSnapshot>(
                      future: _users.doc(doc.get('senderUid')).get(),
                      builder: (context, uSnap) =>
                          uSnap.hasData && uSnap.data!.exists
                              ? _buildUserCard(uSnap.data!, true)
                              : const SizedBox.shrink());
                },
              );
            },
          )),
        ]),
      ),
    );
  }

  void _timerSelectionSheet(bool isHost) {
    int selectedIndex = -1;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(children: [
            const SizedBox(height: 20),
            Text('Start Gossip for ${widget.topic}',
                style: GoogleFonts.dmSerifText(
                    fontSize: 25, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(child: LottieBuilder.asset('assets/animation/logo.json')),
            const SizedBox(height: 20),
            _buildDurationOption("30 minutes", 0, selectedIndex,
                (i) => setModalState(() => selectedIndex = i)),
            const SizedBox(height: 20),
            _buildDurationOption("1 Hour 30 minutes", 1, selectedIndex,
                (i) => setModalState(() => selectedIndex = i)),
            const SizedBox(height: 20),
            _buildDurationOption("2 Hours", 2, selectedIndex,
                (i) => setModalState(() => selectedIndex = i)),
            const SizedBox(height: 40),
            GestureDetector(
              onTap: () async {
                if (selectedIndex == -1) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Select duration first")));
                  return;
                }

                int mins = 0;
                // Explicitly set duration based on selected index
                if (selectedIndex == 0) {
                  mins = 30;
                } else if (selectedIndex == 1) {
                  mins = 90; // 1 Hour 30 Minutes
                } else if (selectedIndex == 2) {
                  _showPremiumDialog();
                  return;
                }

                Navigator.pop(context);
                // setState(() => _isTimerActive = true);
                await _firestore.collection('topic_timer').doc(uid).set({
                  'timerStartedAt': FieldValue.serverTimestamp(),
                  'durationInMinutes': mins,
                  'isRunning': true
                }, SetOptions(merge: true));
                await _users.doc(uid).update({
                  'lastActive': Timestamp.fromDate(
                      DateTime.now().add(Duration(minutes: mins))),
                  'isInMatchmaking': true,
                  'currentTopic': widget.topic
                });
                _timestartedUntilUsersCome(true, mins);
              },
              child: Container(
                  width: double.infinity,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white)),
                  child: Center(
                      child: Text("Start",
                          style: GoogleFonts.poppins(
                              fontSize: 15, fontWeight: FontWeight.bold)))),
            ),
          ]),
        ),
      ),
    );
  }

  void _showPremiumDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              actions: [
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const SizedBox(height: 10),
                  const Center(child: Text("Do you Want to Pay Premium")),
                  const SizedBox(height: 20),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        GestureDetector(
                            onTap: () => log("Implement Paytm"),
                            child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white)),
                                height: 20,
                                width: 60,
                                child: const Center(child: Text("Yes")))),
                        GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                                decoration: BoxDecoration(
                                    border: Border.all(color: Colors.white)),
                                height: 20,
                                width: 60,
                                child: const Center(child: Text("NO")))),
                      ])
                ])
              ],
            ));
  }

  Widget _buildDurationOption(
      String text, int index, int selectedIndex, Function(int) onSelect) {
    return GestureDetector(
      onTap: () => onSelect(index),
      child: Container(
          width: double.infinity,
          height: 40,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white),
              color: selectedIndex == index ? Colors.blue : Colors.transparent),
          child: Center(
              child: Text(text,
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.bold)))),
    );
  }

  void _timestartedUntilUsersCome(bool isHost, int minutes) {
    Timer? localTimer;
    Duration remaining = Duration.zero;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, modalState) {
          void initTimer() async {
            final doc =
                await _firestore.collection('topic_timer').doc(uid).get();
            final data = doc.data();
            if (data == null || data['isRunning'] == false) return;
            final end = (data['timerStartedAt'] as Timestamp)
                .toDate()
                .add(Duration(minutes: data['durationInMinutes']));
            localTimer?.cancel();
            localTimer = Timer.periodic(const Duration(seconds: 1), (t) {
              final diff = end.difference(DateTime.now());
              if (diff.isNegative) {
                t.cancel();
                modalState(() => remaining = Duration.zero);
              } else {
                modalState(() => remaining = diff);
              }
            });
          }

          WidgetsBinding.instance.addPostFrameCallback((_) => initTimer());
          return Container(
            height: MediaQuery.of(context).size.height * 0.8,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20))),
            child: Column(children: [
              Text('You Started Gossip for Topic Name',
                  style: GoogleFonts.dmSerifText(
                      fontSize: 25, fontWeight: FontWeight.bold)),
              Text('Please wait people to respond',
                  style: GoogleFonts.poppins(
                      fontSize: 15, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              SizedBox(
                  child: LottieBuilder.asset('assets/animation/logo.json')),
              const SizedBox(height: 20),
              Text(
                  "${remaining.inHours.toString().padLeft(2, '0')}:${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}:${remaining.inSeconds.remainder(60).toString().padLeft(2, '0')}",
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              const Spacer(),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white),
                  onPressed: () async {
                    localTimer?.cancel();
                    await _firestore
                        .collection('topic_timer')
                        .doc(uid)
                        .update({'isRunning': false});
                    // setState(() => _isTimerActive = false);
                    await _updateUserStatus(true);
                    Navigator.pop(context);
                  },
                  child: const Text("Stop Timer and End Session")),
              const SizedBox(height: 16),
              Expanded(
                  child: FutureBuilder<DocumentSnapshot>(
                      future: _users.doc(uid).get(),
                      builder: (context, mySnap) {
                        final myData =
                            mySnap.data?.data() as Map<String, dynamic>?;
                        final String? myRole = myData?['depressionAction'];
                        final String oppositeRole =
                            (myRole == 'helper') ? 'seeker' : 'helper';

                        return StreamBuilder<QuerySnapshot>(
                          // MODIFICATION: For depression topic, waiting screen explicitly filters for opposite role
                          stream: (widget.topic.contains('Depressed'))
                              ? _users
                                  .where('currentTopic',
                                      isEqualTo: widget.topic)
                                  .where('depressionAction',
                                      isEqualTo: oppositeRole)
                                  .where('isInMatchmaking', isEqualTo: true)
                                  .snapshots()
                              : (isHost
                                  ? _availableUsersStream
                                  : _receivedRequestsStream),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return ListView.builder(
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  final d = snapshot.data!.docs[index];
                                  return d.id == uid
                                      ? const SizedBox.shrink()
                                      : _buildUserCard(
                                          d,
                                          (widget.topic.contains('Depressed'))
                                              ? false
                                              : (isHost ? false : true));
                                });
                          },
                        );
                      })),
            ]),
          );
        },
      ),
    ).whenComplete(() {
      localTimer?.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isDepression = widget.topic.contains('Depressed') ||
        widget.topic.contains('motivation');
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _cleanUpUserData();
        if (mounted) Navigator.pop(context, result);
      },
      child: Scaffold(
        body: Stack(children: [
          Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                  height: 400,
                  child: OverflowBox(
                      maxHeight: double.infinity,
                      alignment: Alignment.topCenter,
                      child: Image.asset("matchmaking_asset/upper.png",
                          fit: BoxFit.cover)))),
          Positioned.fill(
              top: screenHeight * 0.35,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                    child: Container(
                        color: Colors.transparent,
                        child: SingleChildScrollView(
                            child: Column(children: [
                          const SizedBox(height: 10),
                          Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04),
                              child: Row(children: [
                                IconButton(
                                    onPressed: () async {
                                      await _cleanUpUserData();
                                      Navigator.pop(context);
                                    },
                                    icon: Icon(Icons.arrow_back_ios,
                                        size: 24,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface)),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Text(widget.topic,
                                        style: GoogleFonts.poppins(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w700))),
                              ])),
                          const SizedBox(height: 20),
                          if (isDepression) ...[
                            Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: Row(children: [
                                  Expanded(
                                      child: InkWell(
                                          onTap: () =>
                                              _handleDepressionAction('helper'),
                                          child: Container(
                                              padding: const EdgeInsets.all(18),
                                              decoration: BoxDecoration(
                                                  color: Colors.green,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              child: Center(
                                                  child: Text(
                                                      "I am here to help",
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Colors
                                                                  .white)))))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: InkWell(
                                          onTap: () =>
                                              _handleDepressionAction('seeker'),
                                          child: Container(
                                              padding: const EdgeInsets.all(18),
                                              decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              child: Center(
                                                  child: Text("I want help",
                                                      style:
                                                          GoogleFonts.poppins(
                                                              fontSize: 14,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: Colors
                                                                  .white)))))),
                                ])),
                          ] else ...[
                            Material(
                                elevation: 5,
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                    width: 160.w,
                                    height: 140.h,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 30, horizontal: 10),
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: Colors.blue, width: 2),
                                        borderRadius: BorderRadius.circular(20),
                                        color: Colors.blue.shade50),
                                    child: Column(children: [
                                      Text("One to One",
                                          style: GoogleFonts.dmSerifText(
                                              fontSize: 20.sp,
                                              color: Colors.blue[800])),
                                      const SizedBox(height: 8),
                                      Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Icon(Icons.people,
                                                color: Colors.blue, size: 12),
                                            Text("  1:1 Discussion",
                                                style: GoogleFonts.abhayaLibre(
                                                    color: Colors.blue[600],
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 12))
                                          ])
                                    ]))),
                            const SizedBox(height: 24),
                            _buildOriginalButton(
                                "Start a Gossip",
                                const Color(0xFF1976D2),
                                Colors.white,
                                () => _timerSelectionSheet(true)),
                            const SizedBox(height: 16),
                            _buildOriginalButton(
                                "Join a Gossip",
                                Colors.white,
                                Colors.black,
                                () => _showAvailableUsersBottomSheet(false),
                                border: true),
                          ],
                          const SizedBox(height: 24),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              child: Text(
                                  "TIPS : Can't find someone to Discuss with? Join an active Discussion and keep the Discussions going",
                                  style: GoogleFonts.abhayaLibre(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 13,
                                      color: const Color(0xFF828282)),
                                  textAlign: TextAlign.center)),
                        ])))),
              )),
        ]),
      ),
    );
  }

  Widget _buildOriginalButton(
      String text, Color bg, Color txt, VoidCallback tap,
      {bool border = false}) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: InkWell(
            onTap: tap,
            child: Container(
                padding: const EdgeInsets.all(18),
                width: double.infinity,
                decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(12),
                    border: border ? Border.all(color: Colors.black) : null),
                child: Center(
                    child: Text(text,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: txt))))));
  }
}
