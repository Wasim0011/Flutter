import 'package:flash_chat/screens/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flash_chat/components/rounded_button.dart';
import 'package:flash_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:modal_progress_hud_nsn/modal_progress_hud_nsn.dart';

class RegistrationScreen extends StatefulWidget {
  static const String id = 'registration_screen';

  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  bool showSpinner = false;
  final _auth = FirebaseAuth.instance;
  late String phoneNumber;
  late String otp;
  String verificationId = '';

  // Method to request OTP
  Future<void> requestOTP() async {
    setState(() {
      showSpinner = true;
    });
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        // Auto verification is completed
        await _auth.signInWithCredential(credential);
        Navigator.pushNamed(context, ChatScreen.id);
      },
      verificationFailed: (FirebaseAuthException e) {
        print("Verification failed: ${e.message}");
        setState(() {
          showSpinner = false;
        });
      },
      codeSent: (String verId, int? resendToken) {
        // Code successfully sent
        verificationId = verId;
        setState(() {
          showSpinner = false;
        });
      },
      codeAutoRetrievalTimeout: (String verId) {
        verificationId = verId;
      },
    );
  }

  // Method to verify OTP
  Future<void> verifyOTP() async {
    setState(() {
      showSpinner = true;
    });
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: otp,
      );
      await _auth.signInWithCredential(credential);
      Navigator.pushNamed(context, ChatScreen.id);
    } catch (e) {
      print("Error verifying OTP: $e");
    }
    setState(() {
      showSpinner = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: ModalProgressHUD(
        inAsyncCall: showSpinner,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Flexible(
                child: Hero(
                  tag: 'logo',
                  child: Container(
                    height: 200.0,
                    child: Image.asset('images/logo.png'),
                  ),
                ),
              ),
              SizedBox(height: 48.0),
              TextField(
                keyboardType: TextInputType.phone,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  phoneNumber = value;
                },
                decoration: kTextFieldDecoration.copyWith(
                  hintText: 'Enter your phone number',
                ),
              ),
              SizedBox(height: 8.0),
              TextField(
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: (value) {
                  otp = value;
                },
                decoration: kTextFieldDecoration.copyWith(hintText: 'Enter OTP'),
              ),
              SizedBox(height: 24.0),
              RoundedWidget(
                title: 'Request OTP',
                colour: Colors.blueAccent,
                onPressed: requestOTP,
              ),
              SizedBox(height: 10.0),
              RoundedWidget(
                title: 'Verify OTP',
                colour: Colors.green,
                onPressed: verifyOTP,
              ),
            ],
          ),
        ),
      ),
    );
  }
}