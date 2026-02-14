import 'package:flutter/material.dart';

class MyTextField extends StatefulWidget {
  final String hintText;
  final bool obscureText;
  final TextEditingController controller;

  const MyTextField(
      {super.key,
      required this.hintText,
      required this.obscureText,
      required this.controller});

  @override
  State<MyTextField> createState() => _MyTextFieldState();
}

class _MyTextFieldState extends State<MyTextField> {
  late bool _obscure;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25.0),
      child: TextField(
        controller: widget.controller,
        obscureText: _obscure,
        decoration: InputDecoration(
          fillColor: Theme.of(context).colorScheme.secondary,
          filled: true,
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Theme.of(context).colorScheme.primary),
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _obscure ? Icons.remove_red_eye_outlined : Icons.visibility,
                    color: Theme.of(context).colorScheme.onSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscure = !_obscure;
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
