import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/components/heading.dart';
import 'matchmaking.dart';
import 'trending_topic_screen.dart';

class TopicSelectionScreen extends StatefulWidget {
  const TopicSelectionScreen({super.key});

  @override
  TopicSelectionScreenState createState() => TopicSelectionScreenState();
}

class TopicSelectionScreenState extends State<TopicSelectionScreen> {
  final List<String> topics = [
    'Movies & Web \n       series 🎬',
    'Sports  ⚽🏏',
    'Music,Rock,Pop,hop etc 🎧',
    'Daily Life \nProblems 🥺',
    'Office,Work,\nCollege Gossips 💬',
    'Depressed,\nwant some motivation☮'
  ];

  final String trendingSectionText =
      'Any latest Trending topic like big boss or latent show depend on trend';
  // final String trendingTopic = 'Trending topic:\nBig Boss ``🔥';

  bool _isLoading = false;

  // Helper to Check Topic Start Limit
  Future<bool> _checkDailyTopicLimit(String uid) async {
    final userRef = FirebaseFirestore.instance.collection('users').doc(uid);

    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return false;

      final data = snapshot.data() as Map<String, dynamic>;
      final lastReset = (data['lastTopicReset'] as Timestamp?)?.toDate();
      final now = DateTime.now();

      bool isNewDay = lastReset == null ||
          lastReset.year != now.year ||
          lastReset.month != now.month ||
          lastReset.day != now.day;

      int currentCount = isNewDay ? 0 : (data['dailyTopicStartCount'] ?? 0);

      if (currentCount >= 3) {
        return false; // Limit reached
      }

      Map<String, dynamic> updates = {
        'dailyTopicStartCount': currentCount + 1,
      };
      if (isNewDay) {
        updates['lastTopicReset'] = FieldValue.serverTimestamp();
      }

      transaction.update(userRef, updates);
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          body: Column(
            children: [
              SizedBox(height: screenHeight * 0.07),
              // Container(
              //   decoration: BoxDecoration(
              //       color: Theme.of(context).colorScheme.surface,
              //       borderRadius: BorderRadius.circular(12)),
              //   child: Row(
              //     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              //     children: [
              //       Column(
              //         children: [
              //           Text(
              //             "Welcome To",
              //             style: GoogleFonts.poppins(
              //               fontSize: 17,
              //               fontWeight: FontWeight.w300,
              //             ),
              //           ),
              //           Text(
              //             "GOSSIP",
              //             style: GoogleFonts.dmSerifText(
              //               fontSize: 40,
              //               fontWeight: FontWeight.w300,
              //             ),
              //           ),
              //         ],
              //       ),
              //       Image.asset(
              //         'assets/app_logo.png',
              //         height: 120,
              //         fit: BoxFit.fill,
              //         // color: Colors.black12,
              //       )
              //     ],
              //   ),
              // ),
              // SizedBox(height: screenHeight * 0.02),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(width: screenWidth * 0.02),
                  Material(
                    elevation: 5,
                    borderRadius: BorderRadiusDirectional.all(
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
                  const Heading(text: "One Topic Gossip"),
                ],
              ),
              SizedBox(height: screenHeight * 0.03),
              // Trending Topic Button
              // Padding(
              //   padding: const EdgeInsets.symmetric(horizontal: 16.0),
              //   child: SizedBox(
              //     width: double.infinity,
              //     height: 100,
              //     child: Card(
              //       elevation: 8,
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(16),
              //         side: BorderSide(width: 2, color: Colors.orange.shade300),
              //       ),
              //       child: InkWell(
              //         borderRadius: BorderRadius.circular(16),
              //         onTap: () {
              //           Navigator.push(
              //             context,
              //             MaterialPageRoute(
              //                 builder: (_) => const TrendingTopicScreen()),
              //           );
              //         },
              //         child: Container(
              //           decoration: BoxDecoration(
              //             borderRadius: BorderRadius.circular(20),
              //             gradient: LinearGradient(
              //               colors: [
              //                 Colors.orange.shade400,
              //                 Colors.red.shade400
              //               ],
              //               begin: Alignment.topLeft,
              //               end: Alignment.bottomRight,
              //             ),
              //           ),
              //           child: Row(
              //             mainAxisAlignment: MainAxisAlignment.center,
              //             children: [
              //               const Icon(
              //                 Icons.bolt,
              //                 color: Colors.white,
              //                 size: 35,
              //               ),
              //               const SizedBox(
              //                 width: 10,
              //               ),
              //               Text(
              //                 trendingSectionText,
              //                 style: GoogleFonts.dmSerifText(
              //                   color: Colors.white,
              //                   fontSize: 20,
              //                   fontWeight: FontWeight.bold,
              //                 ),
              //                 textAlign: TextAlign.center,
              //               ),
              //             ],
              //           ),
              //         ),
              //       ),
              //     ),
              //   ),
              // ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const TrendingTopicScreen()),
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          spreadRadius: 2,
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      trendingSectionText,
                      style: GoogleFonts.poppins(
                        color: Colors.black87,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 25,),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12.0,
                      mainAxisSpacing: 12.0,
                      childAspectRatio: 1.5,
                    ),
                    itemCount: topics.length,
                    itemBuilder: (context, index) {
                      final topic = topics[index];
                      return Card(
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side:
                              BorderSide(width: 1, color: Colors.grey.shade400),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _isLoading
                              ? null
                              : () async {
                                  setState(() => _isLoading = true);
                                  try {
                                    bool allowed =
                                        await _checkDailyTopicLimit(uid);
                                    if (!allowed) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Limit Reached: You can only start 3 gossip topics per day.'),
                                          backgroundColor: Colors.red,
                                        ));
                                      }
                                      setState(() => _isLoading = false);
                                      return;
                                    }

                                    await FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(uid)
                                        .set({
                                      'currentTopic': topic,
                                      'requests': [],
                                      'accepted': [],
                                    }, SetOptions(merge: true));

                                    if (mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              MatchMaking(topic: topic),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Error: ${e.toString()}')));
                                    }
                                  } finally {
                                    if (mounted) {
                                      setState(() => _isLoading = false);
                                    }
                                  }
                                },
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white),
                            child: Center(
                              child: Text(
                                topic,
                                style: GoogleFonts.dmSerifText(
                                  color: Colors.black,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
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
