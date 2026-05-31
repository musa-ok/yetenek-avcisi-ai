import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

/// iOS/iPadOS paylaşım sayfası için geçerli `sharePositionOrigin`.
class ShareHelper {
  ShareHelper._();

  static Rect originFor(BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize) {
      final size = box.size;
      if (size.width > 0 && size.height > 0) {
        return box.localToGlobal(Offset.zero) & size;
      }
    }
    final media = MediaQuery.sizeOf(context);
    return Rect.fromCenter(
      center: Offset(media.width / 2, media.height * 0.58),
      width: 220,
      height: 56,
    );
  }

  static Rect originFromKey(GlobalKey key, BuildContext context) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
      return box.localToGlobal(Offset.zero) & box.size;
    }
    return originFor(context);
  }

  static Future<void> shareXFiles(
    List<XFile> files, {
    required BuildContext context,
    String? text,
    Rect? sharePositionOrigin,
  }) {
    final origin = (Platform.isIOS || Platform.isMacOS)
        ? (sharePositionOrigin ?? originFor(context))
        : sharePositionOrigin;
    return Share.shareXFiles(
      files,
      text: text,
      sharePositionOrigin: origin,
    );
  }

  static Future<void> shareText(
    String text, {
    required BuildContext context,
    Rect? sharePositionOrigin,
  }) {
    final origin = (Platform.isIOS || Platform.isMacOS)
        ? (sharePositionOrigin ?? originFor(context))
        : sharePositionOrigin;
    return Share.share(
      text,
      sharePositionOrigin: origin,
    );
  }
}
