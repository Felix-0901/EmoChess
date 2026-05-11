import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

enum GameOverResult { playerWin, playerLose, draw }

/// Dialog shown when the game ends
class GameOverDialog extends StatelessWidget {
  final GameOverResult result;
  final VoidCallback onGoHome;
  final VoidCallback onViewAnalysis;
  final VoidCallback onPlayAgain;

  const GameOverDialog({
    super.key,
    required this.result,
    required this.onGoHome,
    required this.onViewAnalysis,
    required this.onPlayAgain,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Result Icon
            _buildResultIcon(),

            const SizedBox(height: 24),

            // Result Title
            Text(
              _getResultTitle(l10n),
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getResultColor(),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Encouraging Message
            Text(
              _getEncouragingMessage(l10n),
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Column(
              children: [
                // Play Again Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onPlayAgain,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.get('playAgain')),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // View Analysis Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onViewAnalysis,
                    icon: const Icon(Icons.analytics_outlined),
                    label: Text(l10n.get('viewEmotionAnalysis')),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Go Home Button
                TextButton.icon(
                  onPressed: onGoHome,
                  icon: const Icon(Icons.home_rounded),
                  label: Text(l10n.get('returnHome')),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultIcon() {
    IconData icon;
    Color color;

    switch (result) {
      case GameOverResult.playerWin:
        icon = Icons.emoji_events_rounded;
        color = AppColors.success;
        break;
      case GameOverResult.playerLose:
        icon = Icons.sentiment_satisfied_rounded;
        color = AppColors.primary;
        break;
      case GameOverResult.draw:
        icon = Icons.handshake_rounded;
        color = AppColors.emotionNeutral;
        break;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 64, color: color),
    );
  }

  String _getResultTitle(AppLocalizations l10n) {
    switch (result) {
      case GameOverResult.playerWin:
        return l10n.get('youWin');
      case GameOverResult.playerLose:
        return l10n.get('gameOver');
      case GameOverResult.draw:
        return l10n.draw;
    }
  }

  String _getEncouragingMessage(AppLocalizations l10n) {
    switch (result) {
      case GameOverResult.playerWin:
        return l10n.get('congratsMessage');
      case GameOverResult.playerLose:
        return l10n.get('goodEffortMessage');
      case GameOverResult.draw:
        return l10n.get('drawMessage');
    }
  }

  Color _getResultColor() {
    switch (result) {
      case GameOverResult.playerWin:
        return AppColors.success;
      case GameOverResult.playerLose:
        return AppColors.primary;
      case GameOverResult.draw:
        return AppColors.emotionNeutral;
    }
  }
}
