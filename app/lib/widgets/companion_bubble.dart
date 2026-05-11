import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';
import '../models/companion_interaction.dart';
import 'companion_choice.dart';

/// AI Companion chat bubble widget
/// Displays supportive messages and interactive choices
class CompanionBubble extends StatelessWidget {
  final CompanionInteraction interaction;
  final VoidCallback? onDismiss;
  final Function(String, String)? onChoiceSelectedWithLabel;
  final bool showChoices;

  const CompanionBubble({
    super.key,
    required this.interaction,
    this.onDismiss,
    this.onChoiceSelectedWithLabel,
    this.showChoices = true,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message =
        interaction.text ??
        (interaction.messageKey != null
            ? l10n.get(interaction.messageKey!)
            : '');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Companion avatar (Icon)
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.primaryLight,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(Icons.face, color: AppColors.primary, size: 24),
            ),
          ),
          const SizedBox(width: 8),
          // Message bubble
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration:
                  AppTheme.clayDecoration(
                    color: AppColors.surface,
                    borderRadius: 16,
                  ).copyWith(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      topRight: Radius.circular(16),
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.chessBuddy,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),

                  // Show choices for interactive types
                  if (showChoices &&
                      interaction.type != CompanionInteractionType.message &&
                      onChoiceSelectedWithLabel != null) ...[
                    const SizedBox(height: 12),
                    CompanionChoices(
                      interaction: interaction,
                      onChoiceSelectedWithLabel: (id, label) {
                        onChoiceSelectedWithLabel?.call(id, label);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Dismiss button
          if (onDismiss != null &&
              interaction.type == CompanionInteractionType.message)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}
