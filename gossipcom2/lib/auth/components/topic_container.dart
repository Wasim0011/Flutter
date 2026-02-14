import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TopicContainer extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool isSelected;
  final Function(bool) onSelected;

  const TopicContainer(
      {super.key,
      required this.text,
      required this.fontSize,
      required this.isSelected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWeight = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: () {
        onSelected(!isSelected);
      },
      child: Material(
        elevation: 14,
        borderRadius: BorderRadius.circular(13),
        child: Container(
          width: screenWeight*0.4,
          height: screenHeight*0.06,
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF1976D2) : Colors.white,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.dmSerifText(
                fontWeight: FontWeight.w400,
                color: isSelected ? Colors.white : const Color(0xFF060606),
                fontSize: fontSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
