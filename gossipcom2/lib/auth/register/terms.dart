import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/auth/auth_service.dart';
import 'package:gossipcom/auth/register/signup.dart';

class Terms extends StatefulWidget {
  final String userName;
  final List<String> selectedTopics;
  final List<String> selectedVibes;
  final String avatar;
  Terms(
      {super.key,
      required this.userName,
      required this.selectedTopics,
      required this.selectedVibes,
      required this.avatar});

  @override
  State<Terms> createState() => _TermsState();
}

class _TermsState extends State<Terms> {
  FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  String? currentuser;
  @override
  void initState() {
    super.initState();
    currentuser = _firebaseAuth.currentUser?.uid;
  }

  void handleuserData() {
    if (currentuser != null) {
      AuthService().signupwithGoogle(context, widget.userName,
          widget.selectedTopics, widget.selectedVibes, widget.avatar);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SignUp(
            userName: widget.userName,
            selectedTopics: widget.selectedTopics,
            selectedVibes: widget.selectedVibes,
            avatar: widget.avatar,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          // Handle any cleanup if needed
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Column(
        children: [
          SizedBox(height: screenHeight * 0.1),
          Row(
            children: [
              SizedBox(
                width: screenWidth * 0.05,
              ),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back_ios, size: 32),
              ),
              SizedBox(
                width: screenWidth * 0.25,
              ),
              Image.asset("assets/smallHeader.png"),
            ],
          ),
          SizedBox(height: screenWidth * 0.09),
          const SizedBox(
            height: 5,
          ),
          Text(
            "Hate Speech Agreement",
            style: GoogleFonts.dmSerifText(
                fontSize: 20,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onSecondary),
          ),
          SizedBox(
            height: screenHeight * 0.04,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Material(
              elevation: 4,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .inversePrimary, // 1px border with custom color
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(25.0),
                  child: Center(
                    child: Text(
                      "If you are disrespectful, go off-topic, or use hate speech during discussions, other users can issue you a strike. And our team will confirm that strike. If u get 2 strikes will result in a 7-day ban or permanent ban.Please communicate respectfully and stay on-topic to help us maintain a safe and welcoming platform for everyone.",
                      style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(
            height: 90,
          ),
          GestureDetector(
            onTap: () {
              print(widget.userName);
              print(widget.selectedVibes);
              print(widget.selectedTopics);
              handleuserData();
            },
            child: Container(
              height: 52,
              width: 315,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  "Accept & Continue",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            height: screenHeight * 0.04,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Thank You, Have a Great Gossiping ",
                style: GoogleFonts.dmSerifText(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: Theme.of(context).colorScheme.onSecondary),
              ),
            ],
          ),
          SizedBox(
            height: screenHeight * 0.02,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "The first rule of discussion is that discussion should not be based on gender, religion, or caste. If anyone discriminates on these grounds, please report them. ",
              style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF828282)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
