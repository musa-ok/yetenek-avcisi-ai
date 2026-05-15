import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Match your FastAPI base URL
/// iOS Simulator: http://127.0.0.1:8000
/// Android Emulator: http://10.0.2.2:8000
/// Physical Device: http://<YOUR_MAC_IP>:8000 (e.g., http://1.1.13.182:8000)
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'https://yetenek-avcisi-ai.onrender.com', // Production: Render
);

final ValueNotifier<AuthenticatedUser?> currentUserNotifier =
    ValueNotifier<AuthenticatedUser?>(null);
final ValueNotifier<String?> currentAccessTokenNotifier =
    ValueNotifier<String?>(null);

class AuthSession {
  const AuthSession({required this.user, required this.accessToken});

  final AuthenticatedUser user;
  final String accessToken;
}

class AuthenticatedUser {
  const AuthenticatedUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.phoneNumber,
    this.profileImageUrl,
    this.birthDate,
    this.age,
    this.isVerified = false,
  });

  final int id;
  final String fullName;
  final String email;
  final String role;
  final String? phoneNumber;
  final String? profileImageUrl;
  final String? birthDate;
  final int? age;
  final bool isVerified;

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'role': role,
    if (phoneNumber != null && phoneNumber!.isNotEmpty)
      'phone_number': phoneNumber,
    if (profileImageUrl != null)
      'profile_image_url': profileImageUrl,
    if (birthDate != null)
      'birth_date': birthDate,
    if (age != null)
      'age': age,
    'is_verified': isVerified,
  };

  factory AuthenticatedUser.fromJson(Map<String, dynamic> m) {
    final idRaw = m['id'];
    final id = switch (idRaw) {
      int v => v,
      _ => int.tryParse('$idRaw') ?? 0,
    };
    final name = '${m['full_name'] ?? m['fullName'] ?? ''}'.trim();
    final email = '${m['email'] ?? ''}'.trim();
    final role = '${m['role'] ?? 'Futbolcu'}'.trim();
    final phone = _readOptionalString(m, 'phone_number', 'phoneNumber');
    final profileImage = _readOptionalString(m, 'profile_image_url', 'profileImageUrl');
    final birth = _readOptionalString(m, 'birth_date', 'birthDate');
    final ageRaw = m['age'];
    final age = ageRaw is int ? ageRaw : (int.tryParse('$ageRaw') ?? 18);
    final isVerified = m['is_verified'] == true || m['isVerified'] == true;
    return AuthenticatedUser(
      id: id,
      fullName: name.isEmpty ? email.split('@').first : name,
      email: email,
      role: role,
      phoneNumber: phone,
      profileImageUrl: profileImage,
      birthDate: birth,
      age: age,
      isVerified: isVerified,
    );
  }
}

class ScoutRating {
  const ScoutRating({required this.scoutName, required this.score});
  final String scoutName;
  final int score;

  factory ScoutRating.fromJson(Map<String, dynamic> m) {
    final raw = m['score'] ?? m['overall'] ?? 0;
    final score = switch (raw) {
      int v => v,
      num v => v.toInt(),
      String v when int.tryParse(v) != null => int.parse(v),
      _ => 0,
    };
    return ScoutRating(
      scoutName: '${m['scout_name'] ?? m['scoutName'] ?? 'Scout'}',
      score: score,
    );
  }
}

class PlayerListItem {
  const PlayerListItem({
    required this.id,
    required this.name,
    required this.age,
    required this.position,
    required this.overallRating,
    this.profileImageUrl,
    this.phoneNumber,
    this.aiScoutReport,
    this.videoUrl,
    this.source = 'legacy',
    this.scoutRatings = const [],
    this.pac,
    this.sho,
    this.pas,
    this.dri,
    this.def,
    this.phy,
  });

  final int id;
  final String name;
  final int age;
  final String position;
  final int overallRating;
  final String? profileImageUrl;
  final String? phoneNumber;
  final String? aiScoutReport;
  final String? videoUrl;
  final String source;
  final List<ScoutRating> scoutRatings;
  final int? pac;
  final int? sho;
  final int? pas;
  final int? dri;
  final int? def;
  final int? phy;

  factory PlayerListItem.fromJson(Map<String, dynamic> m) {
    final idRaw = m['id'];
    final id = switch (idRaw) {
      int v => v,
      _ => int.tryParse('$idRaw') ?? 0,
    };
    final name = '${m['name'] ?? ''}'.trim();
    final ageRaw = m['age'];
    final age = switch (ageRaw) {
      int v => v,
      num v => v.toInt(),
      String v when int.tryParse(v) != null => int.parse(v),
      _ => 0,
    };
    final position = '${m['position'] ?? ''}'.trim();
    final ovrRaw = m['overall_rating'] ?? m['overallRating'];
    final overall = switch (ovrRaw) {
      int v => v,
      num v => v.toInt(),
      String v when int.tryParse(v) != null => int.parse(v),
      _ => 0,
    };
    int? readSkill(List<String> keys) {
      for (final k in keys) {
        final v = m[k];
        if (v == null) continue;
        if (v is int) return v == 0 ? null : v;
        if (v is double) return v == 0.0 ? null : v.toInt();
        if (v is num) return v == 0 ? null : v.toInt();
        if (v is String) {
          final parsed = int.tryParse(v);
          if (parsed != null && parsed != 0) return parsed;
        }
      }
      return null;
    }

    return PlayerListItem(
      id: id,
      name: name.isEmpty ? 'Oyuncu #$id' : name,
      age: age,
      position: position,
      overallRating: overall,
      profileImageUrl: _readOptionalString(m, 'profile_image', 'profileImage', 'profile_photo'),
      phoneNumber: _readOptionalString(m, 'phone_number', 'phoneNumber', 'mobile'),
      aiScoutReport: _readOptionalString(m, 'ai_scout_report', 'aiScoutReport', 'scout_raporu'),
      videoUrl: _readOptionalString(m, 'video_url', 'videoUrl', 'video'),
      source: '${m['source'] ?? 'legacy'}',
      pac: readSkill(const ['pac', 'pace']),
      sho: readSkill(const ['sho', 'shooting']),
      pas: readSkill(const ['pas', 'passing']),
      dri: readSkill(const ['dri', 'dribbling']),
      def: readSkill(const ['def_', 'defending', 'def']),
      phy: readSkill(const ['phy', 'strength', 'physical']),
      scoutRatings: (m['scout_ratings'] is List)
          ? (m['scout_ratings'] as List)
                .whereType<Map<String, dynamic>>()
                .map(ScoutRating.fromJson)
                .toList()
          : const [],
    );
  }
}

class PlayerRatingPayload {
  const PlayerRatingPayload({
    required this.pac,
    required this.sho,
    required this.pas,
    required this.dri,
    required this.def,
    required this.phy,
  });

  final int pac;
  final int sho;
  final int pas;
  final int dri;
  final int def;
  final int phy;

  Map<String, dynamic> toJson() => {
    'pac': pac,
    'sho': sho,
    'pas': pas,
    'dri': dri,
    'def': def,
    'phy': phy,
  };
}

class PlayerRatingSummary {
  const PlayerRatingSummary({
    required this.ovr,
    required this.pac,
    required this.sho,
    required this.pas,
    required this.dri,
    required this.def,
    required this.phy,
    this.profileImageUrl,
  });

  final int ovr;
  final int pac;
  final int sho;
  final int pas;
  final int dri;
  final int def;
  final int phy;
  final String? profileImageUrl;

  // Helper getter - eğer değer 0 veya null ise overallRating kullan
  int get effectivePac => pac > 0 ? pac : ovr;
  int get effectiveSho => sho > 0 ? sho : ovr;
  int get effectivePas => pas > 0 ? pas : ovr;
  int get effectiveDri => dri > 0 ? dri : ovr;
  int get effectiveDef => def > 0 ? def : ovr;
  int get effectivePhy => phy > 0 ? phy : ovr;

  factory PlayerRatingSummary.fromPlayer(PlayerListItem player) {
    return PlayerRatingSummary(
      ovr: player.overallRating,
      pac: player.overallRating,
      sho: player.overallRating,
      pas: player.overallRating,
      dri: player.overallRating,
      def: player.overallRating,
      phy: player.overallRating,
      profileImageUrl: player.profileImageUrl,
    );
  }

  // PlayerListItem'dan gerçek skill değerlerini oku - 0 veya null ise overallRating kullan
  factory PlayerRatingSummary.fromMultiVideoPlayer(PlayerListItem player) {
    final int ovr = player.overallRating;
    final int effectivePac = (player.pac != null && player.pac! > 0) ? player.pac! : ovr;
    final int effectiveSho = (player.sho != null && player.sho! > 0) ? player.sho! : ovr;
    final int effectivePas = (player.pas != null && player.pas! > 0) ? player.pas! : ovr;
    final int effectiveDri = (player.dri != null && player.dri! > 0) ? player.dri! : ovr;
    final int effectiveDef = (player.def != null && player.def! > 0) ? player.def! : ovr;
    final int effectivePhy = (player.phy != null && player.phy! > 0) ? player.phy! : ovr;
    return PlayerRatingSummary(
      ovr: ovr,
      pac: effectivePac,
      sho: effectiveSho,
      pas: effectivePas,
      dri: effectiveDri,
      def: effectiveDef,
      phy: effectivePhy,
      profileImageUrl: player.profileImageUrl,
    );
  }

  factory PlayerRatingSummary.fromJson(Map<String, dynamic> m) {
    int readInt(List<String> keys, int fallback) {
      for (final key in keys) {
        final value = m[key];
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          if (parsed != null) return parsed;
        }
      }
      return fallback;
    }

    final inferredOverall = readInt(const [
      'overall_rating',
      'overall',
      'ovr',
      'average_ovr',
    ], -1);
    final pac = readInt(const ['pac', 'pace', 'avg_pac', 'average_pac'], 0);
    final sho = readInt(const ['sho', 'shooting', 'avg_sho', 'average_sho'], 0);
    final pas = readInt(const ['pas', 'passing', 'avg_pas', 'average_pas'], 0);
    final dri = readInt(const [
      'dri',
      'dribbling',
      'avg_dri',
      'average_dri',
    ], 0);
    final def = readInt(const ['def', 'defense', 'avg_def', 'average_def'], 0);
    final phy = readInt(const ['phy', 'physical', 'avg_phy', 'average_phy'], 0);

    final computedOverall = inferredOverall >= 0
        ? inferredOverall
        : ((pac + sho + pas + dri + def + phy) / 6).round();

    return PlayerRatingSummary(
      ovr: computedOverall,
      pac: pac,
      sho: sho,
      pas: pas,
      dri: dri,
      def: def,
      phy: phy,
      profileImageUrl: _readOptionalString(
        m,
        'profile_image',
        'profileImage',
        'profile_photo',
      ),
    );
  }
}

String? _readOptionalString(
  Map<String, dynamic> m,
  String a,
  String b, [
  String? c,
]) {
  for (final k in <String>[a, b, if (c != null && c.trim().isNotEmpty) c]) {
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);
  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Normalizes arbitrary phone input into digits [country][national] suitable for whatsapp URI.
String whatsAppDigitsOnly(String raw) {
  final digitsOnly = raw.replaceAll(RegExp(r'\D'), '');
  if (digitsOnly.isEmpty) return '';
  String d = digitsOnly;
  if (d.startsWith('90') || d.startsWith('1') || d.length > 10) return d;
  if (d.length == 10 && d.startsWith('5')) {
    return '90$d';
  }
  if (d.startsWith('0') && d.length >= 10) {
    d = d.substring(1);
    if (d.length == 10 && d.startsWith('5')) return '90$d';
  }
  return d;
}

Future<void> openWhatsAppConversation({
  required String phoneRaw,
  String? prefilledMessage,
}) async {
  final digits = whatsAppDigitsOnly(phoneRaw);
  if (digits.isEmpty) {
    throw ArgumentError.value(phoneRaw, 'phoneRaw', 'No digits');
  }
  final text = prefilledMessage?.trim().isEmpty ?? true
      ? ''
      : Uri.encodeComponent(prefilledMessage!.trim());

  final appUri = Uri.parse(
    'whatsapp://send?phone=$digits${text.isEmpty ? '' : '&text=$text'}',
  );
  if (await canLaunchUrl(appUri)) {
    final ok = await launchUrl(appUri, mode: LaunchMode.externalApplication);
    if (ok) return;
  }
  final httpsUri = Uri.parse(
    'https://wa.me/$digits${text.isEmpty ? '' : '?text=$text'}',
  );
  await launchUrl(httpsUri, mode: LaunchMode.externalApplication);
}

class SessionStore {
  static const String _authKey = 'auth_user_json';
  static const String _tokenKey = 'auth_access_token';

  static Future<void> restoreIntoNotifier() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_authKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final map = json.decode(raw);
      if (map is Map<String, dynamic>) {
        currentUserNotifier.value = AuthenticatedUser.fromJson(map);
      }
      final token = prefs.getString(_tokenKey)?.trim();
      currentAccessTokenNotifier.value = (token != null && token.isNotEmpty)
          ? token
          : null;
    } catch (_) {
      await prefs.remove(_authKey);
      await prefs.remove(_tokenKey);
    }
  }

  static Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, json.encode(session.user.toJson()));
    await prefs.setString(_tokenKey, session.accessToken);
    currentUserNotifier.value = session.user;
    currentAccessTokenNotifier.value = session.accessToken;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.remove(_tokenKey);
    currentUserNotifier.value = null;
    currentAccessTokenNotifier.value = null;
  }
}

class BackendApi {
  BackendApi._();

  static Uri _uri(String path) =>
      Uri.parse(kApiBaseUrl).resolve(path.startsWith('/') ? path : '/$path');

  static Map<String, String> _jsonHeaders({bool authRequired = false}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final token = currentAccessTokenNotifier.value?.trim();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    } else if (authRequired) {
      throw ApiException(
        'Oturum suresi dolmus. Lutfen yeniden giris yapin.',
        401,
      );
    }
    return headers;
  }

  /// YENİ KAYIT SİSTEMİ - /auth/register
  /// Token DÖNMEZ! Sadece başarı mesajı döner.
  static Future<Map<String, dynamic>> register({
    required String fullName,
    required String email,
    required String password,
    required String role,
    required String phoneNumber,
    String? birthDate,
    int? age,
  }) async {
    final body = json.encode({
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password,
      'role': role,
      'phone_number': phoneNumber.trim(),
      if (birthDate != null) 'birth_date': birthDate,
      if (age != null) 'age': age,
    });

    // YENİ ENDPOINT: /auth/register
    final res = await http
        .post(_uri('/auth/register'), headers: _jsonHeaders(), body: body)
        .timeout(const Duration(seconds: 90));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = json.decode(res.body);
      // Sadece mesaj dönüyor: {"message": "...", "email": "...", "requires_verification": true}
      return decoded as Map<String, dynamic>;
    }
    throw _friendlyError(res);
  }

  /// YENİ GİRİŞ SİSTEMİ - /auth/login
  /// Sadece is_verified=True kullanıcılar giriş yapabilir
  static Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final body = json.encode({'email': email.trim(), 'password': password});

    // YENİ ENDPOINT: /auth/login
    final res = await http
        .post(_uri('/auth/login'), headers: _jsonHeaders(), body: body)
        .timeout(const Duration(seconds: 90));

    if (res.statusCode == 403) {
      // Doğrulanmamış kullanıcı
      throw ApiException('Lütfen önce e-posta adresinizi doğrulayın.', 403);
    }

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = json.decode(res.body);
      final token = '${decoded['access_token'] ?? ''}'.trim();
      if (token.isEmpty) throw ApiException('Token alınamadı', 500);
      
      final userMap = decoded['user'] as Map<String, dynamic>?;
      if (userMap == null) throw ApiException('Kullanıcı bilgisi alınamadı', 500);
      
      final user = AuthenticatedUser.fromJson(userMap);
      return AuthSession(user: user, accessToken: token);
    }

    throw ApiException(
      res.statusCode == 401 ? 'E-posta veya şifre hatalı.' : _friendlyErrorMsg(res.body, res.statusCode),
      res.statusCode,
    );
  }

  static AuthSession? _tryParseLoggedInSession(
    http.Response res,
    String email,
  ) {
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    try {
      final decoded = json.decode(res.body);
      if (decoded is! Map<String, dynamic>) return null;
      final token = '${decoded['access_token'] ?? ''}'.trim();
      if (token.isEmpty) return null;
      Map<String, dynamic>? uMap;
      final rawUser = decoded['user'];
      if (rawUser is Map<String, dynamic>) uMap = rawUser;
      if (uMap != null &&
          uMap['id'] != null &&
          (uMap['email'] != null || email.isNotEmpty)) {
        return AuthSession(
          accessToken: token,
          user: AuthenticatedUser.fromJson(
            uMap,
          ).copyEnsuringFields(emailOverride: email.trim()),
        );
      }
    } catch (_) {}
    return null;
  }

  static Future<AuthSession?> _tryParseTokenResponse(
    http.Response res,
    String email,
  ) async {
    if (res.statusCode < 200 || res.statusCode >= 300) return null;
    try {
      final decoded = json.decode(res.body);
      if (decoded is! Map<String, dynamic>) return null;
      final token = '${decoded['access_token'] ?? ''}'.trim();
      if (token.isEmpty) return null;
      final me = await http
          .get(
            _uri('/me'),
            headers: {
              'Accept': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 30));
      if (me.statusCode < 200 || me.statusCode >= 300) return null;
      final meDecoded = json.decode(me.body);
      if (meDecoded is! Map<String, dynamic>) return null;
      return AuthSession(
        accessToken: token,
        user: AuthenticatedUser.fromJson(
          meDecoded,
        ).copyEnsuringFields(emailOverride: email.trim()),
      );
    } catch (_) {
      return null;
    }
  }

  /// GET /players — returns `[{ ... }]`.
  static Future<List<PlayerListItem>> fetchPlayers() async {
    final res = await http
        .get(_uri('/players'), headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw _friendlyError(res);
    }
    final decoded = json.decode(res.body);
    if (decoded is List) {
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(PlayerListItem.fromJson)
          .toList();
    }
    throw ApiException('Oyuncu listesi formatı beklenmiyordu.', res.statusCode);
  }

  static Future<PlayerRatingSummary> fetchPlayerRatingSummary(
    int playerId,
  ) async {
    final res = await http
        .get(_uri('/players/$playerId'), headers: _jsonHeaders())
        .timeout(const Duration(seconds: 30));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _friendlyError(res);
    }
    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) {
      final ratingMap = _extractRatingMap(decoded);
      return PlayerRatingSummary.fromJson(ratingMap);
    }
    throw ApiException('Oyuncu puani formati beklenmiyordu.', res.statusCode);
  }

  static Future<PlayerRatingSummary> ratePlayer({
    required int playerId,
    required PlayerRatingPayload payload,
    String source = 'legacy',
  }) async {
    final path = source == 'multivideo'
        ? '/players/multivideo/$playerId/rate'
        : '/players/$playerId/rate';
    final res = await http
        .post(
          _uri(path),
          headers: _jsonHeaders(authRequired: true),
          body: json.encode(payload.toJson()),
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _friendlyError(res);
    }

    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) {
      final ratingMap = _extractRatingMap(decoded);
      return PlayerRatingSummary.fromJson(ratingMap);
    }
    throw ApiException('Puanlama cevabi gecersiz formatta.', res.statusCode);
  }

  static ApiException _friendlyError(http.Response res) {
    return ApiException(
      _friendlyErrorMsg(res.body, res.statusCode),
      res.statusCode,
    );
  }

  static String _friendlyErrorMsg(String body, int status) {
    try {
      final decoded = json.decode(body);
      if (decoded is Map && decoded['detail'] != null) {
        final d = decoded['detail'];
        if (d is String && d.trim().isNotEmpty) return d.trim();
        if (d is List && d.isNotEmpty) return '$d'.trim();
      }
    } catch (_) {}
    return 'Sunucu hatası ($status).';
  }

  static Map<String, dynamic> _extractRatingMap(Map<String, dynamic> root) {
    final candidates = [
      root['rating'],
      root['ratings'],
      root['averages'],
      root['data'],
      root['player'],
      root['player_detail'],
      root['community_rating'],
    ];
    for (final item in candidates) {
      if (item is Map<String, dynamic>) return item;
    }
    return root;
  }

  /// Kullanıcı profili güncelle (PUT /me)
  static Future<AuthenticatedUser> updateUserProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (profileImageUrl != null) body['profile_image_url'] = profileImageUrl;

    final res = await http.put(
      _uri('/me'),
      headers: _jsonHeaders(authRequired: true),
      body: json.encode(body),
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return AuthenticatedUser.fromJson(decoded);
    }
    throw _friendlyError(res);
  }

  /// POST /auth/forgot-password — Şifre sıfırlama kodu gönderir
  static Future<void> forgotPassword({required String email}) async {
    final res = await http
        .post(
          _uri('/auth/forgot-password'),
          headers: _jsonHeaders(),
          body: json.encode({'email': email.trim()}),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw _friendlyError(res);
  }

  /// POST /auth/reset-password — OTP koduyla şifreyi sıfırlar
  static Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final res = await http
        .post(
          _uri('/auth/reset-password'),
          headers: _jsonHeaders(),
          body: json.encode({
            'email': email.trim(),
            'code': code.trim(),
            'new_password': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    throw _friendlyError(res);
  }

  /// SOSYAL MEDYA GİRİŞ - Mevcut kullanıcı kontrolü
  /// status: "complete" -> Kullanıcı var, token döner
  /// status: "incomplete" -> Yeni kullanıcı, profil tamamlanmalı
  static Future<SocialLoginResult> socialLogin({
    required String provider,
    required String email,
    required String fullName,
    String? providerId,
    String? accessToken,
  }) async {
    final body = json.encode({
      'provider': provider,
      'email': email.trim(),
      'full_name': fullName.trim(),
      'provider_id': providerId,
      'access_token': accessToken,
    });

    final res = await http
        .post(
          _uri('/auth/social'),
          headers: _jsonHeaders(),
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = json.decode(res.body) as Map<String, dynamic>;
      
      if (decoded['status'] == 'incomplete') {
        // Kullanıcı yok, profil tamamlama gerekli
        return SocialLoginResult(
          status: 'incomplete',
          email: email,
          fullName: fullName,
          provider: provider,
          providerId: providerId,
        );
      }
      
      // status == 'complete' → token ve user doğrudan parse et
      final token = '${decoded['access_token'] ?? ''}'.trim();
      final userMap = decoded['user'] as Map<String, dynamic>?;
      
      if (token.isNotEmpty && userMap != null) {
        // Sosyal login = her zaman doğrulanmış
        final user = AuthenticatedUser.fromJson(userMap)
            .copyEnsuringFields(emailOverride: email.trim(), isVerifiedOverride: true);
        return SocialLoginResult(
          status: 'complete',
          session: AuthSession(user: user, accessToken: token),
        );
      }
    }
    
    throw _friendlyError(res);
  }

  /// SOSYAL MEDYA KAYIT - Profil tamamlama sonrası
  static Future<AuthSession> socialRegister({
    required String email,
    required String fullName,
    required String phoneNumber,
    required String role,
    required String provider,
    String? providerId,
    String? birthDate,
  }) async {
    final body = json.encode({
      'email': email.trim(),
      'full_name': fullName.trim(),
      'phone_number': phoneNumber.trim(),
      'role': role,
      'provider': provider,
      'provider_id': providerId,
      if (birthDate != null) 'birth_date': birthDate,
    });

    final res = await http
        .post(
          _uri('/auth/social/register'),
          headers: _jsonHeaders(),
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final session = _tryParseLoggedInSession(res, email);
      if (session != null) return session;
    }
    
    throw _friendlyError(res);
  }

  /// OTP KOD GÖNDER (eski endpoint - geriye dönük uyumluluk)
  static Future<void> sendOtp({
    required String email,
  }) => resendOtp(email: email);

  /// OTP YENİDEN GÖNDER - DB tabanlı, sunucu yeniden başlasa bile çalışır
  static Future<void> resendOtp({
    required String email,
  }) async {
    final body = json.encode({'email': email.trim()});

    final res = await http
        .post(
          _uri('/auth/resend-otp'),
          headers: _jsonHeaders(),
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _friendlyError(res);
    }
  }

  /// OTP KOD DOĞRULA - Returns AuthSession on success
  static Future<AuthSession> verifyOtp({
    required String email,
    required String code,
  }) async {
    final body = json.encode({
      'email': email.trim(),
      'code': code.trim(),
    });

    final res = await http
        .post(
          _uri('/auth/verify-otp'),
          headers: _jsonHeaders(),
          body: body,
        )
        .timeout(const Duration(seconds: 30));

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _friendlyError(res);
    }

    // Parse response and create session
    final data = json.decode(res.body);
    final token = data['access_token'] as String?;
    final userMap = data['user'];
    
    if (token == null || token.isEmpty) {
      throw ApiException('Token alınamadı', 500);
    }
    if (userMap == null || userMap is! Map<String, dynamic>) {
      throw ApiException('Kullanıcı bilgisi alınamadı', 500);
    }
    
    final user = AuthenticatedUser.fromJson(userMap);
    return AuthSession(user: user, accessToken: token);
  }

}

/// Sosyal giriş sonuç modeli
class SocialLoginResult {
  final String status; // 'complete' veya 'incomplete'
  final AuthSession? session;
  final String? email;
  final String? fullName;
  final String? provider;
  final String? providerId;

  SocialLoginResult({
    required this.status,
    this.session,
    this.email,
    this.fullName,
    this.provider,
    this.providerId,
  });

  bool get isComplete => status == 'complete';
  bool get isIncomplete => status == 'incomplete';
}

extension AuthenticatedUserCopyExt on AuthenticatedUser {
  AuthenticatedUser copyEnsuringFields({
    String? fullNameOverride,
    String? emailOverride,
    String? roleOverride,
    String? phoneOverride,
    bool? isVerifiedOverride,
  }) {
    final String? resolvedPhone = switch (phoneOverride) {
      null =>
        phoneNumber?.trim().isNotEmpty ?? false ? phoneNumber!.trim() : null,
      final raw when raw.trim().isEmpty =>
        phoneNumber?.trim().isNotEmpty ?? false ? phoneNumber!.trim() : null,
      final raw => raw.trim(),
    };

    return AuthenticatedUser(
      id: id,
      fullName: (fullNameOverride != null && fullNameOverride.trim().isNotEmpty)
          ? fullNameOverride.trim()
          : fullName,
      email: (emailOverride != null && emailOverride.trim().isNotEmpty)
          ? emailOverride.trim()
          : email,
      role: (roleOverride != null && roleOverride.trim().isNotEmpty)
          ? roleOverride.trim()
          : role,
      phoneNumber: resolvedPhone,
      profileImageUrl: profileImageUrl,
      birthDate: birthDate,
      age: age,
      isVerified: isVerifiedOverride ?? isVerified,
    );
  }
}
