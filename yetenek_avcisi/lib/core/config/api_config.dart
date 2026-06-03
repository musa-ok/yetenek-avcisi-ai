/// API tabanı: `--dart-define=API_BASE_URL=...` ile override.
/// Yerel backend için: `--dart-define=API_BASE_URL=http://127.0.0.1:8000`
const _prodApi = 'https://stingray-app-g3o9y.ondigitalocean.app';

String resolveApiBaseUrl() {
  const fromEnv = String.fromEnvironment('API_BASE_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  return _prodApi;
}

final String kApiBaseUrl = resolveApiBaseUrl();
