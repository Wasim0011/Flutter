import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/thoughts/particular_thought/particular_thought.dart';
import 'package:gossipcom/thoughts/thoughts_service.dart';
import 'package:image_picker/image_picker.dart';

class AddThought extends StatefulWidget {
  const AddThought({super.key});

  @override
  State<AddThought> createState() => _AddThoughtState();
}

class _AddThoughtState extends State<AddThought> {
  final TextEditingController _thoughtController = TextEditingController();
  final ThoughtsService thoughtService = ThoughtsService();
  bool _isPosting = false;
  late XFile isImageSelected;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = _firebaseAuth.currentUser?.uid;
  }

  //Helper to Check and Update Limit
  Future<bool> _checkDailyPostLimit() async {
    if (userId == null) return false;
    final userRef = _firestore.collection('users').doc(userId);

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return false;

      final data = snapshot.data() as Map<String, dynamic>;
      final lastReset = (data['lastPostReset'] as Timestamp?)?.toDate();
      final now = DateTime.now();

      // Check if it's a new day
      bool isNewDay = lastReset == null ||
          lastReset.year != now.year ||
          lastReset.month != now.month ||
          lastReset.day != now.day;

      int currentCount = isNewDay ? 0 : (data['dailyNormalPosts'] ?? 0);

      if (currentCount >= 5) {
        return false; // Limit reached
      }

      // Prepare updates
      Map<String, dynamic> updates = {
        'dailyNormalPosts': currentCount + 1,
      };
      if (isNewDay) {
        updates['lastPostReset'] = FieldValue.serverTimestamp();
        // Reset other counters if needed, ensuring they sync
        updates['dailyGossipPosts'] = 0;
      }

      transaction.update(userRef, updates);
      return true;
    });
  }

  Future<void> _addThought() async {
    final thought = _thoughtController.text.trim();
    if (thought.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your thought')),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      // Check Limit First
      bool allowed = await _checkDailyPostLimit();
      if (!allowed) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Daily Limit Reached! You can only post 5 normal posts per day.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await thoughtService.createThought(thought: thought);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to post: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: screenHeight * 0.08),
                Row(
                  children: [
                    const SizedBox(width: 10),
                    IconButton(
                      onPressed: _isPosting
                          ? null
                          : () {
                              Navigator.pop(context);
                            },
                      icon: const Icon(Icons.arrow_back_ios, size: 30),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Container(
                        height: screenHeight * 0.05,
                        width: screenWidth * 0.75,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? const Color(
                                  0x33FFFFFF) // Light white with transparency for dark theme
                              : const Color(
                                  0x33736F6F), // Original grey color for light theme
                        ),
                        child: Center(
                          child: Text(
                            "Thoughts & QnA",
                            style: GoogleFonts.dmSerifText(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors
                                      .grey[300] // Lighter grey for dark theme
                                  : Colors
                                      .grey, // Original grey for light theme
                              fontSize: 18,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),
                      ),
                    )
                  ],
                ),
                const SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Material(
                    borderRadius: BorderRadius.circular(16),
                    elevation: 3,
                    child: Container(
                      width: double.infinity,
                      height: 270,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(color: Colors.grey, width: 1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                UserAvatar(
                                    userId: userId,
                                    size: 40,
                                    firestore: _firestore),
                                const SizedBox(width: 12),
                                FutureBuilder<String?>(
                                  future: thoughtService.getCurrentUsername(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return const CircularProgressIndicator();
                                    }
                                    if (snapshot.hasError ||
                                        !snapshot.hasData) {
                                      return Text(
                                        "User",
                                        style: GoogleFonts.dmSerifText(
                                          fontWeight: FontWeight.w400,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                          fontSize: 20,
                                        ),
                                      );
                                    }
                                    return Text(
                                      snapshot.data!,
                                      style: GoogleFonts.dmSerifText(
                                        fontWeight: FontWeight.w400,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondary,
                                        fontSize: 20,
                                      ),
                                    );
                                  },
                                )
                              ],
                            ),
                            const Divider(
                                thickness: 2, color: Color(0x82979797)),
                            SizedBox(
                              height: 140,
                              child: TextField(
                                controller: _thoughtController,
                                maxLines: null,
                                enabled: !_isPosting,
                                keyboardType: TextInputType.multiline,
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  hintText: "Write Here..",
                                  hintStyle: TextStyle(color: Colors.grey),
                                ),
                                style: GoogleFonts.dmSerifText(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                            const Divider(
                                thickness: 2, color: Color(0x82979797)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "0 Views",
                                  style: GoogleFonts.dmSerifText(
                                    fontWeight: FontWeight.w400,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSecondary,
                                    fontSize: 18,
                                  ),
                                ),
                                Text("❤️‍🔥", style: _emojiStyle()),
                                Text("😍", style: _emojiStyle()),
                                Text("😂", style: _emojiStyle()),
                                Text("🤯", style: _emojiStyle()),
                                Text("💀", style: _emojiStyle()),
                                Text("😢", style: _emojiStyle()),
                                Text("🤔", style: _emojiStyle()),
                                Text("💡", style: _emojiStyle()),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                GestureDetector(
                  onTap: _isPosting ? null : _addThought,
                  child: Container(
                    height: 52,
                    width: 315,
                    decoration: BoxDecoration(
                      color: _isPosting ? Colors.grey : const Color(0xFF1976D2),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Center(
                      child: _isPosting
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              "Post",
                              style: GoogleFonts.abhayaLibre(
                                fontWeight: FontWeight.w800,
                                fontSize: 22,
                                color: const Color(0xFFFFFFFF),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _emojiStyle() {
    return GoogleFonts.dmSerifText(
      fontWeight: FontWeight.w400,
      color: const Color(0xFF060606),
      fontSize: 18,
    );
  }
}
