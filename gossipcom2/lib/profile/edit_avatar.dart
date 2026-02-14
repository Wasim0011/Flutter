import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditAvatar extends StatefulWidget {
  const EditAvatar({super.key});

  @override
  State<EditAvatar> createState() => _EditAvatarState();
}

class _EditAvatarState extends State<EditAvatar> {
  List<String> avatarUrls = [];
  String selectedAvatarUrl = "";
  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    fetchAvatarUrls();
  }

  Future<void> fetchAvatarUrls() async {
    try {
      // 1. Fetch predefined avatars from Firebase Storage
      final ListResult result =
      await FirebaseStorage.instance.ref('avatars').listAll();
      final List<String> urls = await Future.wait(
        result.items.map((ref) => ref.getDownloadURL()).toList(),
      );

      // 2. Fetch current user's avatar to highlight it
      final user = FirebaseAuth.instance.currentUser;
      String currentAvatar = "";
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          currentAvatar = doc.data()?['avatar'] ?? "";
        }
      }

      if (mounted) {
        setState(() {
          avatarUrls = urls.where((url) => url.isNotEmpty).toList();
          selectedAvatarUrl = currentAvatar;
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching avatars: $e');
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveAvatar() async {
    if (selectedAvatarUrl.isEmpty) return;

    setState(() => isSaving = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'avatar': selectedAvatarUrl});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Avatar updated successfully!")),
          );
          Navigator.pop(context, true); // Return true to refresh profile
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text("Choose Avatar", style: GoogleFonts.dmSerifText(color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4, // 4 avatars per row
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: avatarUrls.length,
              itemBuilder: (context, index) {
                final url = avatarUrls[index];
                final isSelected = url == selectedAvatarUrl;

                return GestureDetector(
                  onTap: () => setState(() => selectedAvatarUrl = url),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.transparent,
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, loading) {
                          if (loading == null) return child;
                          return Container(color: Colors.grey[200]);
                        },
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.error),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: GestureDetector(
              onTap: isSaving ? null : _saveAvatar,
              child: Container(
                height: 52,
                width: 315,
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                    "Save New Avatar",
                    style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}