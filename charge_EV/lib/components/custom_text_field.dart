import 'package:flutter/material.dart';
import '../consts/fonts.dart'; // Assuming AppFonts is defined here

class CustomTextField extends StatefulWidget {
  final String label;
  final String hintText;
  final TextEditingController controller;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hintText,
    required this.controller,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontFamily: AppFonts.nunitoMedium,
              fontSize: AppSizes.size16,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF191D23),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            focusNode: _focusNode,
            controller: widget.controller,
            obscureText: widget.obscureText,
            keyboardType: widget.keyboardType,
            style: TextStyle(
              fontFamily: AppFonts.nunito,
              fontSize: AppSizes.size16,
              fontWeight: FontWeight.w400,
            ),
            decoration: InputDecoration(
              hintText: _focusNode.hasFocus ? null : widget.hintText,
              suffixIcon: widget.suffixIcon,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
