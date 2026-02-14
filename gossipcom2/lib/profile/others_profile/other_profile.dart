import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/components/profile_option_tile.dart';
import 'package:gossipcom/profile/others_profile/review_user.dart';
import 'package:gossipcom/profile/report_user/report_user.dart';
import '../../components/profile_vibe_container.dart';

class OtherProfile extends StatefulWidget {
  final String otherUserId;
  final String? otherUserName;
  const OtherProfile(
      {super.key, required this.otherUserId, required this.otherUserName});

  @override
  State<OtherProfile> createState() => _OtherProfileState();
}

class _OtherProfileState extends State<OtherProfile> {
  List<String> selectedVibes = [];
  String vibePoints = "";
  String? avatarUrl = "";

  Future<void> fetchUserVibes(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data();
        setState(() {
          selectedVibes = List<String>.from(data?['selectedVibes'] ?? []);
          vibePoints = data?['vibePoints']?.toString() ?? "0";
          avatarUrl = data?['avatar'] ?? "";
        });
      } else {
        print("No such user with UID: $uid");
      }
    } catch (e) {
      print("Error fetching vibes: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserVibes(widget.otherUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none, // allow overflow
              children: [
                Image.asset(
                  "profile_assets/header.png",
                  width: double.infinity,
                  fit: BoxFit.fill,
                  height: 220,
                ),
                Positioned(
                  top: 40,
                  left: 16,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: CircleAvatar(
                        radius: 36,
                        backgroundImage: avatarUrl != null &&
                                avatarUrl!.isNotEmpty
                            ? NetworkImage(avatarUrl!)
                            : const AssetImage('profile_assets/default_avatar.png')
                                as ImageProvider,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 50), // Give space for avatar

            // Username
            Text(
              widget.otherUserName ?? "User",
              style: GoogleFonts.abhayaLibre(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 8),

            // Vibe Points
            Text(
              "Vibe Points: $vibePoints",
              style: GoogleFonts.abhayaLibre(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),

            const SizedBox(height: 20),

            // Vibes Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  Text(
                    "User Vibe",
                    style: GoogleFonts.abhayaLibre(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const itemHeight = 40.0;
                      final rows = (selectedVibes.length / 3).ceil();
                      return SizedBox(
                        height: rows * (itemHeight + 10),
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: EdgeInsets.zero,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.8,
                          ),
                          itemCount: selectedVibes.length,
                          itemBuilder: (context, index) {
                            return ProfileVibeContainer(
                              text: selectedVibes[index],
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Report and Review Options
            ProfileOptionTile(
              text: "Report User",
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ReportUser(
                              userId: widget.otherUserId,
                              userName: widget.otherUserName!,
                            )));
              },
            ),

            ProfileOptionTile(
              text: "Review User",
              onTap: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ReviewUser(
                              userId: widget.otherUserId,
                              onTap: () {
                                Navigator.pop(context);
                              },
                            )));
              },
            ),
          ],
        ),
      ),
    );
  }
}
