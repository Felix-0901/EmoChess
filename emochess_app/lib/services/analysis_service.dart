import 'dart:math';
import 'package:chess/chess.dart' as chess_lib;
import '../models/companion_interaction.dart';
import '../models/emotion_state.dart';
import '../models/chat_message.dart';
import '../models/conversation_round.dart';
import 'ai_companion_service.dart';

/// Therapeutic AI analysis service
/// Generates context-aware, encouraging questions and commentary
/// Designed to support emotional regulation for ASD children
class AnalysisService {
  final _random = Random();
  final AiCompanionService _aiService = AiCompanionService();

  // Track recent message types to avoid repetition
  final List<String> _recentTriggers = [];
  static const int _maxRecentTracking = 5;

  // Current player emotion (set externally)
  EmotionLevel _currentEmotion = EmotionLevel.neutral;
  String _currentLanguage = 'en';

  /// Set the current player emotion for context-aware messages
  void setPlayerEmotion(EmotionLevel emotion) {
    _currentEmotion = emotion;
  }

  /// Set the current language for localized responses
  void setLanguage(String language) {
    _currentLanguage = language;
  }

  /// Analyze the current move and board state to generate an interaction
  /// Per user spec: sends full context (pre/post FEN, move SAN, emotion)
  Future<CompanionInteraction?> analyzeMove({
    required String preFen,
    required String postFen,
    required String moveSan,
    required bool isCheck,
    required bool isCapture,
    required int moveNumber,
    String? opponentPreFen,
    String? opponentPostFen,
    String? opponentMoveSan,
    bool? opponentIsCheck,
    bool? opponentIsCapture,
    String? playerEmotion,
    String? pieceMovedType,
    String? capturedPieceType,
    String? opponentPieceMovedType,
    String? opponentCapturedPieceType,
    List<ChatMessage>? recentMessages,
    List<ConversationRound>? recentRounds,
  }) async {
    // Update emotion if provided
    if (playerEmotion != null) {
      switch (playerEmotion) {
        case 'happy':
          _currentEmotion = EmotionLevel.happy;
          break;
        case 'anxious':
          _currentEmotion = EmotionLevel.anxious;
          break;
        case 'frustrated':
          _currentEmotion = EmotionLevel.frustrated;
          break;
        default:
          _currentEmotion = EmotionLevel.neutral;
      }
    }

    // No artificial delay; wait for AI response as long as needed.

    // Decide if we should generate a message (not every move needs one)
    if (!_shouldGenerateMessage(moveNumber, isCheck, isCapture)) {
      return null;
    }

    try {
      final intent = _chooseIntent();
      final dynamicInteraction = await _aiService.generateDynamicInteraction(
        preFen: preFen,
        postFen: postFen,
        moveSan: moveSan,
        emotionLevel: _currentEmotion,
        moveNumber: moveNumber,
        isCheck: isCheck,
        isCapture: isCapture,
        opponentPreFen: opponentPreFen,
        opponentPostFen: opponentPostFen,
        opponentMoveSan: opponentMoveSan,
        opponentIsCheck: opponentIsCheck,
        opponentIsCapture: opponentIsCapture,
        pieceMovedType: pieceMovedType,
        capturedPieceType: capturedPieceType,
        opponentPieceMovedType: opponentPieceMovedType,
        opponentCapturedPieceType: opponentCapturedPieceType,
        language: _currentLanguage,
        recentMessages: recentMessages,
        recentRounds: recentRounds,
        intentHint: intent,
      );

      if (dynamicInteraction != null) {
        return dynamicInteraction;
      }
    } catch (_) {}

    return _createFallbackInteraction(
      fen: postFen,
      lastMoveSan: moveSan,
      isCheck: isCheck,
      isCapture: isCapture,
      moveNumber: moveNumber,
    );

  }

  AiInteractionIntent _chooseIntent() {
    if (_currentEmotion == EmotionLevel.frustrated ||
        _currentEmotion == EmotionLevel.anxious) {
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

  /// Decide whether to generate a message for this move
  /// Now always returns true - AI responds to every player move
  bool _shouldGenerateMessage(int moveNumber, bool isCheck, bool isCapture) {
    // Always respond to every move for consistent interaction
    return true;
  }

  /// Create fallback interaction when LLM is unavailable
  CompanionInteraction _createFallbackInteraction({
    required String fen,
    required String lastMoveSan,
    required bool isCheck,
    required bool isCapture,
    required int moveNumber,
  }) {
    final chess = chess_lib.Chess.fromFEN(fen);

    // Check situations
    if (isCheck) {
      return _createCheckInteraction();
    }

    // Capture situations
    if (isCapture && !_wasRecentTrigger('capture')) {
      return _createCaptureInteraction();
    }

    // Emotional check-in for frustrated players
    if (_currentEmotion == EmotionLevel.frustrated ||
        _currentEmotion == EmotionLevel.anxious) {
      if (!_wasRecentTrigger('emotional')) {
        return createEmotionCheckin(_currentEmotion);
      }
    }

    // Teaching moment in opening
    if (moveNumber <= 12 && moveNumber % 4 == 0) {
      if (!_wasRecentTrigger('teaching')) {
        return _createTeachingMoment();
      }
    }

    // General encouragement
    if (!_wasRecentTrigger('encourage')) {
      return _createEncouragement();
    }

    // Strategic question mid-game
    if (chess.history.length > 10 && _random.nextDouble() < 0.4) {
      if (!_wasRecentTrigger('strategy')) {
        return _createStrategyInteraction();
      }
    }

    // Default catch-all: Always provide encouragement
    return _createEncouragement();
  }

  // --- Helper Methods ---

  bool _wasRecentTrigger(String trigger) {
    if (_recentTriggers.contains(trigger)) return true;
    _addRecentTrigger(trigger);
    return false;
  }

  void _addRecentTrigger(String trigger) {
    _recentTriggers.add(trigger);
    if (_recentTriggers.length > _maxRecentTracking) {
      _recentTriggers.removeAt(0);
    }
  }

  // --- Fallback Interaction Generators (Using Message Keys for Localization) ---

  CompanionInteraction _createCheckInteraction() {
    _addRecentTrigger('check');
    final messageKeys = [
      'aiFallbackCheck1',
      'aiFallbackCheck2',
      'aiFallbackCheck3',
    ];
    return CompanionInteraction.yesNo(
      messageKey: messageKeys[_random.nextInt(messageKeys.length)],
      yesKey: 'yes',
      noKey: 'imOkay',
      trigger: 'check',
    );
  }

  CompanionInteraction _createCaptureInteraction() {
    _addRecentTrigger('capture');
    final messageKeys = [
      'aiFallbackCapture1',
      'aiFallbackCapture2',
      'aiFallbackCapture3',
    ];
    return CompanionInteraction.multiChoice(
      messageKey: messageKeys[_random.nextInt(messageKeys.length)],
      trigger: 'capture',
      choices: [
        const CompanionChoice(
          labelKey: 'choiceThanks',
          actionId: 'thanks',
          responseKey: 'responseThanks',
        ),
        const CompanionChoice(
          labelKey: 'choiceCool',
          actionId: 'cool',
          responseKey: 'responseCool',
        ),
      ],
    );
  }

  /// Trigger an immediate emotion check-in interaction
  /// Call this when the user changes their emotion manually during the game
  CompanionInteraction createEmotionCheckin(EmotionLevel emotion) {
    _addRecentTrigger('emotional');
    _currentEmotion = emotion;

    // Choose response based on the new emotion
    if (emotion == EmotionLevel.frustrated ||
        emotion == EmotionLevel.anxious) {
      return CompanionInteraction.multiChoice(
        messageKey: 'aiFallbackFrustrated',
        trigger: 'emotional_frustrated',
        choices: [
          const CompanionChoice(
            labelKey: 'aiFallbackNeedHelp',
            actionId: 'help',
            responseKey: 'aiFallbackHelpResponse',
          ),
          const CompanionChoice(
            labelKey: 'aiFallbackImFine',
            actionId: 'okay',
            responseKey: 'aiFallbackFineResponse',
          ),
          const CompanionChoice(
            labelKey: 'aiFallbackWantBreak',
            actionId: 'break',
            responseKey: 'aiFallbackBreakResponse',
          ),
        ],
      );
    } else if (emotion == EmotionLevel.happy) {
      // Cheering response for happy emotion
      final happyKeys = [
        'aiFallbackHappyAmazing',
        'aiFallbackHappyWonderful',
        'aiFallbackHappyGreat',
      ];
      return CompanionInteraction.multiChoice(
        messageKey: happyKeys[_random.nextInt(happyKeys.length)],
        trigger: 'emotional_happy',
        choices: [
          const CompanionChoice(
            labelKey: 'choiceThanks',
            actionId: 'thanks',
            responseKey: 'responseThanks',
          ),
          const CompanionChoice(
            labelKey: 'choiceCool',
            actionId: 'cool',
            responseKey: 'responseCool',
          ),
        ],
      );
    } else {
      // Calming response for neutral emotion
      return CompanionInteraction.multiChoice(
        messageKey: 'aiFallbackEncourage1', // "Take your time..."
        trigger: 'emotional_neutral',
        choices: [
          const CompanionChoice(
            labelKey: 'choiceThanks',
            actionId: 'thanks',
            responseKey: 'responseThanks',
          ),
          const CompanionChoice(
            labelKey: 'choiceGotIt',
            actionId: 'got_it',
            responseKey: 'responseGotIt',
          ),
        ],
      );
    }
  }

  CompanionInteraction _createTeachingMoment() {
    _addRecentTrigger('teaching');
    final teachingKeys = [
      'aiFallbackTeach1',
      'aiFallbackTeach2',
      'aiFallbackTeach3',
      'aiFallbackTeach4',
      'aiFallbackTeach5',
    ];
    return CompanionInteraction.multiChoice(
      messageKey: teachingKeys[_random.nextInt(teachingKeys.length)],
      trigger: 'teaching',
      choices: [
        const CompanionChoice(
          labelKey: 'choiceInteresting',
          actionId: 'interesting',
          responseKey: 'responseInteresting',
        ),
        const CompanionChoice(
          labelKey: 'choiceGotIt',
          actionId: 'got_it',
          responseKey: 'responseGotIt',
        ),
      ],
    );
  }

  CompanionInteraction _createEncouragement() {
    _addRecentTrigger('encourage');

    if (_currentEmotion == EmotionLevel.happy) {
      final happyKeys = [
        'aiFallbackHappyAmazing',
        'aiFallbackHappyWonderful',
        'aiFallbackHappyGreat',
      ];
      return CompanionInteraction.multiChoice(
        messageKey: happyKeys[_random.nextInt(happyKeys.length)],
        trigger: 'encourage_happy',
        choices: [
          const CompanionChoice(
            labelKey: 'choiceThanks',
            actionId: 'thanks',
            responseKey: 'responseThanks',
          ),
          const CompanionChoice(
            labelKey: 'choiceCool',
            actionId: 'cool',
            responseKey: 'responseCool',
          ),
        ],
      );
    }

    final encourageKeys = [
      'aiFallbackEncourage1',
      'aiFallbackEncourage2',
      // REMOVED: aiFallbackEncourage3 (It's a question "What are you planning?", incompatible with generic choices)
      'aiFallbackEncourage4',
    ];
    return CompanionInteraction.multiChoice(
      messageKey: encourageKeys[_random.nextInt(encourageKeys.length)],
      trigger: 'encourage',
      choices: [
        const CompanionChoice(
          labelKey: 'choiceThanks',
          actionId: 'thanks',
          responseKey: 'responseThanks',
        ),
        const CompanionChoice(
          labelKey: 'choiceGoodPoint',
          actionId: 'good_point',
          responseKey: 'responseGoodPoint',
        ),
      ],
    );
  }

  CompanionInteraction _createStrategyInteraction() {
    _addRecentTrigger('strategy');
    return CompanionInteraction.multiChoice(
      messageKey: 'aiFallbackStrategyQ',
      trigger: 'strategy',
      choices: [
        const CompanionChoice(
          labelKey: 'choiceAttack',
          actionId: 'attack',
          responseKey: 'aiFallbackAttackResponse',
        ),
        const CompanionChoice(
          labelKey: 'choiceDefend',
          actionId: 'defend',
          responseKey: 'aiFallbackDefendResponse',
        ),
        const CompanionChoice(
          labelKey: 'choiceDevelop',
          actionId: 'develop',
          responseKey: 'aiFallbackDevelopResponse',
        ),
      ],
    );
  }

  /// Generate a welcome message for the start of a game
  /// Creates an interactive greeting like a friend sitting across the board
  Future<CompanionInteraction> generateWelcome() async {
    await Future.delayed(const Duration(milliseconds: 300));
    return CompanionInteraction.multiChoice(
      messageKey: 'welcomeGreeting',
      trigger: 'welcome',
      choices: [
        const CompanionChoice(
          labelKey: 'welcomeChoiceReady',
          actionId: 'ready',
          responseKey: 'welcomeResponseReady',
        ),
        const CompanionChoice(
          labelKey: 'welcomeChoiceNervous',
          actionId: 'nervous',
          responseKey: 'welcomeResponseNervous',
        ),
        const CompanionChoice(
          labelKey: 'welcomeChoiceThinking',
          actionId: 'thinking',
          responseKey: 'welcomeResponseThinking',
        ),
      ],
    );
  }

  /// Reset tracking for a new game
  void reset() {
    _recentTriggers.clear();
    _currentEmotion = EmotionLevel.neutral;
  }
}
