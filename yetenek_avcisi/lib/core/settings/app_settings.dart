import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama ayarları — SharedPreferences + ağ kontrolü.
class AppSettings {
  AppSettings._();

  static const notificationsKey = 'settings_notifications_enabled';
  static const mobileUploadKey = 'settings_mobile_upload_allowed';

  static Future<bool> areNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(notificationsKey) ?? true;
  }

  static Future<void> setNotificationsEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(notificationsKey, value);
  }

  static Future<bool> isMobileUploadAllowed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(mobileUploadKey) ?? false;
  }

  static Future<void> setMobileUploadAllowed(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(mobileUploadKey, value);
  }

  /// Wi‑Fi veya ethernet (kablolu) bağlantısı.
  static Future<bool> isOnUnmeteredConnection() async {
    final results = await Connectivity().checkConnectivity();
    return results.any(
      (r) =>
          r == ConnectivityResult.wifi || r == ConnectivityResult.ethernet,
    );
  }

  /// Video yükleme: Wi‑Fi'de serbest; mobil veride ayar açıksa izin ver.
  static Future<bool> canUploadVideoOnCurrentNetwork() async {
    if (await isOnUnmeteredConnection()) return true;
    return isMobileUploadAllowed();
  }

  static Future<({bool allowed, bool onWifi})> uploadNetworkStatus() async {
    final onWifi = await isOnUnmeteredConnection();
    if (onWifi) return (allowed: true, onWifi: true);
    final allowed = await isMobileUploadAllowed();
    return (allowed: allowed, onWifi: false);
  }
}
