import 'package:flutter/foundation.dart';

/// API tabanı: `--dart-define=API_BASE_URL=...` ile override.
/// Debug/simülatörde varsayılan yerel backend (KVKK export vb.).
String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (kDebugMode) return 'http://127.0.0.1:8000';
  return 'https://stingray-app-g3o9y.ondigitalocean.app';
}

final String kApiBaseUrl = resolveApiBaseUrl();
