import 'homepage.dart';
import 'login.dart';
import 'package:auth_demo/verifyemail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Wrapper extends StatefulWidget {
  const Wrapper({super.key});

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('An error occurred.'));
          } else if (snapshot.hasData) {
            print(snapshot.data);
            if(snapshot.data!.emailVerified){
              return Homepage();
            }else{
              return Verify();
            }
          } else {
            return Login();
          }
        },
      ),

    );
  }
}
