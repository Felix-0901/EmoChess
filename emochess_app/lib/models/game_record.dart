import '../models/conversation_round.dart';

/// Complete game record for analysis and cloud sync
class GameRecord {
  String? cloudId;
  final String sessionId;
  final DateTime startTime;
  DateTime? endTime;
  final List<MoveRecord> moves;
  final List<ChatRecord> chatHistory;
  final List<EmotionRecord> emotionLog;
  final List<ConversationRound> conversationRounds;
  final String initialEmotion;
  String? result; // 'white_wins', 'black_wins', 'draw', 'incomplete'
  final int? movesCount;

  GameRecord({
    this.cloudId,
    required this.sessionId,
    required this.startTime,
    this.endTime,
    List<MoveRecord>? moves,
    List<ChatRecord>? chatHistory,
    List<EmotionRecord>? emotionLog,
    List<ConversationRound>? conversationRounds,
    required this.initialEmotion,
    this.result,
    this.movesCount,
  }) : moves = moves ?? [],
       chatHistory = chatHistory ?? [],
       emotionLog = emotionLog ?? [],
       conversationRounds = conversationRounds ?? [];

  void addMove(MoveRecord move) {
    moves.add(move);
  }

  void addChat(ChatRecord chat) {
    chatHistory.add(chat);
  }

  void addEmotion(EmotionRecord emotion) {
    emotionLog.add(emotion);
  }

  void setConversationRounds(List<ConversationRound> rounds) {
    conversationRounds
      ..clear()
      ..addAll(rounds);
  }

  void completeGame(String gameResult) {
    endTime = DateTime.now();
    result = gameResult;
  }

  Duration get duration {
    return (endTime ?? DateTime.now()).difference(startTime);
  }

  Map<String, dynamic> toJson() {
    return {
      if (cloudId != null) 'cloudId': cloudId,
      'sessionId': sessionId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'initialEmotion': initialEmotion,
      'result': result,
      'durationSeconds': duration.inSeconds,
      'moves': moves.map((m) => m.toJson()).toList(),
      'chatHistory': chatHistory.map((c) => c.toJson()).toList(),
      'emotionLog': emotionLog.map((e) => e.toJson()).toList(),
      'conversationRounds': conversationRounds.map((r) => r.toJson()).toList(),
      if (movesCount != null) 'movesCount': movesCount,
    };
  }

  factory GameRecord.fromJson(Map<String, dynamic> json) {
    return GameRecord(
      cloudId: json['cloudId'] as String?,
      sessionId: json['sessionId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime:
          json['endTime'] != null
              ? DateTime.parse(json['endTime'] as String)
              : null,
      initialEmotion: json['initialEmotion'] as String? ?? 'neutral',
      result: json['result'] as String?,
      movesCount:
          json['movesCount'] is int
              ? json['movesCount'] as int
              : int.tryParse('${json['movesCount']}'),
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
      conversationRounds:
          (json['conversationRounds'] as List<dynamic>?)
              ?.map(
                (r) => ConversationRound.fromJson(r as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class MoveRecord {
  final int moveNumber;
  final String san;
  final String player; // 'white' or 'black'
  final DateTime timestamp;
  final String? preFen;
  final String? postFen;

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

class ChatRecord {
  final DateTime timestamp;
  final String sender; // 'ai' or 'user'
  final String message;
  final String? userChoice;
  final String? aiResponse;
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

class EmotionRecord {
  final DateTime timestamp;
  final String emotion;
  final int? moveNumber;
  final String? trigger;

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

