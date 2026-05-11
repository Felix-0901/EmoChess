class ConversationRound {
  final String roundId;
  final String aiQuestion;
  final List<String> choices;
  final String selectedChoice;
  final String aiReply;
  final int? moveNumber;
  final String? emotion;
  final String? trigger;
  final String? angleKey;
  final String? intent;
  final int? promptVersion;
  final DateTime timestamp;

  const ConversationRound({
    required this.roundId,
    required this.aiQuestion,
    required this.choices,
    required this.selectedChoice,
    required this.aiReply,
    this.moveNumber,
    this.emotion,
    this.trigger,
    this.angleKey,
    this.intent,
    this.promptVersion,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'roundId': roundId,
      'aiQuestion': aiQuestion,
      'choices': choices,
      'selectedChoice': selectedChoice,
      'aiReply': aiReply,
      if (moveNumber != null) 'moveNumber': moveNumber,
      if (emotion != null) 'emotion': emotion,
      if (trigger != null) 'trigger': trigger,
      if (angleKey != null) 'angleKey': angleKey,
      if (intent != null) 'intent': intent,
      if (promptVersion != null) 'promptVersion': promptVersion,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory ConversationRound.fromJson(Map<String, dynamic> json) {
    return ConversationRound(
      roundId: json['roundId'] as String,
      aiQuestion: json['aiQuestion'] as String? ?? '',
      choices:
          (json['choices'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      selectedChoice: json['selectedChoice'] as String? ?? '',
      aiReply: json['aiReply'] as String? ?? '',
      moveNumber:
          json['moveNumber'] is int
              ? json['moveNumber'] as int
              : int.tryParse('${json['moveNumber']}'),
      emotion: json['emotion'] as String?,
      trigger: json['trigger'] as String?,
      angleKey: json['angleKey'] as String?,
      intent: json['intent'] as String?,
      promptVersion:
          json['promptVersion'] is int
              ? json['promptVersion'] as int
              : int.tryParse('${json['promptVersion']}'),
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
