import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/user_model.dart';

class AuthRepository {
  final SharedPreferences _sharedPreferences;
  final ApiService _apiService;
  
  AuthRepository({
    required SharedPreferences sharedPreferences,
    required ApiService apiService,
  }) : _sharedPreferences = sharedPreferences,
       _apiService = apiService;

  Future<UserModel> login(String email, String password) async {
    try {
      final user = await _apiService.login(email, password);
      
      // Save user data and token
      await _saveUserData(user);
      
      return user;
    } catch (e) {
      throw Exception('Giriş başarısız: $e');
    }
  }

  Future<UserModel> register(Map<String, dynamic> userData) async {
    try {
      final user = await _apiService.register(userData);
      
      // Save user data and token
      await _saveUserData(user);
      
      return user;
    } catch (e) {
      throw Exception('Kayıt başarısız: $e');
    }
  }

  Future<void> logout() async {
    try {
      // Clear API service token
      _apiService.clearAuthToken();
      
      // Clear local storage
      await _sharedPreferences.remove(AppConstants.tokenKey);
      await _sharedPreferences.remove(AppConstants.userKey);
    } catch (e) {
      throw Exception('Çıkış yapılırken hata oluştu: $e');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final userJson = _sharedPreferences.getString(AppConstants.userKey);
      if (userJson != null) {
        final user = UserModel.fromJson(jsonDecode(userJson));
        
        // Set token for API service
        final token = _sharedPreferences.getString(AppConstants.tokenKey);
        if (token != null) {
          _apiService.setAuthToken(token);
        }
        
        return user;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final user = await getCurrentUser();
    return user != null;
  }

  Future<String?> getToken() async {
    return _sharedPreferences.getString(AppConstants.tokenKey);
  }

  Future<void> saveToken(String token) async {
    await _sharedPreferences.setString(AppConstants.tokenKey, token);
    _apiService.setAuthToken(token);
  }

  Future<void> _saveUserData(UserModel user) async {
    // Save user data
    await _sharedPreferences.setString(
      AppConstants.userKey,
      jsonEncode(user.toJson()),
    );
    
    // Note: In a real app, you'd get the token from the login response
    // For now, we'll use a mock token
    await saveToken('mock_token_${user.id}');
  }

  Future<void> updateUserData(UserModel user) async {
    await _sharedPreferences.setString(
      AppConstants.userKey,
      jsonEncode(user.toJson()),
    );
  }
}
