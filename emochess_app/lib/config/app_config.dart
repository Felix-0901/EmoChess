import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _apiBaseUrlEnv = String.fromEnvironment('API_BASE_URL');
  static const String _aiBaseUrlEnv = String.fromEnvironment('AI_BASE_URL');
  static const String _aiApiKeyEnv = String.fromEnvironment('AI_API_KEY');

  static String get apiBaseUrl {
    final configured = _apiBaseUrlEnv.trim();
    if (configured.isNotEmpty) {
      return _normalizeBaseUrl(configured);
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  static String get aiBaseUrl {
    final configured = _aiBaseUrlEnv.trim();
    if (configured.isNotEmpty) {
      return _normalizeBaseUrl(configured);
    }
    return 'https://free.v36.cm';
  }

  static String get aiApiKey => _aiApiKeyEnv.trim();

  static String _normalizeBaseUrl(String input) {
    var normalized = input.trim().replaceAll(RegExp(r'/+$'), '');
    if (normalized.endsWith('/v1')) {
      normalized = normalized.substring(0, normalized.length - 3);
    }
    return normalized;
  }
}

