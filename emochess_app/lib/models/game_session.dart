import 'emotion_state.dart';

/// Game session model for EmoChess
/// Tracks chess game with emotion history for parent reporting

class GameSession {
  final String id;
  final DateTime startTime;
  DateTime? endTime;
  final List<EmotionState> emotionHistory;
  final List<GameMove> moves;
  final List<BehaviorEvent> behaviorEvents;
  GameResult? result;
  EmotionState? preGameEmotion;
  EmotionState? postGameEmotion;

  GameSession({
    required this.id,
    required this.startTime,
    this.endTime,
    List<EmotionState>? emotionHistory,
    List<GameMove>? moves,
    List<BehaviorEvent>? behaviorEvents,
    this.result,
    this.preGameEmotion,
    this.postGameEmotion,
  }) : emotionHistory = emotionHistory ?? [],
       moves = moves ?? [],
       behaviorEvents = behaviorEvents ?? [];

  /// Create a new game session
  factory GameSession.create() => GameSession(
    id: DateTime.now().millisecondsSinceEpoch.toString(),
    startTime: DateTime.now(),
  );

  /// Add an emotion record
  void addEmotion(EmotionState emotion) {
    emotionHistory.add(emotion);
  }

  /// Add a move
  void addMove(GameMove move) {
    moves.add(move);
  }

  /// Add a behavior event
  void addBehaviorEvent(BehaviorEvent event) {
    behaviorEvents.add(event);
  }

  /// End the game session
  void endGame({required GameResult result, EmotionState? postEmotion}) {
    endTime = DateTime.now();
    this.result = result;
    postGameEmotion = postEmotion;
  }

  /// Get game duration
  Duration get duration => (endTime ?? DateTime.now()).difference(startTime);

  /// Count undos
  int get undoCount => moves.where((m) => m.isUndo).length;

  /// Check if there was a frustration event
  bool get hadFrustrationEvent =>
      emotionHistory.any((e) => e.level == EmotionLevel.frustrated) ||
      behaviorEvents.isNotEmpty;

  /// Get average time per move
  Duration? get averageMoveTime {
    final moveTimes = <Duration>[];
    for (int i = 1; i < moves.length; i++) {
      if (!moves[i].isUndo && !moves[i - 1].isUndo) {
        moveTimes.add(moves[i].timestamp.difference(moves[i - 1].timestamp));
      }
    }
    if (moveTimes.isEmpty) return null;
    final totalMs = moveTimes.fold<int>(0, (sum, d) => sum + d.inMilliseconds);
    return Duration(milliseconds: totalMs ~/ moveTimes.length);
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime?.toIso8601String(),
    'emotionHistory': emotionHistory.map((e) => e.toJson()).toList(),
    'moves': moves.map((m) => m.toJson()).toList(),
    'behaviorEvents': behaviorEvents.map((b) => b.toJson()).toList(),
    'result': result?.name,
    'preGameEmotion': preGameEmotion?.toJson(),
    'postGameEmotion': postGameEmotion?.toJson(),
  };
}

/// A single chess move
class GameMove {
  final String from;
  final String to;
  final String? piece;
  final DateTime timestamp;
  final bool isUndo;
  final bool isCapture;
  final bool isAiMove;

  const GameMove({
    required this.from,
    required this.to,
    this.piece,
    required this.timestamp,
    this.isUndo = false,
    this.isCapture = false,
    this.isAiMove = false,
  });

  Map<String, dynamic> toJson() => {
    'from': from,
    'to': to,
    'piece': piece,
    'timestamp': timestamp.toIso8601String(),
    'isUndo': isUndo,
    'isCapture': isCapture,
    'isAiMove': isAiMove,
  };
}

/// Game result
enum GameResult { win, loss, draw, abandoned }
