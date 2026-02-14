import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ReviewProvider extends ChangeNotifier {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  final TextEditingController reviewController = TextEditingController();

  bool _isLoading = false;

  bool get isLoading => _isLoading;
  TextEditingController get controller => reviewController;

  Future<void> submitReview(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || reviewController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review cannot be empty')),
      );
      return;
    }
    _isLoading = true;
    notifyListeners();

    try {
      await _fireStore.collection('reviews').add({
        'uid': user.uid,
        'email': user.email ?? '',
        'message': reviewController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully')),
      );
      reviewController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Review to submit report: $e')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
