import 'dart:io';

import 'package:flutter/material.dart';

class ImageViewer {
  static Future<void> showNetwork(BuildContext context, String imageUrl) {
    return _show(context, imageProvider: NetworkImage(imageUrl));
  }

  static Future<void> showFile(BuildContext context, String imagePath) {
    return _show(context, imageProvider: FileImage(File(imagePath)));
  }

  static Future<void> _show(
    BuildContext context, {
    required ImageProvider imageProvider,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black87,
      builder: (dialogContext) {
        return Scaffold(
          backgroundColor: Colors.black87,
          body: SafeArea(
            child: Stack(
              children: [
                Center(
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4,
                    child: Image(
                      image: imageProvider,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 12,
                  child: IconButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}