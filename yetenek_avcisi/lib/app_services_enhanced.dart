import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'app_services.dart';

/// Pozisyona özel analiz adımları için model
class AnalysisStep {
  final int stepNumber;
  final String name;
  final String focus;
  final String description;
  final int duration;

  AnalysisStep({
    required this.stepNumber,
    required this.name,
    required this.focus,
    required this.description,
    required this.duration,
  });

  factory AnalysisStep.fromJson(Map<String, dynamic> json) {
    return AnalysisStep(
      stepNumber: json['step_number'] ?? 0,
      name: json['name'] ?? '',
      focus: json['focus'] ?? '',
      description: json['description'] ?? '',
      duration: json['duration'] ?? 0,
    );
  }
}

/// Analiz adımları yanıtı
class AnalysisStepsResponse {
  final String position;
  final int totalSteps;
  final int estimatedDuration;
  final List<AnalysisStep> steps;

  AnalysisStepsResponse({
    required this.position,
    required this.totalSteps,
    required this.estimatedDuration,
    required this.steps,
  });

  factory AnalysisStepsResponse.fromJson(Map<String, dynamic> json) {
    return AnalysisStepsResponse(
      position: json['position'] ?? '',
      totalSteps: json['total_steps'] ?? 0,
      estimatedDuration: json['estimated_duration'] ?? 0,
      steps: (json['steps'] as List?)
          ?.map((e) => AnalysisStep.fromJson(e))
          .toList() ?? [],
    );
  }
}

/// Pozisyona özel detaylı analiz sonucu
class PositionSpecificAnalysis {
  final String position;
  final int averageScore;
  final String analysisType;
  final int totalSteps;
  final Map<String, dynamic> detailedRatings;
  final String aiScoutReport;
  final PlayerListItem? player;

  PositionSpecificAnalysis({
    required this.position,
    required this.averageScore,
    required this.analysisType,
    required this.totalSteps,
    required this.detailedRatings,
    required this.aiScoutReport,
    this.player,
  });

  factory PositionSpecificAnalysis.fromJson(Map<String, dynamic> json) {
    final summary = json['analysis_summary'] ?? {};
    final playerData = json['player'];
    
    return PositionSpecificAnalysis(
      position: json['position'] ?? '',
      averageScore: (summary['average_score'] ?? 0).toInt(),
      analysisType: summary['analysis_type'] ?? 'standard',
      totalSteps: summary['total_steps'] ?? 0,
      detailedRatings: summary['detailed_ratings'] ?? {},
      aiScoutReport: json['ai_scout_report'] ?? '',
      player: playerData != null ? PlayerListItem.fromJson(playerData) : null,
    );
  }

  /// Pozisyona göre özellikleri getir
  List<Map<String, dynamic>> getPositionSpecificTraits() {
    final traits = <Map<String, dynamic>>[];
    
    if (position == 'Forvet') {
      traits.addAll([
        {'name': 'Hız', 'key': 'pace', 'value': detailedRatings['pace'], 'icon': '⚡'},
        {'name': 'Bitiricilik', 'key': 'finishing', 'value': detailedRatings['finishing'], 'icon': '🎯'},
        {'name': 'Dar Alanda Dripling', 'key': 'dribbling_tight_spaces', 'value': detailedRatings['dribbling_tight_spaces'], 'icon': '🔄'},
        {'name': 'Kafa Vuruşu', 'key': 'heading', 'value': detailedRatings['heading'], 'icon': '👤'},
        {'name': 'Pozisyon', 'key': 'positioning', 'value': detailedRatings['positioning'], 'icon': '📍'},
        {'name': 'Soğukkanlılık', 'key': 'composure', 'value': detailedRatings['composure'], 'icon': '🧊'},
      ]);
    } else if (position == 'Kaleci') {
      traits.addAll([
        {'name': 'Refleksler', 'key': 'gk_reflexes', 'value': detailedRatings['gk_reflexes'], 'icon': '👐'},
        {'name': 'Yanlara Atış', 'key': 'gk_diving', 'value': detailedRatings['gk_diving'], 'icon': '🛹'},
        {'name': 'Top Tutma', 'key': 'gk_handling', 'value': detailedRatings['gk_handling'], 'icon': '🤲'},
        {'name': 'Pozisyon', 'key': 'gk_positioning', 'value': detailedRatings['gk_positioning'], 'icon': '📍'},
        {'name': 'Top Dağıtımı', 'key': 'gk_distribution', 'value': detailedRatings['gk_distribution'], 'icon': '⚽'},
        {'name': 'Alan Kontrolü', 'key': 'gk_command_area', 'value': detailedRatings['gk_command_area'], 'icon': '🏰'},
        {'name': '1\'e 1', 'key': 'gk_1v1', 'value': detailedRatings['gk_1v1'], 'icon': '🥅'},
      ]);
    }
    
    return traits.where((t) => t['value'] != null).toList();
  }
}

/// Pozisyona özel analiz servisi
class PositionAnalysisService {
  static final String _baseUrl = kApiBaseUrl;

  /// Analiz adımlarını getir
  static Future<AnalysisStepsResponse> fetchAnalysisSteps(String position) async {
    final res = await http
        .get(Uri.parse('$_baseUrl/analysis-steps/$position'),
            headers: {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 30));

    if (res.statusCode != 200) {
      throw Exception('Analiz adımları alınamadı: ${res.statusCode}');
    }

    final decoded = json.decode(res.body);
    return AnalysisStepsResponse.fromJson(decoded);
  }

  /// Adım adım video analizi yap
  static Future<PositionSpecificAnalysis> uploadAndAnalyzeStepByStep({
    required int userId,
    required String name,
    required int age,
    required String position,
    required File videoFile,
    Function(int currentStep, int totalSteps, String stepName)? onProgress,
  }) async {
    // Multipart request oluştur
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload-video-step-by-step/'),
    );

    // Form fields ekle
    request.fields['user_id'] = userId.toString();
    request.fields['name'] = name;
    request.fields['age'] = age.toString();
    request.fields['position'] = position;

    // Video dosyasını ekle
    final videoStream = http.ByteStream(videoFile.openRead());
    final videoLength = await videoFile.length();
    
    final multipartFile = http.MultipartFile(
      'file',
      videoStream,
      videoLength,
      filename: videoFile.path.split('/').last,
    );
    request.files.add(multipartFile);

    // Gönder ve yanıtı bekle
    final streamedResponse = await request.send()
        .timeout(const Duration(minutes: 5));
    
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode != 200) {
      throw Exception('Video analizi başarısız: ${res.statusCode} - ${res.body}');
    }

    final decoded = json.decode(res.body);
    return PositionSpecificAnalysis.fromJson(decoded);
  }

  /// Standart video analizi (hızlı mod)
  static Future<PositionSpecificAnalysis> uploadAndAnalyzeStandard({
    required int userId,
    required String name,
    required int age,
    required String position,
    required File videoFile,
  }) async {
    // Analiz adımlarını önce getir
    final steps = await fetchAnalysisSteps(position);
    
    // Normal upload endpoint'ini kullan
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$_baseUrl/upload-video/'),
    );

    request.fields['user_id'] = userId.toString();
    request.fields['name'] = name;
    request.fields['age'] = age.toString();
    request.fields['position'] = position;

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
        .timeout(const Duration(minutes: 5));
    
    final res = await http.Response.fromStream(streamedResponse);

    if (res.statusCode != 200) {
      throw Exception('Video analizi başarısız: ${res.statusCode}');
    }

    final decoded = json.decode(res.body);
    
    // Yanıtı yeni formata dönüştür
    return PositionSpecificAnalysis(
      position: position,
      averageScore: decoded['overall_rating'] ?? 50,
      analysisType: 'standard',
      totalSteps: steps.totalSteps,
      detailedRatings: {
        'pace': decoded['pace'],
        'finishing': decoded['finishing'],
        'dribbling': decoded['dribbling'],
        'positioning': decoded['positioning'],
        'gk_reflexes': decoded['gk_reflexes'],
        'gk_diving': decoded['gk_diving'],
        'gk_handling': decoded['gk_handling'],
        'gk_positioning': decoded['gk_positioning'],
      },
      aiScoutReport: decoded['ai_scout_report'] ?? '',
      player: PlayerListItem.fromJson(decoded),
    );
  }
}
