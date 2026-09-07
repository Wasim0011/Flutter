import 'package:flutter/material.dart';

class UShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // Start bottom left
    path.moveTo(0, size.height);
    // Line to top left start of curve (height - width/2)
    path.lineTo(0, size.width / 2);
    // Semi-circle arc to top right
    path.arcToPoint(
      Offset(size.width, size.width / 2),
      radius: Radius.circular(size.width / 2),
      clockwise: true,
    );
    // Line to bottom right
    path.lineTo(size.width, size.height);
    // Close to bottom left
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

class UShapeShadowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.width / 2);
    path.arcToPoint(
      Offset(size.width, size.width / 2),
      radius: Radius.circular(size.width / 2),
      clockwise: true,
    );
    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.05), 4, true);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
