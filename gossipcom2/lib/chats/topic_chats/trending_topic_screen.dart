import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/components/heading.dart';
import 'trending_topic_matchmaking.dart';

class TrendingTopicScreen extends StatefulWidget {
  const TrendingTopicScreen({super.key});

  @override
  TrendingTopicScreenState createState() => TrendingTopicScreenState();
}

class TrendingTopicScreenState extends State<TrendingTopicScreen> {
  final List<String> trendingItems = [
    'Big Boss 🎥',
    'Sports Talk 🏏',
    'Music, Rock,\nPop, Hop etc 🎵',
    'Daily Life\nProblems 😮‍💨',
    'Office, Work,\nCollege Gossip 💭',
    'Depressed,\nGive or Take Help 💪',
  ];

  bool _isLoading = false;

  Future<void> _handleTopicSelection(String topic) async {
    setState(() => _isLoading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    try {
      final cleanTopic = topic.replaceAll('\n', ' ');

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'currentTopic': cleanTopic,
        'requests': [],
        'accepted': [],
      }, SetOptions(merge: true));

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TrendingTopicMatchMaking(topic: cleanTopic),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              SizedBox(height: screenHeight * 0.07),
              // Header Section
              Container(
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Text(
                          "Welcome To",
                          style: GoogleFonts.poppins(
                            fontSize: 17,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          "GOSSIP",
                          style: GoogleFonts.dmSerifText(
                            fontSize: 40,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    Image.asset(
                      'assets/app_logo.png',
                      height: 120,
                      fit: BoxFit.fill,
                    )
                  ],
                ),
              ),
              SizedBox(height: screenHeight * 0.02),

              // Navigation Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(width: screenWidth * 0.02),
                  Material(
                    elevation: 5,
                    borderRadius: const BorderRadiusDirectional.all(
                      Radius.circular(30),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.tertiary,
                        border:
                        Border.all(width: 1, color: Colors.grey.shade400),
                      ),
                      child: Center(
                        child: IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios, size: 30),
                        ),
                      ),
                    ),
                  ),
                  const Heading(text: "Trending Topics 🔥"),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),

              // Grid View
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    padding: EdgeInsets.zero,
                    physics: const BouncingScrollPhysics(),
                    itemCount: trendingItems.length,
                    gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: 1.5,
                    ),
                    itemBuilder: (context, index) {
                      final item = trendingItems[index];
                      return Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              width: 1, color: Colors.grey.shade400),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _handleTopicSelection(item),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                item,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.dmSerifText(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Footer Text
              Text(
                "Soon we are adding more topic, Stay Tuned",
                style: GoogleFonts.abhayaLibre(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF828282),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),

        // Loading Overlay
        if (_isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
      ],
    );
  }
}