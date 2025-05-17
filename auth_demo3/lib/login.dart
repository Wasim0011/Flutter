import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'otp.dart';

class PhoneHome extends StatefulWidget {
  const PhoneHome({super.key});

  @override
  State<PhoneHome> createState() => _PhoneHomeState();
}

class _PhoneHomeState extends State<PhoneHome> {

  TextEditingController phonenumber=TextEditingController();

  sendcode() async{
    try{
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: '+91${phonenumber.text}',
          verificationCompleted: (PhoneAuthCredential credential){},
    verificationFailed: (FirebaseAuthException e){
          Get.snackbar('Error Occurred', e.code);
    },
    codeSent: (String vid, int? token){
          Get.to(OtpPage(vid: vid,),);
    },
    codeAutoRetrievalTimeout: (vid){}
      );
    }on FirebaseAuthException catch(e){
      Get.snackbar('Error Occurred', e.code);
      }catch(e){
      Get.snackbar('Error Occurred', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        shrinkWrap: true,
        children: [
          Image.asset('images/enterotp.png'),
          Center(child: Text("Your Phone !", style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 6),
          ),
          SizedBox(height: 20,),
          phonetext(),
          SizedBox(height: 50,),
          button(),
        ],
      ),
    );
  }

  Widget button(){
    return Center(
      child: ElevatedButton(
        onPressed: (){
          sendcode();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Color.fromRGBO(90, 208, 248, 1.0),
          padding: const EdgeInsets.all(16.0),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 90),
          child: Text(
            'Receive OTP',
            style: TextStyle(
                fontSize: 18.0,
                color: Colors.white,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
      ),
    );
  }

  Widget phonetext(){
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 50),
      child: TextField(
          controller: phonenumber,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              prefix: Text("+91 "),
              prefixIcon: Icon(Icons.phone),
              labelText: 'Enter Phone Number',
              hintStyle: TextStyle(color: Colors.grey),
              labelStyle: TextStyle(color: Colors.grey),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.black),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.blue),
              )
          ),
      ),
    );
  }
}


