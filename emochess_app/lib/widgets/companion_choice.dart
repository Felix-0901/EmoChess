import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../models/companion_interaction.dart';

/// Choice button widget for companion interactions
/// Displays multiple choice or yes/no options
class CompanionChoices extends StatelessWidget {
  final CompanionInteraction interaction;
  final Function(String)? onChoiceSelected;
  final Function(String, String)? onChoiceSelectedWithLabel;

  const CompanionChoices({
    super.key,
    required this.interaction,
    this.onChoiceSelected,
    this.onChoiceSelectedWithLabel,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (interaction.type == CompanionInteractionType.yesNo) {
      return _buildYesNoButtons(context, l10n);
    } else if (interaction.type == CompanionInteractionType.multiChoice) {
      return _buildMultiChoiceButtons(context, l10n);
    }
    return const SizedBox.shrink();
  }

  void _handleSelect(String id, String label) {
    onChoiceSelected?.call(id);
    onChoiceSelectedWithLabel?.call(id, label);
  }

  Widget _buildYesNoButtons(BuildContext context, AppLocalizations l10n) {
    final yesLabel = l10n.get(interaction.yesKey ?? 'yes');
    final noLabel = l10n.get(interaction.noKey ?? 'no');

    return Row(
      children: [
        Expanded(
          child: _ChoiceButton(
            label: yesLabel,
            icon: Icons.check_circle_outline,
            color: AppColors.success,
            onTap: () => _handleSelect('yes', yesLabel),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _ChoiceButton(
            label: noLabel,
            icon: Icons.cancel_outlined,
            color: AppColors.primary,
            onTap: () => _handleSelect('no', noLabel),
          ),
        ),
      ],
    );
  }

  Widget _buildMultiChoiceButtons(BuildContext context, AppLocalizations l10n) {
    final choices = interaction.choices ?? [];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: choices.map((choice) {
        final label =
            choice.label ??
            (choice.labelKey != null ? l10n.get(choice.labelKey!) : '');
        return _ChoiceButton(
          label: label,
          // We map emoji string to Icon for now since we are moving away from Emojis
          // In future, CompanionChoice model should have IconData? icon property
          icon: _mapEmojiToIcon(choice.emoji),
          color: _getChoiceColor(choice.actionId),
          onTap: () => _handleSelect(choice.actionId, label),
        );
      }).toList(),
    );
  }

  IconData _mapEmojiToIcon(String? emoji) {
    // Temporary mapping until model update
    if (emoji == '⚔️') return Icons.sports_kabaddi;
    if (emoji == '🎯') return Icons.track_changes;
    if (emoji == '♟️') return Icons.extension;
    if (emoji == '😊') return Icons.sentiment_satisfied;
    if (emoji == '😐') return Icons.sentiment_neutral;
    if (emoji == '😓') return Icons.sentiment_dissatisfied;
    if (emoji == '🙋') return Icons.live_help;
    return Icons.circle_outlined;
  }

  Color _getChoiceColor(String actionId) {
    switch (actionId) {
      case 'great':
      case 'attack':
        return AppColors.success;
      case 'okay':
      case 'control':
        return AppColors.primary;
      case 'hard':
      case 'develop':
        return AppColors.emotionNeutral;
      case 'help':
        return AppColors.emotionFrustrated;
      default:
        return AppColors.primary;
    }
  }
}

class _ChoiceButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.label,
    this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color, width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 6),
            ],
            Flexible(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
