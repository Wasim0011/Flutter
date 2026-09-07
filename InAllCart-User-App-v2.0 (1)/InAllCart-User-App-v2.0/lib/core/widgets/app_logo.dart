import 'package:flutter/material.dart';

/// Reusable brand logo widget.
class AppLogo extends StatelessWidget {
  final double height;
  final bool transparentBackground;
  final EdgeInsets cardPadding;
  final double cardRadius;

  const AppLogo({
    super.key,
    this.height = 40,
    this.transparentBackground = true,
    this.cardPadding = const EdgeInsets.all(8),
    this.cardRadius = 12,
  });

  const AppLogo.light({
    super.key,
    this.height = 36,
  })  : transparentBackground = true,
        cardPadding = EdgeInsets.zero,
        cardRadius = 0;

  const AppLogo.appBar({super.key})
      : height = 36,
        transparentBackground = true,
        cardPadding = EdgeInsets.zero,
        cardRadius = 0;

  const AppLogo.splash({super.key})
      : height = 100,
        transparentBackground = false,
        cardPadding = const EdgeInsets.all(12),
        cardRadius = 28;

  @override
  Widget build(BuildContext context) {
    return Text(
      'InAllCart',
      style: TextStyle(
        fontSize: height * 0.5,
        fontWeight: FontWeight.w900,
        color: Colors.black87,
        letterSpacing: -0.5,
      ),
    );
  }
}
