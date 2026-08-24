import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class FileBadgeIcon extends StatelessWidget {
  final String extension;
  final Color color;
  final double size;

  const FileBadgeIcon({
    super.key,
    required this.extension,
    required this.color,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) {
    // Determine the string to show (max 4 chars for UI neatness)
    String displayExt = extension.toUpperCase();
    if (displayExt.length > 4) {
      displayExt = displayExt.substring(0, 4);
    }
    if (displayExt.isEmpty) {
      displayExt = 'FILE';
    }

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Icon(
            LucideIcons.file,
            size: size,
            color: color,
          ),
          Positioned(
            bottom: size * 0.15,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: size * 0.1, vertical: 0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: color, width: (size * 0.05).clamp(1.0, 3.0)),
                borderRadius: BorderRadius.circular(size * 0.15),
              ),
              child: Text(
                displayExt,
                style: TextStyle(
                  color: color,
                  fontSize: size * 0.28,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
