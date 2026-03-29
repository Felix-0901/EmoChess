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
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _ScaleEmotionButton(
              icon: Icons.sentiment_satisfied_alt_rounded,
              label: l10n.happy,
              color: AppColors.success,
              onTap: () => context.read<EmotionProvider>().setEmotion(
                EmotionLevel.happy,
              ),
            ),
            const SizedBox(width: 16),
            _ScaleEmotionButton(
              icon: Icons.sentiment_neutral_rounded,
              label: l10n.neutral,
              color: AppColors.primary,
              onTap: () => context.read<EmotionProvider>().setEmotion(
                EmotionLevel.neutral,
              ),
            ),
            const SizedBox(width: 16),
            _ScaleEmotionButton(
              icon: Icons.sentiment_dissatisfied_rounded,
              label: l10n.frustrated,
              color: AppColors.emotionFrustrated,
              onTap: () => context.read<EmotionProvider>().setEmotion(
                EmotionLevel.frustrated,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ScaleEmotionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ScaleEmotionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color, width: 2),
            ),
            child: Center(child: Icon(icon, color: color, size: 32)),
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
