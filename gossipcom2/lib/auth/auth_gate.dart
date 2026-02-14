import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:gossipcom/auth/register/username.dart';
import 'package:gossipcom/auth/register/verificationmail.dart';
import 'package:gossipcom/home_page.dart';
import 'package:gossipcom/main.dart';
import 'ban_screen.dart';
import 'login.dart';
import 'dart:developer';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  Future<void> _signOutUser() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (e) {
      log('Error signing out: $e');
    }
  }

  bool _isGoogleUser(User user) {
    return user.providerData.any((info) => info.providerId == 'google.com');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else if (snapshot.hasData) {
              // User is authenticated, now check ban status
              final user = snapshot.data;
              if (user == null) {
                return const Login();
              }

              if (!user.emailVerified) {
                log('🔍 User email not verified, checking pending users...');
                // Check if user exists in pending_users collection
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('pending_users')
                      .doc(user.uid)
                      .snapshots(),
                  builder: (context, pendingSnapshot) {
                    if (pendingSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (pendingSnapshot.hasData &&
                        pendingSnapshot.data!.exists) {
                      // User exists in pending_users, redirect to verification
                      final pendingData =
                      pendingSnapshot.data!.data() as Map<String, dynamic>;
                      log(
                          '📧 Found user in pending_users, redirecting to verification');

                      return Verificationmail(
                        email: pendingData['email'] ?? user.email ?? '',
                        password:
                        '', // We can't retrieve the password, user will need to re-enter if needed
                      );
                    } else {
                      // User not in pending_users and email not verified
                      // This shouldn't happen in normal flow, sign out and redirect to login
                      log(
                          '❌ User not found in pending_users and email not verified');
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        _signOutUser();
                      });
                      return const Login();
                    }
                  },
                );
              }
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .snapshots(),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (userSnapshot.hasError) {
                    // Handle error by signing out and showing login
                    log('Error loading user data: ${userSnapshot.error}');
                    _signOutUser();
                    return const Login();
                  }

                  if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
                    log('⚠️ Verified user not found in users collection ok');

                    if (_isGoogleUser(user)) {
                      log('🔍 Google user needs to complete registration');
                      return Username();
                    }

                    // Check if they're still in pending_users and need migration
                    return StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('pending_users')
                            .doc(user.uid)
                            .snapshots(),
                        builder: (context, pendingSnapshot) {
                          if (pendingSnapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          }

                          if (pendingSnapshot.hasData &&
                              pendingSnapshot.data!.exists) {
                            // User is verified but still in pending - need to complete migration
                            log(
                                '🔄 Completing user migration from pending to users...');

                            // Trigger the migration process
                            // _completeMigration(user, pendingSnapshot.data!.data() as Map<String, dynamic>);

                            return const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  CircularProgressIndicator(),
                                  SizedBox(height: 16),
                                  Text('Completing setup...'),
                                ],
                              ),
                            );
                            // User document doesn't exist - sign out and redirect to login
                            // This happens when database is deleted or user data is missing
                          } else {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              _signOutUser();
                            });
                            return const Login();
                          }
                        });
                  }

                  final userData =
                  userSnapshot.data!.data() as Map<String, dynamic>;

                  // Check both 'banned' and 'ban' fields for compatibility
                  final bool isBanned =
                      userData['banned'] ?? userData['ban'] ?? false;

                  if (isBanned) {
                    return const BanScreen();
                  } else {
                    // Initialize FCM only when user is properly authenticated and not banned
                    try {
                      initFCM();
                      initFCMinAppNotification();
                      // _requestNotificationPermission();
                    } catch (e) {
                      log('Error initializing FCM: $e');
                    }
                    return const HomePage();
                  }
                },
              );
            } else {
              // User is not authenticated
              return const Login();
            }
          }),
    );
  }
}