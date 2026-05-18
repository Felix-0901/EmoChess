import 'package:flutter/widgets.dart';
import '../models/emotion_state.dart';
import '../models/companion_interaction.dart';
import '../models/chat_message.dart';
import '../models/ai_turn_context.dart';
import '../models/conversation_round.dart';
import '../l10n/app_localizations.dart';

typedef ChatLogCallback =
    void Function(
      ChatSender sender,
      String message, {
      String? userChoice,
      String? aiResponse,
      String? roundId,
      AiTurnContext? turnContext,
    });

/// Emotion state provider for tracking child's emotional state
class EmotionProvider extends ChangeNotifier {
  EmotionState _currentState = EmotionState.neutral();
  final List<EmotionState> _history = [];
  bool _showBreathingPrompt = false;

  final List<ChatMessage> _chatHistory = [];
  final List<ConversationRound> _conversationRounds = [];
  _PendingRound? _pendingRound;
  bool _isResponding = false;
  bool _awaitingResponse = false;
  String _currentLanguage = 'en';

  // Callback to notify GameProvider when meaningful interaction is complete
  VoidCallback? onInteractionCompleted;

  // Callback for emotion changes (triggers AI check-in)
  Function(EmotionLevel)? onEmotionChanged;

  // Callback for emotion logging
  Function(EmotionLevel, EmotionSource)? onEmotionLogged;

  // Callback for chat logging
  ChatLogCallback? onChatLogged;

  EmotionState get currentState => _currentState;
  List<EmotionState> get history => List.unmodifiable(_history);
  bool get showBreathingPrompt => _showBreathingPrompt;

  List<ChatMessage> get chatHistory => List.unmodifiable(_chatHistory);
  List<ConversationRound> get conversationRounds =>
      List.unmodifiable(_conversationRounds);
  EmotionLevel get currentLevel => _currentState.level;
  bool get isResponding => _isResponding;
  bool get isAwaitingResponse => _awaitingResponse;

  void setLanguage(String language) {
    _currentLanguage = language;
  }

  String _localizeKey(String key) {
    return AppLocalizations(Locale(_currentLanguage)).get(key);
  }

  /// Add a message to chat history
  void addMessage(ChatMessage message) {
    _chatHistory.add(message);
    notifyListeners();
  }

  /// Set emotion manually (from emotion buttons)
  void setEmotion(EmotionLevel level, {String? note}) {
    _currentState = EmotionState(
      level: level,
      timestamp: DateTime.now(),
      note: note,
      source: EmotionSource.manual,
    );
    _history.add(_currentState);

    if (level == EmotionLevel.frustrated || level == EmotionLevel.anxious) {
      _showBreathingPrompt = true;
    } else if (level == EmotionLevel.happy) {
      _showBreathingPrompt = false;
    } else {
      _showBreathingPrompt = false;
    }

    // Notify external listener (e.g., GameScreen) to request AI check-in
    onEmotionChanged?.call(level);
    onEmotionLogged?.call(level, EmotionSource.manual);

    notifyListeners();
  }

  /// Record emotion from behavior detection
  void recordBehaviorEmotion(EmotionLevel level, {String? note}) {
    _currentState = EmotionState(
      level: level,
      timestamp: DateTime.now(),
      note: note,
      source: EmotionSource.behavior,
    );
    _history.add(_currentState);

    if (level == EmotionLevel.frustrated || level == EmotionLevel.anxious) {
      _showBreathingPrompt = true;
    }

    // Notify external listener
    onEmotionChanged?.call(level);
    onEmotionLogged?.call(level, EmotionSource.behavior);

    notifyListeners();
  }

  /// Called when player makes a move
  void onPlayerMove() {
    // Tracked for potential future analytics
  }

  /// Called when AI makes a move
  void onAiMove() {
    // Interaction after AI move handled separately
  }

  /// Handle user's choice response
  void onChoiceResponse(String choiceId, String choiceLabel) {
    if (_isResponding || !_awaitingResponse) return;

    _isResponding = true;
    notifyListeners();

    addMessage(ChatMessage.user(choiceLabel));
    _logChat(
      ChatSender.user,
      choiceLabel,
      userChoice: choiceLabel,
      roundId: _pendingRound?.roundId,
      turnContext: _pendingRound?.turnContext,
    );

    final lastAiMessage = _findLastAiMessageWithChoices();
    String? responseText;
    if (lastAiMessage != null && lastAiMessage.interaction?.choices != null) {
      final selectedChoice = lastAiMessage.interaction!.choices!.firstWhere(
        (c) =>
            c.actionId == choiceId ||
            c.label == choiceLabel ||
            c.labelKey == choiceLabel,
        orElse: () => const CompanionChoice(label: '', actionId: ''),
      );
      responseText = selectedChoice.responseText;
      if ((responseText == null || responseText.trim().isEmpty) &&
          selectedChoice.responseKey != null) {
        responseText = _localizeKey(selectedChoice.responseKey!);
      }
    }

    responseText = (responseText == null || responseText.trim().isEmpty)
        ? _fallbackChoiceResponse()
        : responseText.trim();

    addMessage(
      ChatMessage.ai(
        CompanionInteraction.message(
          '',
          text: responseText,
          trigger: 'response',
        ),
      ),
    );
    _logChat(
      ChatSender.ai,
      responseText,
      aiResponse: responseText,
      roundId: _pendingRound?.roundId,
      turnContext: _pendingRound?.turnContext,
    );

    if (_pendingRound != null) {
      _conversationRounds.add(
        ConversationRound(
          roundId: _pendingRound!.roundId,
          aiQuestion: _pendingRound!.aiQuestion,
          choices: _pendingRound!.choices,
          selectedChoice: choiceLabel,
          aiReply: responseText,
          moveNumber: _pendingRound!.turnContext?.moveNumber,
          emotion: _pendingRound!.turnContext?.emotionLevel.name,
          trigger: _pendingRound!.triggerReason,
          angleKey: _pendingRound!.angleKey,
          intent: _pendingRound!.intent,
          promptVersion: _pendingRound!.promptVersion,
          timestamp: DateTime.now(),
        ),
      );
      if (_conversationRounds.length > 200) {
        _conversationRounds.removeAt(0);
      }
    }
    _pendingRound = null;

    _awaitingResponse = false;
    _isResponding = false;
    notifyListeners();
    onInteractionCompleted?.call();
  }

  void _logChat(
    ChatSender sender,
    String message, {
    String? userChoice,
    String? aiResponse,
    String? roundId,
    AiTurnContext? turnContext,
  }) {
    if (message.trim().isEmpty) return;
    onChatLogged?.call(
      sender,
      message,
      userChoice: userChoice,
      aiResponse: aiResponse,
      roundId: roundId,
      turnContext: turnContext,
    );
  }

  String _fallbackChoiceResponse() {
    final isZh = _currentLanguage == 'zh';
    if (isZh) {
      return '我知道了～';
    }
    return 'Got it!';
  }

  /// Find the last AI message that has choices
  ChatMessage? _findLastAiMessageWithChoices() {
    for (int i = _chatHistory.length - 1; i >= 0; i--) {
      final msg = _chatHistory[i];
      if (msg.sender == ChatSender.ai &&
          msg.interaction != null &&
          msg.interaction!.choices != null &&
          msg.interaction!.choices!.isNotEmpty) {
        return msg;
      }
    }
    return null;
  }

  /// Dismiss breathing prompt
  void dismissBreathingPrompt() {
    _showBreathingPrompt = false;
    notifyListeners();
  }

  /// Set interaction directly (e.g. from Analysis Service)
  void setInteraction(CompanionInteraction interaction) {
    addMessage(ChatMessage.ai(interaction));
    _awaitingResponse =
        interaction.type != CompanionInteractionType.message &&
        (interaction.choices?.isNotEmpty ?? false);

    final messageText =
        interaction.text ??
        (interaction.messageKey != null
            ? _localizeKey(interaction.messageKey!)
            : '');
    final choiceTexts = <String>[];
    for (final choice in interaction.choices ?? const <CompanionChoice>[]) {
      final label =
          choice.label ??
          (choice.labelKey != null ? _localizeKey(choice.labelKey!) : '');
      if (label.trim().isNotEmpty) {
        choiceTexts.add(label.trim());
      }
    }

    if (_awaitingResponse) {
      final meta = interaction.meta ?? const <String, dynamic>{};
      _pendingRound = _PendingRound(
        roundId: DateTime.now().microsecondsSinceEpoch.toString(),
        aiQuestion: messageText,
        choices: choiceTexts,
        turnContext: interaction.turnContext,
        triggerReason: interaction.triggerReason,
        angleKey: meta['angleKey']?.toString(),
        intent: meta['intent']?.toString(),
        promptVersion: meta['promptVersion'] is int
            ? meta['promptVersion'] as int
            : int.tryParse('${meta['promptVersion']}'),
      );
    } else {
      _pendingRound = null;
    }

    _logChat(
      ChatSender.ai,
      messageText,
      roundId: _pendingRound?.roundId,
      turnContext: interaction.turnContext,
    );
    notifyListeners();

    // If no user response is needed, notify completion after a short delay
    // so the AI move can proceed
    if (!_awaitingResponse) {
      Future.delayed(const Duration(milliseconds: 800), () {
        onInteractionCompleted?.call();
      });
    }
  }

  /// Stop any pending companion prompt without changing the game emotion.
  void clearPendingCompanionInteraction() {
    _pendingRound = null;
    _awaitingResponse = false;
    _isResponding = false;
    notifyListeners();
  }

  /// Reset emotion state (for new game)
  void reset({EmotionLevel? initialEmotion}) {
    final baseEmotion = initialEmotion ?? _currentState.level;
    _currentState = EmotionState(
      level: baseEmotion,
      timestamp: DateTime.now(),
      source: EmotionSource.manual,
    );
    _showBreathingPrompt = false;
    _chatHistory.clear();
    _conversationRounds.clear();
    _pendingRound = null;

    _isResponding = false;
    _awaitingResponse = false;

    // Add welcome message with choices - like a friend greeting you
    // Add welcome message - stranger greeting (no interaction required)
    addMessage(
      ChatMessage.ai(
        CompanionInteraction.message('welcomeGreeting', trigger: 'welcome'),
      ),
    );
    _logChat(ChatSender.ai, _localizeKey('welcomeGreeting'));

    notifyListeners();
  }
}

class _PendingRound {
  final String roundId;
  final String aiQuestion;
  final List<String> choices;
  final AiTurnContext? turnContext;
  final String? triggerReason;
  final String? angleKey;
  final String? intent;
  final int? promptVersion;

  const _PendingRound({
    required this.roundId,
    required this.aiQuestion,
    required this.choices,
    required this.turnContext,
    required this.triggerReason,
    required this.angleKey,
    required this.intent,
    required this.promptVersion,
  });
}
