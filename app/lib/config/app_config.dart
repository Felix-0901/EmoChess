class AppConfig {
  static const String _apiBaseUrlEnv = String.fromEnvironment('API_BASE_URL');
  static const String _fallbackApiBaseUrl = 'https://api.example.invalid/api';

  static Future<void> init() async {
    return;
  }

  static String get apiBaseUrl {
    final configured = _apiBaseUrlEnv.trim();
    if (configured.isNotEmpty) {
      return _normalizeApiBaseUrl(configured);
    }
    return _defaultApiBaseUrl;
  }

  static String get _defaultApiBaseUrl =>
      _normalizeApiBaseUrl(_fallbackApiBaseUrl);

  static String _normalizeApiBaseUrl(String input) {
    final normalized = _normalizeBaseUrl(input);
    try {
      final uri = Uri.parse(normalized);
      final path = uri.path;
      if (path.isEmpty || path == '/') {
        return uri.replace(path: '/api').toString();
      }
    } catch (_) {}
    return normalized;
  }

  static String _normalizeBaseUrl(String input) {
    var normalized = input.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized.endsWith('/v1')) {
      normalized = normalized.substring(0, normalized.length - 3);
    }
    return normalized;
  }
}
