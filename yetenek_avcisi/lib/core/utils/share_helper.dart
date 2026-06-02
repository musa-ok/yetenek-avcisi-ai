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

  /// iPad/iPhone: küçük, ekran içi anchor (büyük widget rect'i reddedilir).
  static Rect anchorButtonOrigin(GlobalKey key, BuildContext context) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    final screen = MediaQuery.sizeOf(context);
    if (box != null && box.hasSize && box.size.width > 0 && box.size.height > 0) {
      final center = box.localToGlobal(box.size.center(Offset.zero));
      return _clampToScreen(
        Rect.fromCenter(center: center, width: 44, height: 44),
        screen,
      );
    }
    return _clampToScreen(
      Rect.fromLTWH(screen.width - 60, 60, 44, 44),
      screen,
    );
  }

  static Rect _clampToScreen(Rect rect, Size screen) {
    const minSide = 44.0;
    final w = rect.width.clamp(minSide, screen.width);
    final h = rect.height.clamp(minSide, screen.height);
    final left = rect.left.clamp(0.0, screen.width - w);
    final top = rect.top.clamp(0.0, screen.height - h);
    return Rect.fromLTWH(left, top, w, h);
  }

  static Rect _iosOrigin(BuildContext context, {GlobalKey? anchorKey, Rect? override}) {
    if (override != null) {
      return _clampToScreen(override, MediaQuery.sizeOf(context));
    }
    if (anchorKey != null) {
      return anchorButtonOrigin(anchorKey, context);
    }
    final raw = originFor(context);
    final screen = MediaQuery.sizeOf(context);
    if (raw.width > screen.width * 0.6 || raw.height > screen.height * 0.6) {
      return _clampToScreen(
        Rect.fromCenter(center: raw.center, width: 44, height: 44),
        screen,
      );
    }
    return _clampToScreen(raw, screen);
  }

  static Future<void> shareXFiles(
    List<XFile> files, {
    required BuildContext context,
    String? text,
    Rect? sharePositionOrigin,
    GlobalKey? anchorKey,
  }) {
    final origin = (Platform.isIOS || Platform.isMacOS)
        ? _iosOrigin(context, anchorKey: anchorKey, override: sharePositionOrigin)
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
    GlobalKey? anchorKey,
  }) {
    final origin = (Platform.isIOS || Platform.isMacOS)
        ? _iosOrigin(context, anchorKey: anchorKey, override: sharePositionOrigin)
        : sharePositionOrigin;
    return Share.share(
      text,
      sharePositionOrigin: origin,
    );
  }
}
