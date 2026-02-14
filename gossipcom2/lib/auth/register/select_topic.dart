import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/auth/components/topic_container.dart';
import 'package:gossipcom/auth/register/select_vibe.dart';

class SelectTopic extends StatefulWidget {
  final String userName;
  const SelectTopic({super.key, required this.userName});

  @override
  State<SelectTopic> createState() => _SelectTopicState();
}

class _SelectTopicState extends State<SelectTopic> {
  final List<String> selectedTopics = [];

  void _handleTopicSelection(String topic, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedTopics.add(topic);
      } else {
        selectedTopics.remove(topic);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWeight = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          // Handle any cleanup if needed
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: screenHeight*0.1),
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
                  height: screenHeight*0.05,
                  width: screenWeight*0.75,
                  decoration: BoxDecoration(
                    color: Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(20),
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
            const SizedBox(height: 10),
            // Add the new heading
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Select topics you like atleast 6",
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Row 1
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: " Movies &  Series 🎥 ",
                  fontSize: 20,
                  isSelected: selectedTopics.contains(" Movies &  Series 🎥 "),
                  onSelected: (isSelected) =>
                      _handleTopicSelection(" Movies &  Series 🎥 ", isSelected),
                ),
                const SizedBox(width: 20),
                TopicContainer(
                  text: "Sports 🏏  ",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Sports 🏏  "),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Sports 🏏  ", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 2
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Music 🎵  ",
                  fontSize: 19,
                  isSelected: selectedTopics.contains("Music 🎵  "),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Music 🎵  ", isSelected),
                ),
                const SizedBox(width: 20),
                TopicContainer(
                  text: "About Life 😮‍💨 ",
                  fontSize: 19,
                  isSelected: selectedTopics.contains("About Life 😮‍💨 "),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("About Life 😮‍💨 ", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 3
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Office Gossip 💭 ",
                  fontSize: 15,
                  isSelected:
                      selectedTopics.contains("Office Gossip 💭 "),
                  onSelected: (isSelected) => _handleTopicSelection(
                      "Office Gossip 💭 ", isSelected),
                ),
                const SizedBox(width: 20),
                TopicContainer(
                  text: "Mental Health 💪🏻",
                  fontSize: 17,
                  isSelected: selectedTopics.contains("Mental Health 💪🏻"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Mental Health 💪🏻", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 20),

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
                const SizedBox(width: 20),
                TopicContainer(
                  text: "Pets 🐶 ",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Pets 🐶 "),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Pets 🐶 ", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 5
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Stocks 💰 ",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Stocks 💰 "),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Stocks 💰 ", isSelected),
                ),
                const SizedBox(width: 20),
                TopicContainer(
                  text: "Gaming 🎮",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Gaming 🎮"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Gaming 🎮", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 6
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Travel 🚗 ",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Travel 🚗 "),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Travel 🚗 ", isSelected),
                ),
                const SizedBox(width: 20),
                TopicContainer(
                  text: "Fashion 🕶️",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Fashion 🕶️"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Fashion 🕶️", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Row 8 - Additional topics if needed
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TopicContainer(
                  text: "Anime 🎴",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Anime 🎴"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Anime 🎴", isSelected),
                ),
                const SizedBox(width: 20),
                TopicContainer(
                  text: "Crypto 💸",
                  fontSize: 20,
                  isSelected: selectedTopics.contains("Crypto 💸"),
                  onSelected: (isSelected) =>
                      _handleTopicSelection("Crypto 💸", isSelected),
                ),
              ],
            ),
            const SizedBox(height: 30),
            
            // Topic count indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: selectedTopics.length >= 6 && selectedTopics.length <= 8 
                    ? Colors.green[100] 
                    : Colors.orange[100],
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selectedTopics.length >= 6 && selectedTopics.length <= 8 
                      ? Colors.green 
                      : Colors.orange,
                  width: 1,
                ),
              ),
              child: Text(
                'Selected: ${selectedTopics.length}/6-8 topics',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selectedTopics.length >= 6 && selectedTopics.length <= 8 
                      ? Colors.green[800] 
                      : Colors.orange[800],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // Continue Button
            GestureDetector(
              onTap: () {
                if (selectedTopics.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select at least 6 topics')),
                  );
                } else if (selectedTopics.length > 8) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select maximum 8 topics')),
                  );
                } else {
                  print("Selected Topics: $selectedTopics");
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => SelectVibe(
                              userName: widget.userName,
                              selectedTopics: selectedTopics)));
                }
              },
              child: Container(
                height: 52,
                width: 315,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    "Continue",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
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
      ),
    );
  }
}
