import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Bio extends StatefulWidget {
  const Bio({super.key});

  @override
  State<Bio> createState() => _BioState();
}

class _BioState extends State<Bio> {
  late TextEditingController _bioController;
  double screenWidth = 0;
  bool isLoading = false; // ADD THIS

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> saveBio() async {
    setState(() {
      isLoading = true; // show loading spinner
    });
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        print("No user logged in.");
        setState(() {
          isLoading = false;
        });
        return;
      }

      final bioText = _bioController.text.trim();
      if (bioText.isEmpty) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bio cannot be empty!')),
        );
        return;
      }

      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);

      await userDoc.set({
        'bio': bioText,
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bio saved successfully!')),
      );

      Navigator.pop(context, true); // Go back after saving
    } catch (e) {
      print('Error saving bio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save bio!')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false; // hide loading spinner
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: screenWidth * 0.13),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: screenWidth * 0.06),
              Image.asset("assets/app_logo.png", height: 60, width: 60),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios),
              ),
              SizedBox(width: screenWidth * 0.2),
              Text(
                "Edit Bio",
                style: GoogleFonts.dmSerifText(
                  fontWeight: FontWeight.w400,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _bioController,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintStyle: TextStyle(color: Color(0xFF979797)),
                    hintText: 'Write bio...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          InkWell(
            onTap: isLoading ? null : saveBio, // disable tap while loading
            child: Container(
              height: 52,
              width: 315,
              decoration: BoxDecoration(
                color: isLoading ? Colors.grey : const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: isLoading
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      )
                    : Text(
                        "Save",
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
