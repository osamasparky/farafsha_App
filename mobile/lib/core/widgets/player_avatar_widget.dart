import 'dart:io';
import 'package:flutter/material.dart';

/// ويدجت موحد لعرض صورة اللاعب أو المستخدم (يدعم روابط الشبكة، الملفات المحلية، والأصول المدمجة)
class PlayerAvatarWidget extends StatelessWidget {
  final String avatarPath;
  final double size;
  final String fallbackAsset;

  const PlayerAvatarWidget({
    super.key,
    required this.avatarPath,
    this.size = 40,
    this.fallbackAsset = 'assets/images/av-ahmed.webp',
  });

  String _normalizeAsset(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return fallbackAsset;
    if (trimmed.startsWith('assets/images/av-') && trimmed.endsWith('.png')) {
      return '${trimmed.substring(0, trimmed.length - 4)}.webp';
    }
    return trimmed;
  }

  Widget _buildFallback() {
    return Image.asset(
      fallbackAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        width: size,
        height: size,
        color: const Color(0xFF3A1E6D),
        child: Icon(Icons.person_rounded, color: Colors.white70, size: size * 0.55),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final clean = avatarPath.trim();
    final Widget imageWidget;

    if (clean.isEmpty) {
      imageWidget = _buildFallback();
    } else if (clean.startsWith('http://') || clean.startsWith('https://')) {
      imageWidget = Image.network(
        clean,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else if (!clean.startsWith('assets/') && File(clean).existsSync()) {
      imageWidget = Image.file(
        File(clean),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    } else {
      imageWidget = Image.asset(
        _normalizeAsset(clean),
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildFallback(),
      );
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: imageWidget,
      ),
    );
  }
}
