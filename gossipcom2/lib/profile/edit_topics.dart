import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/auth/components/topic_container.dart';

class EditTopic extends StatefulWidget {
  const EditTopic({super.key});

  @override
  State<EditTopic> createState() => _EditTopicState();
}

class _EditTopicState extends State<EditTopic> {
  final List<String> selectedTopics = [];
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentTopics();
  }

  Future<void> _loadCurrentTopics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final currentTopics = List<String>.from(doc['selectedTopics'] ?? []);
        setState(() {
          selectedTopics.addAll(currentTopics);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading topics: $e')),
        );
      }
    }
  }

  void _handleTopicSelection(String topic, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedTopics.add(topic);
      } else {
        selectedTopics.remove(topic);
      }
    });
  }

  Future<void> _updateTopics() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You must be logged in to update topics')),
        );
      }
      return;
    }

    if (selectedTopics.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one topic')),
        );
      }
      return;
    }

    setState(() => _isUpdating = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'selectedTopics': selectedTopics,
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Topics updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update topics: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 70),
            Row(
              children: [
                const SizedBox(width: 40),
                Image.asset("assets/app_logo.png", height: 60, width: 60),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back_ios, size: 32),
                ),
                Container(
                  height: 43,
                  width: 314,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF1976D2),
                        Color(0xFF0D3D6C),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      "Select Topics you like",
                      style: GoogleFonts.dmSerifText(
                        fontWeight: FontWeight.w400,
                        fontSize: 20,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Movies 🎬",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Movies 🎬"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Movies 🎬", isSelected),
                ),
                const SizedBox(width: 10),
                TopicContainer(
                  text: "Web Series 🍿",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Web Series 🍿"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Web Series 🍿", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Sports - Football ⚽",
                  fontSize: 19,
                  isSelected: selectedTopics.contains("Sports - Football ⚽"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Sports - Football ⚽", isSelected),
                ),
                const SizedBox(width: 10),
                TopicContainer(
                  text: "Sports - Cricket 🏏",
                  fontSize: 19,
                  isSelected: selectedTopics.contains("Sports - Cricket 🏏"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Sports - Cricket 🏏", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Music Hindi & English 🎧",
                  fontSize: 15,
                  isSelected:
                      selectedTopics.contains("Music Hindi & English 🎧"),
                  onSelected: (isSelected) => _handleTopicSelection(
                      "Music Hindi & English 🎧", isSelected),
                ),
                const SizedBox(width: 10),
                TopicContainer(
                  text: "Hip hop Music 🎤",
                  fontSize: 17,
                  isSelected: selectedTopics.contains("Hip hop Music 🎤"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Hip hop Music 🎤", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 4
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Books 📕",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Books 📕"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Books 📕", isSelected),
                ),
                const SizedBox(width: 10),
                TopicContainer(
                  text: "Loved Pets 🐶🐱",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Loved Pets 🐶🐱"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Loved Pets 🐶🐱", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 5
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Anime & Manga 🔥",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Anime & Manga 🔥"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Anime & Manga 🔥", isSelected),
                ),
                const SizedBox(width: 10),
                TopicContainer(
                  text: "Gaming 🎮",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Gaming 🎮"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Gaming 🎮", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 6
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Stocks 💰",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Stocks 💰"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Stocks 💰", isSelected),
                ),
                const SizedBox(width: 10),
                TopicContainer(
                  text: "Crypto 💸",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Crypto 💸"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Crypto 💸", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 7
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Travel 🚗",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Travel 🚗"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Travel 🚗", isSelected),
                ),
                const SizedBox(width: 10),
                TopicContainer(
                  text: "Fashion 🕶️",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Fashion 🕶️"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Fashion 🕶️", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Row 8
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Technology 💻",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Technology 💻"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Technology 💻", isSelected),
                ),
                const SizedBox(width: 10),
                TopicContainer(
                  text: "Cooking 🍳",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Cooking 🍳"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Cooking 🍳", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 50),

            // Continue Button
            GestureDetector(
              onTap: _isUpdating ? null : _updateTopics,
              child: Container(
                height: 52,
                width: 315,
                decoration: BoxDecoration(
                  color: _isUpdating ? Colors.grey : const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: _isUpdating
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Continue",
                          style: GoogleFonts.abhayaLibre(
                            fontWeight: FontWeight.w800,
                            fontSize: 20,
                            color: const Color(0xFFFFFFFF),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}
