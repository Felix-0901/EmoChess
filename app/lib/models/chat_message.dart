import '../models/companion_interaction.dart';

enum ChatSender { ai, user }

class ChatMessage {
  final String id;
  final ChatSender sender;
  final CompanionInteraction? interaction; // For AI messages
  final String? text; // For user responses
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.sender,
    this.interaction,
    this.text,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  // Helper for AI message
  factory ChatMessage.ai(CompanionInteraction interaction) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: ChatSender.ai,
      interaction: interaction,
    );
  }

  // Helper for user message
  factory ChatMessage.user(String text) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sender: ChatSender.user,
      text: text,
    );
  }
}
