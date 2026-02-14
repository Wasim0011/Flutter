import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/auth/components/vibe_container.dart';
import 'package:gossipcom/auth/register/avatar_selection.dart';

class SelectVibe extends StatefulWidget {
  final String userName;
  final List<String> selectedTopics;
  const SelectVibe(
      {super.key, required this.userName, required this.selectedTopics});

  @override
  State<SelectVibe> createState() => _SelectVibeState();
}

class _SelectVibeState extends State<SelectVibe> {
  final List<String> selectedVibes = [];
  void _handleTopicSelection(String topic, bool isSelected) {
    setState(() {
      if (isSelected) {
        selectedVibes.add(topic);
      } else {
        selectedVibes.remove(topic);
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
            SizedBox(height: screenHeight*0.08),
            Image.asset("assets/smallHeader.png"),
            SizedBox(height: screenHeight*0.04),


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
                      "Select Your Vibe",
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
            const SizedBox(
              height: 30,
            ),
            Text(
              "Choose below 6  tags define your personality ",
              style: GoogleFonts.dmSerifText(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF505050)
              ),
            ),
            const SizedBox(
              height: 30,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VibeContainer(
                    text: " Lit ! 🔥",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Lit ! 🔥"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Lit ! 🔥", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: "  W Rizz 💯",
                    fontSize: 14,
                    isSelected: selectedVibes.contains("  W Rizz 💯"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection("  W Rizz 💯", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: " Conflict Fixer 🛠️",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Conflict Fixer 🛠️"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Conflict Fixer 🛠️", isSelected)),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VibeContainer(
                    text: " Meme Lord 😂",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Meme Lord 😂"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Meme Lord 😂", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: "   Storyteller  📖",
                    fontSize: 14,
                    isSelected: selectedVibes.contains("   Storyteller  📖"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection("   Storyteller  📖", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: "Low-KeyPhilosopher🌌",
                    fontSize: 14,
                    isSelected: selectedVibes.contains("Low-KeyPhilosopher🌌"),
                    onSelected: (isSelected) => _handleTopicSelection(
                        "Low-KeyPhilosopher🌌", isSelected)),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VibeContainer(
                    text: " Trend Spotter 🔍",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Trend Spotter 🔍"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Trend Spotter 🔍", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: "RantPro💬",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Rant Pro 💬"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Rant Pro 💬", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: " Mood Booster 🌟",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Mood Booster 🌟"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Mood Booster 🌟", isSelected)),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VibeContainer(
                    text: "Drip Dealer 👟",
                    fontSize: 14,
                    isSelected: selectedVibes.contains("Drip Dealer 👟"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection("Drip Dealer 👟", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: " Music Plug 🎵",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Music Plug 🎵"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Music Plug 🎵", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: " Anime Buff 📺 ",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Anime Buff 📺 "),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Anime Buff 📺 ", isSelected)),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VibeContainer(
                    text: " Simp 💖",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Simp 💖"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Simp 💖", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: " Deep Diver 🌊",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Deep Diver 🌊"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Deep Diver 🌊", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: " Therapist🛋️ ",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Therapist🛋️ "),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Therapist🛋️ ", isSelected)),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VibeContainer(
                    text: " Good Listener 👂",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Good Listener 👂"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Good Listener 👂", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: " Confidence Coach 🎤",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Confidence Coach 🎤"),
                    onSelected: (isSelected) => _handleTopicSelection(
                        " Confidence Coach 🎤", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: " Support Squad ",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Support Squad "),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Support Squad ", isSelected)),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                VibeContainer(
                    text: " Rizz Master  😎",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Rizz Master  😎"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Rizz Master  😎", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: " Tea Spiller – ☕️",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Tea Spiller – ☕️"),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Tea Spiller – ☕️", isSelected)),
                const SizedBox(
                  width: 5,
                ),
                VibeContainer(
                    text: " Hype Machine 📣 ",
                    fontSize: 14,
                    isSelected: selectedVibes.contains(" Hype Machine 📣 "),
                    onSelected: (isSelected) =>
                        _handleTopicSelection(" Hype Machine 📣 ", isSelected)),
              ],
            ),
            const SizedBox(
              height: 50,
            ),
            GestureDetector(
              onTap: () {
                print(selectedVibes);
                print(widget.selectedTopics);
                print(widget.userName);
                if (selectedVibes.length < 6) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please select at least six topic')),
                  );
                } else {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AvatarSelection(
                                userName: widget.userName,
                                selectedTopics: widget.selectedTopics,
                                selectedVibes: selectedVibes,
                              )));
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0),
              child: Text("Earn Vibe Points through conversations and unlock medals.",
              style: GoogleFonts.dmSerifText(
                fontWeight: FontWeight.w400,
                fontSize: 13,
                color: Color(0xFF828282)
              ),textAlign: TextAlign.center,),
            )
          ],
        ),
      ),
      ),
    );
  }
}
