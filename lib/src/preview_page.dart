import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_saver_plus/gallery_saver.dart';

class PreviewPage extends StatelessWidget {
  final File imageFile;

  const PreviewPage({super.key, required this.imageFile});

  Future<void> _save(BuildContext context) async {
    await GallerySaver.saveImage(
      imageFile.path,
      albumName: "GPS Camera",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Saved to Gallery 📸"),
      ),
    );

    Navigator.pop(context, imageFile); // return to home
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Image.file(
                imageFile,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // Bottom Buttons
          Positioned(
            bottom: 40,
            left: 30,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.refresh),
              label: const Text("Retake"),
            ),
          ),

          Positioned(
            bottom: 40,
            right: 30,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              onPressed: () => _save(context),
              icon: const Icon(Icons.save),
              label: const Text("Save"),
            ),
          ),
        ],
      ),
    );
  }
}