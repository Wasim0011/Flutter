import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReviewUser extends StatefulWidget {
  final String userId;
  final void Function()? onTap;

  const ReviewUser({super.key, required this.userId, required this.onTap});

  @override
  State<ReviewUser> createState() => _ReviewUserState();
}

class _ReviewUserState extends State<ReviewUser> {
  String selectedPoints = "";
  bool _isSubmitting = false;
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final appOwnerId;
  String? userName;
  @override
  void initState() {
    super.initState();
    appOwnerId = _firebaseAuth.currentUser!.uid;
  }

  Future<void> _submitReview() async {
    if (selectedPoints.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final pointsToAdd = int.parse(selectedPoints);
      final userDoc =
      FirebaseFirestore.instance.collection('users').doc(widget.userId);
      final vibePoints = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection("vibe_Points")
          .doc(appOwnerId);
      DocumentSnapshot<Map<String, dynamic>> docData = await FirebaseFirestore
          .instance
          .collection('users')
          .doc(appOwnerId)
          .get();

      setState(() {
        userName = docData['userName'];
      });

      // Run a transaction to ensure atomic update
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(userDoc);
        if (!snapshot.exists) {
          throw Exception("User does not exist!");
        }

        // Get current points (default to 0 if not exists)
        final currentPoints =
            int.tryParse(snapshot.get('vibePoints') ?? '0') ?? 0;
        final newPoints = currentPoints + pointsToAdd;
        await vibePoints.set({
          'PointsAdded': pointsToAdd,
          'AddedBy': userName,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Update the points
        transaction.update(userDoc, {'vibePoints': newPoints.toString()});
        await _createNotification(userName!, pointsToAdd, widget.userId);

      });

      // Show success message and pop
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Successfully added $selectedPoints points!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _createNotification(
      String senderName, int points, String reciptentUserId) async {
    try {
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .collection("notification")
          .add({
        'type': 'vibe_points',
        'title': 'Vibe Points Received! 🎉',
        'message': '$senderName gave you $points vibe points!',
        'senderName': senderName,
        'senderId': appOwnerId,
        'points': points,
        'isRead': false,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Image.asset(
                "profile_assets/upper_review.png",
                height: 250,
                width: double.infinity,
                fit: BoxFit.fill,
              ),
              Positioned(
                top: 40,
                left: 24,
                child: InkWell(
                  onTap: widget.onTap,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 230,
                left: screenWidth * 0.1,
                right: screenWidth * 0.1,
                child: Material(
                  elevation: 5,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    child: Text(
                      "Review a User you just talked to",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 60),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 80),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F1FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              "Rate them below  👇",
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.black,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              PointsTile(
                text: "Oki Doki 🙂",
                points: "25",
                isSelected: selectedPoints == "25",
                onTap: () {
                  setState(() {
                    selectedPoints = "25";
                  });
                },
              ),
              PointsTile(
                text: "Solid Vibe 🎉",
                points: "50",
                isSelected: selectedPoints == "50",
                onTap: () {
                  setState(() {
                    selectedPoints = "50";
                  });
                },
              ),
              PointsTile(
                text: "Bro is Pro 😎",
                points: "100",
                isSelected: selectedPoints == "100",
                onTap: () {
                  setState(() {
                    selectedPoints = "100";
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            "Earn Vibe Points to Get Batches to your Personality \nand Unlock Medals",
            style: GoogleFonts.abhayaLibre(
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            "Please report users if they are being disrespectful, using inappropriate language, or straying off-topic.",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w400,
              fontSize: 13,
              color: Color(0xFF898A8D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            "Thanks for Rating",
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: const Color(0xFF898A8D),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _isSubmitting ? null : _submitReview,
            child: Container(
              height: 52,
              width: 315,
              decoration: BoxDecoration(
                color: _isSubmitting
                    ? const Color(0xFF1976D2).withValues(alpha: 0.5)
                    : const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  "Review User",
                  style: GoogleFonts.abhayaLibre(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PointsTile extends StatelessWidget {
  final String text;
  final String points;
  final bool isSelected;
  final void Function() onTap;

  const PointsTile({
    super.key,
    required this.text,
    required this.points,
    required this.onTap,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF736F6F).withValues(alpha: 0.8)
                  : const Color(0x33736F6F),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              text,
              style: GoogleFonts.abhayaLibre(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            "$points Vibe Points",
            style: GoogleFonts.abhayaLibre(
              fontWeight: FontWeight.w800,
              fontSize: 12,
              color: const Color(0xFF828282),
            ),
          )
        ],
      ),
    );
  }
}