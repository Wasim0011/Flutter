import 'package:flutter/material.dart';

import '../core/app_export.dart';
import './custom_image_view.dart';

class CustomProductAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  CustomProductAppBar({
    Key? key,
    this.leadingImagePath,
    this.title,
    this.backgroundColor,
    this.titleColor,
    this.onLeadingPressed,
  }) : super(key: key);

  /// Path to the leading icon image
  final String? leadingImagePath;

  /// Title text to display in the AppBar
  final String? title;

  /// Background color of the AppBar
  final Color? backgroundColor;

  /// Color of the title text
  final Color? titleColor;

  /// Callback function when leading image is tapped
  final VoidCallback? onLeadingPressed;

  @override
  Widget build(BuildContext context) {
    return AppBar(
        backgroundColor: backgroundColor ?? Color(0xFFFCF7F7),
        elevation: 5.0,
        automaticallyImplyLeading: false,
        toolbarHeight: 64.h,
        titleSpacing: 16.h,
        title: Row(children: [
          if (leadingImagePath != null) ...[
            GestureDetector(
                onTap: onLeadingPressed,
                child: CustomImageView(
                    imagePath: leadingImagePath!, height: 48.h, width: 48.h)),
            SizedBox(width: 60.h),
          ],
          Expanded(
              child: Text(title ?? "Product Details",
                  style: TextStyleHelper.instance.title18BoldBeVietnamPro
                      .copyWith(
                          color: titleColor ?? Color(0xFF1C0C0C), height: 1.28),
                  overflow: TextOverflow.ellipsis)),
        ]));
  }

  @override
  Size get preferredSize => Size.fromHeight(64.h);
}
