import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'wrapper.dart';

class Verify extends StatefulWidget {
  const Verify({super.key});

  @override
  State<Verify> createState() => _VerifyState();
}

class _VerifyState extends State<Verify> {
  @override
  void initState() {
    super.initState();
    senderVerifyLink();
  }

  Future<void> senderVerifyLink() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;
      await user.sendEmailVerification();
      Get.snackbar(
        'Link sent',
        'A link has been sent to your email',
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to send verification email: $e',
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> reload() async {
    try {
      await FirebaseAuth.instance.currentUser!.reload();
      // Navigate back to the Wrapper screen after reloading the user state
      Get.offAll(() => const Wrapper());
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to reload user: $e',
        margin: const EdgeInsets.all(30),
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Verification"),
      ),
      body: const Padding(
        padding: EdgeInsets.all(28.0),
        child: Center(
          child: Text(
            'Open your email and click on the link provided to verify your email, then reload this page.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: reload,
        child: const Icon(Icons.restart_alt_rounded),
      ),
    );
  }
}
