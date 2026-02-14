import 'package:flutter/material.dart';

LightCodeColors get appTheme => ThemeHelper().themeColor();
ThemeData get theme => ThemeHelper().themeData();

/// Helper class for managing themes and colors.

// ignore_for_file: must_be_immutable
class ThemeHelper {
  // The current app theme
  var _appTheme = "lightCode";

  // A map of custom color themes supported by the app
  Map<String, LightCodeColors> _supportedCustomColor = {
    'lightCode': LightCodeColors()
  };

  // A map of color schemes supported by the app
  Map<String, ColorScheme> _supportedColorScheme = {
    'lightCode': ColorSchemes.lightCodeColorScheme
  };

  /// Returns the lightCode colors for the current theme.
  LightCodeColors _getThemeColors() {
    return _supportedCustomColor[_appTheme] ?? LightCodeColors();
  }

  /// Returns the current theme data.
  ThemeData _getThemeData() {
    var colorScheme =
        _supportedColorScheme[_appTheme] ?? ColorSchemes.lightCodeColorScheme;
    return ThemeData(
      visualDensity: VisualDensity.standard,
      colorScheme: colorScheme,
    );
  }

  /// Returns the lightCode colors for the current theme.
  LightCodeColors themeColor() => _getThemeColors();

  /// Returns the current theme data.
  ThemeData themeData() => _getThemeData();
}

class ColorSchemes {
  static final lightCodeColorScheme = ColorScheme.light();
}

class LightCodeColors {
  // App Colors
  Color get gray_900 => Color(0xFF1C0C0C);
  Color get gray_50 => Color(0xFFFAFCF7);
  Color get deep_orange_50 => Color(0xFFF2E8E8);
  Color get gray_300 => Color(0xFFE8D1D1);
  Color get gray_50_01 => Color(0xFFFCF7F7);
  Color get red_600 => Color(0xFFEA2833);
  Color get pink_800 => Color(0xFF994C51);
  Color get gray_200 => Color(0xFFE5E8EA);

  Color get teal_400 => Color(0xFF2E9A92);
  Color get orange_50 => Color(0xFFFBE5D5);
  Color get gray_600 => Color(0xFF828282);

  // Additional Colors
  Color get transparentCustom => Colors.transparent;
  Color get greyCustom => Colors.grey;

  // Color Shades - Each shade has its own dedicated constant
  Color get grey200 => Colors.grey.shade200;
  Color get grey100 => Colors.grey.shade100;
}
