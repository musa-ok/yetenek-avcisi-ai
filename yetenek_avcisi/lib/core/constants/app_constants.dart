class AppConstants {
  // API
  // iOS Simulator: http://127.0.0.1:8000
  // Android Emulator: http://10.0.2.2:8000
  // Physical Device: http://<YOUR_MAC_IP>:8000
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://yetenek-avcisi-ai.onrender.com', // Production: Render
  );
  
  // Routes
  static const String splashRoute = '/splash';
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String playersRoute = '/players';
  static const String playerDetailRoute = '/player-detail';
  static const String uploadRoute = '/upload';
  static const String profileRoute = '/profile';
  static const String settingsRoute = '/settings';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  static const String languageKey = 'language_code';
  
  // App Info
  static const String appName = 'Yetenek Avcısı';
  static const String appVersion = '2.0.0';
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultRadius = 12.0;
  static const double largeRadius = 16.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Rating Constants
  static const int maxRating = 99;
  static const int minRating = 1;
  
  // Position Types
  static const List<String> positions = [
    'Forvet',
    'Orta Saha',
    'Defans',
    'Kaleci',
  ];
  
  // Rating Categories
  static const List<String> ratingCategories = [
    'PAC',
    'SHO', 
    'PAS',
    'DRI',
    'DEF',
    'PHY',
  ];
}
