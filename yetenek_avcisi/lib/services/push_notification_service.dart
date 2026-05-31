import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:yetenek_avcisi/app_services.dart';
import 'package:yetenek_avcisi/core/settings/app_settings.dart';
import 'package:yetenek_avcisi/firebase_options.dart';

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
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final messaging = FirebaseMessaging.instance;
      if (await AppSettings.areNotificationsEnabled()) {
        await messaging.requestPermission(alert: true, badge: true, sound: true);
      }

      FirebaseMessaging.onMessage.listen((message) async {
        if (!await AppSettings.areNotificationsEnabled()) return;
        debugPrint('[FCM] foreground: ${message.notification?.title}');
      });

      FirebaseMessaging.instance.onTokenRefresh.listen((_) {
        syncTokenWithBackend();
      });

      _initialized = true;
      await syncTokenWithBackend();
    } catch (e, st) {
      debugPrint('[FCM] init atlandi (Firebase yapilandirmasi gerekli): $e\n$st');
    }
  }

  static Future<void> syncTokenWithBackend() async {
    if (!_initialized) return;
    if (!await AppSettings.areNotificationsEnabled()) return;
    if (currentAccessTokenNotifier.value == null ||
        currentAccessTokenNotifier.value!.isEmpty) {
      return;
    }
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) return;
      await BackendApi.registerFcmToken(token);
      debugPrint('[FCM] token backend\'e kaydedildi');
    } catch (e) {
      debugPrint('[FCM] token kaydi basarisiz: $e');
    }
  }

  /// Ayarlar ekranından bildirim aç/kapa (tercih her zaman kaydedilir; FCM hata verse de UI kırılmaz).
  static Future<void> setNotificationsEnabled(bool enabled) async {
    await AppSettings.setNotificationsEnabled(enabled);
    if (!_initialized) return;

    try {
      if (enabled) {
        await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        await syncTokenWithBackend();
      } else {
        try {
          await FirebaseMessaging.instance.deleteToken();
        } catch (e) {
          debugPrint('[FCM] deleteToken atlandi: $e');
        }
        try {
          if (currentAccessTokenNotifier.value != null &&
              currentAccessTokenNotifier.value!.isNotEmpty) {
            await BackendApi.clearFcmToken();
          }
        } catch (e) {
          debugPrint('[FCM] backend token temizleme atlandi: $e');
        }
        debugPrint('[FCM] bildirimler kapatildi');
      }
    } catch (e) {
      debugPrint('[FCM] FCM islemi atlandi (tercih kayitli): $e');
    }
  }
}
