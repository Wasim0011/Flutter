import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../core/app_export.dart';

class CustomLoadingIndicator extends StatelessWidget {
  const CustomLoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromRGBO(255, 255, 255, 0.1),
              Color.fromRGBO(255, 255, 255, 0.3),
            ],
          ),
        ),
        child: Center(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 24.h),
            decoration: BoxDecoration(
              color: appTheme.deep_orange_50,
              borderRadius: BorderRadius.circular(20.h),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.shade200,
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LoadingAnimationWidget.fourRotatingDots(
                  color: appTheme.pink_800, // Use a primary theme color
                  size: 80.h,
                ),
                SizedBox(height: 32.h),
                Text(
                  'Extracting Details',
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.title18BoldBeVietnamPro.copyWith(
                    color: appTheme.gray_900,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Please wait a moment...',
                  textAlign: TextAlign.center,
                  style: TextStyleHelper.instance.body14RegularBeVietnamPro.copyWith(
                    color: appTheme.gray_600,
                    fontSize: 15.fSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}