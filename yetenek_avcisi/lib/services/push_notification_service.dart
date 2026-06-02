import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yetenek_avcisi/app_services.dart';
import 'package:yetenek_avcisi/core/settings/app_settings.dart';
import 'package:yetenek_avcisi/features/product/product_screens.dart';
import 'package:yetenek_avcisi/firebase_options.dart';
import 'package:yetenek_avcisi/core/navigation/app_navigator.dart';

/// Arka plan / kapali uygulama mesajlari (minimal handler).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('[FCM] background: ${message.notification?.title}');
}

/// FCM token kaydi ve izinler. Firebase yapilandirmasi yoksa sessizce atlanir.
class PushNotificationService {
  PushNotificationService._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    if (kIsWeb) return;

    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      if (kReleaseMode) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      FirebaseMessaging.onMessage.listen((message) async {
        if (!await AppSettings.areNotificationsEnabled()) return;
        debugPrint('[FCM] foreground: ${message.notification?.title}');
      });

      FirebaseMessaging.onMessageOpenedApp.listen(_openNotificationsFromMessage);

      FirebaseMessaging.instance.onTokenRefresh.listen((_) {
        syncTokenWithBackend();
      });

      _initialized = true;
    } catch (e, st) {
      debugPrint('[FCM] init atlandi (Firebase yapilandirmasi gerekli): $e\n$st');
    }
  }

  /// Oturum acildiktan / ayar degisince: aciksa token kaydet, kapaliysa sunucudan sil.
  static Future<void> applyNotificationPreference() async {
    await syncTokenWithBackend();
  }

  /// Splash sonrası — cold start'ta bildirime tıklanmışsa listeyi açar.
  static Future<void> handlePendingLaunchNotification() async {
    if (!_initialized) return;
    try {
      final initial = await FirebaseMessaging.instance.getInitialMessage();
      if (initial == null) return;
      await Future<void>.delayed(const Duration(milliseconds: 500));
      _openNotificationsFromMessage(initial);
    } catch (e) {
      debugPrint('[FCM] cold start bildirim atlandi: $e');
    }
  }

  static void _openNotificationsFromMessage(RemoteMessage message) {
    final nav = appNavigatorKey.currentState;
    if (nav == null || !nav.mounted) return;
    nav.push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsScreen()),
    );
  }

  static Future<void> _openSystemNotificationSettings() async {
    if (kIsWeb) return;
    try {
      final ok = await launchUrl(Uri.parse('app-settings:'));
      if (!ok) {
        debugPrint('[FCM] app-settings acilamadi');
      }
    } catch (e) {
      debugPrint('[FCM] app-settings hatasi: $e');
    }
  }

  static Future<String?> _awaitApnsToken(
    FirebaseMessaging messaging, {
    int attempts = 8,
  }) async {
    for (var i = 0; i < attempts; i++) {
      final apns = await messaging.getAPNSToken();
      if (apns != null && apns.isNotEmpty) return apns;
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    return null;
  }

  static Future<void> syncTokenWithBackend() async {
    final hasSession = currentAccessTokenNotifier.value != null &&
        currentAccessTokenNotifier.value!.isNotEmpty;
    if (!hasSession) return;

    final enabled = await AppSettings.areNotificationsEnabled();
    if (!enabled) {
      await _clearDeviceAndBackendToken();
      return;
    }

    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return;

    try {
      final messaging = FirebaseMessaging.instance;
      var settings = await messaging.getNotificationSettings();
      if (settings.authorizationStatus == AuthorizationStatus.notDetermined) {
        settings = await messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
      }
      final authorized = settings.authorizationStatus ==
              AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!authorized) {
        await AppSettings.setNotificationsEnabled(false);
        await _clearDeviceAndBackendToken();
        debugPrint('[FCM] izin yok, token senkronu atlandi');
        return;
      }

      if (defaultTargetPlatform == TargetPlatform.iOS) {
        await _awaitApnsToken(messaging);
      }

      var token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        // iOS tarafinda APNS gec geldiginde ilk deneme null donuyor.
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        token = await messaging.getToken();
      }
      if (token == null || token.isEmpty) {
        final apns = await messaging.getAPNSToken();
        debugPrint('[FCM] token yok (apns=${apns != null && apns.isNotEmpty})');
        await _clearDeviceAndBackendToken();
        return;
      }
      await BackendApi.registerFcmToken(token);
      debugPrint('[FCM] token backend\'e kaydedildi');
    } catch (e) {
      debugPrint('[FCM] token kaydi basarisiz: $e');
    }
  }

  static Future<void> _clearDeviceAndBackendToken() async {
    if (_initialized) {
      try {
        await FirebaseMessaging.instance.deleteToken();
      } catch (e) {
        debugPrint('[FCM] deleteToken atlandi: $e');
      }
    }
    try {
      if (currentAccessTokenNotifier.value != null &&
          currentAccessTokenNotifier.value!.isNotEmpty) {
        await BackendApi.clearFcmToken();
        debugPrint('[FCM] sunucu token kaldirildi');
      }
    } catch (e) {
      debugPrint('[FCM] backend token temizleme: $e');
      rethrow;
    }
  }

  /// Ayarlar: telefon push ac/kapa (uygulama icindeki Bildirimler listesi ayri kalir).
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await AppSettings.setNotificationsEnabled(enabled);

    if (!enabled) {
      await _clearDeviceAndBackendToken();
      return;
    }

    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) {
      throw StateError('Firebase yapilandirmasi yok; push acilamadi.');
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    final authorized = settings.authorizationStatus ==
            AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional;
    if (!authorized) {
      await AppSettings.setNotificationsEnabled(false);
      await _clearDeviceAndBackendToken();
      await _openSystemNotificationSettings();
      throw StateError(
        'Sistem bildirim izni verilmedi. iPhone Ayarlar → Scoutiq → Bildirimler bölümünden açın.',
      );
    }
    await syncTokenWithBackend();
  }

  static Future<bool> isPushEnabledOnDevice() async {
    return loadEffectivePushEnabled();
  }

  /// Uygulama tercihi + iOS/Android sistem izni birlikte.
  static Future<bool> loadEffectivePushEnabled() async {
    final appOn = await AppSettings.areNotificationsEnabled();
    if (!appOn) return false;
    if (kIsWeb) return false;

    if (!_initialized) {
      await initialize();
    }
    if (!_initialized) return appOn;

    try {
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      final status = settings.authorizationStatus;

      if (status == AuthorizationStatus.denied) {
        await AppSettings.setNotificationsEnabled(false);
        await _clearDeviceAndBackendToken();
        return false;
      }

      if (status != AuthorizationStatus.authorized &&
          status != AuthorizationStatus.provisional) {
        return false;
      }

      await syncTokenWithBackend();
      return true;
    } catch (e) {
      debugPrint('[FCM] izin durumu okunamadi: $e');
      return appOn;
    }
  }

  /// Ayarlar ekranı: anahtar durumu + gerekirse tercihi sistemle hizala.
  static Future<bool> refreshPushPreferenceForSettings() async {
    return loadEffectivePushEnabled();
  }
}
