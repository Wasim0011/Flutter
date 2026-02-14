import 'package:flutter/material.dart';
import '../consts/fonts.dart';
import '../consts/images.dart'; // for AppAssets.imgMap, imgCar

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  const CustomAppBar({
    super.key,
    required this.title,
    required this.subtitle
  }); //constructor

  @override
  Size get preferredSize => const Size.fromHeight(250); //Set height for app bar

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Base black background with bottom-right radius
        Container(
          height: preferredSize.height,
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.only(
              bottomRight: Radius.circular(100),
            ),
          ),
        ),

        // World map only on bottom half
        Positioned(
          top: preferredSize.height * 0.2, // show only from half down
          // width: ,/
          child: Opacity(
            opacity: 0.70,
            child: Image.asset(
              AppAssets.imgMap,
              width: 400,
              fit: BoxFit.cover,
            ),
          ),
        ),

        // Text content
        Positioned(
          left: 20,
          top: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontFamily: AppFonts.interBold,
                  fontSize: AppSizes.size30,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontFamily: AppFonts.inter,
                  fontSize: AppSizes.size16,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFFEBEDF0),
                ),
              ),
            ],
          ),
        ),

        //Car image at bottom right
        Positioned(
          bottom: -140,
          right: -60,
          child: Image.asset(
            AppAssets.imgCar,
            width: 340,
            height: 380,
          ),
        ),
      ],
    );
  }
}
