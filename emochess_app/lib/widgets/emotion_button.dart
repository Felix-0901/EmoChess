import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/emotion_state.dart';
import '../providers/emotion_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Single emotion button widget
class EmotionButton extends StatelessWidget {
  final EmotionLevel emotion;
  final bool isSelected;
  final VoidCallback onTap;

  const EmotionButton({
    super.key,
    required this.emotion,
    required this.isSelected,
    required this.onTap,
  });

  Color get _color {
    switch (emotion) {
      case EmotionLevel.happy:
        return AppColors.emotionHappy;
      case EmotionLevel.neutral:
        return AppColors.emotionNeutral;
      case EmotionLevel.frustrated:
        return AppColors.emotionFrustrated;
    }
  }

  IconData get _icon {
    switch (emotion) {
      case EmotionLevel.happy:
        return Icons.sentiment_satisfied_alt_rounded;
      case EmotionLevel.neutral:
        return Icons.sentiment_neutral_rounded;
      case EmotionLevel.frustrated:
        return Icons.sentiment_dissatisfied_rounded;
    }
  }

  String _getLabel(AppLocalizations l10n) {
    switch (emotion) {
      case EmotionLevel.happy:
        return l10n.happy;
      case EmotionLevel.neutral:
        return l10n.neutral;
      case EmotionLevel.frustrated:
        return l10n.frustrated;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: isSelected
            ? AppTheme.clayDecoration(
                color: _color,
                borderRadius: 20,
                isPressed: true,
              )
            : BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border, width: 3),
              ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _icon,
              size: isSelected ? 48 : 40,
              color: isSelected ? Colors.white : _color,
            ),
            const SizedBox(height: 8),
            Text(
              _getLabel(l10n),
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: isSelected ? Colors.white : AppColors.textPrimary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Row of emotion buttons for selection
class EmotionSelector extends StatelessWidget {
  const EmotionSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EmotionProvider>(
      builder: (context, emotionProvider, _) {
        final currentEmotion = emotionProvider.currentState.level;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            EmotionButton(
              emotion: EmotionLevel.happy,
              isSelected: currentEmotion == EmotionLevel.happy,
              onTap: () => emotionProvider.setEmotion(EmotionLevel.happy),
            ),
            EmotionButton(
              emotion: EmotionLevel.neutral,
              isSelected: currentEmotion == EmotionLevel.neutral,
              onTap: () => emotionProvider.setEmotion(EmotionLevel.neutral),
            ),
            EmotionButton(
              emotion: EmotionLevel.frustrated,
              isSelected: currentEmotion == EmotionLevel.frustrated,
              onTap: () => emotionProvider.setEmotion(EmotionLevel.frustrated),
            ),
          ],
        );
      },
    );
  }
}

/// Small emotion indicator for game screen
class EmotionIndicator extends StatelessWidget {
  const EmotionIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<EmotionProvider>(
      builder: (context, emotionProvider, _) {
        final emotion = emotionProvider.currentState;

        Color color;
        IconData icon;

        switch (emotion.level) {
          case EmotionLevel.happy:
            color = AppColors.emotionHappy;
            icon = Icons.sentiment_satisfied_alt_rounded;
            break;
          case EmotionLevel.neutral:
            color = AppColors.emotionNeutral;
            icon = Icons.sentiment_neutral_rounded;
            break;
          case EmotionLevel.frustrated:
            color = AppColors.emotionFrustrated;
            icon = Icons.sentiment_dissatisfied_rounded;
            break;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: color),
              const SizedBox(width: 8),
              Text(
                emotion.getLocalizedText(context),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
