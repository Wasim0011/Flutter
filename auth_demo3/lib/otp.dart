import 'package:auth_demo3/wrapper.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pinput/pinput.dart';

class OtpPage extends StatefulWidget {
  final String vid;
  const OtpPage({super.key, required this.vid});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  var code = '';

  Future<void> signIN() async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.vid,
        smsCode: code,
      );

      await FirebaseAuth.instance
          .signInWithCredential(credential)
          .then((value) {
        Get.offAll(() => Wrapper());
      });
    } on FirebaseAuthException catch (e) {
      Get.snackbar('Error Occurred', e.code);
    } catch (e) {
      Get.snackbar('Error Occurred', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Image.asset(
              'images/enterphone.png',
              height: 330,
              width: 330,
            ),
            const Center(
              child: Text(
                "OTP verification",
                style: TextStyle(fontSize: 30.0, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 25, vertical: 6),
              child: Text(
                "Enter OTP sent to +91 9876543210",
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20.0),
            textcode(),
            const SizedBox(height: 80),
            button(),
          ],
        ),
      ),
    );
  }

  Widget button() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          signIN(); // Call the corrected method name.
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromRGBO(140, 178, 241, 1.0),
          padding: const EdgeInsets.all(16.0),
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 80),
          child: Text(
            'Verify & Proceed',
            style: TextStyle(
              fontSize: 18.0,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget textcode() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: Pinput(
          length: 6,
          onChanged: (value) {
            setState(() {
              code = value;
            });
          },
        ),
      ),
    );
  }
}
