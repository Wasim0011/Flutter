import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/profile/review/review_provider.dart';
import 'package:provider/provider.dart';

class Review extends StatelessWidget {
  const Review({super.key});

  @override
  Widget build(BuildContext context) {
    final reviewProvider = Provider.of<ReviewProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: screenWidth * 0.13),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              SizedBox(width: screenWidth * 0.06),
              Image.asset("assets/app_logo.png", height: 60, width: 60),
            ],
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back_ios),
              ),
              Text(
                "Write Review About us or Suggestion",
                style: GoogleFonts.dmSerifText(
                  fontWeight: FontWeight.w400,
                  fontSize: 20,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: SingleChildScrollView(
              child: Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondary,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: reviewProvider.controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintStyle: TextStyle(color: Color(0xFF979797)),
                    hintText: 'Write here...',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          InkWell(
            onTap: reviewProvider.isLoading
                ? null
                : () => reviewProvider.submitReview(context),
            child: Container(
              height: 52,
              width: 315,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: reviewProvider.isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        "Save",
                        style: GoogleFonts.abhayaLibre(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          color: const Color(0xFFFFFFFF),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
