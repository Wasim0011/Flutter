import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gossipcom/auth/auth_service.dart';
import 'package:gossipcom/auth/register/loadingscreen.dart';

class Verificationmail extends StatefulWidget {
  final String? email;
  final String? password;

  const Verificationmail({super.key, this.email, this.password});

  @override
  State<Verificationmail> createState() => _VerificationmailState();
}

class _VerificationmailState extends State<Verificationmail> {
  final _auth = AuthService();
  Timer? timer;
  bool _isResendingEmail = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
    _startEmailVerificationCheck();
  }

  void _startEmailVerificationCheck() {
    timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      await _checkEmailVerification();
    });
  }

  Future<void> _checkEmailVerification() async {
    try {
      User? currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser == null) {
        if (widget.email != null && widget.password != null) {
          try {
            await FirebaseAuth.instance.signInWithEmailAndPassword(
              email: widget.email!,
              password: widget.password!,
            );
            currentUser = FirebaseAuth.instance.currentUser;
            if (currentUser?.emailVerified == true) {
              if (mounted) {
                timer?.cancel();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const Loadingscreen()),
                );
              }
            }
          } catch (e) {
            print("Sign in failed: $e");
            return;
          }
        } else {
          return;
        }
      }

      await currentUser?.reload();
      currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser?.emailVerified == true) {
        if (mounted) {
          print("Email verified! Redirecting...");
          timer?.cancel();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const Loadingscreen()),
          );
        }
        if (mounted) {
          _auth.completeEmailVerification();
        }
      } else {
        print("Email not yet verified");
      }
    } catch (e) {
      print("Error checking email verification: $e");
    }
  }

  Future<void> _resendEmail() async {
    if (_isResendingEmail || widget.email == null || widget.password == null)
      return;

    setState(() {
      _isResendingEmail = true;
    });

    try {
      // await _auth
      await _auth.resendVerificationForPendingUser(
          widget.email!, widget.password!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Verification email sent!"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to send email: ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResendingEmail = false;
        });
      }
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Email Verification"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.mark_email_unread_outlined,
                size: 100,
                color: Colors.orange,
              ),
              const SizedBox(height: 24),
              const Text(
                "Verify Your Email",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                "We've sent a verification link to:",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  widget.email ?? "your email",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.security, color: Colors.amber, size: 32),
                    SizedBox(height: 8),
                    Text(
                      "Security Notice",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "You must verify your email before you can sign in. Your account will remain inactive until verification is complete.",
                      style: TextStyle(fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                "Click the link in your email to verify your account. This page will automatically update once verified. Wait for Few Seconds After Verifying It",
                style: TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isResendingEmail ? null : _resendEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isResendingEmail
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text("Sending..."),
                        ],
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.email, size: 20),
                          SizedBox(width: 8),
                          Text("Resend Email"),
                        ],
                      ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
