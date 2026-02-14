import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/chats/recent_chats/user_screen.dart';
import 'package:gossipcom/components/heading.dart';
import 'package:gossipcom/themes/themes.dart';
import '../chats/match_chat/topic_match_making.dart';
import '../chats/topic_chats/topic_screen.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Chat extends StatefulWidget {
  const Chat({super.key});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.055),
            Container(
              height: 100,
              width: 110,
              color: Colors.transparent,
              child: Image.asset(
                'assets/app_logo.png',
                // color: Color(0xffffffff),
                fit: BoxFit.contain,
                // placeholderBuilder: (context) => Icon(Icons.error),
              ),
            ),
            SizedBox(height: screenHeight * 0.025),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Heading(text: "Start Gossip"),
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) =>
                                    const RecentChatsScreen()));
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            // color: const Color(0x80D9D9D9),
                          ),
                          child: SvgPicture.asset(
                            'assets/recent_chat.svg',
                            height: 25,
                          )
                          // Svg.asset('assets/chat_icon.png'),
                          ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // First option - Topic Chat
                  _buildOptionCard(
                    icon: Icons.chat_bubble_outlined,
                    title: "One Topic Discussion",
                    subtitle: "Choose a topic & dive in",
                    color: const Color(0xFF235087),
                    iconColor: const Color(0xFF97B5D8),
                    gradientStartHex: '#3571B5',
  gradientEndHex: '#225187',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TopicSelectionScreen(),
                        ),
                      );
                    },
                  ),
                  _buildOptionCard(
                    icon: Icons.people,
                    title: "Profile Match",
                    subtitle: "Based on your interest",
                    color: const Color(0xFF3472B5),
                    iconColor: const Color(0xFFCADFF8),
                    gradientStartHex: '#3571B5',
  gradientEndHex: '#225187',
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const TopicMatchMaking()));
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Material(
                borderRadius: BorderRadius.circular(20),
                elevation: 5,
                child: Container(
                  height: screenHeight * 0.27,
                  width: screenWidth * 0.9,
                  decoration: BoxDecoration(
                    color: hexToColor('#EDF1F5'),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(10),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        // color: Theme.of(context).colorScheme.onSurface,
                        color: hexToColor('#828282'),
                        height: 1.4,
                      ),
                      children: [
                        TextSpan(
                          text: '⚠️ Strike System: \n',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.sp),
                        ),
                        TextSpan(
                          text:
                              'If you are disrespectful, go off-topic, or use hate speech during discussions, other users can issue you a strike.',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                        ),
                        TextSpan(
                          text:
                              'Our team will confirm the strike. If you get 2 strikes, it will result in a 7-day ban or permanent ban.\n\n',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                        ),
                        TextSpan(
                          text:
                              'Please communicate respectfully andstay on-topic to help us maintain a safe and welcoming platform for everyone.',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
  required IconData icon,
  required String title,
  required String subtitle,
  // keep old color param as fallback
  Color? color,
  required Color iconColor,
  required VoidCallback onTap,
  // optional: pass hex strings to create a gradient
  String? gradientStartHex,
  String? gradientEndHex,
}) {
  // decide decoration: gradient if both hex values provided, otherwise plain color
  final Decoration decoration = (gradientStartHex != null && gradientEndHex != null)
      ? BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              hexToColor(gradientStartHex),
              hexToColor(gradientEndHex),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
        )
      : BoxDecoration(
          color: color ?? Colors.blue,
          borderRadius: BorderRadius.circular(20),
        );

  return Material(
    color: Colors.transparent,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      splashColor: iconColor.withOpacity(0.6),
      highlightColor: iconColor.withOpacity(0.3),
      child: Ink(
        height: 190.h,
        width: 160.w,
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 46.sp, color: iconColor),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.start,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 16.sp,
                ),
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      subtitle,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 40.h,
                    width: 40.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.blue,
                      size: 18.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

}
