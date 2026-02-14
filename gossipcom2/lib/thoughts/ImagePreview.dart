import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gossipcom/thoughts/thoughts_service.dart';
import 'package:image_picker/image_picker.dart';

class Imagepreview extends StatefulWidget {
  final List<XFile> selectedImage;
  // final XFile? capturedImage;

  const Imagepreview({super.key, required this.selectedImage});

  @override
  State<Imagepreview> createState() => _ImagepreviewState();
}

class _ImagepreviewState extends State<Imagepreview> {
  final TextEditingController _captionController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
              child: widget.selectedImage.isNotEmpty
                  ? PageView.builder(
                      itemCount: widget.selectedImage.length,
                      itemBuilder: (context, index) {
                        return Image.file(
                          File(widget.selectedImage[index].path),
                          fit: BoxFit.contain,
                        );
                      })
                  : const Center(
                      child: Text("No image selected"),
                    )),
          // Caption Input and Buttons at the Bottom
          Positioned(
            bottom: 20,
            left: 10,
            right: 10,
            child: Row(
              children: [
                // TextField for Caption
                Expanded(
                  child: TextField(
                    controller: _captionController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: "Enter a caption...",
                      hintStyle: const TextStyle(color: Colors.white54),
                      filled: true,
                      fillColor: Colors.black.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                FloatingActionButton(
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_captionController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("Please enter some caption")));
                          } else {
                            setState(() {
                              _isLoading = true;
                            });

                            try {
                              await ThoughtsService().createThought(
                                thought: _captionController.text,
                                images: widget.selectedImage,
                              );
                              if (mounted) Navigator.pop(context);
                            } catch (e) {
                              debugPrint("Error uploading thought: $e");
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Failed to upload")),
                              );
                            } finally {
                              if (mounted) {
                                setState(() {
                                  _isLoading = false;
                                });
                              }
                            }
                          }
                        },
                  backgroundColor: Colors.blueAccent,
                  child: _isLoading
                      ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                      : const Icon(Icons.send, color: Colors.white),
                ),
              ],
            ),
          ),

          // Close (Cancel) Button at Top-left
          Positioned(
            top: 40,
            left: 10,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
