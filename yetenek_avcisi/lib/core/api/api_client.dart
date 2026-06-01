import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../app_services.dart';

/// Merkezi HTTP istemcisi — Bearer token otomatik eklenir.
class ApiClient {
  ApiClient._();

  static Uri uri(String path) =>
      Uri.parse(kApiBaseUrl).resolve(path.startsWith('/') ? path : '/$path');

  static Map<String, String> headers({
    bool json = true,
    bool authRequired = false,
  }) {
    final h = <String, String>{'Accept': 'application/json'};
    if (json) {
      h['Content-Type'] = 'application/json';
    }
    final token = currentAccessTokenNotifier.value?.trim();
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    } else if (authRequired) {
      throw ApiException(
        'Oturum süresi dolmuş. Lütfen yeniden giriş yapın.',
        401,
      );
    }
    return h;
  }

  static Uri _buildUri(String path, Map<String, String>? query) {
    final base = uri(path);
    if (query == null || query.isEmpty) return base;
    return base.replace(queryParameters: {...base.queryParameters, ...query});
  }

  static Future<http.Response> get(
    String path, {
    Map<String, String>? query,
    bool authRequired = false,
    Duration timeout = const Duration(seconds: 30),
  }) {
    return http
        .get(_buildUri(path, query), headers: headers(authRequired: authRequired))
        .timeout(timeout);
  }

  static Future<http.Response> post(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = false,
    Duration timeout = const Duration(seconds: 30),
  }) {
    return http
        .post(
          uri(path),
          headers: headers(authRequired: authRequired),
          body: body == null ? null : json.encode(body),
        )
        .timeout(timeout);
  }

  static Future<http.Response> put(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = true,
    Duration timeout = const Duration(seconds: 30),
  }) {
    return http
        .put(
          uri(path),
          headers: headers(authRequired: authRequired),
          body: body == null ? null : json.encode(body),
        )
        .timeout(timeout);
  }

  static Future<http.Response> delete(
    String path, {
    bool authRequired = true,
    Duration timeout = const Duration(seconds: 30),
  }) {
    return http
        .delete(uri(path), headers: headers(authRequired: authRequired))
        .timeout(timeout);
  }

  static Future<http.Response> patch(
    String path, {
    Map<String, dynamic>? body,
    bool authRequired = true,
    Duration timeout = const Duration(seconds: 30),
  }) {
    return http
        .patch(
          uri(path),
          headers: headers(authRequired: authRequired),
          body: body == null ? null : json.encode(body),
        )
        .timeout(timeout);
  }

  static ApiException friendlyError(http.Response res) {
    return ApiException(_friendlyMessage(res.body, res.statusCode), res.statusCode);
  }

  static String _friendlyMessage(String body, int status) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map && decoded['detail'] != null) {
        final d = decoded['detail'];
        if (d is String && d.trim().isNotEmpty) return d.trim();
        if (d is List && d.isNotEmpty) return '$d'.trim();
      }
    } catch (_) {}
    return 'Sunucu hatasi ($status).';
  }
}
