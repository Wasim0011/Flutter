import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:gossipcom/auth/login.dart';
import 'package:gossipcom/auth/register/username.dart';
import 'package:gossipcom/home_page.dart';
import 'dart:developer';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<UserCredential> signInWithEmailPassword(
      String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      // SECURITY CHECK: Only allow verified users to sign in
      if (!userCredential.user!.emailVerified) {
        debugPrint("Email verification checking");
        await _auth.signOut(); // Sign them out immediately
        throw Exception("Please verify your email before signing in");
      }
      debugPrint("Email verification checked ${userCredential.user!.uid}");

      // DocumentSnapshot userDoc;
      DocumentSnapshot<Map<String, dynamic>>? userDoc;

      try {
        debugPrint(" Fetching Firestore user doc...");
        userDoc = await _fireStore
            .collection('users')
            .doc(userCredential.user!.uid)
            .get();
        debugPrint(" Got userDoc. Exists: ${userDoc.exists}");
      } catch (e) {
        debugPrint(" Error fetching Firestore user doc: $e");
        await _auth.signOut();
        throw Exception("Error fetching user data.");
      }

      debugPrint(
          "Checking if user doc exists for UID: ${userCredential.user!.uid}");

      if (!userDoc.exists) {
        // User might be in pending verification - sign them out
        debugPrint("User doc found: ${userDoc.data()}");
        debugPrint("account not verified");
        await _auth.signOut();
        throw Exception("Account not found. Please complete registration.");
      }

      // Update last login
      await _fireStore
          .collection('users')
          .doc(userCredential.user!.uid)
          .update({
        'lastLoginAt': FieldValue.serverTimestamp(),
      });

      return userCredential;
    } on FirebaseAuthException catch (e) {
      log("FirebaseAuth Error: ${e.code} - ${e.message}");
      throw Exception("Error: ${e.message}");
    }
  }

  Future<UserCredential> signUpWithEmailPassword(
      BuildContext context,
      String email,
      String password,
      String userName,
      List<String> selectedTopics,
      List<String> selectedVibes,
      String avatar,
      String firstName,
      String lastName) async {
    try {
      // Create the user account
      UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(email: email, password: password);
      log("Started to saving in pending users");

      // Save user data to PENDING collection (not main users collection)
      try {
        debugPrint(" Saving user data to pending_users collection...");
        await _fireStore
            .collection('pending_users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'email': email,
          'userName': userName,
          'selectedTopics': selectedTopics,
          'selectedVibes': selectedVibes,
          'agreement': true,
          'vibePoints': '1000',
          'avatar': avatar,
          'firstName': firstName,
          'lastName': lastName,
          'emailVerified': false,
          'createdAt': FieldValue.serverTimestamp(),
          'verificationEmailSent': false,
        });
        debugPrint(" User data saved to pending_users collection");
        debugPrint("())()()()saved in pending users");
      } on FirebaseException catch (e) {
        log("Firestore error: ${e.code} - ${e.message}");
        await userCredential.user!.delete();
      } catch (e) {
        log("Error saving to Firestore: $e");
        await userCredential.user!.delete();
        throw Exception("Failed to save user data: $e");
      }
      // Send verification email
      try {
        log("trying to send email");
        await userCredential.user!.sendEmailVerification();
        log("email send");
        // Immediately sign out the user so they can't bypass verification
        await _fireStore
            .collection('pending_users')
            .doc(userCredential.user!.uid)
            .update({
          'verificationEmailSent': true,
          'verificationEmailSentAt': FieldValue.serverTimestamp(),
        });
      } catch (e) {
        log(" Error sending verification email: $e");
      }
      // await _auth.signOut();
      log(" Signing out user for security...");
      await _auth.signOut();
      log(" User signed out successfully");

      return userCredential;
    } on FirebaseAuthException catch (e) {
      log("FirebaseAuth Error: ${e.code} - ${e.message}");
      throw Exception("Error: ${e.message}");
    } catch (e) {
      log("❌ Unexpected error during registration: $e");
      throw Exception("Registration failed: $e");
    }
  }

  // This method moves user from pending to verified users collection
  Future<bool> completeEmailVerification() async {
    try {
      User? user = _auth.currentUser;
      if (user == null) return false;

      // Reload user to get latest email verification status
      await user.reload();
      user = _auth.currentUser;

      if (user?.emailVerified == true) {
        // Get user data from pending collection
        DocumentSnapshot pendingDoc =
            await _fireStore.collection('pending_users').doc(user!.uid).get();

        if (pendingDoc.exists) {
          Map<String, dynamic> userData =
              pendingDoc.data() as Map<String, dynamic>;

          // Move data to main users collection
          await _fireStore.collection('users').doc(user.uid).set({
            ...userData,
            'emailVerified': true,
            'verifiedAt': FieldValue.serverTimestamp(),
          });

          // Remove from pending collection
          await _fireStore.collection('pending_users').doc(user.uid).delete();

          return true;
        }
      }
      return false;
    } catch (e) {
      log("Error completing email verification: $e");
      return false;
    }
  }

  Future<void> signOut(BuildContext context) async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      log("SignOut Error: $e");
    }
  }

  Future<void> signinwithgoogle(BuildContext context) async {
    try {
      final GoogleSignInAccount? signinGoogle = await GoogleSignIn().signIn();

      if (signinGoogle == null) {
        return;
      }

      final GoogleSignInAuthentication googleSignInAuthentication =
      await signinGoogle.authentication;

      final AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );

      final UserCredential userCredential =
      await _auth.signInWithCredential(authCredential);

      if (userCredential.user == null) {
        throw Exception('Failed to authenticate user');
      }

      // Check if user document already exists
      DocumentSnapshot userDoc = await _fireStore
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (userDoc.exists) {
        // User exists, proceed to HomePage
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const HomePage()));
      } else {
        // User does not exist, redirect to Registration
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "User with this email is not registered, Redirecting to Registration")));
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => Username()));
      }
    } catch (e) {
      debugPrint('Google Sign-In error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Google Sign-In failed. Please try again.')));
    }
  }

  Future<void> signupwithGoogle(
      BuildContext context,
      String userName,
      List<String> selectedTopics,
      List<String> selectedVibes,
      String avatar) async {
    User? localUser;

    try {
      final GoogleSignInAccount? signupGoogle = await GoogleSignIn().signIn();
      if (signupGoogle == null) {
        return;
      }
      final GoogleSignInAuthentication googleSignInAuthentication =
      await signupGoogle.authentication;
      final AuthCredential authCredential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken,
      );
      UserCredential userCredential =
      await _auth.signInWithCredential(authCredential);
      localUser = userCredential.user;

      if (localUser == null) {
        throw Exception('Failed to authenticate user');
      }

      // Google accounts are pre-verified, so save directly to main users collection
      await _fireStore.collection('users').doc(userCredential.user!.uid).set({
        'uid': userCredential.user!.uid,
        'email': localUser.email,
        'userName': userName,
        'firstName': localUser.displayName,
        'selectedTopics': selectedTopics,
        'selectedVibes': selectedVibes,
        'agreement': true,
        'vibePoints': '1000',
        'avatar': avatar,
        'emailVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'signupMethod': 'google',
        'signupwithgoogle': true,
      });
      // Navigate to home page after successful Google signup
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
              (Route<dynamic> route) => false);
    } catch (e) {
      log(e.toString());

      // final user = this.user;
      if (localUser != null) {
        try {
          await localUser.delete();
          log(
              'User deleted from Firebase Authentication due to signup failure');
        } catch (deleteError) {
          log(
              'Failed to delete user from Authentication: ${deleteError.toString()}');
        }
      }

      rethrow;
    }
  }

  Future<void> verificationEmail() async {
    try {
      User? user = _auth.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        log("Verification email sent to ${user.email}");
      }
    } catch (e) {
      log("Error sending verification email: $e");
      rethrow;
    }
  }

  // Method to check if user has pending verification
  Future<bool> hasPendingVerification(String email) async {
    try {
      QuerySnapshot query = await _fireStore
          .collection('pending_users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      return query.docs.isNotEmpty;
    } catch (e) {
      log("Error checking pending verification: $e");
      return false;
    }
  }

  // Method to resend verification email for pending users
  Future<void> resendVerificationForPendingUser(
      String email, String password) async {
    try {
      // Temporarily sign in to send verification email
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
          email: email, password: password);

      if (!userCredential.user!.emailVerified) {
        await userCredential.user!.sendEmailVerification();
        log("Resent verification email to $email");
      }

      // Sign out immediately
      await _auth.signOut();
    } catch (e) {
      log("Error resending verification email: $e");
      rethrow;
    }
  }

  // Clean up expired pending users (call this periodically)
  Future<void> cleanupExpiredPendingUsers() async {
    try {
      // Remove pending users older than 24 hours
      DateTime yesterday = DateTime.now().subtract(const Duration(hours: 24));

      QuerySnapshot expiredUsers = await _fireStore
          .collection('pending_users')
          .where('createdAt', isLessThan: Timestamp.fromDate(yesterday))
          .get();

      for (DocumentSnapshot doc in expiredUsers.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      log("Error cleaning up expired users: $e");
    }
  }

  Future<void> saveUserData(
    String uid,
    String email,
    String userName,
    List<String> selectedTopics,
    List<String> selectedVibes,
    String avatar,
    String firstName,
    String lastName,
  ) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'userName': userName,
        'selectedTopics': selectedTopics,
        'selectedVibes': selectedVibes,
        'agreement': true,
        'vibePoints': '1000',
        'avatar': avatar,
        'firstName': firstName,
        'lastName': lastName,
        'emailVerified': false,
        'createdAt': FieldValue.serverTimestamp(),
        'verificationEmailSent': true,
      });
    } catch (e) {
      log("❌ Error saving user data: $e");
      throw Exception("Could not save user data.");
    }
  }
}
