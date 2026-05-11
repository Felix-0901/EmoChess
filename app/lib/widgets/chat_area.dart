import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emotion_provider.dart';
import '../models/chat_message.dart';
import 'companion_bubble.dart';
import 'user_bubble.dart';

class ChatArea extends StatefulWidget {
  const ChatArea({super.key});

  @override
  State<ChatArea> createState() => _ChatAreaState();
}

class _ChatAreaState extends State<ChatArea> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto-scroll on new messages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<EmotionProvider>(
      builder: (context, provider, child) {
        final messages = provider.chatHistory;

        // Auto-scroll when list changes
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return Container(
          color: Colors.transparent, // Or a subtle chat background
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];

              if (message.sender == ChatSender.ai) {
                // For the LAST message, if it's AI, show choices if available
                final isLast = index == messages.length - 1;
                final canRespond =
                    provider.isAwaitingResponse && !provider.isResponding;

                return CompanionBubble(
                  interaction: message.interaction!,
                  showChoices: isLast && canRespond,
                  onChoiceSelectedWithLabel: canRespond
                      ? (id, label) {
                          provider.onChoiceResponse(id, label);
                        }
                      : null,
                );
              } else {
                return UserBubble(text: message.text ?? '');
              }
            },
          ),
        );
      },
    );
  }
}
