import 'package:sign_in_with_apple/sign_in_with_apple.dart';

/// Google / Apple sosyal giriş için isim ve e-posta normalizasyonu.
class SocialAuthHelper {
  SocialAuthHelper._();

  static bool isApplePrivateRelay(String email) =>
      email.toLowerCase().contains('privaterelay.appleid.com');

  static bool isInternalAppleEmail(String email) =>
      email.toLowerCase().endsWith('@private.yetenekavcisi.app');

  /// Apple relay veya opaque ID gibi görünen metinler.
  static bool looksLikeOpaqueToken(String value) {
    final v = value.trim();
    if (v.isEmpty) return true;
    if (RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-', caseSensitive: false).hasMatch(v)) {
      return true;
    }
    // 001234.abcd1234.5678 veya uzun hex
    if (RegExp(r'^[0-9]{3,}\.[0-9a-zA-Z.-]+\.[0-9a-zA-Z.-]+$').hasMatch(v)) {
      return true;
    }
    if (RegExp(r'^[0-9a-f]{16,}$', caseSensitive: false).hasMatch(v)) {
      return true;
    }
    return false;
  }

  static String resolveAppleFullName(AuthorizationCredentialAppleID credential) {
    final given = credential.givenName?.trim() ?? '';
    final family = credential.familyName?.trim() ?? '';
    return '$given $family'.trim();
  }

  /// İlk girişte Apple e-posta verebilir; sonraki girişlerde null — backend provider_id ile bulur.
  static String resolveAppleEmailForApi(AuthorizationCredentialAppleID credential) {
    final raw = credential.email?.trim().toLowerCase() ?? '';
    if (raw.isNotEmpty) return raw;
    final pid = credential.userIdentifier?.trim() ?? '';
    if (pid.isEmpty) return '';
    return 'apple_$pid@private.yetenekavcisi.app';
  }

  static String sanitizeDisplayName({
    required String fullName,
    required String email,
    String fallback = 'Kullanıcı',
  }) {
    final name = fullName.trim();
    if (name.isNotEmpty &&
        !looksLikeOpaqueToken(name) &&
        name.toLowerCase() != email.split('@').first.toLowerCase()) {
      return name;
    }

    if (email.isNotEmpty &&
        !isApplePrivateRelay(email) &&
        !isInternalAppleEmail(email)) {
      final local = email.split('@').first;
      if (!looksLikeOpaqueToken(local)) {
        final cleaned = local.replaceAll(RegExp(r'[._-]+'), ' ').trim();
        if (cleaned.length >= 2) {
          return cleaned
              .split(' ')
              .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
              .join(' ');
        }
      }
    }

    return fallback;
  }

  static String formatEmailForDisplay(String email) {
    if (email.isEmpty) return '';
    if (isApplePrivateRelay(email) || isInternalAppleEmail(email)) {
      return 'Apple ile doğrulandı (gizli e-posta)';
    }
    return email;
  }

  static bool needsManualNameEntry(String fullName, String email) {
    final name = fullName.trim();
    if (name.isEmpty) return true;
    if (looksLikeOpaqueToken(name)) return true;
    if (name.toLowerCase() == email.split('@').first.toLowerCase()) return true;
    return false;
  }
}
