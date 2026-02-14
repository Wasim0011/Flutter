import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../core/app_export.dart';

class CustomTranslationLoader extends StatelessWidget {
  const CustomTranslationLoader({Key? key}) : super(key: key);

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
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 32.h),
              decoration: BoxDecoration(
                color: appTheme.deep_orange_50,
                borderRadius: BorderRadius.circular(16.h),
                boxShadow: [
                  BoxShadow(
                    color: Colors.deepPurple.shade200,
                    blurRadius: 15,
                    spreadRadius: 2,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Transform.scale(
                    scale: 1.6,
                    child: LoadingAnimationWidget.waveDots(
                      color: appTheme.pink_800,
                      size: 60.h,
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    'Generating Voice',
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
      ),
    );
  }
}
