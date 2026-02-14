import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthController extends GetxController {
  // Form controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // State tracking
  final isLoading = false.obs;
  final isPasswordVisible = false.obs; // ✅ Add this line

  // Firebase user
  UserCredential? userCredential;

  /// Sign up with Email and Password
  Future<void> signupUser() async {
    try {
      isLoading.value = true;
      userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Get.snackbar('Success', 'Account created successfully');
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Something went wrong');
    } finally {
      isLoading.value = false;
    }
  }

  /// Log in with Email and Password
  Future<void> loginUser() async {
    try {
      isLoading.value = true;
      userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      Get.snackbar('Success', 'Logged in successfully');
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error', e.message ?? 'Something went wrong');
    } finally {
      isLoading.value = false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    Get.snackbar('Signed out', 'You have been signed out');
  }

  @override
  void onClose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
