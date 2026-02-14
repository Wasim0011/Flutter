import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/auth/login.dart';
import 'package:gossipcom/auth/register/verificationmail.dart';
import '../auth_service.dart';
import '../components/my_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignUp extends StatefulWidget {
  final String userName;
  final List<String> selectedTopics;
  final List<String> selectedVibes;
  final String avatar;
  const SignUp({
    super.key,
    required this.userName,
    required this.selectedTopics,
    required this.selectedVibes,
    required this.avatar,
  });
  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  AuthService authService = AuthService();
  TextEditingController email = TextEditingController();
  TextEditingController password = TextEditingController();
  TextEditingController confirmPassword = TextEditingController();
  TextEditingController firstName = TextEditingController();
  TextEditingController lastName = TextEditingController();

  bool _isLoading = false;
  bool _isGoogleLoading = false;

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains("email-already-in-use")) {
      return "This email is already in use. Try logging in.";
    } else if (error.contains("invalid-email")) {
      return "The email address is invalid.";
    } else if (error.contains("weak-password")) {
      return "Your password is too weak. Try a stronger one.";
    } else if (error.contains("network-request-failed")) {
      return "Network error. Please check your connection.";
    } else if (error.contains("too-many-requests")) {
      return "Too many attempts. Please try again later.";
    } else {
      return "An unexpected error occurred. Please try again.";
    }
  }

  Future<void> register() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    String name = "${firstName.text.trim()} ${lastName.text.trim()}";
    String emailText = email.text.trim();
    String passwordText = password.text.trim();
    String confirmPasswordText = confirmPassword.text.trim();

    // Input validation
    if (emailText.isEmpty ||
        passwordText.isEmpty ||
        confirmPasswordText.isEmpty ||
        firstName.text.trim().isEmpty ||
        lastName.text.trim().isEmpty) {
      _showSnackBar(context, "All fields are required.", Colors.red);
      setState(() => _isLoading = false);
      return;
    }

    if (!_isValidEmail(emailText)) {
      _showSnackBar(
          context, "Please enter a valid email address.", Colors.orange);
      setState(() => _isLoading = false);
      return;
    }

    if (passwordText.length < 6) {
      _showSnackBar(context, "Password must be at least 6 characters long.",
          Colors.orange);
      setState(() => _isLoading = false);
      return;
    }

    if (passwordText != confirmPasswordText) {
      _showSnackBar(context, "Passwords do not match.", Colors.red);
      setState(() => _isLoading = false);
      return;
    }

    try {
      print("DEBUG: Starting signup process...");
      print("DEBUG: Email: $emailText");
      print("DEBUG: Username: ${widget.userName}");
      print("DEBUG: Name: $name");
      print("DEBUG: Topics: ${widget.selectedTopics}");
      print("DEBUG: Vibes: ${widget.selectedVibes}");
      print("DEBUG: Avatar: ${widget.avatar}");

      await authService.signUpWithEmailPassword(
          context,
          emailText,
          passwordText,
          widget.userName,
          widget.selectedTopics,
          widget.selectedVibes,
          widget.avatar,
          firstName.text,
          lastName.text);

      print("DEBUG: Signup completed successfully");
      print("DEBUG: User has been signed out for security");
      print("DEBUG: Verification email sent");

      if (mounted) {
        setState(() => _isLoading = false);
        // _showSnackBar(context, "Account Created Successfully please check your email for verification", Colors.green);
        _showSnackBar(context, "Account created successfully!", Colors.green);
      }

      // await Future.delayed(const Duration(milliseconds: 1000));

      print("🔄 DEBUG: About to navigate to verification screen");

      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate to verification screen
      if (mounted) {
        Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => Verificationmail(
                      email: emailText,
                      password: passwordText,
                    )));
        print("🎯 DEBUG: Navigation completed, result: ");
      } else {
        print("❌ DEBUG: Widget not mounted, cannot navigate");
      }
    } catch (e) {
      print("DEBUG: Error occurred during signup: $e");
      print("DEBUG: Error type: ${e.runtimeType}");
      print("DEBUG: Full error: ${e.toString()}");

      // Handle specific Firebase Auth errors
      if (mounted) {
        if (e is FirebaseAuthException) {
          print("DEBUG: Firebase Auth Exception - Code: ${e.code}");
          String errorMessage = _getFriendlyErrorMessage(e.code);
          _showSnackBar(context, errorMessage, Colors.red);
        } else {
          _showSnackBar(
              context, _getFriendlyErrorMessage(e.toString()), Colors.red);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;

    setState(() => _isGoogleLoading = true);
    try {
      await authService.signupwithGoogle(context, widget.userName,
          widget.selectedTopics, widget.selectedVibes, widget.avatar);
    } catch (e) {
      print("DEBUG: Google sign in error: $e");
      _showSnackBar(
          context, "Google sign in failed: ${e.toString()}", Colors.red);
    } finally {
      if (mounted) {
        setState(() => _isGoogleLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 100),
            Center(
                child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset("reg_terms/gossip.png", fit: BoxFit.fill),
            )),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    flex: 1,
                    child: MyTextField(
                      hintText: "First Name",
                      obscureText: false,
                      controller: firstName,
                    ),
                  ),
                  const SizedBox(width: 10), // Add spacing between fields
                  Expanded(
                    flex: 1,
                    child: MyTextField(
                      hintText: "Last Name",
                      obscureText: false,
                      controller: lastName,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: MyTextField(
                hintText: "Email",
                obscureText: false,
                controller: email,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: MyTextField(
                hintText: "Password",
                obscureText: true,
                controller: password,
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: MyTextField(
                hintText: "Confirm Password",
                obscureText: true,
                controller: confirmPassword,
              ),
            ),
            const SizedBox(height: 40),

            // Sign Up Button with Animation
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isLoading ? null : register,
                borderRadius: BorderRadius.circular(30),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Ink(
                  height: 52,
                  width: 315,
                  decoration: BoxDecoration(
                    color: _isLoading ? Colors.grey : const Color(0xFF1976D2),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Center(
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            "Sign Up",
                            style: GoogleFonts.abhayaLibre(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: const Color(0xFFFFFFFF),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // Google Sign In Button with Animation
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isGoogleLoading ? null : _signInWithGoogle,
                borderRadius: BorderRadius.circular(30),
                splashColor: Colors.grey.withOpacity(0.2),
                highlightColor: Colors.grey.withOpacity(0.1),
                child: Ink(
                  width: 315,
                  height: 52,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(30),
                    color: _isGoogleLoading ? Colors.grey[100] : Colors.white,
                  ),
                  child: Center(
                    child: _isGoogleLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.blue,
                              strokeWidth: 2,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset("assets/googleimage.png"),
                              const SizedBox(width: 10),
                              Text(
                                "Continue with Google",
                                style: GoogleFonts.poppins(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF242222),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 90),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "Already a member? ",
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Color(0xFFA0A0A0) // Dark theme equivalent
                        : Color(0xFF606060), // Original light theme color
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const Login()),
                          );
                        },
                  child: Text(
                    "LOG IN",
                    style: TextStyle(
                      color: _isLoading
                          ? Colors.grey
                          : (Theme.of(context).brightness == Brightness.dark
                              ? Color(0xFF7B7BFF) // Dark theme equivalent
                              : Color(
                                  0xFF5252C7)), // Original light theme color
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
