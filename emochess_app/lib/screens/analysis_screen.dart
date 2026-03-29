import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/game_record_provider.dart';
import '../services/game_history_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

/// Emotion Analysis Screen - replaces Breathing Exercise
/// Shows game history and allows analysis of past games
class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<GameRecordProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('emotionAnalysis')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Consumer<GameRecordProvider>(
          builder: (context, historyProvider, _) {
            if (historyProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (historyProvider.records.isEmpty) {
              return _buildEmptyState(context, l10n);
            }

            return _buildGameList(context, historyProvider.records, l10n);
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: AppTheme.clayDecoration(
              color: AppColors.primaryLight,
              borderRadius: 60,
            ),
            child: const Center(
              child: Text('📊', style: TextStyle(fontSize: 56)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.get('noGamesYet'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.get('playFirstGame'),
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/emotion-checkin'),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l10n.playChess),
          ),
        ],
      ),
    );
  }

  Widget _buildGameList(
    BuildContext context,
    List<GameRecord> games,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            l10n.get('gameHistory'),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: games.length,
            itemBuilder: (context, index) {
              final game = games[index];
              return _GameHistoryCard(
                game: game,
                l10n: l10n,
                onTap: () => context.go('/analysis/${game.sessionId}'),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _GameHistoryCard extends StatelessWidget {
  final GameRecord game;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _GameHistoryCard({
    required this.game,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resultText = _resultLabel(game.result, l10n);
    final resultColor = game.result == 'win'
        ? AppColors.success
        : (game.result == 'loss' ? AppColors.emotionFrustrated : AppColors.primary);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: AppTheme.clayDecoration(
          color: AppColors.surface,
          borderRadius: 16,
        ),
        child: Row(
          children: [
            // Date indicator
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primaryLight.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    game.startTime.day.toString(),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _getMonthAbbr(game.startTime.month),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Game info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: resultColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          resultText,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: resultColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDuration(game.duration),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.touch_app,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${game.moves.length} ${l10n.get('totalMoves')}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Arrow
            Icon(Icons.chevron_right, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  String _getMonthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _resultLabel(String? result, AppLocalizations l10n) {
    switch (result) {
      case 'win':
        return l10n.get('resultWin');
      case 'loss':
        return l10n.get('resultLoss');
      case 'draw':
        return l10n.get('resultDraw');
      case 'abandoned':
        return l10n.get('resultAbandoned');
      default:
        return l10n.get('resultUnknown');
    }
  }
}
