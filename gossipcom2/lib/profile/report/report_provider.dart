import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportProvider extends ChangeNotifier {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  final TextEditingController reportController = TextEditingController();
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  TextEditingController get controller => reportController;

  Future<void> submitReport(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || reportController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report cannot be empty')),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _fireStore.collection('reports').add({
        'uid': user.uid,
        'email': user.email ?? '',
        'message': reportController.text.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully')),
      );
      reportController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit report: $e')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
