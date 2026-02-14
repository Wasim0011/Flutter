import 'package:flutter/material.dart';

var lightTheme = ThemeData(
  colorScheme: ColorScheme.light(
    brightness: Brightness.light,
    primary: Color(0xFF828282),
    inversePrimary: Color(0x898A8D6B),
    onPrimary: Color(0xFF606060),
    secondary: Color(0xFFEDF1F5),
    onSecondary: Color(0xFF060606),
    background: Colors.white,
    onBackground: Colors.black,
    tertiary: Colors.white,
    surface: Colors.white,
    onSurface: Colors.black,
    onTertiary: Colors.white,
    onTertiaryContainer: Colors.blue,
  ),
);

var darkTheme = ThemeData(
  colorScheme: ColorScheme.dark(
      brightness: Brightness.dark,
      primary: Color(0xFFB0B0B0),
      tertiary: Colors.grey.shade400,
      onTertiary: Colors.grey.shade800,
      inversePrimary: Color(0x89B5B89C),
      onPrimary: Color(0xFFA0A0A0),
      secondary: Color(0xFF1E1E1E),
      onSecondary: Color(0xFFF5F5F5),
      background: Colors.black,
      onBackground: Colors.white,
      surface: Colors.black,
      onSurface: Colors.white,
      onTertiaryContainer: Colors.blue),
);


Color hexToColor(String hexString) {
  var hex = hexString.replaceAll('#', '').replaceAll('0x', '').toUpperCase();
  if (hex.length == 3) {
    // expand shorthand like "0F8" -> "00FF88"
    hex = hex.split('').map((c) => c + c).join();
  }
  if (hex.length == 6) {
    hex = 'FF$hex'; // add full opacity
  }
  if (hex.length != 8) {
    throw FormatException('Invalid hex color format.', hexString);
  }
  return Color(int.parse(hex, radix: 16));
}