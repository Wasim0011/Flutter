import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportUserProvider with ChangeNotifier {
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  void setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  final Map<String, bool> _switchStates = {
    "Abusive Talk": false,
    "Disrespectful": false,
    "Off-Topic": false,
    "HateFul Speech": false,
  };

  final TextEditingController reportTextController = TextEditingController();

  Map<String, bool> get switchStates => _switchStates;

  List<String> get selectedTags =>
      _switchStates.entries.where((e) => e.value).map((e) => e.key).toList();

  void toggleSwitch(String tag, bool value) {
    _switchStates[tag] = value;
    notifyListeners();
  }

  Future<void> submitReport(String userId, BuildContext context) async {
    final tags = selectedTags;
    final reason = reportTextController.text.trim();

    if (tags.isEmpty && reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select tags or write a reason.")),
      );
      return;
    }

    setLoading(true);

    // Get current user's ID (reporter)
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to report a user.")),
      );
      setLoading(false);
      return;
    }

    final reporterId = currentUser.uid;

    final newReport = {
      'reporterId': reporterId, // Store the ID of the user making the report
      'tags': tags,
      'reason': reason,
      'timestamp': Timestamp.now(),
    };

    try {
      final userDoc =
          FirebaseFirestore.instance.collection('users').doc(userId);
      final snapshot = await userDoc.get();

      if (!snapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found.")),
        );
        setLoading(false);
        return;
      }

      if (snapshot.data()?['reports'] == null) {
        await userDoc.set({
          'reports': [newReport]
        }, SetOptions(merge: true));
      } else {
        await userDoc.update({
          'reports': FieldValue.arrayUnion([newReport])
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report submitted successfully.")),
      );

      _switchStates.updateAll((key, value) => false);
      reportTextController.clear();
      notifyListeners();
    } catch (e) {
      print("Error submitting report: ${e.toString()}");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit report.")),
      );
    } finally {
      setLoading(false);
    }
  }
}
