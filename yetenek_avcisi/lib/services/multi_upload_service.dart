import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../app_services.dart';

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

  PositionSkill({
    required this.slot,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.descriptionEn,
    required this.icon,
    required this.durationSec,
    required this.color,
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
    );
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
  });

  factory MultiVideoPlayer.fromJson(Map<String, dynamic> json) {
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
      skillScores: json['skill_scores'] ?? {},
      aiSummaryReport: json['ai_summary_report'],
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
    );
  }
}

class VideoInfo {
  final String? url;
  final String? skill;
  final int? rating;
  final String? analysis;
  final int slot;

  VideoInfo({
    this.url,
    this.skill,
    this.rating,
    this.analysis,
    required this.slot,
  });

  factory VideoInfo.fromJson(Map<String, dynamic> json) {
    return VideoInfo(
      url: json['url'],
      skill: json['skill'],
      rating: json['rating'],
      analysis: json['analysis'],
      slot: json['slot'] ?? 0,
    );
  }

  bool get isUploaded => url != null && url!.isNotEmpty;
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
  }) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/players/multivideo/$playerId/upload-slot-$slot'),
    );

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
      throw Exception('Video yüklenemedi: ${response.statusCode} - ${response.body}');
    }

    final data = json.decode(response.body);
    return MultiVideoPlayer.fromJson(data['player']);
  }

  /// Tüm videoları tamamlayınca analizi sonlandır
  static Future<MultiVideoPlayer> finalizePlayer(int playerId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/players/multivideo/$playerId/finalize'),
    ).timeout(Duration(seconds: 180)); // Gemini AI 1-2 dk sürebilir

    if (response.statusCode != 200) {
      throw Exception('Analiz tamamlanamadı: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['deleted'] == true) {
      throw Exception(data['error'] ?? 'Uyumsuz veya geçersiz video. Lütfen doğru mevki videolarını yükleyin.');
    }
    return MultiVideoPlayer.fromJson(data['player']);
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
