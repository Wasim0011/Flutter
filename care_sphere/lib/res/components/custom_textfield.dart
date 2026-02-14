import 'package:care_sphere/consts/colors.dart';
import 'package:flutter/material.dart';

class CustomTextfield extends StatefulWidget {
  final String hint;
  final TextEditingController? textController;
  final Color textColor;
  final Color borderColor;
  final Color inputColor;
  final bool isPassword;
  final TextInputType? keyboardType;
  final int? maxLines;

  const CustomTextfield(
      {super.key,
      required this.hint,
      this.textController,
      this.textColor = Colors.black,
      this.borderColor = Colors.black,
      this.inputColor = Colors.black,
      this.isPassword = false,
      this.keyboardType,
      this.maxLines = 1
      });

  @override
  State<CustomTextfield> createState() => _CustomTextfieldState();
}

class _CustomTextfieldState extends State<CustomTextfield> {
  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.textController,
      cursorColor: AppColors.blueColor,
      style: TextStyle(color: widget.inputColor),
      obscureText: widget.isPassword,
      keyboardType: widget.keyboardType,
      maxLines: widget.maxLines,
      decoration: InputDecoration(
          isDense: true,
          focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(
            color: widget.borderColor,
          )),
          enabledBorder: OutlineInputBorder(
              borderSide: BorderSide(color: widget.borderColor)),
          border: OutlineInputBorder(
              borderSide: BorderSide(color: widget.borderColor)),
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: widget.textColor,
          )),
    );
  }
}
