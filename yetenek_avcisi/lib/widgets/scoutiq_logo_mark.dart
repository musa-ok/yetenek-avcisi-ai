import 'package:flutter/material.dart';

/// Scoutiq marka logosu — launcher ile aynı dürbün ikonu (PNG).
class ScoutiqLogoMark extends StatelessWidget {
  const ScoutiqLogoMark({super.key, this.size = 120});

  final double size;

  static const String assetPath = 'assets/branding/scoutiq_icon.png';

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        assetPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
      ),
    );
  }
}
