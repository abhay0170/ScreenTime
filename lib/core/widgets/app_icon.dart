import 'dart:typed_data';

import 'package:flutter/material.dart';

/// A circular app icon, falling back to a generic glyph when no icon
/// bytes are available (e.g. the app couldn't be resolved).
class AppIcon extends StatelessWidget {
  final Uint8List? bytes;
  final double radius;

  const AppIcon({super.key, required this.bytes, this.radius = 18});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundImage: bytes != null ? MemoryImage(bytes!) : null,
      child: bytes == null ? Icon(Icons.apps, size: radius) : null,
    );
  }
}
