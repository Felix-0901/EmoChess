// Emotion state model for EmoChess
// Tracks child's emotional state during chess gameplay

import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

enum EmotionLevel { happy, neutral, frustrated }

class EmotionState {
  final EmotionLevel level;
  final DateTime timestamp;
  final String? note;
  final EmotionSource source;

  const EmotionState({
    required this.level,
    required this.timestamp,
    this.note,
    this.source = EmotionSource.manual,
  });

  /// Create a happy emotion state
  factory EmotionState.happy({String? note}) => EmotionState(
    level: EmotionLevel.happy,
    timestamp: DateTime.now(),
    note: note,
    source: EmotionSource.manual,
  );

  /// Create a neutral emotion state
  factory EmotionState.neutral({String? note}) => EmotionState(
    level: EmotionLevel.neutral,
    timestamp: DateTime.now(),
    note: note,
    source: EmotionSource.manual,
  );

  /// Create a frustrated emotion state
  factory EmotionState.frustrated({String? note}) => EmotionState(
    level: EmotionLevel.frustrated,
    timestamp: DateTime.now(),
    note: note,
    source: EmotionSource.manual,
  );

  /// Get emoji representation
  String getText() {
    switch (level) {
      case EmotionLevel.happy:
        return 'Happy';
      case EmotionLevel.neutral:
        return 'Calm';
      case EmotionLevel.frustrated:
        return 'Frustrated';
    }
  }

  String getLocalizedText(BuildContext context) {
    try {
      final l10n = AppLocalizations.of(context);
      switch (level) {
        case EmotionLevel.happy:
          return l10n.happy;
        case EmotionLevel.neutral:
          return l10n.neutral;
        case EmotionLevel.frustrated:
          return l10n.frustrated;
      }
    } catch (_) {
      // Fallback to English
      return getText();
    }
  }

  /// Get icon representation
  IconData get icon {
    switch (level) {
      case EmotionLevel.happy:
        return Icons.sentiment_satisfied_alt_rounded;
      case EmotionLevel.neutral:
        return Icons.sentiment_neutral_rounded;
      case EmotionLevel.frustrated:
        return Icons.sentiment_dissatisfied_rounded;
    }
  }

  /// Get display text
  String get displayText {
    switch (level) {
      case EmotionLevel.happy:
        return 'I feel good!';
      case EmotionLevel.neutral:
        return 'I\'m okay';
      case EmotionLevel.frustrated:
        return 'I feel frustrated';
    }
  }

  /// Get localized display text (Chinese)
  String get displayTextZh {
    switch (level) {
      case EmotionLevel.happy:
        return '我感覺很好！';
      case EmotionLevel.neutral:
        return '我還可以';
      case EmotionLevel.frustrated:
        return '我有點挫折';
    }
  }

  EmotionState copyWith({
    EmotionLevel? level,
    DateTime? timestamp,
    String? note,
    EmotionSource? source,
  }) {
    return EmotionState(
      level: level ?? this.level,
      timestamp: timestamp ?? this.timestamp,
      note: note ?? this.note,
      source: source ?? this.source,
    );
  }

  Map<String, dynamic> toJson() => {
    'level': level.name,
    'timestamp': timestamp.toIso8601String(),
    'note': note,
    'source': source.name,
  };

  factory EmotionState.fromJson(Map<String, dynamic> json) => EmotionState(
    level: EmotionLevel.values.byName(json['level'] as String),
    timestamp: DateTime.parse(json['timestamp'] as String),
    note: json['note'] as String?,
    source: EmotionSource.values.byName(json['source'] as String),
  );
}

/// Source of emotion detection
enum EmotionSource {
  manual, // User tapped emotion button
  behavior, // Detected from behavior (rapid moves, etc.)
  parent, // Parent/teacher input
  aiSuggested, // AI companion suggestion
}

/// Behavioral trigger that might indicate frustration
enum BehaviorTrigger {
  rapidUndos, // >3 undos in 30 seconds
  longPause, // >60 seconds without move
  rapidRandomMoves, // <2 seconds per move × 5
  repeatedMistakes, // Same mistake pattern
}

class BehaviorEvent {
  final BehaviorTrigger trigger;
  final DateTime timestamp;
  final int count;

  const BehaviorEvent({
    required this.trigger,
    required this.timestamp,
    this.count = 1,
  });

  Map<String, dynamic> toJson() => {
    'trigger': trigger.name,
    'timestamp': timestamp.toIso8601String(),
    'count': count,
  };
}
