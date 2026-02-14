import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class VibeContainer extends StatelessWidget {
  final String text;
  final double fontSize;
  final bool isSelected;
  final Function(bool) onSelected;

  const VibeContainer(
      {super.key,
      required this.text,
      required this.fontSize,
      required this.isSelected,
      required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        onSelected(!isSelected);
      },
      child: Container(
        width: 120,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1976D2) : const Color(0xFFECECEC),
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
    );
  }
}
