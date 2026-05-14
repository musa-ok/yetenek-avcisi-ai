import 'dart:convert';
import 'package:dio/dio.dart';
import '../constants/app_constants.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/players/data/models/player_model.dart';

class ApiService {
  late Dio _dio;
  
  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }
  
  // Auth
  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _dio.post(
        '/login',
        data: {
          'email': email,
          'password': password,
        },
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<UserModel> register(Map<String, dynamic> userData) async {
    try {
      final response = await _dio.post(
        '/register',
        data: userData,
      );
      return UserModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Players
  Future<List<PlayerModel>> getPlayers() async {
    try {
      final response = await _dio.get('/players');
      return (response.data as List)
          .map((json) => PlayerModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<PlayerModel> getPlayerDetail(String playerId) async {
    try {
      final response = await _dio.get('/players/$playerId');
      return PlayerModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<PlayerModel> createPlayer(Map<String, dynamic> playerData) async {
    try {
      final response = await _dio.post(
        '/players',
        data: playerData,
      );
      return PlayerModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<PlayerModel> uploadVideoAndAnalyze({
    required String userId,
    required String name,
    required int age,
    required String position,
    required String videoPath,
  }) async {
    try {
      final formData = FormData.fromMap({
        'user_id': userId,
        'name': name,
        'age': age,
        'position': position,
        'file': await MultipartFile.fromFile(videoPath),
      });
      
      final response = await _dio.post(
        '/upload-video/',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      
      return PlayerModel.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> ratePlayer({
    required String playerId,
    required Map<String, dynamic> ratingData,
  }) async {
    try {
      await _dio.post(
        '/players/$playerId/rate',
        data: ratingData,
      );
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Add auth token to requests
  void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  // Remove auth token
  void clearAuthToken() {
    _dio.options.headers.remove('Authorization');
  }
  
  // Error handling
  String _handleError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return 'Bağlantı zaman aşımı. Lütfen internet bağlantınızı kontrol edin.';
      case DioExceptionType.sendTimeout:
        return 'İstek zaman aşımı. Lütfen tekrar deneyin.';
      case DioExceptionType.receiveTimeout:
        return 'Yanıt zaman aşımı. Lütfen tekrar deneyin.';
      case DioExceptionType.badResponse:
        if (error.response?.data is Map<String, dynamic>) {
          final data = error.response!.data as Map<String, dynamic>;
          return data['detail'] ?? 'Bir hata oluştu.';
        }
        return 'Sunucu hatası: ${error.response?.statusCode}';
      case DioExceptionType.cancel:
        return 'İstek iptal edildi.';
      case DioExceptionType.unknown:
        return 'Bilinmeyen bir hata oluştu. Lütfen tekrar deneyin.';
      default:
        return 'Bir hata oluştu: ${error.message}';
    }
  }
}
