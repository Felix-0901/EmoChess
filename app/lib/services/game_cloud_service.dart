import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../models/conversation_round.dart';
import '../models/game_record.dart';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';

class GameCloudService {
  static const Duration _timeout = Duration(seconds: 15);

  final String _apiBaseUrl;
  final TokenStorage _tokenStorage;
  final http.Client _client;
  final AuthService _authService;

  GameCloudService({
    String? apiBaseUrl,
    TokenStorage? tokenStorage,
    http.Client? client,
    AuthService? authService,
  }) : _apiBaseUrl = _normalizeBaseUrl(apiBaseUrl ?? AppConfig.apiBaseUrl),
       _tokenStorage = tokenStorage ?? SecureTokenStorage(),
       _client = client ?? http.Client(),
       _authService = authService ?? AuthService();

  String get _gamesEndpoint => '$_apiBaseUrl/games';

  Future<String?> uploadGameRecord(GameRecord record) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) return null;

    final body = _toCreateGamePayload(record);

    final first = await _client
        .post(
          Uri.parse(_gamesEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (first.statusCode == 201) {
      final data = _tryDecodeMap(first.body);
      final rec = (data?['record'] as Map?)?.cast<String, dynamic>();
      return rec?['id'] as String?;
    }

    if (first.statusCode == 409) {
      final existing = await _findGameIdBySessionId(record.sessionId);
      return existing;
    }

    if (first.statusCode != 401) return null;

    final refreshed = await _authService.refreshToken();
    if (!refreshed) return null;

    final newToken = await _tokenStorage.readAccessToken();
    if (newToken == null || newToken.trim().isEmpty) return null;

    final second = await _client
        .post(
          Uri.parse(_gamesEndpoint),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
          body: jsonEncode(body),
        )
        .timeout(_timeout);

    if (second.statusCode != 201) return null;
    final data = _tryDecodeMap(second.body);
    final rec = (data?['record'] as Map?)?.cast<String, dynamic>();
    return rec?['id'] as String?;
  }

  Future<String?> _findGameIdBySessionId(String sessionId) async {
    final list = await fetchGameList(limit: 100);
    for (final rec in list) {
      if (rec.sessionId == sessionId && rec.cloudId != null) {
        return rec.cloudId;
      }
    }
    return null;
  }

  Future<List<GameRecord>> fetchGameList({int page = 1, int limit = 50}) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) return [];

    final uri = Uri.parse(_gamesEndpoint).replace(
      queryParameters: {'page': '$page', 'limit': '$limit'},
    );

    final first = await _client
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(_timeout);

    if (first.statusCode == 200) {
      return _parseGameList(first.body);
    }

    if (first.statusCode != 401) return [];

    final refreshed = await _authService.refreshToken();
    if (!refreshed) return [];

    final newToken = await _tokenStorage.readAccessToken();
    if (newToken == null || newToken.trim().isEmpty) return [];

    final second = await _client
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        )
        .timeout(_timeout);

    if (second.statusCode != 200) return [];
    return _parseGameList(second.body);
  }

  Future<GameRecord?> fetchGameDetail(String gameId) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) return null;

    final uri = Uri.parse('$_gamesEndpoint/$gameId');

    final first = await _client
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(_timeout);

    if (first.statusCode == 200) {
      return _parseGameDetail(first.body, gameId);
    }

    if (first.statusCode != 401) return null;

    final refreshed = await _authService.refreshToken();
    if (!refreshed) return null;

    final newToken = await _tokenStorage.readAccessToken();
    if (newToken == null || newToken.trim().isEmpty) return null;

    final second = await _client
        .get(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        )
        .timeout(_timeout);

    if (second.statusCode != 200) return null;
    return _parseGameDetail(second.body, gameId);
  }

  Future<bool> deleteGame(String gameId) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) return false;

    final uri = Uri.parse('$_gamesEndpoint/$gameId');

    final first = await _client
        .delete(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(_timeout);

    if (first.statusCode == 200) return true;
    if (first.statusCode != 401) return false;

    final refreshed = await _authService.refreshToken();
    if (!refreshed) return false;

    final newToken = await _tokenStorage.readAccessToken();
    if (newToken == null || newToken.trim().isEmpty) return false;

    final second = await _client
        .delete(
          uri,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $newToken',
          },
        )
        .timeout(_timeout);

    return second.statusCode == 200;
  }

  Map<String, dynamic> _toCreateGamePayload(GameRecord record) {
    return {
      'sessionId': record.sessionId,
      'startTime': record.startTime.toIso8601String(),
      if (record.endTime != null) 'endTime': record.endTime!.toIso8601String(),
      'initialEmotion': record.initialEmotion,
      if (record.result != null) 'result': record.result,
      'durationSeconds': record.duration.inSeconds,
      'moves': record.moves.map((m) => m.toJson()).toList(),
      'chatHistory': record.chatHistory.map((c) => c.toJson()).toList(),
      'emotionLog': record.emotionLog.map((e) => e.toJson()).toList(),
      'conversationRounds': record.conversationRounds.map(_roundToJson).toList(),
    };
  }

  Map<String, dynamic> _roundToJson(ConversationRound r) {
    final json = r.toJson();
    return {
      'roundId': json['roundId'],
      'aiQuestion': json['aiQuestion'],
      'choices': (json['choices'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      'selectedChoice': json['selectedChoice'],
      'aiReply': json['aiReply'],
      'timestamp': json['timestamp'],
      if (json['moveNumber'] != null) 'moveNumber': json['moveNumber'],
      if (json['emotion'] != null) 'emotion': json['emotion'],
      if (json['trigger'] != null) 'trigger': json['trigger'],
      if (json['intent'] != null) 'intent': json['intent'],
      if (json['angleKey'] != null) 'angleKey': json['angleKey'],
      if (json['promptVersion'] != null) 'promptVersion': json['promptVersion'],
    };
  }

  List<GameRecord> _parseGameList(String body) {
    final data = _tryDecodeMap(body);
    final list = (data?['records'] as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((m) => m.cast<String, dynamic>())
        .map((m) {
          final id = (m['id'] as String?)?.trim();
          final sessionId = (m['sessionId'] as String?)?.trim() ?? '';
          final startTimeStr = m['startTime']?.toString() ?? '';
          final endTimeStr = m['endTime']?.toString();
          final startTime = DateTime.tryParse(startTimeStr) ?? DateTime.now();
          final endTime = endTimeStr != null ? DateTime.tryParse(endTimeStr) : null;
          return GameRecord(
            cloudId: id,
            sessionId: sessionId.isEmpty ? (id ?? '') : sessionId,
            startTime: startTime,
            endTime: endTime,
            initialEmotion: (m['initialEmotion'] as String?)?.trim() ?? 'neutral',
            result: m['result'] as String?,
            movesCount:
                m['movesCount'] is int
                    ? m['movesCount'] as int
                    : int.tryParse('${m['movesCount']}'),
          );
        })
        .toList();
  }

  GameRecord? _parseGameDetail(String body, String gameId) {
    final data = _tryDecodeMap(body);
    final rec = (data?['record'] as Map?)?.cast<String, dynamic>();
    if (rec == null) return null;

    final sessionId = (rec['sessionId'] as String?)?.trim() ?? '';
    final startTime = DateTime.tryParse(rec['startTime']?.toString() ?? '');
    if (startTime == null) return null;

    final endTime =
        rec['endTime'] != null ? DateTime.tryParse(rec['endTime'].toString()) : null;

    final moves =
        (rec['moves'] as List?)
            ?.whereType<Map>()
            .map((m) => MoveRecord.fromJson(m.cast<String, dynamic>()))
            .toList() ??
        [];
    final chats =
        (rec['chatHistory'] as List?)
            ?.whereType<Map>()
            .map((c) => ChatRecord.fromJson(c.cast<String, dynamic>()))
            .toList() ??
        [];
    final emotions =
        (rec['emotionLog'] as List?)
            ?.whereType<Map>()
            .map((e) => EmotionRecord.fromJson(e.cast<String, dynamic>()))
            .toList() ??
        [];
    final rounds =
        (rec['conversationRounds'] as List?)
            ?.whereType<Map>()
            .map((r) => ConversationRound.fromJson(r.cast<String, dynamic>()))
            .toList() ??
        [];

    return GameRecord(
      cloudId: gameId,
      sessionId: sessionId.isEmpty ? gameId : sessionId,
      startTime: startTime,
      endTime: endTime,
      initialEmotion: (rec['initialEmotion'] as String?)?.trim() ?? 'neutral',
      result: rec['result'] as String?,
      moves: moves,
      chatHistory: chats,
      emotionLog: emotions,
      conversationRounds: rounds,
    );
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
