import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Heading extends StatelessWidget {
  final String text;
  const Heading({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(13),
      child: Container(
        height: 53,
        width: screenWidth * 0.8,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(width: 1, color: Colors.grey.shade400),
        ),
        child: Center(
          child: Text(
            text,
            style: GoogleFonts.dmSerifText(
                fontWeight: FontWeight.w400, fontSize: 32, color: Colors.black),
          ),
        ),
      ),
    );
  }
}
