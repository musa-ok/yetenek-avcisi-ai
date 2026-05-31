import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// yetenekavcisi://player/123 ve yetenekavcisi://invite/CODE
class DeepLinkService {
  DeepLinkService._();

  static final AppLinks _appLinks = AppLinks();
  static final StreamController<DeepLinkTarget> _controller =
      StreamController.broadcast();

  static Stream<DeepLinkTarget> get stream => _controller.stream;

  static Future<void> init() async {
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        _handleUri(initial);
      }
      _appLinks.uriLinkStream.listen(_handleUri, onError: (e) {
        debugPrint('[DeepLink] $e');
      });
    } catch (e) {
      debugPrint('[DeepLink] init skipped: $e');
    }
  }

  static void _handleUri(Uri uri) {
    final target = parseUri(uri);
    if (target != null) {
      _controller.add(target);
    }
  }

  static DeepLinkTarget? parseUri(Uri uri) {
    final okScheme = uri.scheme == 'yetenekavcisi';
    final okHttps = uri.scheme == 'https' &&
        (uri.host.contains('yetenekavcisi') || uri.host.contains('scoutiq'));
    if (!okScheme && !okHttps) return null;

    final segs = uri.pathSegments;

    if (uri.host == 'player' && segs.isNotEmpty) {
      final id = int.tryParse(segs.first);
      if (id != null) return player(id);
    }
    if (uri.host == 'invite' && segs.isNotEmpty) {
      final code = segs.first.toUpperCase();
      persistPendingInvite(code);
      return invite(code);
    }

    if (segs.isEmpty) return null;
    if (segs.first == 'player' && segs.length >= 2) {
      final id = int.tryParse(segs[1]);
      if (id != null) return player(id);
    }
    if (segs.first == 'invite' && segs.length >= 2) {
      final code = segs[1].toUpperCase();
      persistPendingInvite(code);
      return invite(code);
    }
    return null;
  }

  static Future<void> persistPendingInvite(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pending_referral_code', code);
  }

  static Future<String?> consumePendingInvite() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('pending_referral_code');
    if (code != null) await prefs.remove('pending_referral_code');
    return code;
  }
}

sealed class DeepLinkTarget {}

class DeepLinkPlayer extends DeepLinkTarget {
  DeepLinkPlayer(this.playerId);
  final int playerId;
}

class DeepLinkInvite extends DeepLinkTarget {
  DeepLinkInvite(this.code);
  final String code;
}

// Alias factories for pattern matching simplicity
DeepLinkTarget player(int id) => DeepLinkPlayer(id);
DeepLinkTarget invite(String code) => DeepLinkInvite(code);
