import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gossipcom/auth/register/terms.dart';

class AvatarSelection extends StatefulWidget {
  final String userName;
  final List<String> selectedTopics;
  final List<String> selectedVibes;
  const AvatarSelection(
      {super.key,
        required this.userName,
        required this.selectedTopics,
        required this.selectedVibes});

  @override
  State<AvatarSelection> createState() => _AvatarSelectionState();
}

class _AvatarSelectionState extends State<AvatarSelection> {
  List<String> avatarUrls = [];
  String selectedAvatarUrl = "";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchAvatarUrls();
  }

  Future<void> fetchAvatarUrls() async {
    try {
      final ListResult result =
      await FirebaseStorage.instance.ref('avatars').listAll();
      final List<String> urls = await Future.wait(
        result.items.map((Reference ref) async {
          try {
            return await ref.getDownloadURL();
          } catch (e) {
            print("Error getting download URL for ${ref.name}: $e");
            return ''; // skip this avatar if error
          }
        }).toList(),
      );
      setState(() {
        avatarUrls = urls.where((url) => url.isNotEmpty).toList();
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching avatars: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return PopScope(
      canPop: true,
      onPopInvoked: (bool didPop) {
        if (didPop) {
          // Handle any cleanup if needed
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: Column(
        children: [
          SizedBox(height: screenHeight * 0.1),
          Row(
            children: [
              SizedBox(width: screenWidth*0.05,),
              IconButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                icon: const Icon(Icons.arrow_back_ios, size: 32),
              ),
              SizedBox(width: screenWidth*0.25,),
              Image.asset("assets/smallHeader.png"),
            ],
          ),
          SizedBox(height: screenWidth* 0.09),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Container(

                child: Center(
                  child: Text(
                    "Choose your Avatar",
                    style: GoogleFonts.dmSerifText(
                      fontWeight: FontWeight.w400,
                      fontSize: 20,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Show selected avatar if one is selected
          if (selectedAvatarUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Column(
                children: [

                  const SizedBox(height: 8),
                  Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue,
                        width: 2.5,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        selectedAvatarUrl,
                        fit: BoxFit.cover,
                        width: 70.0,
                        height: 70.0,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.grey.shade200,
                            child: const Icon(
                              Icons.person,
                              size: 35.0,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          isLoading
              ? Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  "Loading...",
                  style: TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
              : Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 avatars per row
                crossAxisSpacing: 8, // Reduced from 15 to 8
                mainAxisSpacing: 8,  // Reduced from 15 to 8
                childAspectRatio: 1.0, // Makes grid items square
              ),
              itemCount: avatarUrls.length,
              itemBuilder: (context, index) {
                final bool isSelected =
                    avatarUrls[index] == selectedAvatarUrl;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedAvatarUrl = avatarUrls[index];
                    });
                    print('Selected Avatar URL: $selectedAvatarUrl');
                  },
                  child: Center(
                    child: Container(
                      width: 70, // Increased from 50 to 70
                      height: 70, // Increased from 50 to 70
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.black,
                          width: isSelected ? 2.5 : 1.5,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.network(
                          avatarUrls[index],
                          fit: BoxFit.cover,
                          width: 70.0, // Increased from 50 to 70
                          height: 70.0, // Increased from 50 to 70
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 70.0, // Increased from 50 to 70
                              height: 70.0, // Increased from 50 to 70
                              color: Colors.grey.shade200,
                              child: const Icon(
                                Icons.person,
                                size: 35.0, // Increased from 25 to 35
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(
            height: 30,
          ),
          GestureDetector(
            onTap: () {
              print(widget.selectedVibes);
              print(widget.selectedTopics);
              print(widget.userName);
              print(selectedAvatarUrl);

              // Check if avatar is selected
              if (selectedAvatarUrl.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please select an avatar')),
                );
                return;
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Terms(
                      userName: widget.userName,
                      selectedTopics: widget.selectedTopics,
                      selectedVibes: widget.selectedVibes,
                      avatar: selectedAvatarUrl,
                    ),
                  ),
                );
              }
            },
            child: Container(
              height: 52,
              width: 315,
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Center(
                child: Text(
                  "Continue",
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: screenHeight*0.12),
        ],
      ),
      ),
    );
  }
}