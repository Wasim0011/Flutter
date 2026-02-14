import 'package:circle_nav_bar/circle_nav_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gossipcom/auth/auth_service.dart';
import 'package:gossipcom/botoomNavigationScreens/category.dart';
import 'package:gossipcom/botoomNavigationScreens/chat.dart';
import 'package:gossipcom/botoomNavigationScreens/home.dart';
import 'package:gossipcom/botoomNavigationScreens/profile.dart';
import 'package:gossipcom/thoughts/ImagePreview.dart';
import 'package:image_picker/image_picker.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedNavIndex = 0;
  final AuthService authService = AuthService();

  // 📸 Camera image picker
  void cameraImagePick() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(source: ImageSource.camera);

      if (photo != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Imagepreview(selectedImage: [photo]),
          ),
        );
      }
    } catch (e) {
      debugPrint("Camera pick error: $e");
    }
  }

  // 🖼️ Gallery image picker
  void galleryImagePick() async {
    try {
      final ImagePicker picker = ImagePicker();
      final List<XFile>? images = await picker.pickMultiImage();

      if (images != null && images.isNotEmpty && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Imagepreview(selectedImage: images),
          ),
        );
      }
    } catch (e) {
      debugPrint("Gallery pick error: $e");
    }
  }

  // 👇 Map bottom nav index to screen index (skips add button)
  int _mapIndexToScreen(int index) {
    if (index < 2) return index;
    return index - 1; // Skip "Add" button index (2)
  }

  final List<Widget> _screens = const [
    Home(),
    Category(),
    Chat(),
    Profile(),
  ];

  // 🔹 Helper for active/inactive icons
  Widget _navIcon(String asset, {bool active = false}) {
    return SizedBox(
      height: active ? 18 : 24,
      width: active ? 18 : 24,
      child: Center(
        child: SvgPicture.asset(
          asset,
          fit: BoxFit.contain,
          colorFilter: ColorFilter.mode(
            active ? Colors.white : Colors.grey.shade600,
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // this helps avoid resize issues when keyboard appears
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        bottom: false, // we’ll manually handle bottom nav area
        child: _screens[_mapIndexToScreen(_selectedNavIndex)],
      ),
      bottomNavigationBar: SafeArea(
        top: false, // only safe for bottom
        child: CircleNavBar(
          activeIndex: _selectedNavIndex,
          color: Colors.white,
          circleColor: Colors.blue,
          height: 70,
          circleWidth: 70,
          activeIcons: [
            _navIcon('assets/Home_icons.svg', active: true),
            _navIcon('assets/Category_icons.svg', active: true),
            _navIcon('assets/Plus_icons.svg', active: true),
            _navIcon('assets/Chat_icons.svg', active: true),
            _navIcon('assets/Profile_icons.svg', active: true),
          ],
          inactiveIcons: [
            _navIcon('assets/Home_icons.svg'),
            _navIcon('assets/Category_icons.svg'),
            _navIcon('assets/Plus_icons.svg'),
            _navIcon('assets/Chat_icons.svg'),
            _navIcon('assets/Profile_icons.svg'),
          ],
          onTap: (index) {
            if (index == 2) {
              // ➕ Add button pressed
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text("Choose Image Source"),
                  content: const Text(
                      "Select from where you want to choose the image"),
                  actionsAlignment: MainAxisAlignment.center,
                  actions: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        cameraImagePick();
                      },
                      child: const Text("Camera"),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(dialogContext);
                        galleryImagePick();
                      },
                      child: const Text("Gallery"),
                    ),
                  ],
                ),
              );
            } else {
              setState(() {
                _selectedNavIndex = index;
              });
            }
          },
        ),
      ),
    );
  }
}
