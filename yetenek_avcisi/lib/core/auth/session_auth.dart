import 'package:http/http.dart' as http;

import '../../app_services.dart';

/// Oturum: access token yenileme ve 401 sonrası tek seferlik retry.
class SessionAuth {
  SessionAuth._();

  static Future<bool>? _refreshInFlight;

  static bool get hasLoggedInUser => currentUserNotifier.value != null;

  /// Uygulama açılışında veya ön plana dönüşte sessiz token yenileme.
  static Future<void> warmSessionAfterRestore() async {
    if (!hasLoggedInUser) return;
    final refresh = await SessionStore.readRefreshToken();
    if (refresh != null && refresh.isNotEmpty) {
      await _refreshAccessTokenOnce();
      return;
    }
    final token = currentAccessTokenNotifier.value?.trim();
    if (token == null || token.isEmpty) {
      await SessionStore.clear();
      return;
    }
    try {
      final user = await BackendApi.fetchCurrentUser();
      await SessionStore.updateUser(user);
    } catch (_) {
      await SessionStore.clear();
    }
  }

  static Future<bool> _refreshAccessTokenOnce() async {
    if (_refreshInFlight != null) {
      return _refreshInFlight!;
    }
    final fut = _doRefresh();
    _refreshInFlight = fut;
    try {
      return await fut;
    } finally {
      if (identical(_refreshInFlight, fut)) {
        _refreshInFlight = null;
      }
    }
  }

  static Future<bool> _doRefresh() async {
    try {
      await BackendApi.refreshAccessToken();
      return true;
    } catch (_) {
      await SessionStore.clear();
      return false;
    }
  }

  /// 401 alınırsa refresh dener ve isteği bir kez daha gönderir.
  static Future<http.Response> execute(
    Future<http.Response> Function() request,
  ) async {
    var response = await request();
    if (response.statusCode != 401) return response;

    final hadSession =
        hasLoggedInUser ||
        (currentAccessTokenNotifier.value?.trim().isNotEmpty ?? false);
    if (!hadSession) return response;

    if (!await _refreshAccessTokenOnce()) return response;
    return request();
  }
}
