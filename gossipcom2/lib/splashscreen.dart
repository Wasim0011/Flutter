import 'package:flutter/material.dart';
import 'package:gossipcom/auth/auth_gate.dart';
import 'package:lottie/lottie.dart';
class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> {
  @override
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(const Duration(seconds: 5),
        (){
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>const AuthGate()));
        }
    );
  }
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.asset('assets/animation/logo.json'),
      ),
    );
  }
}
