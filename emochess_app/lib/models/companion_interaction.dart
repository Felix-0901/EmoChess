// Companion interaction model for EmoChess
// Supports yes/no questions, multiple choice, and simple messages

import 'ai_turn_context.dart';

/// Type of companion interaction
enum CompanionInteractionType {
  message, // Simple encouraging message
  yesNo, // Yes/No question
  multiChoice, // Multiple choice question
}

/// A single interaction from the AI companion
class CompanionInteraction {
  final String? messageKey;
  final String? text; // Raw text support for LLM
  final CompanionInteractionType type;
  final List<CompanionChoice>? choices;
  final String? yesKey;
  final String? noKey;
  final AiTurnContext? turnContext;
  final DateTime timestamp;
  final String? triggerReason;

  CompanionInteraction({
    this.messageKey,
    this.text,
    required this.type,
    this.choices,
    this.yesKey,
    this.noKey,
    this.turnContext,
    DateTime? timestamp,
    this.triggerReason,
  }) : assert(
         messageKey != null || text != null,
         'Must provide either messageKey or text',
       ),
       timestamp = timestamp ?? DateTime.now();

  /// Create a simple message interaction
  factory CompanionInteraction.message(
    String messageKey, {
    String? trigger,
    String? text,
    AiTurnContext? turnContext,
  }) {
    return CompanionInteraction(
      messageKey: text == null ? messageKey : null,
      text: text,
      type: CompanionInteractionType.message,
      turnContext: turnContext,
      triggerReason: trigger,
    );
  }

  /// Create a yes/no interaction
  factory CompanionInteraction.yesNo({
    String? messageKey,
    String? text,
    String yesKey = 'yes',
    String noKey = 'no',
    String? trigger,
    AiTurnContext? turnContext,
  }) {
    return CompanionInteraction(
      messageKey: messageKey,
      text: text,
      type: CompanionInteractionType.yesNo,
      yesKey: yesKey,
      noKey: noKey,
      turnContext: turnContext,
      triggerReason: trigger,
    );
  }

  /// Create a multiple choice interaction
  factory CompanionInteraction.multiChoice({
    String? messageKey,
    String? text,
    required List<CompanionChoice> choices,
    String? trigger,
    AiTurnContext? turnContext,
  }) {
    return CompanionInteraction(
      messageKey: messageKey,
      text: text,
      type: CompanionInteractionType.multiChoice,
      choices: choices,
      turnContext: turnContext,
      triggerReason: trigger,
    );
  }
}

/// A choice option for multiple choice interactions
class CompanionChoice {
  final String? labelKey;
  final String? label; // Raw text support for LLM
  final String? emoji;
  final String actionId;
  final String? responseText; // Pre-generated response for this choice
  final String? responseKey; // Localization key for response

  const CompanionChoice({
    this.labelKey,
    this.label,
    this.emoji,
    required this.actionId,
    this.responseText,
    this.responseKey,
  }) : assert(
         labelKey != null || label != null,
         'Must provide either labelKey or label',
       );
}

/// User's response to a companion interaction
class CompanionResponse {
  final CompanionInteraction interaction;
  final String? selectedChoiceId;
  final bool? yesNoResponse;
  final DateTime responseTime;

  CompanionResponse({
    required this.interaction,
    this.selectedChoiceId,
    this.yesNoResponse,
    DateTime? responseTime,
  }) : responseTime = responseTime ?? DateTime.now();
}
