import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Service for saving and loading game history
/// Records moves, chat history, and emotional states for analysis
class GameHistoryService {
  static const String _historyFolder = 'game_history';

  /// Save a complete game session to JSON file
  Future<String?> saveGameSession(GameRecord record) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${directory.path}/$_historyFolder');

      if (!await historyDir.exists()) {
        await historyDir.create(recursive: true);
      }

      final fileName = 'game_${record.sessionId}.json';
      final file = File('${historyDir.path}/$fileName');

      final jsonString = const JsonEncoder.withIndent(
        '  ',
      ).convert(record.toJson());
      await file.writeAsString(jsonString);

      return file.path;
    } catch (_) {
      return null;
    }
  }

  /// Load all game records for analysis
  Future<List<GameRecord>> loadAllGameRecords() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final historyDir = Directory('${directory.path}/$_historyFolder');

      if (!await historyDir.exists()) {
        return [];
      }

      final List<GameRecord> records = [];
      await for (final entity in historyDir.list()) {
        if (entity is File && entity.path.endsWith('.json')) {
          try {
            final content = await entity.readAsString();
            final json = jsonDecode(content) as Map<String, dynamic>;
            records.add(GameRecord.fromJson(json));
          } catch (_) {}
        }
      }

      // Sort by start time, most recent first
      records.sort((a, b) => b.startTime.compareTo(a.startTime));
      return records;
    } catch (_) {
      return [];
    }
  }

  /// Delete a game record
  Future<bool> deleteGameRecord(String sessionId) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/$_historyFolder/game_$sessionId.json',
      );

      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }
}

/// Complete game record for analysis
class GameRecord {
  final String sessionId;
  final DateTime startTime;
  DateTime? endTime;
  final List<MoveRecord> moves;
  final List<ChatRecord> chatHistory;
  final List<EmotionRecord> emotionLog;
  final String initialEmotion;
  String? result; // 'white_wins', 'black_wins', 'draw', 'incomplete'

  GameRecord({
    required this.sessionId,
    required this.startTime,
    this.endTime,
    List<MoveRecord>? moves,
    List<ChatRecord>? chatHistory,
    List<EmotionRecord>? emotionLog,
    required this.initialEmotion,
    this.result,
  }) : moves = moves ?? [],
       chatHistory = chatHistory ?? [],
       emotionLog = emotionLog ?? [];

  /// Add a move record
  void addMove(MoveRecord move) {
    moves.add(move);
  }

  /// Add a chat record
  void addChat(ChatRecord chat) {
    chatHistory.add(chat);
  }

  /// Add an emotion record
  void addEmotion(EmotionRecord emotion) {
    emotionLog.add(emotion);
  }

  /// Complete the game
  void completeGame(String gameResult) {
    endTime = DateTime.now();
    result = gameResult;
  }

  /// Calculate game duration
  Duration get duration {
    return (endTime ?? DateTime.now()).difference(startTime);
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'initialEmotion': initialEmotion,
      'result': result,
      'durationSeconds': duration.inSeconds,
      'moves': moves.map((m) => m.toJson()).toList(),
      'chatHistory': chatHistory.map((c) => c.toJson()).toList(),
      'emotionLog': emotionLog.map((e) => e.toJson()).toList(),
    };
  }

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      sessionId: json['sessionId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      initialEmotion: json['initialEmotion'] as String? ?? 'neutral',
      result: json['result'] as String?,
      moves:
          (json['moves'] as List<dynamic>?)
              ?.map((m) => MoveRecord.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      chatHistory:
          (json['chatHistory'] as List<dynamic>?)
              ?.map((c) => ChatRecord.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      emotionLog:
          (json['emotionLog'] as List<dynamic>?)
              ?.map((e) => EmotionRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

/// Record of a single chess move
class MoveRecord {
  final int moveNumber;
  final String san; // Standard Algebraic Notation
  final String player; // 'white' or 'black'
  final DateTime timestamp;
  final String? preFen; // Board state before move
  final String? postFen; // Board state after move

  MoveRecord({
    required this.moveNumber,
    required this.san,
    required this.player,
    required this.timestamp,
    this.preFen,
    this.postFen,
  });

  Map<String, dynamic> toJson() {
    return {
      'moveNumber': moveNumber,
      'san': san,
      'player': player,
      'timestamp': timestamp.toIso8601String(),
      if (preFen != null) 'preFen': preFen,
      if (postFen != null) 'postFen': postFen,
    };
  }

  factory MoveRecord.fromJson(Map<String, dynamic> json) {
    return MoveRecord(
      moveNumber: json['moveNumber'] as int,
      san: json['san'] as String,
      player: json['player'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      preFen: json['preFen'] as String?,
      postFen: json['postFen'] as String? ?? json['fen'] as String?,
    );
  }
}

/// Record of a chat interaction
class ChatRecord {
  final DateTime timestamp;
  final String sender; // 'ai' or 'user'
  final String message;
  final String? userChoice; // If user selected a choice
  final String? aiResponse; // AI's response to user choice
  final int? moveNumber;
  final String? whitePreFen;
  final String? whitePostFen;
  final String? blackPostFen;
  final String? roundId;

  ChatRecord({
    required this.timestamp,
    required this.sender,
    required this.message,
    this.userChoice,
    this.aiResponse,
    this.moveNumber,
    this.whitePreFen,
    this.whitePostFen,
    this.blackPostFen,
    this.roundId,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'sender': sender,
      'message': message,
      if (userChoice != null) 'userChoice': userChoice,
      if (aiResponse != null) 'aiResponse': aiResponse,
      if (moveNumber != null) 'moveNumber': moveNumber,
      if (whitePreFen != null) 'whitePreFen': whitePreFen,
      if (whitePostFen != null) 'whitePostFen': whitePostFen,
      if (blackPostFen != null) 'blackPostFen': blackPostFen,
      if (roundId != null) 'roundId': roundId,
    };
  }

  factory ChatRecord.fromJson(Map<String, dynamic> json) {
    return ChatRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      sender: json['sender'] as String,
      message: json['message'] as String,
      userChoice: json['userChoice'] as String?,
      aiResponse: json['aiResponse'] as String?,
      moveNumber: json['moveNumber'] as int?,
      whitePreFen: json['whitePreFen'] as String?,
      whitePostFen: json['whitePostFen'] as String?,
      blackPostFen: json['blackPostFen'] as String?,
      roundId: json['roundId'] as String?,
    );
  }
}

/// Record of an emotional state change
class EmotionRecord {
  final DateTime timestamp;
  final String emotion; // 'happy', 'neutral', 'frustrated'
  final int? moveNumber; // Which move triggered this emotion
  final String?
  trigger; // What triggered the emotion (e.g., 'check', 'capture', 'user_input')

  EmotionRecord({
    required this.timestamp,
    required this.emotion,
    this.moveNumber,
    this.trigger,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'emotion': emotion,
      if (moveNumber != null) 'moveNumber': moveNumber,
      if (trigger != null) 'trigger': trigger,
    };
  }

  factory EmotionRecord.fromJson(Map<String, dynamic> json) {
    return EmotionRecord(
      timestamp: DateTime.parse(json['timestamp'] as String),
      emotion: json['emotion'] as String,
      moveNumber: json['moveNumber'] as int?,
      trigger: json['trigger'] as String?,
    );
  }
}
