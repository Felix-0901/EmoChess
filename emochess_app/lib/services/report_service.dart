import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';

class ReportService {
  static const Duration _timeout = Duration(seconds: 25);

  final String _apiBaseUrl;
  final TokenStorage _tokenStorage;
  final http.Client _client;
  final AuthService _authService;

  ReportService({
    String? apiBaseUrl,
    TokenStorage? tokenStorage,
    http.Client? client,
    AuthService? authService,
  }) : _apiBaseUrl = _normalizeBaseUrl(apiBaseUrl ?? AppConfig.apiBaseUrl),
       _tokenStorage = tokenStorage ?? SecureTokenStorage(),
       _client = client ?? http.Client(),
       _authService = authService ?? AuthService();

  Future<Map<String, dynamic>?> generateGameReport({
    required String gameId,
    required String language,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) return null;

    final uri = Uri.parse('$_apiBaseUrl/reports/game/$gameId');
    final payload = {'language': language};

    final first = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    final firstJson = _tryDecodeMap(first.body);
    if (first.statusCode == 200) {
      final report = (firstJson?['report'] as Map?)?.cast<String, dynamic>();
      final reportJson = (report?['reportJson'] as Map?)?.cast<String, dynamic>();
      return reportJson;
    }

    if (first.statusCode != 401) return null;

    final refreshed = await _authService.refreshToken();
    if (!refreshed) return null;

    final newToken = await _tokenStorage.readAccessToken();
    if (newToken == null || newToken.trim().isEmpty) return null;

    final second = await _client
        .post(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: jsonEncode(payload),
        )
        .timeout(_timeout);

    final secondJson = _tryDecodeMap(second.body);
    if (second.statusCode != 200) return null;
    final report = (secondJson?['report'] as Map?)?.cast<String, dynamic>();
    final reportJson = (report?['reportJson'] as Map?)?.cast<String, dynamic>();
    return reportJson;
  }
}

String _normalizeBaseUrl(String input) {
  final trimmed = input.trim().replaceAll(RegExp(r'/+$'), '');
  return trimmed;
}

Map<String, dynamic>? _tryDecodeMap(String body) {
  try {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) return decoded;
  } catch (_) {}
  return null;
}

