import 'package:flutter/material.dart';
import '../core/app_export.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.variant,
    this.width,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.borderRadius,
    this.padding,
    this.margin,
    this.isEnabled = true,
  }) : super(key: key);

  /// The text displayed on the button
  final String text;

  /// Callback function triggered when button is pressed
  final VoidCallback? onPressed;

  /// Button style variant
  final CustomButtonVariant? variant;

  /// Button width - if null, uses auto width
  final double? width;

  /// Custom background color
  final Color? backgroundColor;

  /// Custom text color
  final Color? textColor;

  /// Custom font size
  final double? fontSize;

  /// Custom border radius
  final double? borderRadius;

  /// Custom padding
  final EdgeInsetsGeometry? padding;

  /// Custom margin
  final EdgeInsetsGeometry? margin;

  /// Whether the button is enabled
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final effectiveVariant = variant ?? CustomButtonVariant.primary;

    return Container(
      width: width,
      margin: margin ?? _getDefaultMargin(effectiveVariant),
      child: ElevatedButton(
        onPressed: isEnabled ? onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor:
          backgroundColor ?? _getBackgroundColor(effectiveVariant),
          foregroundColor: textColor ?? _getTextColor(effectiveVariant),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              borderRadius ?? _getBorderRadius(effectiveVariant),
            ),
          ),
          padding: padding ?? _getPadding(effectiveVariant),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Be Vietnam Pro',
            fontWeight: _getFontWeight(effectiveVariant),
            fontSize: fontSize ?? _getFontSize(effectiveVariant),
            color: textColor ?? _getTextColor(effectiveVariant),
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(CustomButtonVariant variant) {
    switch (variant) {
      case CustomButtonVariant.primary:
        return appTheme.gray_50; // light background
      case CustomButtonVariant.secondary:
        return appTheme.deep_orange_50; // subtle upload btn
      case CustomButtonVariant.action:
        return appTheme.red_600; // red action btn
    }
  }

  Color _getTextColor(CustomButtonVariant variant) {
    switch (variant) {
      case CustomButtonVariant.primary:
      case CustomButtonVariant.secondary:
        return appTheme.gray_900; // dark text
      case CustomButtonVariant.action:
        return appTheme.gray_50_01; // light text
    }
  }

  FontWeight _getFontWeight(CustomButtonVariant variant) {
    switch (variant) {
      case CustomButtonVariant.primary:
      case CustomButtonVariant.action:
        return FontWeight.w700;
      case CustomButtonVariant.secondary:
        return FontWeight.w400;
    }
  }

  double _getFontSize(CustomButtonVariant variant) {
    switch (variant) {
      case CustomButtonVariant.primary:
      case CustomButtonVariant.action:
        return 18;
      case CustomButtonVariant.secondary:
        return 14;
    }
  }

  double _getBorderRadius(CustomButtonVariant variant) {
    switch (variant) {
      case CustomButtonVariant.primary:
        return 0;
      case CustomButtonVariant.secondary:
        return 20.h;
      case CustomButtonVariant.action:
        return 24.h;
    }
  }

  EdgeInsetsGeometry _getPadding(CustomButtonVariant variant) {
    switch (variant) {
      case CustomButtonVariant.primary:
        return EdgeInsets.symmetric(
          vertical: 12.h,
          horizontal: 30.h,
        );
      case CustomButtonVariant.action:
        return EdgeInsets.symmetric(
          vertical: 10.h,
          horizontal: 16.h,
        );
      case CustomButtonVariant.secondary:
        return EdgeInsets.symmetric(
          vertical: 10.h,
          horizontal: 16.h,
        );
    }
  }

  EdgeInsetsGeometry? _getDefaultMargin(CustomButtonVariant variant) {
    return null;
  }
}

/// Enum defining different button style variants
enum CustomButtonVariant {
  /// Light background button typically used for headers
  primary,

  /// Upload button with rounded corners
  secondary,

  /// Action button with prominent styling
  action,
}