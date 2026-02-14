import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gossipcom/auth/register/username.dart';

class EditUserNameProvider extends ChangeNotifier {
  final FirebaseFirestore _fireStore = FirebaseFirestore.instance;
  final TextEditingController usernameController = TextEditingController();
  final UsernameGenderValidator _genderValidator = UsernameGenderValidator();

  bool _isLoading = false;

  bool get isLoading => _isLoading;
  TextEditingController get controller => usernameController;

  Future<void> submitReview(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || usernameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('UserName cannot be empty'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final detected = _localValidator(usernameController.text);
    if (detected != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(detected),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      await _fireStore.collection('users').doc(user.uid).update({
        'userName': usernameController.text.trim(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username updated successfully')),
      );
      Navigator.pop(context);

      usernameController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update username: $e')),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String? _localValidator(String? v) {
    final s = v ?? '';
    if (s.trim().isEmpty) return 'Enter a username';
    if (s.trim().length < 3) return 'Username too short';
    final detected = _genderValidator.detectGender(s);
    if (detected == GenderCheckResult.male) {
      return 'Usernames that indicate male gender are disallowed';
    }
    if (detected == GenderCheckResult.female) {
      return 'Usernames that indicate female gender are disallowed';
    }
    return null;
  }
}
