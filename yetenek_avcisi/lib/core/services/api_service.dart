import 'package:dio/dio.dart';

import '../../app_services.dart';
import '../api/api_client.dart';
import '../constants/app_constants.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/players/data/models/player_model.dart';

/// Dio tabanlı servis — token [ApiClient] / [SessionStore] ile senkron.
class ApiService {
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = currentAccessTokenNotifier.value?.trim();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] ??= 'application/json';
          handler.next(options);
        },
      ),
    );
  }

  late final Dio _dio;

  Future<UserModel> login(String email, String password) async {
    final session = await BackendApi.login(email: email, password: password);
    await SessionStore.save(session);
    return UserModel.fromJson(session.user.toJson());
  }

  Future<UserModel> register(Map<String, dynamic> userData) async {
    await BackendApi.register(
      fullName: userData['full_name'] ?? '',
      email: userData['email'] ?? '',
      password: userData['password'] ?? '',
      role: userData['role'] ?? 'Scout',
      phoneNumber: userData['phone_number'] ?? '',
    );
    final session = await BackendApi.login(
      email: userData['email'] ?? '',
      password: userData['password'] ?? '',
    );
    await SessionStore.save(session);
    return UserModel.fromJson(session.user.toJson());
  }

  Future<List<PlayerModel>> getPlayers() async {
    final items = await BackendApi.fetchPlayers();
    return items
        .map(
          (p) => PlayerModel(
            id: '${p.id}',
            userId: '${p.id}',
            name: p.name,
            age: p.age,
            position: p.position,
            overallRating: p.overallRating,
            aiScoutReport: p.aiScoutReport,
            videoUrl: null,
          ),
        )
        .toList();
  }

  Future<PlayerModel> getPlayerDetail(String playerId) async {
    final detail = await BackendApi.fetchPlayerDetail(int.parse(playerId));
    final p = detail.player;
    final r = detail.rating;
    return PlayerModel(
      id: '${p.id}',
      userId: '${p.id}',
      name: p.name,
      age: p.age,
      position: p.position,
      overallRating: r.ovr,
      pace: r.pac,
      shooting: r.sho,
      passing: r.pas,
      dribbling: r.dri,
      defending: r.def,
      physical: r.phy,
      aiScoutReport: p.aiScoutReport,
    );
  }

  Exception _handleError(DioException e) {
    if (e.response?.data is Map && e.response?.data['detail'] != null) {
      return Exception('${e.response?.data['detail']}');
    }
    return Exception(e.message ?? 'Ag hatasi');
  }
}
