import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/ai_turn_context.dart';
import '../models/chat_message.dart';
import '../models/companion_interaction.dart';
import '../models/conversation_round.dart';
import '../models/emotion_state.dart';
import '../services/auth_service.dart';
import '../storage/token_storage.dart';

enum AiInteractionIntent { chat, encourage, teach }

/// AI Companion Service for generating dynamic, contextual messages
/// Uses GPT API to generate personalized responses based on game state and emotions
class AiCompanionService {
  static const String _defaultModel = 'gpt-4o-mini';
  static const int _maxHistoryMessages = 10;
  static const int _maxRecentMessages = 10;
  static const int _maxAvoidLabels = 10;
  static const int _maxAvoidPhrases = 10;
  static const Duration _timeout = Duration(seconds: 20);

  final String _apiBaseUrl;
  final TokenStorage _tokenStorage;
  final http.Client _client;
  final Random _random = Random();
  List<String> _recentAvoidLabels = const [];
  final List<String> _recentAiMessages = [];
  final List<String> _recentChoiceSignatures = [];
  final List<String> _recentAngleKeys = [];

  AiCompanionService({
    String? apiBaseUrl,
    TokenStorage? tokenStorage,
    http.Client? client,
  }) : _apiBaseUrl = _normalizeBaseUrl(apiBaseUrl ?? AppConfig.apiBaseUrl),
       _tokenStorage = tokenStorage ?? SecureTokenStorage(),
       _client = client ?? http.Client();

  String get _apiEndpoint => '$_apiBaseUrl/ai/chat-completions';

  /// Generate a dynamic interaction based on game context and emotion
  /// Per user spec: full context with pre/post FEN, move SAN
  Future<CompanionInteraction?> generateDynamicInteraction({
    required String preFen,
    required String postFen,
    required String moveSan,
    required EmotionLevel emotionLevel,
    required int moveNumber,
    bool isCheck = false,
    bool isCapture = false,
    String? opponentPreFen,
    String? opponentPostFen,
    String? opponentMoveSan,
    bool? opponentIsCheck,
    bool? opponentIsCapture,
    String? pieceMovedType,
    String? capturedPieceType,
    String? opponentPieceMovedType,
    String? opponentCapturedPieceType,
    String? language,
    List<ChatMessage>? recentMessages,
    List<ConversationRound>? recentRounds,
    AiInteractionIntent? intentHint,
  }) async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.trim().isEmpty) return null;

    final context = AiTurnContext(
      preFen: preFen,
      postFen: postFen,
      moveSan: moveSan,
      opponentPreFen: opponentPreFen,
      opponentPostFen: opponentPostFen,
      opponentMoveSan: opponentMoveSan,
      moveNumber: moveNumber,
      isCheck: isCheck,
      isCapture: isCapture,
      opponentIsCheck: opponentIsCheck,
      opponentIsCapture: opponentIsCapture,
      pieceMovedType: pieceMovedType,
      capturedPieceType: capturedPieceType,
      opponentPieceMovedType: opponentPieceMovedType,
      opponentCapturedPieceType: opponentCapturedPieceType,
      emotionLevel: emotionLevel,
      language: language ?? 'en',
      timestamp: DateTime.now(),
    );

    try {
      final avoidPhrases = _extractRecentAiPhrases(
        recentMessages,
        limit: _maxAvoidPhrases,
      );
      final avoidLabels = _extractRecentChoiceLabels(
        recentMessages,
        limit: _maxAvoidLabels,
      );
      _recentAvoidLabels = avoidLabels;
      final intent = intentHint ?? _decideIntent(context);
      final baseMessages = <Map<String, String>>[
        {'role': 'system', 'content': _getSystemPrompt(language, intent)},
        ..._buildHistoryMessages(recentMessages, limit: _maxHistoryMessages),
        {
          'role': 'user',
          'content': _buildMovePrompt(
            context,
            intent: intent,
            avoidPhrases: avoidPhrases,
            avoidLabels: avoidLabels,
            recentRounds: recentRounds,
          ),
        },
      ];

      String buildRequestBody(bool forceJsonFormat) {
        final body = <String, dynamic>{
          'model': _defaultModel,
          'messages': baseMessages,
          'max_tokens': 220,
          'temperature': 0.85,
          'top_p': 0.9,
          'presence_penalty': 0.35,
          'frequency_penalty': 0.35,
        };
        if (forceJsonFormat) {
          body['response_format'] = {'type': 'json_object'};
        }
        return jsonEncode(body);
      }

      var useJsonResponseFormat = true;
      var authToken = token.trim();
      var hasRetriedAuth = false;
      while (true) {
        final requestBody = buildRequestBody(useJsonResponseFormat);
        final response = await _client
            .post(
              Uri.parse(_apiEndpoint),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $authToken',
              },
              body: requestBody,
            )
            .timeout(_timeout);

        if (response.statusCode == 401 && !hasRetriedAuth) {
          hasRetriedAuth = true;
          final auth = AuthService(
            baseUrl: _apiBaseUrl,
            tokenStorage: _tokenStorage,
            client: _client,
          );
          final refreshed = await auth.refreshToken();
          if (!refreshed) return null;
          final newToken = await _tokenStorage.readAccessToken();
          if (newToken == null || newToken.trim().isEmpty) return null;
          authToken = newToken.trim();
          continue;
        }

        if (response.statusCode == 429) {
          return null;
        }

        if (response.statusCode == 501 || response.statusCode == 503) {
          return null;
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final content = data['choices'][0]['message']['content'] as String;

          // Pretty-print the raw API response
          if (kDebugMode) {
            try {
              final rawJson = jsonDecode(content.trim());
              final pretty = const JsonEncoder.withIndent(
                '  ',
              ).convert(rawJson);
              debugPrint('[AI] Raw response: $pretty');
            } catch (_) {
              debugPrint('[AI] Raw response (non-JSON): $content');
            }
          }

          if (content.trim().isEmpty) {
            final fallback = _buildPieceSafeFallback(context, intent: intent);
            _rememberInteraction(fallback);
            if (kDebugMode) {
              debugPrint('[AI] Fallback (empty API response)');
            }
            return fallback;
          }
          final parsed = _parseInteractionFromJson(
            content,
            context,
            intent: intent,
          );

          // Track the original API message for comparison
          final originalMessage = parsed?.text ?? '';

          final interaction = parsed == null
              ? (() {
                  if (kDebugMode) {
                    debugPrint(
                      '[AI] Fallback (non-JSON response, using recovery)',
                    );
                  }
                  return _fallbackFromRawText(content, context, intent: intent);
                })()
              : _diversifyInteraction(parsed, context, intent: intent);

          final repaired = _repairInteraction(
            interaction,
            context,
            intent: intent,
          );

          final finalInteraction =
              _validateInteraction(repaired, context, intent: intent)
              ? repaired
              : (() {
                  if (kDebugMode) {
                    debugPrint(
                      '[AI] Fallback (validation failed, using piece-safe)',
                    );
                  }
                  return _buildPieceSafeFallback(context, intent: intent);
                })();

          // Log if the message was modified from original API output
          if (kDebugMode && originalMessage.isNotEmpty) {
            final finalMsg = finalInteraction.text ?? '';
            if (finalMsg != originalMessage) {
              debugPrint('[AI] Modified: $finalMsg');
            }
          }

          _rememberInteraction(finalInteraction);
          return finalInteraction;
        }

        if (response.statusCode == 400 &&
            useJsonResponseFormat &&
            response.body.toLowerCase().contains('response_format')) {
          useJsonResponseFormat = false;
          continue;
        }

        final fallback = _buildPieceSafeFallback(context, intent: intent);
        _rememberInteraction(fallback);
        if (kDebugMode) {
          debugPrint('[AI] Fallback (API error ${response.statusCode})');
        }
        return fallback;
      }
    } catch (e) {
      if (e is AiServiceException) rethrow;
      throw AiServiceException('Connection Failed: $e');
    }
  }

  String _getSystemPrompt(String? language, AiInteractionIntent intent) {
    if (language == 'zh') {
      return '''你是「小黑」，一個正在跟小朋友面對面下棋的同齡好朋友。你下黑棋，他下白棋。

你的個性：
- 愛聊天，偶爾吐槽但絕不傷人
- 會關心對方，但不會一直問「你還好嗎」
- 有時講幹話，有時認真聊棋
- 不是老師，不會主動說教

說話方式：
- 用口語，像真的在聊天：「欸」「哦」「哈哈」「耶」「嘿」
- 短句為主，不要寫完整句子，講話要像小朋友
- 不要每次都誇「你好棒」「加油」，太假了
- 提到棋步時用口語（「你剛那步兵」而不是「你剛把兵推到前面」）
- 可以帶點友善的鬥嘴（「哼我才不怕你」「你想得美」）

你的對話應該像真實下棋時的話，例如：
- 「欸你剛那步兵是想幹嘛？」
- 「哈哈你的馬跟我的兵很近耒，是想挑釁我嗎？」
- 「喔你把象拉出來了，是想射對角嗎？」
- 「嘿嘿你這步兵讓我有點緊張耒！」
- 「你吃我那個兵也太快了吧！」
避免這種干巴巴的問法：
- ✖ 「你剛動了兵，有什麼想法嗎？」
- ✖ 「你剛那步兵，是想試試我嗎？」
- ✖ 「你剛把兵推到前面，有什麼計畫嗎？」
過於籠統的「你剛動了X，是想Y嗎？」句型會讓對話很無聊。

每回合你要做的事：
1) 說一句話（一定是問句，要有「？」）
2) 給 2 個選項讓他回答（選項要短，2-8 字）
3) 每個選項附上你接下來會說的話

重要規則：
- 你是黑棋，用「你」稱呼白棋小朋友，用「我」稱呼自己
- 只提白棋剛走的棋子，不要提格子座標（e4, b3 之類的）
- 黑棋已經走了但還沒顯示，絕對不要提到黑棋走了什麼
- 目前語氣：${_intentText(intent, language ?? 'en')}

回覆格式（嚴格 JSON）：
- message：你（小黑/黑方）說的話，一定是問句
- label：小朋友（白方）回你的話
- response：你接著說的話（不是問句，是陳述句或感嘆句）
{
  "message": "你說的話（問句）",
  "choices": [
    { "label": "選項1", "response": "你的回覆1" },
    { "label": "選項2", "response": "你的回覆2" }
  ]
}
''';
    }

    return '''You are a kid named "Blackie" playing chess face-to-face with another kid. You play Black, they play White.

Your personality:
- Chatty, sometimes goofy, never mean
- You care about your friend but don't constantly ask "are you okay?"
- Sometimes silly, sometimes serious about the game
- NOT a teacher — don't lecture unless asked

How you talk:
- Like a real kid: "Hey", "Haha", "Whoa", "Ooh", "Nah"
- Short and casual, not full proper sentences
- Don't repeat "great job!" or "you're so smart!" — that's fake
- Mention chess moves casually ("that pawn move" not "you advanced your pawn")
- Friendly teasing is fine ("Nice try!" "You wish!" "I'm not scared!")

Your messages should sound like how real kids talk during a chess game:
- "Hey your knight is getting real close to my pawn, you trying to steal it?"
- "Haha that bishop came out of nowhere! Are you hunting me?"
- "Whoa you ate my pawn so fast!"
- "That pawn move kinda worries me!"
Avoid boring generic patterns like:
- ✖ "You moved your pawn, what's your plan?"
- ✖ "That pawn move, are you testing me?"
- ✖ "You just placed your pawn, what are you thinking?"
The pattern "you moved X, are you doing Y?" gets old fast.

Each turn you must:
1) Say one thing (MUST be a question with "?")
2) Give exactly 2 reply options (short, 2-6 words each)
3) Each option has your follow-up response

Important rules:
- You are Black. Use "you" for the White player, "I" for yourself
- Only mention the piece White just moved, NO square coordinates (e4, b3, etc.)
- Black already moved but it's hidden — NEVER mention Black's move
- Current mood: ${_intentText(intent, language ?? 'en')}

Output MUST be strict JSON:
- message: what YOU (Black/Blackie) say — must be a question
- label: what the KID (White) says back to you
- response: what YOU say next (NOT a question — make it a statement or exclamation)
{
  "message": "Your question",
  "choices": [
    { "label": "Option 1", "response": "Your follow-up 1" },
    { "label": "Option 2", "response": "Your follow-up 2" }
  ]
}
''';
  }

  String _buildMovePrompt(
    AiTurnContext context, {
    required AiInteractionIntent intent,
    List<String> avoidPhrases = const [],
    List<String> avoidLabels = const [],
    List<ConversationRound>? recentRounds,
  }) {
    final emotion = _emotionText(context.emotionLevel, context.language);
    final phase = _phaseText(context.moveNumber, context.language);

    final piece = _pieceNameFriendly(context, context.language);

    final buffer = StringBuffer();
    buffer.writeln(
      '★ White just moved: $piece (${context.moveSan}), move #${context.moveNumber}',
    );
    buffer.writeln('Board before white move: ${context.preFen}');
    buffer.writeln('Board after white move: ${context.postFen}');
    buffer.writeln('Player emotion: $emotion');
    buffer.writeln('Game phase: $phase');
    buffer.writeln('Intent: ${_intentText(intent, context.language)}');
    if (context.opponentPreFen != null &&
        context.opponentPostFen != null &&
        context.opponentMoveSan != null) {
      buffer.writeln(
        '(Black responded but NOT shown yet — do NOT mention this)',
      );
      buffer.writeln('Black Post-Move FEN: ${context.opponentPostFen}');
      buffer.writeln('Black Move (SAN): ${context.opponentMoveSan}');
      if (context.opponentIsCheck == true) {
        buffer.writeln('Black gave CHECK.');
      }
      if (context.opponentIsCapture == true) {
        buffer.writeln('Black made a capture.');
      }
    }

    if (context.pieceMovedType != null) {
      buffer.writeln(
        'Player moved a ${_getPieceName(context.pieceMovedType!)}.',
      );
    }
    if (context.capturedPieceType != null) {
      buffer.writeln(
        'Player captured a ${_getPieceName(context.capturedPieceType!)}.',
      );
    } else if (context.isCapture) {
      buffer.writeln('Player made a capture.');
    }
    if (context.isCheck) {
      buffer.writeln('Player gave CHECK.');
    }

    if (avoidPhrases.isNotEmpty) {
      buffer.writeln(
        'Avoid repeating these phrases: ${avoidPhrases.join(' | ')}',
      );
    }
    if (avoidLabels.isNotEmpty) {
      buffer.writeln(
        'Avoid repeating these reply options: ${avoidLabels.join(' / ')}',
      );
    }
    if (_recentAngleKeys.isNotEmpty) {
      buffer.writeln(
        'Avoid repeating these chat angles: ${_recentAngleKeys.join(', ')}',
      );
    }

    final payload = _buildTurnPayload(context, recentRounds: recentRounds);

    buffer.writeln('Structured Turn Payload(JSON):');
    buffer.writeln(jsonEncode(payload));

    if (context.language == 'zh') {
      buffer.writeln('\n用口語聊天，選項 2-8 字。問句要有「？」。不要提座標。不要說出黑棋的步。');
    } else {
      buffer.writeln(
        '\nBe casual and fun. Options 2-6 words. Question must have "?". No coordinates. Don\'t reveal Black\'s move.',
      );
    }

    return buffer.toString();
  }

  Map<String, dynamic> _buildTurnPayload(
    AiTurnContext context, {
    List<ConversationRound>? recentRounds,
  }) {
    final rounds = recentRounds ?? const [];
    final start = rounds.length > 10 ? rounds.length - 10 : 0;
    final trimmed = rounds.sublist(start);
    return {
      'white_pre_fen': context.preFen,
      'white_post_fen': context.postFen,
      'black_post_fen': context.opponentPostFen,
      'emotion': context.emotionLevel.name,
      'recent_10_rounds': trimmed.map((r) => r.toJson()).toList(),
    };
  }

  List<Map<String, String>> _buildHistoryMessages(
    List<ChatMessage>? recentMessages, {
    required int limit,
  }) {
    if (recentMessages == null || recentMessages.isEmpty) return [];

    final filtered = <ChatMessage>[];
    for (final message in recentMessages) {
      final text = _messageText(message);
      if (text != null && text.trim().isNotEmpty) {
        filtered.add(message);
      }
    }

    if (filtered.isEmpty) return [];

    final startIndex = filtered.length > limit ? filtered.length - limit : 0;
    final trimmed = filtered.sublist(startIndex);

    return trimmed.map((message) {
      final text = _messageText(message) ?? '';
      final role = message.sender == ChatSender.user ? 'user' : 'assistant';
      return {'role': role, 'content': text};
    }).toList();
  }

  AiInteractionIntent _decideIntent(AiTurnContext context) {
    if (context.emotionLevel == EmotionLevel.frustrated ||
        context.emotionLevel == EmotionLevel.anxious) {
      final roll = _random.nextDouble();
      if (roll < 0.4) return AiInteractionIntent.encourage;
      if (roll < 0.9) return AiInteractionIntent.chat;
      return AiInteractionIntent.teach;
    }
    final roll = _random.nextDouble();
    if (roll < 0.7) return AiInteractionIntent.chat;
    if (roll < 0.9) return AiInteractionIntent.encourage;
    return AiInteractionIntent.teach;
  }

  String _intentText(AiInteractionIntent intent, String language) {
    if (language == 'zh') {
      switch (intent) {
        case AiInteractionIntent.chat:
          return '聊天陪伴';
        case AiInteractionIntent.encourage:
          return '鼓勵陪伴';
        case AiInteractionIntent.teach:
          return '教學提醒';
      }
    }
    switch (intent) {
      case AiInteractionIntent.chat:
        return 'chat';
      case AiInteractionIntent.encourage:
        return 'encouragement';
      case AiInteractionIntent.teach:
        return 'teaching';
    }
  }

  String? _messageText(ChatMessage message) {
    if (message.sender == ChatSender.user) {
      return message.text;
    }
    return message.interaction?.text;
  }

  CompanionInteraction? _parseInteractionFromJson(
    String jsonStr,
    AiTurnContext context, {
    required AiInteractionIntent intent,
  }) {
    final data = _extractJsonMap(jsonStr);
    if (data == null) return null;

    if (data.containsKey('message')) {
      final message = _ensureBoardContextQuestion(
        _sanitizeAiText(data['message'] as String? ?? '', context.language),
        context.language,
        context,
      );
      final choicesData = data['choices'] as List<dynamic>? ?? [];

      final choices = <CompanionChoice>[];
      final fallbackResponses = _defaultResponses(context.language);
      for (int i = 0; i < choicesData.length && i < 2; i++) {
        final item = choicesData[i];
        if (item is Map<String, dynamic>) {
          final label = _sanitizeLabel(
            item['label']?.toString() ?? '',
            context.language,
          );
          final rawResponse = item['response']?.toString().trim();
          final response = _sanitizeAiText(
            (rawResponse == null || rawResponse.isEmpty)
                ? fallbackResponses[i % fallbackResponses.length]
                : rawResponse,
            context.language,
          );
          if (label.isEmpty) continue;
          choices.add(
            CompanionChoice(
              label: label,
              actionId: 's${i + 1}',
              responseText: response,
            ),
          );
        }
      }

      final normalized = _normalizeChoices(
        choices,
        context,
        message: message,
        intent: intent,
        allowFallback: true,
      );

      if (normalized.length != 2) {
        return null;
      }

      return CompanionInteraction.multiChoice(
        text: message,
        choices: normalized,
        trigger: 'dynamic',
        turnContext: context,
      );
    }

    // Backwards compatibility: question/option format
    if (data.containsKey('question')) {
      final question = data['question'] as String? ?? '';
      final optionA = data['option_a'] as String?;
      final optionB = data['option_b'] as String?;
      final choices = <CompanionChoice>[];
      if (optionA != null && optionA.trim().isNotEmpty) {
        choices.add(CompanionChoice(label: optionA, actionId: 'a'));
      }
      if (optionB != null && optionB.trim().isNotEmpty) {
        choices.add(CompanionChoice(label: optionB, actionId: 'b'));
      }
      return CompanionInteraction.multiChoice(
        text: question,
        choices: choices,
        trigger: 'dynamic',
        turnContext: context,
      );
    }

    return null;
  }

  CompanionInteraction _fallbackFromRawText(
    String content,
    AiTurnContext context, {
    required AiInteractionIntent intent,
  }) {
    final cleaned = _sanitizeAiText(content, context.language);
    final isQuestion =
        _hasQuestionMark(cleaned) ||
        _looksLikeQuestion(cleaned, context.language);
    final angle = _detectAngleKey(cleaned, context.language);
    final bundle = angle != null
        ? _buildAltBundleForAngle(context, angle)
        : _buildAltBundle(context);
    final message = isQuestion
        ? _ensureBoardContextQuestion(cleaned, context.language, context)
        : _ensureBoardContextQuestion(
            bundle.message,
            context.language,
            context,
          );
    final normalized = _normalizeChoices(
      bundle.choices,
      context,
      message: message,
      intent: intent,
      allowFallback: true,
    );
    final choices = normalized.length >= 2
        ? normalized.take(2).toList()
        : bundle.choices.take(2).toList();
    final interaction = CompanionInteraction.multiChoice(
      text: message,
      choices: choices,
      trigger: 'dynamic_recovered',
      turnContext: context,
    );
    return _diversifyInteraction(interaction, context, intent: intent);
  }

  CompanionInteraction _buildPieceSafeFallback(
    AiTurnContext context, {
    required AiInteractionIntent intent,
  }) {
    final piece = _pieceNameFriendly(context, context.language);
    final isZh = context.language == 'zh';
    final messagePool = isZh
        ? [
            '欸你剛那步$piece蠻有意思的耶，你在想什麼？',
            '哦～你動了$piece，是有什麼計劃嗎？',
            '嘿你那步$piece我有注意到，想跟我聊聊嗎？',
            '哈你剛走的$piece讓我有點意外，你是故意的嗎？',
          ]
        : [
            'Hey, that $piece move was interesting! What were you thinking?',
            'Ooh you moved your $piece — got a plan or just vibing?',
            'Whoa, that $piece move caught my eye! Wanna tell me why?',
            'Haha that $piece move surprised me a bit. Was that on purpose?',
          ];
    final message = _ensureQuestion(
      messagePool[_random.nextInt(messagePool.length)],
      context.language,
    );

    final choices = _rewriteYesNoPair(context, message: message);

    return CompanionInteraction.multiChoice(
      text: message,
      choices: choices,
      trigger: 'piece_safe_fallback',
      turnContext: context,
    );
  }

  Map<String, dynamic>? _extractJsonMap(String content) {
    try {
      String cleanJson = content.trim();
      final startIndex = cleanJson.indexOf('{');
      final endIndex = cleanJson.lastIndexOf('}');
      if (startIndex == -1 || endIndex == -1) return null;
      cleanJson = cleanJson.substring(startIndex, endIndex + 1);
      final data = jsonDecode(cleanJson);
      if (data is Map<String, dynamic>) return data;
      return null;
    } catch (_) {
      try {
        final repaired = _attemptRepairJson(content);
        final data = jsonDecode(repaired);
        if (data is Map<String, dynamic>) return data;
      } catch (_) {}
      return null;
    }
  }

  String _attemptRepairJson(String content) {
    var cleaned = content.trim();
    final startIndex = cleaned.indexOf('{');
    final endIndex = cleaned.lastIndexOf('}');
    if (startIndex != -1 && endIndex != -1) {
      cleaned = cleaned.substring(startIndex, endIndex + 1);
    }
    cleaned = cleaned.replaceAll('“', '"').replaceAll('”', '"');
    cleaned = cleaned.replaceAll('‘', "'").replaceAll('’', "'");
    cleaned = cleaned.replaceAllMapped(
      RegExp(r"(?<=[:\s])'([^']*)'"),
      (m) => '"${m[1]}"',
    );
    cleaned = cleaned.replaceAll(RegExp(r",\s*}"), '}');
    cleaned = cleaned.replaceAll(RegExp(r",\s*]"), ']');
    return cleaned;
  }

  bool _validateInteraction(
    CompanionInteraction interaction,
    AiTurnContext context, {
    required AiInteractionIntent intent,
  }) {
    final message = (interaction.text ?? '').trim();
    if (message.isEmpty || message.length < 4) return false;
    if (_recentAiMessages.any((m) => m == message)) return false;
    if (!_hasQuestionMark(message)) return false;
    if (_containsBannedTerms(message, context.language)) return false;
    if (_mentionsSquare(message)) return false;
    if (!_messageMatchesPiece(message, context)) return false;

    final choices = interaction.choices ?? [];
    if (choices.length != 2) return false;

    final seenLabels = <String>{};
    for (final choice in choices) {
      final label = (choice.label ?? '').trim();
      final response = (choice.responseText ?? '').trim();
      if (label.isEmpty || response.isEmpty) return false;
      if (_containsBannedTerms(label, context.language)) return false;
      if (_containsBannedTerms(response, context.language)) return false;
      if (_mentionsSquare(label) || _mentionsSquare(response)) return false;
      final labelKey = label.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      if (seenLabels.contains(labelKey)) return false;
      seenLabels.add(labelKey);
      if (context.language == 'zh' && label.length > 12) return false;
      if (context.language != 'zh' && label.length > 40) return false;
    }

    return true;
  }

  bool _hasQuestionMark(String message) {
    return message.contains('？') || message.contains('?');
  }

  bool _looksTextbook(String text, String language) {
    if (language == 'zh') {
      return text.contains('主要是為了') ||
          text.contains('目的在於') ||
          text.contains('因此');
    }
    final lower = text.toLowerCase();
    return lower.contains('the purpose is') || lower.contains('therefore');
  }

  bool _containsBannedTerms(String text, String? language) {
    if (text.isEmpty) return false;
    if (language == 'zh') {
      const banned = ['控制中心', '發展棋子', '空間優勢', '開局', '中局', '殘局'];
      return banned.any(text.contains);
    }
    final lower = text.toLowerCase();
    const banned = [
      'control the center',
      'develop pieces',
      'space advantage',
      'opening',
      'middlegame',
      'endgame',
    ];
    return banned.any(lower.contains);
  }

  void _rememberInteraction(CompanionInteraction interaction) {
    final message = (interaction.text ?? '').trim();
    if (message.isEmpty) return;
    _recentAiMessages.add(message);
    if (_recentAiMessages.length > _maxRecentMessages) {
      _recentAiMessages.removeAt(0);
    }

    final choices = interaction.choices ?? [];
    if (choices.length == 2) {
      final signature = _choiceSignature(choices);
      _recentChoiceSignatures.add(signature);
      if (_recentChoiceSignatures.length > _maxRecentMessages) {
        _recentChoiceSignatures.removeAt(0);
      }
    }
    final angleKey = _detectAngleKey(
      message,
      interaction.turnContext?.language,
    );
    if (angleKey != null) {
      _recentAngleKeys.add(angleKey);
      if (_recentAngleKeys.length > _maxRecentMessages) {
        _recentAngleKeys.removeAt(0);
      }
    }
  }

  CompanionInteraction _diversifyInteraction(
    CompanionInteraction interaction,
    AiTurnContext context, {
    required AiInteractionIntent intent,
  }) {
    var message = interaction.text ?? '';
    var choices = interaction.choices ?? const [];

    // Keep AI output whenever it is valid enough. Only hard-rewrite on
    // strong duplication or invalid option shape.
    final hardDuplicate = _isHardDuplicate(
      message,
      choices,
      language: context.language,
    );
    if (hardDuplicate || choices.length != 2) {
      final bundle = _buildAltBundle(context);
      message = bundle.message;
      choices = bundle.choices;
    }

    message = _ensureBoardContextQuestion(
      _sanitizeAiText(message, context.language),
      context.language,
      context,
    );

    final normalized = _normalizeChoices(
      choices,
      context,
      message: message,
      intent: intent,
      allowFallback: true,
    );

    final finalChoices = normalized.length >= 2
        ? normalized.take(2).toList()
        : choices;

    return CompanionInteraction.multiChoice(
      text: message,
      choices: finalChoices,
      trigger: interaction.triggerReason,
      turnContext: context,
    );
  }

  bool _isHardDuplicate(
    String message,
    List<CompanionChoice> choices, {
    required String language,
  }) {
    final sig = _normalizeSignature(message);
    if (sig.isEmpty) return false;
    var sameMessageCount = 0;
    var samePatternCount = 0;
    final pattern = _patternSignature(message, language);
    for (final prev in _recentAiMessages) {
      if (_normalizeSignature(prev) == sig) {
        sameMessageCount++;
      }
      if (pattern.isNotEmpty && _patternSignature(prev, language) == pattern) {
        samePatternCount++;
      }
    }
    if (sameMessageCount >= 1) return true;
    if (samePatternCount >= 2) return true;

    if (choices.length == 2) {
      final sigChoice = _choiceSignature(choices);
      if (_recentChoiceSignatures.contains(sigChoice)) {
        return true;
      }
    }
    return false;
  }

  CompanionInteraction _repairInteraction(
    CompanionInteraction interaction,
    AiTurnContext context, {
    required AiInteractionIntent intent,
  }) {
    var message = interaction.text ?? '';
    message = _repairMessage(message, context);

    final choices = interaction.choices ?? const <CompanionChoice>[];
    final normalized = _normalizeChoices(
      choices,
      context,
      message: message,
      intent: intent,
      allowFallback: true,
    );
    final finalChoices = normalized.length >= 2
        ? normalized.take(2).toList()
        : _rewriteYesNoPair(context, message: message);

    return CompanionInteraction.multiChoice(
      text: message,
      choices: finalChoices,
      trigger: interaction.triggerReason ?? 'repair',
      turnContext: context,
    );
  }

  String _repairMessage(String message, AiTurnContext context) {
    var cleaned = _sanitizeAiText(message, context.language);
    cleaned = _repairPerspective(cleaned, context.language);
    if (_mentionsSquare(cleaned)) {
      cleaned = cleaned.replaceAll(
        RegExp(r'\b[a-h][1-8]\b', caseSensitive: false),
        context.language == 'zh' ? '那步' : 'that square',
      );
    }
    if (!_messageMatchesPiece(cleaned, context)) {
      cleaned = _buildPieceAlignedQuestion(context);
    }
    cleaned = _ensureBoardContextQuestion(cleaned, context.language, context);
    return cleaned;
  }

  String _repairPerspective(String text, String language) {
    var cleaned = text.trim();
    if (cleaned.isEmpty) return cleaned;
    if (language == 'zh') {
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'^(我剛剛)(?=把|動|走|推|下|用)'),
        (_) => '你剛剛',
      );
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'^(我剛)(?=把|動|走|推|下|用)'),
        (_) => '你剛',
      );
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'^(我把)(?=兵|馬|象|車|后|王|棋子|這手|那步)'),
        (_) => '你把',
      );
      return cleaned;
    }
    cleaned = cleaned.replaceFirst(
      RegExp(
        r'^(I just)(?=\s+(moved|played|pushed|put))',
        caseSensitive: false,
      ),
      'You just',
    );
    return cleaned;
  }

  String _buildPieceAlignedQuestion(AiTurnContext context) {
    final piece = _pieceNameFriendly(context, context.language);
    if (context.language == 'zh') {
      final pool = [
        '欸你剛那步$piece，是想試試我嗎？',
        '哦～你動了$piece，有什麼想法嗎？',
        '嘿你走的$piece蠻有意思的，是故意的嗎？',
      ];
      return pool[_random.nextInt(pool.length)];
    }
    final pool = [
      'Hey, that $piece move — trying to test me?',
      'Ooh you moved your $piece, got a plan?',
      'Haha that $piece was interesting, was that on purpose?',
    ];
    return pool[_random.nextInt(pool.length)];
  }

  String? _starterKey(String message, String? language) {
    final text = message.trim();
    if (language == 'zh') {
      if (text.startsWith('你剛')) return 'you_just';
      if (text.startsWith('剛才') || text.startsWith('剛剛')) return 'just_now';
      if (text.startsWith('這手') || text.startsWith('這步')) return 'this_move';
      if (text.startsWith('我看你')) return 'i_saw';
    } else {
      final lower = text.toLowerCase();
      if (lower.startsWith('you just')) return 'you_just';
      if (lower.startsWith('just now') || lower.startsWith('right now')) {
        return 'just_now';
      }
      if (lower.startsWith('that move') || lower.startsWith('this move')) {
        return 'this_move';
      }
    }
    return null;
  }

  String _choiceSignature(List<CompanionChoice> choices) {
    final a = _normalizeSignature(choices[0].label ?? '');
    final b = _normalizeSignature(choices[1].label ?? '');
    return '$a|$b';
  }

  String _normalizeSignature(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll(RegExp(r'[^\w\u4e00-\u9fff]'), '');
  }

  bool _mentionsSquare(String text) {
    return RegExp(r'\b[a-h][1-8]\b', caseSensitive: false).hasMatch(text);
  }

  bool _messageMatchesPiece(String message, AiTurnContext context) {
    final expected = _expectedPieceTokens(context, context.language);
    if (expected.isEmpty) return true;
    final lower = message.toLowerCase();
    final mentions = <String>{};
    for (final token in _pieceTokens(context.language)) {
      if (lower.contains(token)) {
        mentions.add(token);
      }
    }
    if (mentions.isEmpty) return true;
    for (final token in mentions) {
      if (!expected.contains(token)) {
        return false;
      }
    }
    return true;
  }

  Set<String> _expectedPieceTokens(AiTurnContext context, String language) {
    final tokens = <String>{};
    final pieceCode = _normalizePieceCode(context.pieceMovedType);
    if (language == 'zh') {
      if (context.isCapture || context.moveSan.contains('x')) {
        tokens.add('吃');
      }
      if (context.isCheck || context.moveSan.contains('+')) {
        tokens.add('將軍');
      }
      switch (pieceCode) {
        case 'p':
          tokens.add('兵');
          break;
        case 'n':
          tokens.add('馬');
          break;
        case 'b':
          tokens.add('象');
          break;
        case 'r':
          tokens.add('車');
          break;
        case 'q':
          tokens.add('后');
          break;
        case 'k':
          tokens.add('王');
          break;
      }
      return tokens;
    }

    if (context.isCapture || context.moveSan.contains('x')) {
      tokens.add('capture');
    }
    if (context.isCheck || context.moveSan.contains('+')) {
      tokens.add('check');
    }
    switch (pieceCode) {
      case 'p':
        tokens.add('pawn');
        break;
      case 'n':
        tokens.add('knight');
        break;
      case 'b':
        tokens.add('bishop');
        break;
      case 'r':
        tokens.add('rook');
        break;
      case 'q':
        tokens.add('queen');
        break;
      case 'k':
        tokens.add('king');
        break;
    }
    return tokens;
  }

  List<String> _pieceTokens(String language) {
    if (language == 'zh') {
      return ['兵', '馬', '象', '車', '后', '王', '吃', '將軍'];
    }
    return [
      'pawn',
      'knight',
      'bishop',
      'rook',
      'queen',
      'king',
      'capture',
      'check',
    ];
  }

  String _patternSignature(String text, String? language) {
    var cleaned = text.toLowerCase();
    if (language == 'zh') {
      cleaned = cleaned
          .replaceAll('你剛剛', '')
          .replaceAll('你剛', '')
          .replaceAll('剛剛', '')
          .replaceAll('剛才', '')
          .replaceAll('這步', '')
          .replaceAll('這手', '')
          .replaceAll('那步', '')
          .replaceAll('那手', '')
          .replaceAll('是不是', '')
          .replaceAll('想', '')
          .replaceAll('要', '')
          .replaceAll('有沒有', '')
          .replaceAll('要不要', '')
          .replaceAll('什麼', '')
          .replaceAll('特別', '')
          .replaceAll('想法', '')
          .replaceAll('計畫', '')
          .replaceAll('打算', '')
          .replaceAll('嗎', '')
          .replaceAll('呢', '')
          .replaceAll('啊', '')
          .replaceAll('吧', '');
      cleaned = cleaned.replaceAll(RegExp(r'[兵馬象車后王吃將軍易位]'), '棋子');
    } else {
      cleaned = cleaned
          .replaceAll('you just', '')
          .replaceAll('just now', '')
          .replaceAll('that move', '')
          .replaceAll('this move', '')
          .replaceAll('is it', '')
          .replaceAll('are you', '')
          .replaceAll('do you', '')
          .replaceAll('?', '');
      cleaned = cleaned.replaceAll(
        RegExp(r'(pawn|knight|bishop|rook|queen|king|capture|check|castle)'),
        'piece',
      );
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), '');
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\u4e00-\u9fff]'), '');
    return cleaned;
  }

  String? _detectAngleKey(String message, String? language) {
    if (language == 'zh') {
      if (message.contains('主導')) return 'dominance';
      if (message.contains('壓力')) return 'pressure';
      if (message.contains('試探')) return 'test';
      if (message.contains('拚') || message.contains('挑戰')) return 'challenge';
      if (message.contains('騙') || message.contains('挖坑')) return 'trap';
      if (message.contains('誘') ||
          message.contains('釣') ||
          message.contains('引')) {
        return 'bait';
      }
      if (message.contains('換')) return 'trade';
      if (message.contains('守') || message.contains('穩')) return 'defend';
      if (message.contains('堵') ||
          message.contains('封') ||
          message.contains('擠')) {
        return 'block';
      }
      if (message.contains('節奏') || message.contains('步調')) return 'tempo';
      if (message.contains('風格') || message.contains('花')) return 'style';
      if (message.contains('偷') || message.contains('空檔')) return 'sneak';
      if (message.contains('賭') || message.contains('冒險')) return 'risk';
      if (message.contains('突然') || message.contains('嚇')) return 'surprise';
    } else {
      final lower = message.toLowerCase();
      if (lower.contains('dominant')) return 'dominance';
      if (lower.contains('pressure')) return 'pressure';
      if (lower.contains('test')) return 'test';
      if (lower.contains('challenge')) return 'challenge';
      if (lower.contains('trap')) return 'trap';
      if (lower.contains('bait') || lower.contains('lure')) return 'bait';
      if (lower.contains('trade') || lower.contains('swap')) return 'trade';
      if (lower.contains('defend') || lower.contains('protect')) {
        return 'defend';
      }
      if (lower.contains('tempo') || lower.contains('pace')) return 'tempo';
      if (lower.contains('style') || lower.contains('flashy')) return 'style';
      if (lower.contains('sneak') || lower.contains('steal')) return 'sneak';
      if (lower.contains('risk') || lower.contains('gamble')) return 'risk';
      if (lower.contains('surprise')) return 'surprise';
    }
    return null;
  }

  _AltBundle _buildAltBundle(AiTurnContext context) {
    final isZh = context.language == 'zh';
    final piece = _pieceNameFriendly(context, context.language);
    final bundles = isZh ? _altBundlesZh(piece) : _altBundlesEn(piece);
    final recentStarters = _recentAiMessages
        .map((m) => _starterKey(m, context.language))
        .whereType<String>()
        .toSet();
    final available = bundles.where((b) {
      if (_recentAngleKeys.contains(b.angleKey)) return false;
      if (_isMessageSignatureUsed(b.message)) return false;
      final starter = _starterKey(b.message, context.language);
      if (starter != null && recentStarters.contains(starter)) return false;
      return true;
    }).toList();
    final pool = available.isNotEmpty ? available : bundles;
    final picked = pool[_random.nextInt(pool.length)];
    return picked;
  }

  _AltBundle _buildAltBundleForAngle(AiTurnContext context, String angleKey) {
    final isZh = context.language == 'zh';
    final piece = _pieceNameFriendly(context, context.language);
    final bundles = isZh ? _altBundlesZh(piece) : _altBundlesEn(piece);
    final candidates = bundles.where((b) => b.angleKey == angleKey).toList();
    if (candidates.isNotEmpty) {
      return candidates[_random.nextInt(candidates.length)];
    }
    return _buildAltBundle(context);
  }

  bool _isMessageSignatureUsed(String message) {
    final sig = _normalizeSignature(message);
    if (sig.isEmpty) return false;
    for (final prev in _recentAiMessages) {
      if (_normalizeSignature(prev) == sig) return true;
    }
    return false;
  }

  List<_AltBundle> _altBundlesZh(String piece) {
    return [
      _AltBundle(
        angleKey: 'dominance',
        message: '你這手$piece有點主導味，是想先搶先手嗎？',
        choices: [
          _choice('嘿嘿，被你看出來了', '那我可不能退喔。'),
          _choice('沒有啦，我只是試試', '我才不信，你很會。'),
        ],
      ),
      _AltBundle(
        angleKey: 'pressure',
        message: '剛才你把$piece往前放，是想逼我動起來嗎？',
        choices: [
          _choice('對啊，我想壓你一下', '好啊，那我就迎戰。'),
          _choice('沒有啦，手滑', '手滑也挺有氣勢的。'),
        ],
      ),
      _AltBundle(
        angleKey: 'test',
        message: '你剛那步$piece像在測我，是不是？',
        choices: [
          _choice('有點想試你', '那我可要小心了。'),
          _choice('不是啦，剛好想到', '剛好想到也很準。'),
        ],
      ),
      _AltBundle(
        angleKey: 'challenge',
        message: '你這手$piece是在挑我嗎？',
        choices: [
          _choice('來啊，拚一下', '好啊，我也不客氣囉。'),
          _choice('沒有啦，鬧著玩', '哈哈你很會鬧。'),
        ],
      ),
      _AltBundle(
        angleKey: 'bait',
        message: '你把$piece放那裡，是想釣我去吃嗎？',
        choices: [
          _choice('對啊，看看你敢不敢', '我會注意一下。'),
          _choice('不是啦，剛好', '我才不信那麼剛好。'),
        ],
      ),
      _AltBundle(
        angleKey: 'trade',
        message: '你剛那步$piece，是想跟我換一換嗎？',
        choices: [
          _choice('可以啊，換換看', '好啊，那就來吧。'),
          _choice('沒有啦，只是路過', '路過也很有味道。'),
        ],
      ),
      _AltBundle(
        angleKey: 'defend',
        message: '你剛那步$piece看起來很穩，是想先守一下嗎？',
        choices: [_choice('對，我想先穩', '穩一點也很帥。'), _choice('沒有啦，只是感覺', '感覺很準呢。')],
      ),
      _AltBundle(
        angleKey: 'block',
        message: '你把$piece擺那，是想把路封起來嗎？',
        choices: [_choice('對啊，先堵住', '那我得想別的路了。'), _choice('沒有啦，隨手', '隨手也挺會堵。')],
      ),
      _AltBundle(
        angleKey: 'tempo',
        message: '你這手$piece有點快，是想先搶步嗎？',
        choices: [_choice('對啊，先走快點', '好啊，我跟上。'), _choice('沒有啦，剛好', '剛好也讓我緊張。')],
      ),
      _AltBundle(
        angleKey: 'style',
        message: '你剛那步$piece很有風格，是想玩帥一點嗎？',
        choices: [_choice('嘿嘿，有點想', '那我也要帥一下。'), _choice('沒有啦，剛好', '剛好也很帥啦。')],
      ),
      _AltBundle(
        angleKey: 'sneak',
        message: '你剛那步$piece，是想偷我一個小空檔嗎？',
        choices: [
          _choice('被你看出來了', '我可不會白白送你。'),
          _choice('沒有啦，亂走', '亂走也會嚇到我。'),
        ],
      ),
      _AltBundle(
        angleKey: 'surprise',
        message: '這手$piece有點突然，是想給我驚喜嗎？',
        choices: [
          _choice('對啊，嚇你一下', '被你嚇到一點點。'),
          _choice('沒有啦，剛好想到', '你這種剛好很可怕。'),
        ],
      ),
      _AltBundle(
        angleKey: 'risk',
        message: '你這手$piece有點冒險，是想賭一把嗎？',
        choices: [_choice('有點想試試', '好啊，那我也來。'), _choice('沒有啦，隨便', '隨便也很敢。')],
      ),
      _AltBundle(
        angleKey: 'trap',
        message: '你把$piece放那，是想挖個小坑嗎？',
        choices: [_choice('嘿嘿，可能喔', '我會小心點。'), _choice('沒有啦，別想太多', '你越說我越想。')],
      ),
      _AltBundle(
        angleKey: 'plan',
        message: '你剛把$piece放那，是想先鋪路嗎？',
        choices: [
          _choice('對，先鋪一點', '好啊，那我得想下一步。'),
          _choice('沒有啦，想到就走', '想到就走也很帥。'),
        ],
      ),
    ];
  }

  List<_AltBundle> _altBundlesEn(String piece) {
    return [
      _AltBundle(
        angleKey: 'dominance',
        message: 'You just moved your $piece — trying to take tempo?',
        choices: [
          _choice('Haha, you caught me', 'I won’t let you off easy.'),
          _choice('No way~', 'Come on, you’re too good.'),
        ],
      ),
      _AltBundle(
        angleKey: 'pressure',
        message: 'That $piece move — trying to pressure me?',
        choices: [
          _choice('Yeah, a little', 'Alright, I’m ready.'),
          _choice('Nah, just casual', 'Haha, sure you are.'),
        ],
      ),
      _AltBundle(
        angleKey: 'test',
        message: 'That $piece move feels like a test, yeah?',
        choices: [
          _choice('Kind of, yeah', 'Then I’ll keep you guessing.'),
          _choice('Not really', 'You say that now.'),
        ],
      ),
      _AltBundle(
        angleKey: 'challenge',
        message: 'You moved that $piece — challenging me?',
        choices: [
          _choice('Bring it on', 'Then I’ll bring it too.'),
          _choice('Just teasing', 'Haha, you’re playful.'),
        ],
      ),
      _AltBundle(
        angleKey: 'bait',
        message: 'You placed that $piece — trying to bait me?',
        choices: [
          _choice('Maybe~', 'I won’t bite so easily.'),
          _choice('Nah, just a move', 'Sure, sure.'),
        ],
      ),
      _AltBundle(
        angleKey: 'trade',
        message: 'That $piece move — looking to trade?',
        choices: [
          _choice('Yeah, let’s trade', 'Alright, I’m in.'),
          _choice('Not really', 'Then I’ll keep guessing.'),
        ],
      ),
      _AltBundle(
        angleKey: 'defend',
        message: 'That $piece move feels safe — guarding up?',
        choices: [
          _choice('Yeah, just being safe', 'Safe can be smart.'),
          _choice('Nope, just vibe', 'Vibes can be tricky.'),
        ],
      ),
      _AltBundle(
        angleKey: 'block',
        message: 'That $piece move — trying to block my path?',
        choices: [
          _choice('Yep, for now', 'Then I’ll find another way.'),
          _choice('Not really', 'It sure looks like it.'),
        ],
      ),
      _AltBundle(
        angleKey: 'trap',
        message: 'You slid that $piece there — setting a trap?',
        choices: [
          _choice('Maybe~', 'I won’t fall for it.'),
          _choice('Nope', 'That sounds like a yes.'),
        ],
      ),
      _AltBundle(
        angleKey: 'style',
        message: 'That $piece move was stylish — going flashy today?',
        choices: [
          _choice('You noticed', 'Then I’ll match your style.'),
          _choice('Just a thought', 'Your thoughts are sharp.'),
        ],
      ),
      _AltBundle(
        angleKey: 'surprise',
        message: 'That $piece move was sudden — trying to surprise me?',
        choices: [
          _choice('Got you~', 'A little, yeah.'),
          _choice('Not at all', 'Sure, sure.'),
        ],
      ),
      _AltBundle(
        angleKey: 'risk',
        message: 'That $piece move felt risky — you gambling?',
        choices: [
          _choice('Yeah, a little', 'Alright, I’m in.'),
          _choice('Not really', 'Risky doesn’t scare me.'),
        ],
      ),
    ];
  }

  CompanionChoice _choice(String label, String response) {
    return CompanionChoice(
      label: label,
      actionId: 'alt',
      responseText: response,
    );
  }

  List<CompanionChoice> _fallbackChoiceSet(
    AiTurnContext context, {
    required String message,
  }) {
    final isZh = context.language == 'zh';
    final setsZh = [
      [
        {'label': '嘿嘿，被你發現了', 'response': '我不會讓你得逞～'},
        {'label': '怎麼可能～', 'response': '別騙我了～你這麽厲害。'},
      ],
      [
        {'label': '我就是想試試', 'response': '好啊，來看看你怎麼回。'},
        {'label': '沒有啦，隨便走', 'response': '哈哈你也太會騙了。'},
      ],
      [
        {'label': '我想給你壓力', 'response': '那我更要認真了。'},
        {'label': '我只是放鬆玩', 'response': '放鬆也可以，但我不會手軟喔。'},
      ],
      [
        {'label': '我想先穩一下', 'response': '穩穩也很帥。'},
        {'label': '我想衝一下', 'response': '好啊，那就拚一拚。'},
      ],
      [
        {'label': '我想逗你一下', 'response': '你很壞耶，但我喜歡。'},
        {'label': '我沒有啦', 'response': '哈哈我不信。'},
      ],
      [
        {'label': '我想試你反應', 'response': '那我就陪你玩。'},
        {'label': '我只是巧合', 'response': '巧合也挺準的。'},
      ],
    ];

    final setsEn = [
      [
        {
          'label': 'Haha, you caught me',
          'response': 'I won’t let you off easy.',
        },
        {'label': 'No way~', 'response': 'Come on, you’re too good.'},
      ],
      [
        {
          'label': 'Just testing you',
          'response': 'Alright, show me what you’ve got.',
        },
        {'label': 'Just messing around', 'response': 'Haha, you’re sneaky.'},
      ],
      [
        {'label': 'I want some pressure', 'response': 'Then I’ll push back.'},
        {
          'label': 'I’m just chilling',
          'response': 'Chill is fine, but I’m still coming.',
        },
      ],
      [
        {'label': 'Playing it safe', 'response': 'Safe can be smart.'},
        {'label': 'Going for it', 'response': 'Alright, I’m in.'},
      ],
      [
        {'label': 'Just teasing you', 'response': 'You’re cheeky, I like it.'},
        {'label': 'Not at all', 'response': 'Sure, sure.'},
      ],
      [
        {
          'label': 'Testing your reaction',
          'response': 'Then I’ll give you one.',
        },
        {
          'label': 'Just a coincidence',
          'response': 'That’s a sharp coincidence.',
        },
      ],
    ];

    final sets = isZh ? setsZh : setsEn;
    final idx = context.moveNumber % sets.length;
    final chosen = sets[idx];
    return List.generate(chosen.length, (i) {
      final item = chosen[i];
      return CompanionChoice(
        label: item['label'] as String,
        actionId: 'f${i + 1}',
        responseText: item['response'] as String,
      );
    });
  }

  bool _looksLikeQuestion(String text, String language) {
    if (text.contains('？') || text.contains('?')) return true;
    if (language == 'zh') {
      return text.contains('為什麼') ||
          text.contains('怎麼') ||
          text.contains('要不要');
    }
    final lower = text.toLowerCase();
    return lower.contains('why') ||
        lower.contains('how') ||
        lower.contains('what');
  }

  String _sanitizeLabel(String label, String language) {
    var cleaned = label.trim();
    if (cleaned.contains('/')) {
      cleaned = cleaned.split('/').first.trim();
    }
    if (language == 'zh') {
      cleaned = cleaned.replaceAll('控制中心', '先佔位置');
      cleaned = cleaned.replaceAll('發展棋子', '讓棋子動起來');
      cleaned = cleaned.replaceAll('空間優勢', '走得更順');
      final banned = ['開局', '中局', '殘局'];
      if (banned.any(cleaned.contains)) {
        return '';
      }
    }
    if (language == 'zh' &&
        (cleaned.contains('不知道') || cleaned.contains('不確定'))) {
      return '';
    }
    if (language != 'zh') {
      final lower = cleaned.toLowerCase();
      if (lower.contains('don\'t know') || lower.contains('not sure')) {
        return '';
      }
    }
    if (cleaned.isEmpty) {
      return language == 'zh' ? '嗯嗯' : 'Okay';
    }
    return cleaned;
  }

  String _adjustLabelVariant(
    String label,
    AiTurnContext context, {
    List<String> avoidLabels = const [],
  }) {
    final lang = context.language;
    final normalized = label
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '')
        .trim();
    final avoid = avoidLabels
        .map((e) => e.toLowerCase().replaceAll(RegExp(r'\s+'), ''))
        .toList();
    if (!avoid.contains(normalized)) return label;

    if (lang == 'zh') {
      final variants = <String, List<String>>{
        '我不知道': ['我不太確定', '有點不懂', '不太知道'],
        '有點緊張': ['有點怕怕', '有點小緊張', '有點焦慮'],
        '挺好的': ['還不錯', '可以啦', '還行'],
        '我覺得不錯': ['還不錯', '蠻可以的', '感覺OK'],
        '我想進攻': ['想試著打', '想衝一下', '想攻看看'],
        '我想守住': ['先顧好自己', '先穩住', '想先防守'],
        '你先說': ['你先講', '你先說說', '你先說啦'],
        '對啊': ['是啊', '對呀', '沒錯'],
        '當然': ['當然啊', '一定', '肯定'],
        '沒有啦': ['才沒有', '哪有', '沒有吧'],
      };
      final list = variants[normalized];
      if (list != null && list.isNotEmpty) {
        return list[context.moveNumber % list.length];
      }
    } else {
      final variants = <String, List<String>>{
        'idontknow': ['Not sure', 'No idea', 'Not really sure'],
        'abitnervous': ['A little nervous', 'Kinda nervous', 'A bit shaky'],
        'feelsokay': ['Feels fine', 'Pretty okay', 'Kind of okay'],
      };
      final list = variants[normalized];
      if (list != null && list.isNotEmpty) {
        return list[context.moveNumber % list.length];
      }
    }

    return label;
  }

  String _sanitizeAiText(String text, String language) {
    var cleaned = text.trim();
    if (cleaned.isEmpty) return cleaned;

    if (language == 'zh') {
      // Fix double question particles
      cleaned = cleaned.replaceAllMapped(
        RegExp(r'是不是([^？\?]*?)嗎'),
        (m) => '是不是${m[1]}',
      );
      // Fix perspective — must use I/you, not third-person
      cleaned = cleaned.replaceAll('對方', '我');
      cleaned = cleaned.replaceAll('對手', '我');
      cleaned = cleaned.replaceAll('你剛剛選擇了', '你剛');
      cleaned = cleaned.replaceAll('你選擇了', '你走了');
    } else {
      // Fix perspective
      cleaned = cleaned.replaceAll('You just chose', 'You just played');
      cleaned = cleaned.replaceAll('the opponent', 'I');
    }

    return cleaned;
  }

  String _ensureQuestion(String text, String language) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return trimmed;
    if (trimmed.contains('？') || trimmed.contains('?')) return trimmed;

    final suffixesZh = ['你覺得呢？', '想聊聊嗎？', '要不要說說？', '你會怎麼回？', '要不要一起想？'];
    final suffixesEn = [
      'What do you think?',
      'Want to share?',
      'How would you answer?',
      'Wanna talk?',
    ];
    final suffixes = language == 'zh' ? suffixesZh : suffixesEn;
    final suffix = suffixes[_random.nextInt(suffixes.length)];
    return '$trimmed $suffix';
  }

  String _ensureBoardContextQuestion(
    String text,
    String language,
    AiTurnContext context,
  ) {
    var cleaned = text.trim();
    if (cleaned.isEmpty) return cleaned;
    if (!_hasPieceMention(cleaned, language)) {
      final prefix = _boardPrefix(context, language);
      cleaned = '$prefix$cleaned';
    }
    return _ensureQuestion(cleaned, language);
  }

  String _boardPrefix(AiTurnContext context, String language) {
    final piece = _pieceNameFriendly(context, language);
    if (language == 'zh') {
      final prefixes = [
        '你剛把$piece動了一下，',
        '剛才你把$piece放過去，',
        '你這手$piece挺有戲的，',
        '你剛那步$piece有點意思，',
        '我看你把$piece放那邊，',
      ];
      return prefixes[_random.nextInt(prefixes.length)];
    }
    final prefixes = [
      'You just moved your $piece, ',
      'That $piece move just now, ',
      'I saw you move your $piece, ',
      'That $piece move felt bold — ',
    ];
    return prefixes[_random.nextInt(prefixes.length)];
  }

  bool _hasPieceMention(String text, String language) {
    if (language == 'zh') {
      const pieces = ['兵', '馬', '象', '車', '后', '王', '吃', '將軍', '易位'];
      return pieces.any(text.contains);
    }
    final lower = text.toLowerCase();
    const pieces = [
      'pawn',
      'knight',
      'bishop',
      'rook',
      'queen',
      'king',
      'capture',
      'check',
      'castle',
    ];
    return pieces.any(lower.contains);
  }

  String _pieceNameFriendly(AiTurnContext context, String language) {
    final pieceCode = _normalizePieceCode(context.pieceMovedType);
    if (language == 'zh') {
      if (context.isCapture || context.moveSan.contains('x')) return '吃子';
      if (context.isCheck || context.moveSan.contains('+')) return '將軍';
      switch (pieceCode) {
        case 'p':
          return '兵';
        case 'n':
          return '馬';
        case 'b':
          return '象';
        case 'r':
          return '車';
        case 'q':
          return '后';
        case 'k':
          return '王';
      }
      return '棋子';
    }

    if (context.isCapture || context.moveSan.contains('x')) return 'capture';
    if (context.isCheck || context.moveSan.contains('+')) return 'check';
    switch (pieceCode) {
      case 'p':
        return 'pawn';
      case 'n':
        return 'knight';
      case 'b':
        return 'bishop';
      case 'r':
        return 'rook';
      case 'q':
        return 'queen';
      case 'k':
        return 'king';
    }
    return 'piece';
  }

  List<CompanionChoice> _normalizeChoices(
    List<CompanionChoice> choices,
    AiTurnContext context, {
    required String message,
    required AiInteractionIntent intent,
    bool allowFallback = false,
  }) {
    final normalized = <CompanionChoice>[];
    final seen = <String>{};
    final isTeaching =
        intent == AiInteractionIntent.teach ||
        _looksLikeQuestion(message, context.language);
    for (final choice in choices) {
      final label = _sanitizeLabel(choice.label ?? '', context.language);
      if (label.isEmpty) continue;
      final adjustedLabel = _adjustLabelVariant(
        label,
        context,
        avoidLabels: _recentAvoidLabels,
      );
      final key = adjustedLabel.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      if (seen.contains(key)) continue;
      seen.add(key);
      final response = _sanitizeAiText(
        (choice.responseText ?? '').trim(),
        context.language,
      );
      final adjustedResponse = _alignResponseForLabel(
        response,
        context,
        label: adjustedLabel,
        intent: intent,
        isTeaching: isTeaching,
      );
      final finalResponse = adjustedResponse.isEmpty
          ? _defaultResponses(context.language)[0]
          : adjustedResponse;
      // Ensure response is never a question — strip trailing ? / ？
      final cleanedResponse = finalResponse
          .replaceAll(RegExp(r'[？?]+\s*$'), '！')
          .replaceAll(RegExp(r'[？?]+(\s)'), '！\$1');
      normalized.add(
        CompanionChoice(
          label: adjustedLabel,
          actionId: choice.actionId,
          responseText: cleanedResponse,
        ),
      );
      if (normalized.length >= 2) break;
    }

    if (allowFallback && normalized.length < 2) {
      final fallback = _fallbackChoiceSet(context, message: message);
      for (final choice in fallback) {
        final key = (choice.label ?? '').toLowerCase().replaceAll(
          RegExp(r'\s+'),
          '',
        );
        if (key.isEmpty || seen.contains(key)) continue;
        normalized.add(choice);
        seen.add(key);
        if (normalized.length >= 2) break;
      }
    }

    if (normalized.length == 2 && _isYesNoPair(normalized, context.language)) {
      final rewritten = _rewriteYesNoPair(context, message: message);
      return rewritten;
    }

    return normalized;
  }

  bool _isYesNoPair(List<CompanionChoice> choices, String language) {
    if (choices.length != 2) return false;
    final a = choices[0].label ?? '';
    final b = choices[1].label ?? '';
    return (_isYesLike(a, language) && _isNoLike(b, language)) ||
        (_isYesLike(b, language) && _isNoLike(a, language));
  }

  bool _isYesLike(String label, String language) {
    final text = label.trim();
    if (language == 'zh') {
      return text.startsWith('對') ||
          text.startsWith('是') ||
          text.startsWith('好') ||
          text.startsWith('沒錯') ||
          text.startsWith('當然') ||
          text.startsWith('想') ||
          text.startsWith('要');
    }
    final lower = text.toLowerCase();
    return lower.startsWith('yes') ||
        lower.startsWith('yeah') ||
        lower.startsWith('yep') ||
        lower.startsWith('sure') ||
        lower.startsWith('of course');
  }

  bool _isNoLike(String label, String language) {
    final text = label.trim();
    if (language == 'zh') {
      return text.startsWith('不') ||
          text.startsWith('沒') ||
          text.startsWith('別') ||
          text.startsWith('才') ||
          text.startsWith('不是') ||
          text.startsWith('沒有');
    }
    final lower = text.toLowerCase();
    return lower.startsWith('no') ||
        lower.startsWith('nah') ||
        lower.startsWith('nope');
  }

  List<CompanionChoice> _rewriteYesNoPair(
    AiTurnContext context, {
    required String message,
  }) {
    final isZh = context.language == 'zh';
    final poolsZh = [
      [_choice('我想試試這一步', '很棒，我們一起看看接下來。'), _choice('我先慢慢想', '可以，慢慢想很重要。')],
      [_choice('我覺得這樣不錯', '你有自己的節奏，這很好。'), _choice('我還不太確定', '沒關係，我會陪你一步一步走。')],
      [_choice('我想再觀察一下', '好主意，先看清楚也很棒。'), _choice('我先照感覺走', '可以，照感覺走也會有收穫。')],
      [_choice('我想穩穩地下', '穩穩下很好，我們慢慢來。'), _choice('我想試個新走法', '很棒，願意嘗試很厲害。')],
      [_choice('這步我有點緊張', '我懂，你已經做得很好了。'), _choice('這步我覺得輕鬆', '太好了，保持這個感覺。')],
      [
        _choice('我想先保護棋子', '很好的想法，先保護自己很重要。'),
        _choice('我想讓局面更活', '不錯，這樣會有更多選擇。'),
      ],
    ];

    final poolsEn = [
      [
        _choice('I’m just teasing', 'You’re playful — I’ll watch out.'),
        _choice('Just a casual move', 'Casual can be dangerous too.'),
      ],
      [
        _choice('Feeling a bit bold', 'Alright, I’m paying attention.'),
        _choice('Still thinking', 'Take your time, I’m here.'),
      ],
      [
        _choice('Testing you a bit', 'Okay, I’ll play along.'),
        _choice('Just popped in', 'That pop-in is sharp.'),
      ],
      [
        _choice('Wanna go for it', 'Bring it — I’m ready.'),
        _choice('No special plan', 'Sometimes that’s the fun part.'),
      ],
      [
        _choice('Just messing with you', 'Haha, you’re fun.'),
        _choice('Trying a new vibe', 'New vibes can be tricky.'),
      ],
      [
        _choice('Want your reaction', 'Then I’ll give you one.'),
        _choice('Just testing the mood', 'The mood feels good.'),
      ],
    ];

    final pools = isZh ? poolsZh : poolsEn;
    final available = <List<CompanionChoice>>[];
    for (final pair in pools) {
      final sig = _choiceSignature(pair);
      if (!_recentChoiceSignatures.contains(sig)) {
        available.add(pair);
      }
    }
    final pool = (available.isNotEmpty ? available : pools);
    return pool[_random.nextInt(pool.length)];
  }

  bool _isUnknownLabel(String label, String language) {
    final lower = label.toLowerCase();
    if (language == 'zh') {
      return label.contains('不知道') || label.contains('不確定');
    }
    return lower.contains('don\'t know') || lower.contains('not sure');
  }

  String _softenResponse(
    String response,
    AiTurnContext context, {
    required bool isTeaching,
  }) {
    if (response.isEmpty) {
      return _friendlyEncouragement(context);
    }
    if (_looksTextbook(response, context.language)) {
      return _friendlyEncouragement(context);
    }
    if (isTeaching) {
      return _softenTeachingResponse(response, context);
    }
    if (_looksTeachingResponse(response, context.language)) {
      return _friendlyEncouragement(context);
    }
    return response;
  }

  String _normalizeUnknownResponse(
    String response,
    AiTurnContext context, {
    required bool isTeaching,
  }) {
    final lang = context.language;
    final trimmed = response.trim();
    if (!isTeaching) {
      if (_looksTeachingResponse(trimmed, lang)) {
        return lang == 'zh'
            ? '沒關係～跟你下棋很有趣，我們慢慢來。'
            : 'No worries — playing with you is fun. We can take it slow.';
      }
      return trimmed.isEmpty
          ? (lang == 'zh'
                ? '沒關係～跟你下棋很有趣，我們慢慢來。'
                : 'No worries — playing with you is fun. We can take it slow.')
          : trimmed;
    }

    if (!_looksTeachingResponse(trimmed, lang)) {
      final explain = _friendlyTeachingTip(context);
      return trimmed.isEmpty ? explain : '$trimmed $explain';
    }
    return trimmed;
  }

  String _alignResponseForLabel(
    String response,
    AiTurnContext context, {
    required String label,
    required AiInteractionIntent intent,
    required bool isTeaching,
  }) {
    final lang = context.language;
    final trimmed = response.trim();

    if (_isUnknownLabel(label, lang)) {
      return _normalizeUnknownResponse(
        trimmed,
        context,
        isTeaching: isTeaching,
      );
    }

    if (_labelIsQuestion(label, lang)) {
      if (intent == AiInteractionIntent.teach) {
        if (!_looksTeachingResponse(trimmed, lang)) {
          return '${_friendlyTeachingTip(context)} 我們慢慢來就好。';
        }
        return trimmed;
      }
      if (_looksTeachingResponse(trimmed, lang) || trimmed.isEmpty) {
        return _lightAnswer(context);
      }
      return trimmed;
    }

    if (_labelIsPositive(label, lang)) {
      if (_looksTeachingResponse(trimmed, lang) &&
          intent != AiInteractionIntent.teach) {
        return _friendlyEncouragement(context);
      }
      return trimmed.isEmpty ? _friendlyEncouragement(context) : trimmed;
    }

    return _softenResponse(trimmed, context, isTeaching: isTeaching);
  }

  String _lightAnswer(AiTurnContext context) {
    final isZh = context.language == 'zh';
    final poolZh = [
      '我只是想試試看～你也可以這樣玩。',
      '我就想隨意走走，看看感覺。',
      '我也在摸索，一起慢慢玩吧。',
      '我只是覺得有趣，就試了一步。',
      '嘿嘿，被你發現了～我就想給你壓力。',
      '我不會讓你得逞的～',
      '別看我這樣，我也想跟你拚一下。',
    ];
    final poolEn = [
      'I just wanted to try it — you can too.',
      'I was just exploring a bit.',
      'I\'m figuring it out too — we can go slow.',
      'It felt fun, so I tried it.',
      'Haha, you caught me — I wanted some pressure.',
      'I won\'t let you off easy.',
    ];
    final pool = isZh ? poolZh : poolEn;
    return pool[_random.nextInt(pool.length)];
  }

  bool _labelIsQuestion(String label, String language) {
    if (label.contains('？') || label.contains('?')) return true;
    if (language == 'zh') {
      return label.contains('為什麼') ||
          label.contains('怎麼') ||
          label.contains('要不要') ||
          label.contains('可以嗎');
    }
    final lower = label.toLowerCase();
    return lower.contains('why') ||
        lower.contains('how') ||
        lower.contains('what') ||
        lower.contains('can');
  }

  bool _labelIsPositive(String label, String language) {
    if (language == 'zh') {
      return label.contains('不錯') ||
          label.contains('可以') ||
          label.contains('好') ||
          label.contains('喜歡') ||
          label.contains('謝謝');
    }
    final lower = label.toLowerCase();
    return lower.contains('good') ||
        lower.contains('nice') ||
        lower.contains('thanks') ||
        lower.contains('okay') ||
        lower.contains('great');
  }

  String _softenTeachingResponse(String response, AiTurnContext context) {
    final lang = context.language;
    final trimmed = response.trim();
    if (trimmed.isEmpty) return _friendlyTeachingTip(context);

    if (lang == 'zh' && trimmed.length > 26) {
      return '${_friendlyTeachingTip(context)} 我們慢慢來就好。';
    }
    if (lang != 'zh' && trimmed.length > 90) {
      return '${_friendlyTeachingTip(context)} We can take it slow.';
    }
    return trimmed;
  }

  String _friendlyTeachingTip(AiTurnContext context) {
    final lang = context.language;
    final tip = _shortTipFromText(context, seed: context.moveSan);
    if (lang == 'zh') {
      return '小提醒：$tip。';
    }
    return 'Quick tip: $tip.';
  }

  String _shortTipFromText(AiTurnContext context, {String? seed}) {
    final lang = context.language;
    final text = seed ?? '';
    if (lang == 'zh') {
      if (text.contains('+') || context.isCheck) {
        return '將軍時先確保自己安全';
      }
      if (text.contains('x') || context.isCapture) {
        return '吃子很棒，但也要看安全';
      }
      if (text.contains('O-O') || text.contains('O-O-O')) {
        return '把國王藏好會更安心';
      }
      return '先把棋子走出來會比較有空間';
    }

    if (text.contains('+') || context.isCheck) {
      return 'when you give check, keep your king safe';
    }
    if (text.contains('x') || context.isCapture) {
      return 'captures are good, but check safety';
    }
    if (text.contains('O-O')) {
      return 'castling keeps your king safer';
    }
    return 'bring pieces out to get space';
  }

  String _friendlyEncouragement(AiTurnContext context) {
    final isZh = context.language == 'zh';
    final poolZh = [
      '跟你下棋很有趣～',
      '這步蠻有感覺的耶。',
      '我覺得你很會想。',
      '慢慢來也很棒。',
      '我喜歡你的節奏。',
      '我們就順著玩下去～',
      '跟你一起想很舒服。',
      '這局很有陪伴感。',
      '我在這裡陪你。',
      '這樣走也蠻可愛的。',
    ];
    final poolEn = [
      'Playing with you is fun.',
      'That felt pretty nice.',
      'I like your pace.',
      'We can take it slow.',
      'This is going well.',
      'Let\'s keep it chill.',
      'This feels calm and good.',
      'Nice, we\'re in sync.',
      'I\'m here with you.',
    ];
    final pool = isZh ? poolZh : poolEn;
    return pool[_random.nextInt(pool.length)];
  }

  bool _looksTeachingResponse(String text, String language) {
    if (text.isEmpty) return false;
    if (language == 'zh') {
      return text.contains('因為') ||
          text.contains('所以') ||
          text.contains('可以') ||
          text.contains('開局') ||
          text.contains('中心') ||
          text.contains('空間');
    }
    final lower = text.toLowerCase();
    return lower.contains('because') ||
        lower.contains('so that') ||
        lower.contains('opening') ||
        lower.contains('center') ||
        lower.contains('space') ||
        lower.contains('develop');
  }

  String _emotionText(EmotionLevel level, String language) {
    if (language == 'zh') {
      switch (level) {
        case EmotionLevel.happy:
          return '開心';
        case EmotionLevel.neutral:
          return '平靜';
        case EmotionLevel.anxious:
          return '緊張';
        case EmotionLevel.frustrated:
          return '有點挫折';
      }
    }

    switch (level) {
      case EmotionLevel.happy:
        return 'happy';
      case EmotionLevel.neutral:
        return 'calm';
      case EmotionLevel.anxious:
        return 'anxious';
      case EmotionLevel.frustrated:
        return 'frustrated';
    }
  }

  List<String> _defaultResponses(String language) {
    if (language == 'zh') {
      return ['我也覺得不錯～', '沒事，我陪你～', '哈哈我也是！'];
    }
    return ['Nice one!', 'It\'s okay, I\'m here.', 'Haha, same!'];
  }

  String _phaseText(int moveNumber, String language) {
    final isZh = language == 'zh';
    if (moveNumber <= 6) {
      return isZh ? '開局' : 'opening';
    }
    if (moveNumber <= 20) {
      return isZh ? '中局' : 'middlegame';
    }
    return isZh ? '殘局' : 'endgame';
  }

  List<String> _extractRecentAiPhrases(
    List<ChatMessage>? recentMessages, {
    int limit = 10,
  }) {
    if (recentMessages == null || recentMessages.isEmpty) return const [];
    final phrases = <String>[];
    for (int i = recentMessages.length - 1; i >= 0; i--) {
      final msg = recentMessages[i];
      if (msg.sender != ChatSender.ai) continue;
      final text = msg.interaction?.text;
      if (text != null && text.trim().isNotEmpty) {
        phrases.add(text.trim());
      }
      if (phrases.length >= limit) break;
    }
    return phrases;
  }

  List<String> _extractRecentChoiceLabels(
    List<ChatMessage>? recentMessages, {
    int limit = 6,
  }) {
    if (recentMessages == null || recentMessages.isEmpty) return const [];
    final labels = <String>[];
    for (int i = recentMessages.length - 1; i >= 0; i--) {
      final msg = recentMessages[i];
      if (msg.sender != ChatSender.ai) continue;
      final choices = msg.interaction?.choices;
      if (choices == null || choices.isEmpty) continue;
      for (final choice in choices) {
        final label = choice.label?.trim();
        if (label != null && label.isNotEmpty) {
          labels.add(label);
        }
        if (labels.length >= limit) break;
      }
      if (labels.length >= limit) break;
    }
    return labels;
  }

  String _getPieceName(String type) {
    switch (_normalizePieceCode(type)) {
      case 'p':
        return 'pawn';
      case 'n':
        return 'knight';
      case 'b':
        return 'bishop';
      case 'r':
        return 'rook';
      case 'q':
        return 'queen';
      case 'k':
        return 'king';
      default:
        return 'piece';
    }
  }

  String _normalizePieceCode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final lower = raw.toLowerCase().trim();
    if (lower.length == 1 && RegExp(r'[pnbrqk]').hasMatch(lower)) {
      return lower;
    }
    if (lower.contains('pawn')) return 'p';
    if (lower.contains('knight')) return 'n';
    if (lower.contains('bishop')) return 'b';
    if (lower.contains('rook')) return 'r';
    if (lower.contains('queen')) return 'q';
    if (lower.contains('king')) return 'k';
    if (lower.contains('馬')) return 'n';
    if (lower.contains('象')) return 'b';
    if (lower.contains('車')) return 'r';
    if (lower.contains('后')) return 'q';
    if (lower.contains('王')) return 'k';
    if (lower.contains('兵')) return 'p';
    return '';
  }

  static String _normalizeBaseUrl(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return AppConfig.apiBaseUrl;
    var normalized = trimmed.replaceAll(RegExp(r'/+$'), '');
    if (normalized.endsWith('/v1')) {
      normalized = normalized.substring(0, normalized.length - 3);
    }
    return normalized;
  }
}

/// Exception class for AI Service errors
class AiServiceException implements Exception {
  final String message;
  AiServiceException(this.message);
  @override
  String toString() => 'AiServiceException: $message';
}

class _AltBundle {
  final String angleKey;
  final String message;
  final List<CompanionChoice> choices;

  _AltBundle({
    required this.angleKey,
    required this.message,
    required this.choices,
  });
}
