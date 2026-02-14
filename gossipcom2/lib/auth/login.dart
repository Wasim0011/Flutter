import 'dart:ui';
import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/auth/components/gradient_text.dart';
import 'package:gossipcom/auth/components/my_textfield.dart';
import 'package:gossipcom/auth/register/username.dart';
import 'package:gossipcom/auth/auth_service.dart';
import 'package:gossipcom/home_page.dart';
import 'ban_screen.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
  bool isLoading = false;
  final AuthService authService = AuthService();
  late AnimationController _loginScaleController;
  late Animation<double> _loginScaleAnimation;
  late AnimationController _googleScaleController;
  late Animation<double> _googleScaleAnimation;

  @override
  void initState() {
    super.initState();
    _loginScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _loginScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _loginScaleController,
        curve: Curves.easeInOut,
      ),
    );
    _googleScaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _googleScaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(
        parent: _googleScaleController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _loginScaleController.dispose();
    _googleScaleController.dispose();
    super.dispose();
  }

  bool isValidEmail(String email) {
    return RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
        .hasMatch(email);
  }

  String _getFriendlyErrorMessage(String error) {
    if (error.contains("user-not-found")) {
      return "No user found for this email. Please register first.";
    } else if (error.contains("wrong-password")) {
      return "Incorrect password. Please try again.";
    } else if (error.contains("invalid-email")) {
      return "The email address is invalid.";
    } else {
      return "An unexpected error occurred. Please try again later.";
    }
  }

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

  // Forgot Password Implementation
  Future<void> _forgotPassword() async {
    String emailText = email.text.trim();

    if (emailText.isEmpty) {
      _showSnackBar(
          context, "Please enter your email address first.", Colors.orange);
      return;
    }

    if (!isValidEmail(emailText)) {
      _showSnackBar(
          context, "Please enter a valid email address.", Colors.orange);
      return;
    }

    // Show confirmation dialog
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text(
            'Reset Password',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          content: Text(
            'We will send a password reset link to:\n$emailText\n\nDo you want to continue?',
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5252C7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Send Reset Link',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() {
      isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: emailText);

      _showSnackBar(
          context,
          "Password reset email sent! Please check your inbox and spam folder.",
          Colors.green);

      // Show success dialog with additional instructions
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 24),
                SizedBox(width: 8),
                Text(
                  'Email Sent!',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'We\'ve sent a password reset link to:',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  emailText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your email and follow the instructions to reset your password.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                Text(
                  'Don\'t forget to check your spam folder if you don\'t see the email.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5252C7),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          );
        },
      );
    } catch (e) {
      String errorMessage = "Failed to send reset email. Please try again.";

      if (e.toString().contains("user-not-found")) {
        errorMessage = "No account found with this email address.";
      } else if (e.toString().contains("invalid-email")) {
        errorMessage = "Please enter a valid email address.";
      } else if (e.toString().contains("too-many-requests")) {
        errorMessage = "Too many attempts. Please try again later.";
      }

      _showSnackBar(context, errorMessage, Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> _checkBanStatusAndNavigate() async {
    if (!mounted) return;
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get();
      if (!mounted) return;

      if (userDoc.exists) {
        debugPrint("data exists");
        final userData = userDoc.data() as Map<String, dynamic>;
        final bool isBanned = userData['ban'] ?? false;

        if (isBanned) {
          // User is banned, show ban screen
          if (!mounted) return;
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (context) => const BanScreen()));
        } else {
          if (!mounted) return;
          // User is not banned, proceed to home page
          debugPrint("Not banned pass to homePage");
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => const HomePage()));
        }
      } else {
        if (!mounted) return;
        // User document doesn't exist, proceed to home page (fallback)
        debugPrint("Not  user exist in banned to homePage");
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (context) => const HomePage()));
      }
    } catch (e) {
      if (!mounted) return;
      // If there's an error checking ban status, proceed to home page
      debugPrint("Not banned pass to homePage with error $e");
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const HomePage()));
    }
  }

  Future<void> login() async {
    if (!mounted) return;
    setState(() {
      isLoading = true;
    });

    String emailText = email.text.trim();
    String passwordText = password.text.trim();

    if (emailText.isEmpty || passwordText.isEmpty) {
      if (!mounted) return;
      _showSnackBar(context, "Email and password cannot be empty.", Colors.red);
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (!isValidEmail(emailText)) {
      if (!mounted) return;
      _showSnackBar(
          context, "Please enter a valid email address.", Colors.orange);
      setState(() {
        isLoading = false;
      });
      return;
    }

    if (passwordText.length < 6) {
      if (!mounted) return;
      _showSnackBar(
          context, "Password must be at least 6 characters.", Colors.orange);
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      await authService.signInWithEmailPassword(emailText, passwordText);
      if (!mounted) return;
      debugPrint("checking for the banstatus");
      await _checkBanStatusAndNavigate();
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(
          context, _getFriendlyErrorMessage(e.toString()), const Color(0xFF5252C7));
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> signInWithGoogle() async {
    setState(() {
      isLoading = true;
    });
    try {
      await authService.signinwithgoogle(context);

      // Check if user is banned after successful Google sign-in
      if (FirebaseAuth.instance.currentUser != null) {
        await _checkBanStatusAndNavigate();
      }
    } catch (e) {
      _showSnackBar(context, "Failed to sign in with Google", Colors.red);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            // bottom: 0,
            child: SizedBox(
              height: 400,
              width: double.infinity,
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  maxHeight: double.infinity,
                  child: Image.asset(
                    "assets/loginTop.png",
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            top: 240,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 40, sigmaY: 90),
                child: AnimatedPadding(
                  duration: const Duration(milliseconds: 150),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Container(
                    color: Colors.transparent,
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 40,),
                          GradientText("Welcome To",
                            style: TextStyle(fontSize: 22.6),
                            gradient:LinearGradient(colors: [
                              Color(0xff0B3957),
                              Color(0xff287F9B)
                            ],stops: [0.0,1.0]),

                          ),
                          GradientText("GOSSIP",
                            style: TextStyle(fontSize: 52,fontWeight: FontWeight.w500),
                            gradient:LinearGradient(colors: [
                              Color(0xff0B3957),
                              Color(0xff287F9B)
                            ],stops: [0.3,0.7]),

                          ),

                          const SizedBox(height: 50),
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                            child: MyTextField(
                              hintText: "Email",
                              obscureText: false,
                              controller: email,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 20.0),
                            child: MyTextField(
                              hintText: "Password",
                              obscureText: true,
                              controller: password,
                            ),
                          ),
                          const SizedBox(height: 40),
                          InkWell(
                            onTap: isLoading ? null : _forgotPassword,
                            borderRadius: BorderRadius.circular(4),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                "FORGOT PASSWORD",
                                style: TextStyle(
                                  fontFamily: 'CircularStd',
                                  color: isLoading
                                      ? Colors.grey
                                      : (Theme.of(context).brightness == Brightness.dark
                                      ? Color(0xFF7B7BFF)  // Dark theme equivalent
                                      : Color(0xFF5252C7)), // Original light theme color
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          GestureDetector(
                            onTapDown: (_) => _loginScaleController.forward(),
                            onTapUp: (_) {
                              _loginScaleController.reverse();
                              if (!isLoading) login();
                            },
                            onTapCancel: () => _loginScaleController.reverse(),
                            child: ScaleTransition(
                              scale: _loginScaleAnimation,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.asset("assets/loginbutton.png"),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Google Sign-In Button with its own scale animation
                          GestureDetector(
                            onTapDown: (_) => _googleScaleController.forward(),
                            onTapUp: (_) {
                              _googleScaleController.reverse();
                              if (!isLoading) signInWithGoogle();
                            },
                            onTapCancel: () => _googleScaleController.reverse(),
                            child: ScaleTransition(
                              scale: _googleScaleAnimation,
                              child: Container(
                                width: 315,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: isLoading
                                      ? Colors.grey[300]
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Image.asset("assets/googleimage.png"),
                                    const SizedBox(width: 10),
                                    Text(
                                      "Continue with Google",
                                      style: GoogleFonts.poppins(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: isLoading
                                            ? Colors.grey
                                            : const Color(0xFF242222),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 70),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Don't have account? ",
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              InkWell(
                                onTap: isLoading
                                    ? null
                                    : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => Username(),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(4),
                                splashColor:
                                const Color(0xFF5252C7).withValues(alpha: 0.2),
                                child: Padding(
                                  padding: const EdgeInsets.all(4.0),
                                  child: Text(
                                    "SIGN UP",
                                    style: TextStyle(
                                      color: isLoading
                                          ? Colors.grey
                                          : (Theme.of(context).brightness == Brightness.dark
                                          ? Color(0xFF7B7BFF)  // Dark theme equivalent
                                          : Color(0xFF5252C7)), // Original light theme color
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (isLoading)
            const Opacity(
              opacity: 0.5,
              child: ModalBarrier(
                dismissible: false,
                color: Colors.black,
              ),
            ),
          if (isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.grey,
              ),
            ),
        ],
      ),
    );
  }
}