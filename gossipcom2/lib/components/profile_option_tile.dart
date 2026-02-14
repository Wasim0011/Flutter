import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileOptionTile extends StatelessWidget {
  final String text;
  final void Function()? onTap;
  const ProfileOptionTile({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _isClassicBlue(text)
                ? const Color(0xFF0F4C81) // Classic Blue
                : const Color(0x33736F6F),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: screenWidth * 0.05,
              ),
              Center(
                child: Text(
                  text,
                  style: GoogleFonts.abhayaLibre(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _isClassicBlue(text)
                          ? Colors.white
                          : Theme.of(context).colorScheme.onSurface),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: const BoxDecoration(
                      color: Color(0x33000000), // #00000033
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  bool _isClassicBlue(String label) {
    switch (label.toLowerCase()) {
      case 'your posts':
      case 'edit topics you like':
      case 'report an issue':
      case 'invite a friend':
      case 'striked by user':
      case 'write a review about us':
      case 'log out':
        return true;
      default:
        return false;
    }
  }
}
