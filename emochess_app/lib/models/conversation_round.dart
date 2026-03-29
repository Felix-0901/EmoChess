class ConversationRound {
  final String roundId;
  final String aiQuestion;
  final List<String> choices;
  final String selectedChoice;
  final String aiReply;
  final DateTime timestamp;

  const ConversationRound({
    required this.roundId,
    required this.aiQuestion,
    required this.choices,
    required this.selectedChoice,
    required this.aiReply,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'roundId': roundId,
      'aiQuestion': aiQuestion,
      'choices': choices,
      'selectedChoice': selectedChoice,
      'aiReply': aiReply,
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
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}
