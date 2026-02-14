import 'package:flutter/material.dart';
import '../core/app_export.dart';
// Its purpose is to centralize all text styles so our app has consistent typography everywhere.
class TextStyleHelper {
  static TextStyleHelper? _instance;

  TextStyleHelper._();

  static TextStyleHelper get instance {
    _instance ??= TextStyleHelper._();
    return _instance!;
  }

  // Title Styles
  // Medium text styles for titles and subtitles

  TextStyle get title22BoldBeVietnamPro => TextStyle(
        fontSize: 22.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Be Vietnam Pro',
        color: appTheme.gray_900,
      );

  TextStyle get title20RegularRoboto => TextStyle(
        fontSize: 20.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Roboto',
      );

  TextStyle get title18BoldBeVietnamPro => TextStyle(
        fontSize: 18.fSize,
        fontWeight: FontWeight.w700,
        fontFamily: 'Be Vietnam Pro',
      );

  // Body Styles
  // Standard text styles for body content

  TextStyle get body14RegularBeVietnamPro => TextStyle(
        fontSize: 14.fSize,
        fontWeight: FontWeight.w400,
        fontFamily: 'Be Vietnam Pro',
      );

  // Other Styles
  // Miscellaneous text styles without specified font size

  TextStyle get bodyTextBoldBeVietnamPro => TextStyle(
        fontWeight: FontWeight.w700,
        fontFamily: 'Be Vietnam Pro',
      );
}
