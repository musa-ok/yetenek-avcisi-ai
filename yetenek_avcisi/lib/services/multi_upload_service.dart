import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../app_services.dart';
import '../core/utils/profile_formatters.dart';

/// ==========================================
/// MULTI-UPLOAD SERVİSİ
/// 3 Yetenek Videosu Sistemi
/// ==========================================

/// Güvenli int çevirme (int, double, String olabilir)
int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

class PositionSkill {
  final int slot;
  final String name;
  final String nameEn;
  final String description;
  final String descriptionEn;
  final String icon;
  final int durationSec;
  final String color;
  final bool isKosuSlot;

  PositionSkill({
    required this.slot,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.descriptionEn,
    required this.icon,
    required this.durationSec,
    required this.color,
    this.isKosuSlot = false,
  });

  factory PositionSkill.fromJson(Map<String, dynamic> json) {
    return PositionSkill(
      slot: json['slot'] ?? 0,
      name: json['name'] ?? '',
      nameEn: json['name_en'] ?? '',
      description: json['description'] ?? '',
      descriptionEn: json['description_en'] ?? '',
      icon: json['icon'] ?? '⚽',
      durationSec: json['duration_sec'] ?? 10,
      color: json['color'] ?? '#00FF87',
      isKosuSlot: json['is_kosu_slot'] == true,
    );
  }

  String get displayDescription {
    if (isKosuSlot) {
      return 'Önce 20 metre düz koşu, sonra 10 metre yokuş yukarı koşu yükleyin.';
    }
    return description;
  }
}

class MultiVideoPlayer {
  final int id;
  final int userId;
  final String name;
  final String? birthDate;
  final int age;
  final String position;
  final String positionCode;
  final int overallRating;
  final double averageRating;
  final double completionPercentage;
  final bool isComplete;
  final List<VideoInfo> videos;
  final Map<String, dynamic> skillScores;
  final String? aiSummaryReport;
  final List<String> aiStrengths;
  final List<String> aiImprovements;
  
  // AI Analizi Detaylı Skorlar
  final int? pace;
  final int? finishing;
  final int? passing;
  final int? dribbling;
  final int? defending;
  final int? strength;
  final int? technicalAbility;
  final int? physicalAttributes;
  final int? tacticalAwareness;
  final int? mentalAttributes;
  final String? analysisStatus;
  final String? analysisError;
  final String? createdAt;
  final String? updatedAt;
  final int requiredVideoCount;
  final bool usesSprintProtocol;
  final List<Map<String, dynamic>> slotBreakdown;
  final String? analysisVersion;

  MultiVideoPlayer({
    required this.id,
    required this.userId,
    required this.name,
    this.birthDate,
    required this.age,
    required this.position,
    required this.positionCode,
    required this.overallRating,
    required this.averageRating,
    required this.completionPercentage,
    required this.isComplete,
    required this.videos,
    required this.skillScores,
    this.aiSummaryReport,
    required this.aiStrengths,
    required this.aiImprovements,
    this.pace,
    this.finishing,
    this.passing,
    this.dribbling,
    this.defending,
    this.strength,
    this.technicalAbility,
    this.physicalAttributes,
    this.tacticalAwareness,
    this.mentalAttributes,
    this.analysisStatus,
    this.analysisError,
    this.createdAt,
    this.updatedAt,
    this.requiredVideoCount = 3,
    this.usesSprintProtocol = false,
    this.slotBreakdown = const [],
    this.analysisVersion,
  });

  bool get analysisFailed => analysisStatus == 'failed';
  bool get analysisProcessing =>
      analysisStatus == 'processing' || analysisStatus == 'pending';
  bool get analysisCompleted => analysisStatus == 'completed';

  static List<Map<String, dynamic>> _parseSlotBreakdown(Map<String, dynamic> json) {
    final raw = json['slot_breakdown'];
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    final scores = json['skill_scores'];
    if (scores is Map && scores['slot_breakdown'] is List) {
      return (scores['slot_breakdown'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return [];
  }

  factory MultiVideoPlayer.fromJson(Map<String, dynamic> json) {
    final skillScores = json['skill_scores'] is Map
        ? Map<String, dynamic>.from(json['skill_scores'] as Map)
        : <String, dynamic>{};
    return MultiVideoPlayer(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      name: json['name'] ?? '',
      birthDate: json['birth_date'],
      age: json['age'] ?? 0,
      position: json['position'] ?? '',
      positionCode: json['position_code'] ?? '',
      overallRating: json['overall_rating'] ?? 0,
      averageRating: (json['average_rating'] ?? 0).toDouble(),
      completionPercentage: (json['completion_percentage'] ?? 0).toDouble(),
      isComplete: json['is_complete'] ?? false,
      videos: (json['videos'] as List? ?? [])
          .map((v) => VideoInfo.fromJson(v))
          .toList(),
      skillScores: skillScores,
      slotBreakdown: _parseSlotBreakdown(json),
      analysisVersion: json['analysis_version'] as String? ??
          skillScores['analysis_version'] as String?,
      aiSummaryReport: () {
        final raw = json['ai_summary_report'];
        if (raw == null) return null;
        final clean = stripAnalysisDisclaimer('$raw');
        return clean.isEmpty ? null : clean;
      }(),
      aiStrengths: List<String>.from(json['ai_strengths'] ?? []),
      aiImprovements: List<String>.from(json['ai_improvements'] ?? []),
      // AI Skorlar (int veya double olabilir, toInt() ile güvenli çevir)
      pace: _toInt(json['pace']),
      finishing: _toInt(json['finishing']),
      passing: _toInt(json['passing']),
      dribbling: _toInt(json['dribbling']),
      defending: _toInt(json['defending']),
      strength: _toInt(json['strength']),
      technicalAbility: _toInt(json['technical_ability']),
      physicalAttributes: _toInt(json['physical_attributes']),
      tacticalAwareness: _toInt(json['tactical_awareness']),
      mentalAttributes: _toInt(json['mental_attributes']),
      analysisStatus: json['analysis_status'] as String?,
      analysisError: json['analysis_error'] as String?,
      createdAt: json['created_at'] as String?,
      updatedAt: json['updated_at'] as String?,
      requiredVideoCount: json['required_video_count'] as int? ?? 3,
      usesSprintProtocol: json['uses_sprint_protocol'] == true,
    );
  }
}

String _parseApiErrorDetail(dynamic body, String fallback) {
  if (body is Map) {
    final d = body['detail'];
    if (d is String && d.isNotEmpty) return d;
    if (d is List && d.isNotEmpty) return '$d';
    final e = body['error'];
    if (e is String && e.isNotEmpty) return e;
  }
  return fallback;
}

/// AI finalize sonucu — başarısız olsa bile kısmi oyuncu verisi dönebilir.
class FinalizeAnalysisResult {
  const FinalizeAnalysisResult({
    required this.player,
    required this.success,
    this.partial = false,
    this.retryable = false,
    this.errorMessage,
  });

  final MultiVideoPlayer player;
  final bool success;
  final bool partial;
  final bool retryable;
  final String? errorMessage;
}

class SmartSummaryData {
  const SmartSummaryData({
    required this.headline,
    required this.summary,
    required this.sections,
  });

  final String headline;
  final String summary;
  final List<({String title, String body})> sections;

  factory SmartSummaryData.fromJson(Map<String, dynamic> json) {
    final rawSections = json['sections'] as List? ?? [];
    final sections = rawSections
        .map((s) {
          final m = s as Map<String, dynamic>;
          return (title: '${m['title'] ?? ''}', body: '${m['body'] ?? ''}');
        })
        .toList();
    return SmartSummaryData(
      headline: '${json['headline'] ?? ''}',
      summary: '${json['summary'] ?? ''}',
      sections: sections,
    );
  }
}

class VideoInfo {
  final String? url;
  final String? skill;
  final int? rating;
  final String? analysis;
  final int slot;
  final bool isKosuSlot;
  final bool kosuFlatUploaded;
  final bool kosuUphillUploaded;

  VideoInfo({
    this.url,
    this.skill,
    this.rating,
    this.analysis,
    required this.slot,
    this.isKosuSlot = false,
    this.kosuFlatUploaded = false,
    this.kosuUphillUploaded = false,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    final isKosu = json['is_kosu_slot'] == true;
    final flat = json['kosu_flat_uploaded'] == true;
    final uphill = json['kosu_uphill_uploaded'] == true;
    return VideoInfo(
      url: json['url'],
      skill: json['skill'],
      rating: json['rating'],
      analysis: json['analysis'],
      slot: json['slot'] ?? 0,
      isKosuSlot: isKosu,
      kosuFlatUploaded: flat,
      kosuUphillUploaded: uphill,
    );
  }

  bool get isUploaded {
    if (isKosuSlot) {
      return kosuFlatUploaded && kosuUphillUploaded;
    }
    return url != null && url!.isNotEmpty;
  }
}

class MultiUploadService {
  static final String _baseUrl = kApiBaseUrl;

  /// Mevki için 3 yetenek videosu bilgisini getir
  static Future<List<PositionSkill>> getPositionSkills(String position) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/position-skills/$position'),
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Mevki yetenekleri alınamadı: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final skills = (data['skills'] as List? ?? [])
        .map((s) => PositionSkill.fromJson(s))
        .toList();
    
    return skills;
  }

  /// Yeni çoklu video oyuncu kaydı oluştur
  /// Doğum tarihinden yaş otomatik hesaplanır (her yıl güncellenir)
  static Future<MultiVideoPlayer> createPlayer({
    required int userId,
    required String name,
    required DateTime birthDate, // Doğum tarihi
    required String position,
  }) async {
    // ISO formatında tarih: "2000-05-15"
    final birthDateStr = "${birthDate.year.toString().padLeft(4, '0')}-"
        "${birthDate.month.toString().padLeft(2, '0')}-"
        "${birthDate.day.toString().padLeft(2, '0')}";
    
    final response = await http.post(
      Uri.parse('$_baseUrl/players/multivideo/create'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'user_id': userId.toString(),
        'name': name,
        'birth_date': birthDateStr, // Yaş otomatik hesaplanacak
        'position': position,
      },
    ).timeout(Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Oyuncu oluşturulamadı: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return MultiVideoPlayer.fromJson(data['player']);
  }

  /// Auth'dan (Bearer token) kullanıcı bilgilerini çekerek oyuncu kaydı oluştur
  /// Token header'da gönderilir, isim/bilgiler token'dan otomatik çekilir
  static Future<MultiVideoPlayer> createPlayerFromAuth({
    required String position,
    required String accessToken,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/players/multivideo/create-from-auth'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Authorization': 'Bearer $accessToken',
      },
      body: {
        'position': position,
      },
    ).timeout(Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Oyuncu oluşturulamadı: ${response.statusCode} - ${response.body}');
    }

    final data = json.decode(response.body);
    return MultiVideoPlayer.fromJson(data['player']);
  }

  /// Belirli slota video yükle
  static Future<MultiVideoPlayer> uploadVideoToSlot({
    required int playerId,
    required int slot,
    required String skillName,
    required File videoFile,
    String? accessToken,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/players/multivideo/$playerId/upload-slot-$slot'),
    );

    final token = accessToken ?? currentAccessTokenNotifier.value;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    request.fields['skill_name'] = skillName;
    
    final videoStream = http.ByteStream(videoFile.openRead());
    final videoLength = await videoFile.length();
    
    final multipartFile = http.MultipartFile(
      'file',
      videoStream,
      videoLength,
      filename: videoFile.path.split('/').last,
    );
    request.files.add(multipartFile);

    final streamedResponse = await request.send()
        .timeout(Duration(minutes: 3));
    
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      var msg = 'Video yüklenemedi';
      try {
        final errBody = json.decode(response.body);
        msg = _parseApiErrorDetail(errBody, msg);
      } catch (_) {
        msg = 'Video yüklenemedi (${response.statusCode})';
      }
      throw Exception(msg);
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    return MultiVideoPlayer.fromJson(data['player'] as Map<String, dynamic>);
  }

  /// Koşu/hız slotu: phase `flat` (20m düz) veya `uphill` (10m yokuş).
  static Future<Map<String, dynamic>> uploadKosuToSlotRaw({
    required int playerId,
    required int slot,
    required String phase,
    required String skillName,
    required File videoFile,
    String? accessToken,
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/players/multivideo/$playerId/upload-slot-$slot/kosu'),
    );
    final token = accessToken ?? currentAccessTokenNotifier.value;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.fields['phase'] = phase;
    request.fields['skill_name'] = skillName;

    final videoStream = http.ByteStream(videoFile.openRead());
    final videoLength = await videoFile.length();
    request.files.add(http.MultipartFile(
      'file',
      videoStream,
      videoLength,
      filename: videoFile.path.split('/').last,
    ));

    final streamedResponse = await request.send().timeout(const Duration(minutes: 3));
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      var msg = 'Video yüklenemedi';
      try {
        final errBody = json.decode(response.body);
        msg = _parseApiErrorDetail(errBody, msg);
      } catch (_) {
        msg = 'Video yüklenemedi (${response.statusCode})';
      }
      throw Exception(msg);
    }

    return json.decode(response.body) as Map<String, dynamic>;
  }

  static Future<MultiVideoPlayer> uploadKosuToSlot({
    required int playerId,
    required int slot,
    required String phase,
    required String skillName,
    required File videoFile,
    String? accessToken,
  }) async {
    final data = await uploadKosuToSlotRaw(
      playerId: playerId,
      slot: slot,
      phase: phase,
      skillName: skillName,
      videoFile: videoFile,
      accessToken: accessToken,
    );
    return MultiVideoPlayer.fromJson(data['player'] as Map<String, dynamic>);
  }

  /// Koşu yükleme yanıtındaki kalite özeti (varsa).
  static Map<String, dynamic>? parseKosuQualityFromUploadResponse(
    Map<String, dynamic> body,
  ) {
    final q = body['kosu_quality'];
    if (q is Map) return Map<String, dynamic>.from(q);
    return null;
  }

  /// Tüm videoları tamamlayınca analizi kuyruğa al (async) veya senkron bekle.
  static Future<FinalizeAnalysisResult> finalizePlayer(
    int playerId, {
    String? accessToken,
  }) async {
    final headers = <String, String>{};
    final token = accessToken ?? currentAccessTokenNotifier.value;
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    final response = await http.post(
      Uri.parse('$_baseUrl/players/multivideo/$playerId/finalize'),
      headers: headers,
    ).timeout(const Duration(seconds: 30));

    if (response.statusCode != 200) {
      final body = json.decode(response.body);
      throw Exception(body is Map ? (body['detail'] ?? body['error'] ?? 'Analiz başlatılamadı') : 'Analiz başlatılamadı');
    }

    final data = json.decode(response.body) as Map<String, dynamic>;
    if (data['player'] != null) {
      final player = MultiVideoPlayer.fromJson(data['player'] as Map<String, dynamic>);
      final ok = data['analysis_status'] != 'failed';
      return FinalizeAnalysisResult(
        player: player,
        success: ok,
        partial: data['partial'] == true,
        retryable: data['retryable'] == true,
        errorMessage: data['message'] as String?,
      );
    }

    // Async kuyruk — durumu poll et
    const maxAttempts = 60;
    for (var i = 0; i < maxAttempts; i++) {
      await Future.delayed(const Duration(seconds: 3));
      final statusRes = await http.get(
        Uri.parse('$_baseUrl/players/multivideo/$playerId/analysis-status'),
      ).timeout(const Duration(seconds: 15));
      if (statusRes.statusCode != 200) continue;
      final status = json.decode(statusRes.body) as Map<String, dynamic>;
      final st = status['analysis_status'] as String?;
      if (st == 'completed') {
        final player = await getPlayerDetail(playerId);
        return FinalizeAnalysisResult(player: player, success: true);
      }
      if (st == 'failed') {
        final player = await getPlayerDetail(playerId);
        final err = status['analysis_error'] as String? ??
            'Analiz başarısız. Lütfen tekrar deneyin.';
        final partial = (player.aiSummaryReport?.isNotEmpty ?? false) ||
            player.overallRating > 0;
        return FinalizeAnalysisResult(
          player: player,
          success: false,
          partial: partial,
          retryable: true,
          errorMessage: err,
        );
      }
    }
    throw Exception('Analiz zaman aşımı. Daha sonra tekrar deneyin.');
  }

  static Future<SmartSummaryData> fetchSmartSummary(int playerId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/players/multivideo/$playerId/smart-summary'),
      headers: {'Accept': 'application/json'},
    ).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw Exception('Özet yüklenemedi: ${response.statusCode}');
    }
    return SmartSummaryData.fromJson(
      json.decode(response.body) as Map<String, dynamic>,
    );
  }

  /// Oyuncu detayını getir
  static Future<MultiVideoPlayer> getPlayerDetail(int playerId) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/players/multivideo/$playerId'),
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Oyuncu detayı alınamadı: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    return MultiVideoPlayer.fromJson(data);
  }

  /// Tüm çoklu video oyuncularını listele
  static Future<List<MultiVideoPlayer>> listPlayers({
    int skip = 0,
    int limit = 100,
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/players/multivideo?skip=$skip&limit=$limit'),
      headers: {'Accept': 'application/json'},
    ).timeout(Duration(seconds: 30));

    if (response.statusCode != 200) {
      throw Exception('Oyuncular listelenemedi: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    final players = (data['players'] as List? ?? [])
        .map((p) => MultiVideoPlayer.fromJson(p))
        .toList();
    
    return players;
  }
}
