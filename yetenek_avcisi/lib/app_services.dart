import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yetenek_avcisi/core/api/api_client.dart';
import 'package:yetenek_avcisi/core/config/api_config.dart';
import 'package:yetenek_avcisi/core/utils/profile_formatters.dart';
import 'package:yetenek_avcisi/core/utils/social_auth_helper.dart';

export 'package:yetenek_avcisi/core/config/api_config.dart' show kApiBaseUrl;

final ValueNotifier<AuthenticatedUser?> currentUserNotifier =
    ValueNotifier<AuthenticatedUser?>(null);
final ValueNotifier<String?> currentAccessTokenNotifier =
    ValueNotifier<String?>(null);

class AuthSession {
  const AuthSession({
    required this.user,
    required this.accessToken,
    this.refreshToken,
  });

  final AuthenticatedUser user;
  final String accessToken;
  final String? refreshToken;
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
    this.scoutDocumentUrl,
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
  final String? scoutDocumentUrl;

  bool get hasScoutDocumentSubmitted =>
      scoutDocumentUrl != null && scoutDocumentUrl!.trim().isNotEmpty;

  /// Ekranda gösterilecek güvenli isim (Apple ID / relay karışıklığını önler).
  String get displayName =>
      SocialAuthHelper.sanitizeDisplayName(fullName: fullName, email: email);

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
    if (scoutDocumentUrl != null && scoutDocumentUrl!.isNotEmpty)
      'scout_document_url': scoutDocumentUrl,
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
    final scoutDoc = _readOptionalString(
      m,
      'scout_document_url',
      'scoutDocumentUrl',
    );
    return AuthenticatedUser(
      id: id,
      fullName: SocialAuthHelper.sanitizeDisplayName(fullName: name, email: email),
      email: email,
      role: role,
      phoneNumber: phone,
      profileImageUrl: profileImage,
      birthDate: birth,
      age: age,
      isVerified: isVerified,
      scoutDocumentUrl: scoutDoc,
    );
  }
}

class ScoutRating {
  const ScoutRating({
    required this.scoutName,
    required this.score,
    this.isMine = false,
  });
  final String scoutName;
  final int score;
  final bool isMine;

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
      isMine: m['is_mine'] == true,
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
    this.city,
    this.birthDate,
    this.clubName,
    this.clubHistory,
    this.preferredFoot,
    this.heightCm,
    this.weightKg,
    this.rising7d = false,
    this.ovrDelta,
    this.userId,
    this.slotBreakdown = const [],
    this.analysisVersion,
    this.updatedAt,
    this.aiOvr,
    this.fifaOvr,
    this.communityOvr,
    this.combinedOvr,
    this.scoutCountForRating = 0,
  });

  final int id;
  final int? userId;
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
  final String? city;
  final String? birthDate;
  final String? clubName;
  final String? clubHistory;
  final String? preferredFoot;
  final int? heightCm;
  final int? weightKg;
  final bool rising7d;
  final int? ovrDelta;
  final List<Map<String, dynamic>> slotBreakdown;
  final String? analysisVersion;
  final String? updatedAt;
  final int? aiOvr;
  /// FIFA kartı — yalnızca AI analiz OVR (scout birleşimi yok).
  final int? fifaOvr;
  final int? communityOvr;
  final int? combinedOvr;
  final int scoutCountForRating;

  /// Scout + AI birleşik OVR (rozet, Keşfet listesi).
  int get scoutInfluencedOvr => combinedOvr ?? overallRating;

  /// FIFA kartında gösterilecek OVR (sadece AI; scout birleşimi hariç).
  int get fifaCardOvr => fifaOvr ?? aiOvr ?? overallRating;

  PlayerListItem copyWith({
    String? name,
    int? age,
    String? position,
    int? overallRating,
    String? profileImageUrl,
    String? city,
    String? clubName,
    String? clubHistory,
    String? preferredFoot,
    int? heightCm,
    int? weightKg,
  }) {
    return PlayerListItem(
      id: id,
      userId: userId,
      name: name ?? this.name,
      age: age ?? this.age,
      position: position ?? this.position,
      overallRating: overallRating ?? this.overallRating,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      phoneNumber: phoneNumber,
      aiScoutReport: aiScoutReport,
      videoUrl: videoUrl,
      source: source,
      scoutRatings: scoutRatings,
      pac: pac,
      sho: sho,
      pas: pas,
      dri: dri,
      def: def,
      phy: phy,
      city: city ?? this.city,
      birthDate: birthDate,
      clubName: clubName ?? this.clubName,
      clubHistory: clubHistory ?? this.clubHistory,
      preferredFoot: preferredFoot ?? this.preferredFoot,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      rising7d: rising7d,
      ovrDelta: ovrDelta,
    );
  }

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

    final reportRaw =
        _readOptionalString(m, 'ai_scout_report', 'aiScoutReport', 'scout_raporu');
    final reportClean = stripAnalysisDisclaimer(reportRaw);

    return PlayerListItem(
      id: id,
      userId: _readOptionalInt(m, 'user_id', 'userId'),
      name: name.isEmpty ? 'Oyuncu #$id' : name,
      age: age,
      position: position,
      overallRating: overall,
      profileImageUrl: _readOptionalString(
        m,
        'profile_image_url',
        'profileImageUrl',
        'profile_image',
        'profileImage',
        'profile_photo',
      ),
      phoneNumber: _readOptionalString(m, 'phone_number', 'phoneNumber', 'mobile'),
      aiScoutReport: reportClean.isEmpty ? null : reportClean,
      videoUrl: _readOptionalString(m, 'video_url', 'videoUrl', 'video'),
      source: '${m['source'] ?? 'legacy'}',
      city: _readOptionalString(m, 'city'),
      birthDate: _readOptionalString(m, 'birth_date', 'birthDate'),
      clubName: _readOptionalString(m, 'club_name', 'clubName'),
      clubHistory: _readOptionalString(m, 'club_history', 'clubHistory'),
      preferredFoot: _readOptionalString(m, 'preferred_foot', 'preferredFoot'),
      heightCm: _readOptionalInt(m, 'height_cm', 'heightCm'),
      weightKg: _readOptionalInt(m, 'weight_kg', 'weightKg'),
      rising7d: m['rising_7d'] == true,
      ovrDelta: _readOptionalInt(m, 'ovr_delta', 'ovrDelta'),
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
      slotBreakdown: _parseSlotBreakdownMap(m),
      analysisVersion: _readOptionalString(m, 'analysis_version', 'analysisVersion'),
      updatedAt: _readOptionalString(m, 'updated_at', 'updatedAt', 'created_at', 'createdAt'),
      aiOvr: _readCombinedInt(m, const ['ai_ovr', 'aiOvr']),
      fifaOvr: _readCombinedInt(m, const ['fifa_ovr', 'fifaOvr', 'ai_ovr', 'aiOvr']),
      communityOvr: _readCombinedInt(m, const ['community_ovr', 'communityOvr']),
      combinedOvr: _readCombinedInt(m, const ['combined_ovr', 'combinedOvr']),
      scoutCountForRating: _readScoutCountForRating(m),
    );
  }

  static int? _readCombinedInt(Map<String, dynamic> m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is int && v > 0) return v;
      if (v is num && v > 0) return v.toInt();
      if (v is String) {
        final p = int.tryParse(v);
        if (p != null && p > 0) return p;
      }
    }
    final nested = m['combined_rating'] ?? m['rating_sources'];
    if (nested is Map) {
      final map = Map<String, dynamic>.from(nested);
      return _readCombinedInt(map, keys);
    }
    return null;
  }

  static int _readScoutCountForRating(Map<String, dynamic> m) {
    final nested = m['combined_rating'] ?? m['rating_sources'];
    if (nested is Map) {
      final c = nested['scout_count'];
      if (c is int) return c;
      if (c is num) return c.toInt();
    }
    final comm = m['community_rating'];
    if (comm is Map) {
      final c = comm['rating_count'];
      if (c is int) return c;
      if (c is num) return c.toInt();
    }
    return 0;
  }

  static List<Map<String, dynamic>> _parseSlotBreakdownMap(Map<String, dynamic> m) {
    final raw = m['slot_breakdown'];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    final scores = m['skill_scores'];
    if (scores is Map && scores['slot_breakdown'] is List) {
      return (scores['slot_breakdown'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }
}

class ScoutNoteItem {
  const ScoutNoteItem({
    required this.id,
    required this.scoutId,
    required this.scoutName,
    required this.body,
    required this.visibility,
    this.isMine = false,
    this.createdAt,
  });

  final int id;
  final int scoutId;
  final String scoutName;
  final String body;
  final String visibility;
  final bool isMine;
  final String? createdAt;

  factory ScoutNoteItem.fromJson(Map<String, dynamic> m) {
    return ScoutNoteItem(
      id: m['id'] is int ? m['id'] as int : int.parse('${m['id']}'),
      scoutId: m['scout_id'] is int ? m['scout_id'] as int : int.parse('${m['scout_id']}'),
      scoutName: '${m['scout_name'] ?? 'Scout'}',
      body: '${m['body'] ?? ''}',
      visibility: '${m['visibility'] ?? 'private'}',
      isMine: m['is_mine'] == true,
      createdAt: m['created_at']?.toString(),
    );
  }
}

class ShortlistSummary {
  const ShortlistSummary({
    required this.id,
    required this.title,
    required this.shareToken,
    this.shareUrl,
    this.itemCount = 0,
    this.items = const [],
  });

  final int id;
  final String title;
  final String shareToken;
  final String? shareUrl;
  final int itemCount;
  final List<ShortlistItemEntry> items;

  factory ShortlistSummary.fromJson(Map<String, dynamic> m) {
    final rawItems = m['items'];
    return ShortlistSummary(
      id: m['id'] is int ? m['id'] as int : int.parse('${m['id']}'),
      title: '${m['title'] ?? 'Favorilerim'}',
      shareToken: '${m['share_token'] ?? ''}',
      shareUrl: m['share_url']?.toString(),
      itemCount: m['item_count'] is int ? m['item_count'] as int : int.tryParse('${m['item_count']}') ?? 0,
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(ShortlistItemEntry.fromJson)
              .toList()
          : const [],
    );
  }
}

class ShortlistItemEntry {
  const ShortlistItemEntry({
    required this.playerId,
    required this.source,
    this.player,
  });

  final int playerId;
  final String source;
  final PlayerListItem? player;

  factory ShortlistItemEntry.fromJson(Map<String, dynamic> m) {
    final playerMap = m['player'];
    return ShortlistItemEntry(
      playerId: m['player_id'] is int ? m['player_id'] as int : int.parse('${m['player_id']}'),
      source: '${m['player_source'] ?? 'multivideo'}',
      player: playerMap is Map<String, dynamic> ? PlayerListItem.fromJson(playerMap) : null,
    );
  }
}

class AppNotificationItem {
  const AppNotificationItem({
    required this.id,
    required this.kind,
    required this.title,
    this.body,
    this.read = false,
    this.createdAt,
  });

  final int id;
  final String kind;
  final String title;
  final String? body;
  final bool read;
  final String? createdAt;

  factory AppNotificationItem.fromJson(Map<String, dynamic> m) {
    return AppNotificationItem(
      id: m['id'] is int ? m['id'] as int : int.parse('${m['id']}'),
      kind: '${m['kind'] ?? ''}',
      title: '${m['title'] ?? ''}',
      body: m['body']?.toString(),
      read: m['read'] == true,
      createdAt: m['created_at']?.toString(),
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
    this.ratingCount = 0,
    this.currentUserHasRated = false,
  });

  final int ovr;
  final int pac;
  final int sho;
  final int pas;
  final int dri;
  final int def;
  final int phy;
  final String? profileImageUrl;
  final int ratingCount;
  final bool currentUserHasRated;

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
      ratingCount: readInt(const ['rating_count'], 0),
      currentUserHasRated: m['current_user_has_rated'] == true,
    );
  }
}

String? _readOptionalString(
  Map<String, dynamic> m,
  String a, [
  String? b,
  String? c,
  String? d,
  String? e,
  String? f,
]) {
  for (final k in <String?>[a, b, c, d, e, f]) {
    if (k == null || k.trim().isEmpty) continue;
    final v = m[k];
    if (v is String && v.trim().isNotEmpty) return v.trim();
  }
  return null;
}

int? _readOptionalInt(Map<String, dynamic> m, String a, [String? b]) {
  for (final k in <String?>[a, b]) {
    if (k == null) continue;
    final v = m[k];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
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
  static const String _refreshKey = 'auth_refresh_token';

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
      await prefs.remove(_refreshKey);
    }
  }

  static Future<void> save(AuthSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, json.encode(session.user.toJson()));
    await prefs.setString(_tokenKey, session.accessToken);
    if (session.refreshToken != null && session.refreshToken!.isNotEmpty) {
      await prefs.setString(_refreshKey, session.refreshToken!);
    }
    currentUserNotifier.value = session.user;
    currentAccessTokenNotifier.value = session.accessToken;
  }

  static Future<String?> readRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_refreshKey)?.trim();
  }

  static Future<void> updateUser(AuthenticatedUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, json.encode(user.toJson()));
    currentUserNotifier.value = user;
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_refreshKey);
    currentUserNotifier.value = null;
    currentAccessTokenNotifier.value = null;
  }
}

AuthSession _authSessionFromJson(Map<String, dynamic> decoded) {
  final token = '${decoded['access_token'] ?? ''}'.trim();
  if (token.isEmpty) throw ApiException('Token alınamadı', 500);
  final userMap = decoded['user'] as Map<String, dynamic>?;
  if (userMap == null) throw ApiException('Kullanıcı bilgisi alınamadı', 500);
  final refresh = '${decoded['refresh_token'] ?? ''}'.trim();
  return AuthSession(
    user: AuthenticatedUser.fromJson(userMap),
    accessToken: token,
    refreshToken: refresh.isEmpty ? null : refresh,
  );
}

class BackendApi {
  BackendApi._();

  static Uri _uri(String path) =>
      Uri.parse(kApiBaseUrl).resolve(path.startsWith('/') ? path : '/$path');

  static Map<String, String> _jsonHeaders({bool authRequired = false}) =>
      ApiClient.headers(json: true, authRequired: authRequired);

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
    String? referralCode,
  }) async {
    final body = json.encode({
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password,
      'role': role,
      'phone_number': phoneNumber.trim(),
      if (birthDate != null) 'birth_date': birthDate,
      if (age != null) 'age': age,
      if (referralCode != null && referralCode.trim().isNotEmpty)
        'referral_code': referralCode.trim().toUpperCase(),
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
      final decoded = json.decode(res.body) as Map<String, dynamic>;
      return _authSessionFromJson(decoded);
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
  static Future<AuthSession> refreshAccessToken() async {
    final refresh = await SessionStore.readRefreshToken();
    if (refresh == null || refresh.isEmpty) {
      throw ApiException('Oturum yenilenemedi. Lütfen tekrar giriş yapın.', 401);
    }
    final res = await http
        .post(
          _uri('/auth/refresh'),
          headers: _jsonHeaders(),
          body: json.encode({'refresh_token': refresh}),
        )
        .timeout(const Duration(seconds: 30));
    if (res.statusCode >= 200 && res.statusCode < 300) {
      final decoded = json.decode(res.body) as Map<String, dynamic>;
      final user = currentUserNotifier.value;
      if (user == null) throw ApiException('Kullanıcı oturumu yok', 401);
      final session = AuthSession(
        user: user,
        accessToken: '${decoded['access_token']}',
        refreshToken: '${decoded['refresh_token'] ?? refresh}',
      );
      await SessionStore.save(session);
      return session;
    }
    throw _friendlyError(res);
  }

  static Future<void> logout() async {
    final refresh = await SessionStore.readRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        await ApiClient.post(
          '/auth/logout',
          body: {'refresh_token': refresh},
          authRequired: true,
        );
      }
    } catch (_) {}
    await SessionStore.clear();
  }

  static Future<void> deleteMyAccount() async {
    final res = await ApiClient.delete('/users/me', authRequired: true);
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(_friendlyErrorMsg(res.body, res.statusCode), res.statusCode);
    }
    await SessionStore.clear();
  }

  static Future<Map<String, dynamic>> exportMyData() async {
    const paths = ['/users/me/export', '/api/v1/users/me/export'];
    http.Response? last;
    for (final path in paths) {
      final res = await ApiClient.get(path, authRequired: true);
      last = res;
      if (res.statusCode == 404) continue;
      if (res.statusCode >= 200 && res.statusCode < 300) {
        return json.decode(res.body) as Map<String, dynamic>;
      }
      throw ApiException(_friendlyExportError(res.body, res.statusCode), res.statusCode);
    }
    throw ApiException(
      _friendlyExportError(last?.body ?? '', last?.statusCode ?? 404),
      last?.statusCode ?? 404,
    );
  }

  static String _friendlyExportError(String body, int status) {
    if (status == 404) {
      return 'Veri export bu sunucuda henüz yok. Debug modda yerel backend çalıştırın '
          '(http://127.0.0.1:8000) veya production\'ı güncel kodla deploy edin.';
    }
    return _friendlyErrorMsg(body, status);
  }

  static Future<Map<String, dynamic>> fetchReferralLink() async {
    final res = await ApiClient.get('/auth/me/referral', authRequired: true);
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return json.decode(res.body) as Map<String, dynamic>;
    }
    throw ApiException(_friendlyErrorMsg(res.body, res.statusCode), res.statusCode);
  }

  static Future<List<PlayerListItem>> fetchPlayers() async {
    final res = await ApiClient.get('/players');

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
    final detail = await fetchPlayerDetail(playerId);
    return detail.rating;
  }

  /// GET /players/{id} — oyuncu + community_rating.
  static Future<({PlayerListItem player, PlayerRatingSummary rating})>
      fetchPlayerDetail(int playerId) async {
    final res = await ApiClient.get('/players/$playerId');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _friendlyError(res);
    }
    final decoded = json.decode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Oyuncu detayı formatı beklenmiyordu.', res.statusCode);
    }
    final ratingMap = _extractRatingMap(decoded);
    final rating = PlayerRatingSummary.fromJson(ratingMap);
    final player = PlayerListItem.fromJson(decoded);
    return (player: player, rating: rating);
  }

  static Future<PlayerRatingSummary> ratePlayer({
    required int playerId,
    required PlayerRatingPayload payload,
    String source = 'legacy',
  }) async {
    final path = source == 'multivideo'
        ? '/players/multivideo/$playerId/rate'
        : '/players/$playerId/rate';
    final res = await ApiClient.post(
      path,
      body: payload.toJson(),
      authRequired: true,
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _friendlyError(res);
    }

    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) {
      final ratingMap = _extractRatingMap(decoded);
      return PlayerRatingSummary.fromJson(ratingMap);
    }
    throw ApiException('Puanlama cevabı geçersiz formatta.', res.statusCode);
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

  /// Profil fotoğrafı yükle (POST /me/upload-photo)
  static Future<String> uploadProfilePhoto(String filePath) async {
    final uri = _uri('/me/upload-photo');
    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_jsonHeaders(authRequired: true)..remove('Content-Type'));
    request.files.add(await http.MultipartFile.fromPath('file', filePath));
    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return decoded['profile_image_url'] as String;
    }
    throw _friendlyError(res);
  }

  /// Kullanıcı profili güncelle (PUT /me)
  static Future<AuthenticatedUser> updateUserProfile({
    String? fullName,
    String? email,
    String? phoneNumber,
    String? profileImageUrl,
    String? birthDate,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phone_number'] = phoneNumber;
    if (profileImageUrl != null) body['profile_image_url'] = profileImageUrl;
    if (birthDate != null) body['birth_date'] = birthDate;

    final res = await ApiClient.put(
      '/me',
      body: body,
      authRequired: true,
    ).timeout(const Duration(seconds: 15));

    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      return AuthenticatedUser.fromJson(decoded);
    }
    throw _friendlyError(res);
  }

  /// Oturumdaki kullanıcıyı sunucudan yeniler (scout belgesi vb.).
  static Future<AuthenticatedUser> fetchCurrentUser() async {
    final res = await ApiClient.get('/me', authRequired: true)
        .timeout(const Duration(seconds: 15));
    if (res.statusCode == 200) {
      final decoded = json.decode(res.body);
      if (decoded is Map<String, dynamic>) {
        return AuthenticatedUser.fromJson(decoded);
      }
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
        return SocialLoginResult(
          status: 'incomplete',
          email: '${decoded['email'] ?? email}'.trim(),
          fullName: '${decoded['full_name'] ?? fullName}'.trim(),
          provider: '${decoded['provider'] ?? provider}'.trim(),
          providerId: '${decoded['provider_id'] ?? providerId ?? ''}'.trim(),
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
    String? referralCode,
  }) async {
    final body = json.encode({
      'email': email.trim(),
      'full_name': fullName.trim(),
      'phone_number': phoneNumber.trim(),
      'role': role,
      'provider': provider,
      'provider_id': providerId,
      if (birthDate != null) 'birth_date': birthDate,
      if (referralCode != null && referralCode.trim().isNotEmpty)
        'referral_code': referralCode.trim().toUpperCase(),
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

    final data = json.decode(res.body) as Map<String, dynamic>;
    return _authSessionFromJson(data);
  }

  static Future<List<PlayerListItem>> fetchPlayersWithFilters({
    String? position,
    int? minAge,
    int? maxAge,
    int? minOvr,
    int? maxOvr,
    String? city,
    bool rising7d = false,
  }) async {
    final params = <String, String>{};
    if (position != null && position.isNotEmpty && position != 'Tum') {
      params['position'] = position;
    }
    if (minAge != null) params['min_age'] = '$minAge';
    if (maxAge != null) params['max_age'] = '$maxAge';
    if (minOvr != null) params['min_ovr'] = '$minOvr';
    if (maxOvr != null) params['max_ovr'] = '$maxOvr';
    if (city != null && city.trim().isNotEmpty) params['city'] = city.trim();
    if (rising7d) params['rising_7d'] = 'true';

    final res = await ApiClient.get('/players', query: params);
    if (res.statusCode != 200) throw _friendlyError(res);
    final decoded = json.decode(res.body);
    if (decoded is! List) {
      throw ApiException('Oyuncu listesi formatı beklenmiyordu.', res.statusCode);
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(PlayerListItem.fromJson)
        .toList();
  }

  static Future<Map<String, dynamic>> comparePlayers(int a, int b) async {
    final res = await ApiClient.get('/players/compare', query: {'a': '$a', 'b': '$b'});
    if (res.statusCode != 200) throw _friendlyError(res);
    final decoded = json.decode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Karşılaştırma cevabı geçersiz.', res.statusCode);
    }
    return decoded;
  }

  static Future<List<ScoutNoteItem>> fetchPlayerNotes(int playerId, {String source = 'multivideo'}) async {
    final res = await ApiClient.get(
      '/players/$playerId/notes',
      query: {'player_source': source},
      authRequired: false,
    );
    if (res.statusCode != 200) throw _friendlyError(res);
    final decoded = json.decode(res.body);
    if (decoded is! List) return [];
    return decoded.whereType<Map<String, dynamic>>().map(ScoutNoteItem.fromJson).toList();
  }

  static Future<ScoutNoteItem> createPlayerNote({
    required int playerId,
    required String body,
    String visibility = 'private',
    String source = 'multivideo',
  }) async {
    final res = await ApiClient.post(
      '/players/$playerId/notes',
      body: {'body': body, 'visibility': visibility, 'player_source': source},
      authRequired: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) throw _friendlyError(res);
    return ScoutNoteItem.fromJson(json.decode(res.body) as Map<String, dynamic>);
  }

  static Future<void> deletePlayerNote(int noteId) async {
    final res = await ApiClient.delete('/notes/$noteId', authRequired: true);
    if (res.statusCode != 204 && (res.statusCode < 200 || res.statusCode >= 300)) {
      throw _friendlyError(res);
    }
  }

  static Future<List<ShortlistSummary>> fetchMyShortlists() async {
    final res = await ApiClient.get('/shortlists/mine', authRequired: true);
    if (res.statusCode != 200) throw _friendlyError(res);
    final decoded = json.decode(res.body);
    if (decoded is! List) return [];
    return decoded.whereType<Map<String, dynamic>>().map(ShortlistSummary.fromJson).toList();
  }

  static Future<void> addToShortlist({
    required int shortlistId,
    required int playerId,
    String source = 'multivideo',
  }) async {
    final res = await ApiClient.post(
      '/shortlists/$shortlistId/items',
      body: {'player_id': playerId, 'player_source': source},
      authRequired: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) throw _friendlyError(res);
  }

  static Future<void> removeFromShortlist({
    required int shortlistId,
    required int playerId,
    String source = 'multivideo',
  }) async {
    final res = await ApiClient.delete(
      '/shortlists/$shortlistId/items/$playerId?player_source=$source',
      authRequired: true,
    );
    if (res.statusCode != 204 && (res.statusCode < 200 || res.statusCode >= 300)) {
      throw _friendlyError(res);
    }
  }

  static Future<List<AppNotificationItem>> fetchNotifications({bool unreadOnly = false}) async {
    final res = await ApiClient.get(
      '/notifications',
      query: unreadOnly ? {'unread_only': 'true'} : null,
      authRequired: true,
    );
    if (res.statusCode != 200) throw _friendlyError(res);
    final decoded = json.decode(res.body);
    if (decoded is! List) return [];
    return decoded.whereType<Map<String, dynamic>>().map(AppNotificationItem.fromJson).toList();
  }

  static Future<void> markNotificationRead(int id) async {
    final res = await ApiClient.patch('/notifications/$id/read', authRequired: true);
    if (res.statusCode < 200 || res.statusCode >= 300) throw _friendlyError(res);
  }

  static Future<void> registerFcmToken(String deviceToken) async {
    final res = await ApiClient.post(
      '/notifications/register-device',
      body: {'device_token': deviceToken},
      authRequired: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _friendlyError(res);
    }
  }

  static Future<void> clearFcmToken() async {
    final res = await ApiClient.post(
      '/notifications/register-device',
      body: {'device_token': ''},
      authRequired: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _friendlyError(res);
    }
  }

  static Future<Map<String, dynamic>> fetchNotificationDeviceStatus() async {
    final res = await ApiClient.get(
      '/notifications/device-status',
      authRequired: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw _friendlyError(res);
    }
    final decoded = json.decode(res.body);
    if (decoded is Map<String, dynamic>) return decoded;
    return <String, dynamic>{'ok': false, 'message': 'unexpected response'};
  }

  static Future<Map<String, dynamic>?> fetchMyMultivideoProfile() async {
    final res = await ApiClient.get('/me/multivideo-profile', authRequired: true);
    if (res.statusCode != 200) throw _friendlyError(res);
    final decoded = json.decode(res.body) as Map<String, dynamic>;
    if (decoded['player_id'] == null) return null;
    return decoded;
  }

  static Future<Map<String, dynamic>> updateMyMultivideoProfile(
    Map<String, dynamic> fields,
  ) async {
    final res = await ApiClient.patch(
      '/me/multivideo-profile',
      body: fields,
      authRequired: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) throw _friendlyError(res);
    return json.decode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> updateMultivideoProfile(
    int playerId,
    Map<String, dynamic> fields,
  ) async {
    final res = await ApiClient.patch(
      '/players/multivideo/$playerId/profile',
      body: fields,
      authRequired: true,
    );
    if (res.statusCode < 200 || res.statusCode >= 300) throw _friendlyError(res);
    return json.decode(res.body) as Map<String, dynamic>;
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
    String? scoutDocumentUrlOverride,
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
      scoutDocumentUrl: scoutDocumentUrlOverride ?? scoutDocumentUrl,
    );
  }
}
