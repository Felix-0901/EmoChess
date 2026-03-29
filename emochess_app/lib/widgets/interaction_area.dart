import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/emotion_provider.dart';
import '../models/emotion_state.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

/// Interaction Area - Displays emotion recording buttons
/// Used for tracking player emotions during the game.
class InteractionArea extends StatelessWidget {
  const InteractionArea({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: _buildEmotionInput(context),
    );
  }

  /// Default state: "How do you feel?" + 3 buttons
  Widget _buildEmotionInput(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Consumer<EmotionProvider>(
      builder: (context, emotionProvider, _) {
        final current = emotionProvider.currentState;
        const emotions = <EmotionLevel>[
          EmotionLevel.happy,
          EmotionLevel.neutral,
          EmotionLevel.anxious,
          EmotionLevel.frustrated,
        ];

        return Column(
          mainAxisSize: MainAxisSize.min,
          key: const ValueKey('emotion_input'),
          children: [
            Text(
              l10n.howDoYouFeel,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${l10n.currentEmotion}${current.getLocalizedText(context)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final e in emotions)
                  _SelectableEmotionButton(
                    emotion: e,
                    isSelected: current.level == e,
                    onTap: () => emotionProvider.setEmotion(e),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _SelectableEmotionButton extends StatelessWidget {
  final EmotionLevel emotion;
  final bool isSelected;
  final VoidCallback onTap;

  const _SelectableEmotionButton({
    required this.emotion,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final state = EmotionState(level: emotion, timestamp: DateTime.now());
    final label = state.getLocalizedText(context);
    final icon = state.icon;
    Color color;
    switch (emotion) {
      case EmotionLevel.happy:
        color = AppColors.emotionHappy;
        break;
      case EmotionLevel.neutral:
        color = AppColors.emotionNeutral;
        break;
      case EmotionLevel.anxious:
        color = AppColors.emotionAnxious;
        break;
      case EmotionLevel.frustrated:
        color = AppColors.emotionFrustrated;
        break;
    }

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isSelected ? color : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(
              child: Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
