import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileVibeContainer extends StatelessWidget {
  final String text;

  const ProfileVibeContainer({
    super.key,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      // height: 10,
      height: MediaQuery.of(context).size.height * 0.02,
      // margin: const EdgeInsets.all(2), // Reduced margin
      padding: const EdgeInsets.symmetric(
          horizontal: 4, vertical: 4), // Adjusted padding
      decoration: BoxDecoration(
        color: const Color(0xFFECECEC),
        borderRadius: BorderRadius.circular(20),

        // Slightly reduced radius
      ),
      child: Center(
        child: Text(
          text,
          style: GoogleFonts.dmSerifText(
            fontWeight: FontWeight.w400,
            color: const Color(0xFF060606),
            fontSize: 11, // Reduced font size
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
      ),
    );
  }
}
