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

  /// Push hattını uçtan uca test eder ve adım adım rapor döner.
  static Future<PushDiagnosticsReport> runDiagnostics() async {
    final steps = <PushDiagnosticsStep>[];

    void addStep(String name, bool ok, String detail) {
      steps.add(PushDiagnosticsStep(name: name, ok: ok, detail: detail));
    }

    final hasSession = currentAccessTokenNotifier.value != null &&
        currentAccessTokenNotifier.value!.isNotEmpty;
    addStep(
      'Session',
      hasSession,
      hasSession ? 'Oturum token var' : 'Oturum token yok',
    );
    if (!hasSession) {
      return PushDiagnosticsReport(
        createdAt: DateTime.now(),
        steps: steps,
        summary: 'Önce giriş yapmalısın (auth token yok).',
      );
    }

    final appSettingOn = await AppSettings.areNotificationsEnabled();
    addStep(
      'App toggle',
      appSettingOn,
      appSettingOn ? 'Uygulama içi bildirim açık' : 'Uygulama içi bildirim kapalı',
    );

    await initialize();
    addStep(
      'Firebase init',
      _initialized,
      _initialized ? 'Firebase Messaging hazır' : 'Firebase initialize başarısız',
    );
    if (!_initialized) {
      return PushDiagnosticsReport(
        createdAt: DateTime.now(),
        steps: steps,
        summary: 'Firebase initialize başarısız; iOS/Firebase konfigürasyonunu kontrol et.',
      );
    }

    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.getNotificationSettings();
    final status = settings.authorizationStatus;
    final authorized = status == AuthorizationStatus.authorized ||
        status == AuthorizationStatus.provisional;
    addStep(
      'OS permission',
      authorized,
      'authorizationStatus=$status',
    );

    String? apns;
    try {
      apns = await messaging.getAPNSToken();
      if ((apns == null || apns.isEmpty) && defaultTargetPlatform == TargetPlatform.iOS) {
        apns = await _awaitApnsToken(messaging, attempts: 6);
      }
      addStep(
        'APNS token',
        apns != null && apns.isNotEmpty,
        apns != null && apns.isNotEmpty ? 'APNS token var' : 'APNS token yok',
      );
    } catch (e) {
      addStep('APNS token', false, 'APNS token okunamadi: $e');
    }

    String? fcm;
    try {
      fcm = await messaging.getToken();
      if (fcm == null || fcm.isEmpty) {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        fcm = await messaging.getToken();
      }
      addStep(
        'FCM token',
        fcm != null && fcm.isNotEmpty,
        fcm != null && fcm.isNotEmpty ? 'FCM token var' : 'FCM token yok',
      );
    } catch (e) {
      addStep('FCM token', false, 'FCM token okunamadi: $e');
    }

    if (fcm != null && fcm.isNotEmpty) {
      try {
        await BackendApi.registerFcmToken(fcm);
        addStep('Backend register', true, 'register-device çağrısı başarılı');
      } catch (e) {
        addStep('Backend register', false, 'register-device hata: $e');
      }
    } else {
      addStep('Backend register', false, 'FCM token yok, register çağrılmadı');
    }

    try {
      final statusMap = await BackendApi.fetchNotificationDeviceStatus();
      final pushStatus = (statusMap['push_status'] ?? 0).toString();
      addStep(
        'Backend device-status',
        pushStatus == '1',
        'push_status=$pushStatus, has_device_token=${statusMap['has_device_token']}',
      );
    } catch (e) {
      addStep('Backend device-status', false, 'device-status hata: $e');
    }

    final okCount = steps.where((s) => s.ok).length;
    final summary = '$okCount/${steps.length} adım başarılı';
    return PushDiagnosticsReport(
      createdAt: DateTime.now(),
      steps: steps,
      summary: summary,
    );
  }
}

class PushDiagnosticsStep {
  const PushDiagnosticsStep({
    required this.name,
    required this.ok,
    required this.detail,
  });

  final String name;
  final bool ok;
  final String detail;
}

class PushDiagnosticsReport {
  const PushDiagnosticsReport({
    required this.createdAt,
    required this.steps,
    required this.summary,
  });

  final DateTime createdAt;
  final List<PushDiagnosticsStep> steps;
  final String summary;

  String prettyText() {
    final b = StringBuffer();
    b.writeln('Push Diagnostics @ ${createdAt.toIso8601String()}');
    b.writeln(summary);
    for (final s in steps) {
      b.writeln('${s.ok ? '[OK]' : '[FAIL]'} ${s.name}: ${s.detail}');
    }
    return b.toString().trimRight();
  }
}
