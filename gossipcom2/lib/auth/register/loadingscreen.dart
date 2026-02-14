import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:gossipcom/auth/login.dart';
import 'package:gossipcom/auth/register/verificationmail.dart';
import 'package:gossipcom/home_page.dart';

class Loadingscreen extends StatefulWidget {
  const Loadingscreen({super.key});

  @override
  State<Loadingscreen> createState() => _LoadingscreenState();
}

class _LoadingscreenState extends State<Loadingscreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
    return const Center(
    child: CircularProgressIndicator(),
    );
    }
    else if (snapshot.hasError) {
    return const Center(
    child: Text("error"),
    );
    }
    else {
      Future.microtask(() {
        final user = snapshot.data;
        if (user == null) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const Login()),
                (route) => false,
          );
        } else if (user.emailVerified) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomePage()),
                (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  Verificationmail(
                    email: user.email,
                    password: null, // Or retrieve it if needed
                  ),
            ),
                (route) => false,
          );
        }
      });
      return const Center(child: CircularProgressIndicator());
    }

          },
          ),
    );
  }
}
