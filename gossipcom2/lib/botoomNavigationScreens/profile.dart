import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For Clipboard
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/auth/auth_service.dart';
import 'package:gossipcom/components/profile_option_tile.dart';
import 'package:gossipcom/profile/edit_topics.dart';
import 'package:gossipcom/profile/edit_username/edit_username.dart';
import 'package:gossipcom/profile/report/report_an_issue.dart';
import 'package:gossipcom/profile/reported_by_user.dart';
import 'package:gossipcom/profile/userpost/your_post.dart';
import '../components/profile_vibe_container.dart';
import '../profile/bio/edit_bio.dart';
import '../profile/review/review.dart';
import 'package:gossipcom/profile/edit_avatar.dart';
import 'dart:developer';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  AuthService authService = AuthService();

  String? userName;
  String? userFirstName;
  String? userBio;
  String? avatarUrl;
  String vibePoints = "";
  List<String> selectedVibes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (doc.exists) {
          setState(() {
            userName = doc['userName'];
            userFirstName = doc['firstName'];
            selectedVibes = List<String>.from(doc['selectedVibes'] ?? []);
            vibePoints = doc['vibePoints'] ?? "";

            if (doc.data()!.containsKey('avatar')) {
              avatarUrl = doc['avatar'];
            } else {
              avatarUrl = null;
            }

            userBio = doc['bio'] ?? '';

            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
        }
      } catch (e) {
        log("Error fetching user data: $e");
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Static Content - Top part
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Header Image with Avatar at bottom center
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.bottomCenter,
                  children: [
                    Image.asset(
                      "profile_assets/header.png",
                      width: double.infinity,
                      fit: BoxFit.cover,
                      height: screenHeight * 0.18,
                    ),
                    Positioned(
                      top: screenHeight * 0.1,
                      left: 10,
                      right: 10,
                      child: Row(
                        children: [
                          Expanded(
                            child: Center(
                              child: Text(
                                '@ ${userName ?? ""}',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Avatar Positioned Widget (Keep Phase 2 Fix)
                    Positioned(
                      bottom: -40,
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const EditAvatar()),
                          ).then((value) {
                            if (value == true) {
                              fetchUserData();
                            }
                          });
                        },
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 3,
                            ),
                            color: Colors.grey[200],
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(40),
                                child: _buildAvatarImage(), // Reverted to no args
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.edit,
                                    size: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                // Extra space for the avatar overflow
                const SizedBox(height: 45),

                // User Info Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Expanded(
                            flex: 1,
                            child: SizedBox(), // Left spacing
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: Text(
                                userFirstName ?? 'No Name',
                                style: GoogleFonts.abhayaLibre(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                          const EditUsername()))
                                      .then((_) => fetchUserData());
                                },
                                child: const Text("Edit",
                                    style: TextStyle(color: Colors.grey)),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0x33736F6F),
                        ),
                        child: Text(
                          "$vibePoints Vibe Point 🔥",
                          style: GoogleFonts.abhayaLibre(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF828282),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bio Section
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 16),
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const Bio()),
                      ).then((value) {
                        if (value == true) {
                          fetchUserData();
                        }
                      });
                    },
                    child: Text(
                      (userBio != null && userBio!.isNotEmpty)
                          ? userBio!
                          : 'Tell us about yourself',
                      style: GoogleFonts.abhayaLibre(
                        fontWeight: FontWeight.w400,
                        fontSize: 15,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),

                // Vibes Title
                Text(
                  "$userFirstName's Vibe",
                  style: GoogleFonts.abhayaLibre(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Vibes Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _buildVibesSection(),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // Scrollable Options Section
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    ProfileOptionTile(
                        text: "Your Posts",
                        onTap: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                  const UserPosts()));
                        }),
                    ProfileOptionTile(
                      text: "Edit Topics You Like",
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const EditTopic()))
                            .then((_) => fetchUserData());
                      },
                    ),
                    ProfileOptionTile(
                      text: "Report an issue",
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const ReportAnIssue()));
                      },
                    ),
                    ProfileOptionTile(
                        text: "Invite a friend",
                        onTap: () async {
                          // Keep Phase 2 Fix
                          await Clipboard.setData(const ClipboardData(
                              text: "Join me on Gossip! https://gossipcom.com"));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    "Invite link copied to clipboard!"),
                                duration: Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }),
                    ProfileOptionTile(
                      text: "Striked by user",
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                const ReportedByUser()));
                      },
                    ),
                    ProfileOptionTile(
                      text: "Write a Review about us",
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const Review()));
                      },
                    ),
                    ProfileOptionTile(
                      text: "Log Out",
                      onTap: () {
                        authService.signOut(context);
                      },
                    ),
                    SizedBox(height: screenHeight * 0.03),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Original Vibe Section logic
  Widget _buildVibesSection() {
    if (selectedVibes.isEmpty) {
      return Container(
        height: 50,
        alignment: Alignment.center,
        child: const Text(
          "No vibes selected",
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    final itemsPerRow = 3;
    final rows = (selectedVibes.length / itemsPerRow).ceil();
    final needsScroll = rows > 2;

    if (needsScroll) {
      return SizedBox(
        height: 120,
        child: GridView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 4.8,
          ),
          itemCount: selectedVibes.length,
          itemBuilder: (context, index) {
            return ProfileVibeContainer(
              text: selectedVibes[index],
            );
          },
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
    );
  }

  // Reverted Avatar Image logic (uses class variable avatarUrl)
  Widget _buildAvatarImage() {
    if (avatarUrl == null || avatarUrl!.isEmpty) {
      return Container(
        color: Colors.grey[300],
        child: const Icon(
          Icons.person,
          size: 40,
          color: Colors.grey,
        ),
      );
    }

    return Image.network(
      avatarUrl!,
      fit: BoxFit.cover,
      width: 80,
      height: 80,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                loadingProgress.expectedTotalBytes!
                : null,
            color: Colors.blue,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return Container(
          color: Colors.red[100],
          child: const Center(
            child: Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red,
            ),
          ),
        );
      },
    );
  }
}