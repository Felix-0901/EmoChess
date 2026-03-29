import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/game_record_provider.dart';
import '../services/game_history_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class AnalysisDetailScreen extends StatelessWidget {
  final String recordId;

  const AnalysisDetailScreen({super.key, required this.recordId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('emotionAnalysis')),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go('/analysis'),
        ),
      ),
      body: SafeArea(
        child: Consumer<GameRecordProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final record = provider.getRecord(recordId);
            if (record == null) {
              return Center(
                child: Text(
                  l10n.get('analysisNotFound'),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryCard(record: record),
                  const SizedBox(height: 16),
                  _EmotionTrendCard(record: record),
                  const SizedBox(height: 16),
                  _EmotionDistributionCard(record: record),
                  const SizedBox(height: 16),
                  _ChatHistoryCard(record: record),
                  const SizedBox(height: 16),
                  _MoveHistoryCard(record: record),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final GameRecord record;
  const _SummaryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final initialEmotion = _emotionLabel(
      record.initialEmotion,
      l10n,
    );
    final lastEmotion = record.emotionLog.isNotEmpty
        ? _emotionLabel(record.emotionLog.last.emotion, l10n)
        : initialEmotion;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.clayDecoration(
        color: AppColors.surface,
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('analysisSummary'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          _InfoRow(
            label: l10n.get('gameDuration'),
            value: _formatDuration(record.duration),
          ),
          _InfoRow(
            label: l10n.get('totalMoves'),
            value: record.moves.length.toString(),
          ),
          _InfoRow(
            label: l10n.get('totalChats'),
            value: record.chatHistory.length.toString(),
          ),
          _InfoRow(
            label: l10n.get('emotionEvents'),
            value: record.emotionLog.length.toString(),
          ),
          _InfoRow(
            label: l10n.get('initialEmotion'),
            value: initialEmotion,
          ),
          _InfoRow(
            label: l10n.get('finalEmotion'),
            value: lastEmotion,
          ),
          _InfoRow(
            label: l10n.get('result'),
            value: _resultLabel(record.result, l10n),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _emotionLabel(String emotion, AppLocalizations l10n) {
    switch (emotion) {
      case 'happy':
        return l10n.happy;
      case 'frustrated':
        return l10n.frustrated;
      case 'neutral':
      default:
        return l10n.neutral;
    }
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

class _EmotionTrendCard extends StatelessWidget {
  final GameRecord record;
  const _EmotionTrendCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final spots = _buildSpots(record);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.clayDecoration(
        color: AppColors.surface,
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('emotionTrend'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (spots.isEmpty)
            Text(
              l10n.get('analysisNoEmotion'),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) {
                            return Text(
                              l10n.frustrated,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          if (value == 1) {
                            return Text(
                              l10n.neutral,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          if (value == 2) {
                            return Text(
                              l10n.happy,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      barWidth: 3,
                      color: AppColors.primary,
                      dotData: FlDotData(show: true),
                    ),
                  ],
                  minY: 0,
                  maxY: 2,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<FlSpot> _buildSpots(GameRecord record) {
    final spots = <FlSpot>[];
    for (int i = 0; i < record.emotionLog.length; i++) {
      final emotion = record.emotionLog[i].emotion;
      spots.add(FlSpot(i.toDouble(), _emotionValue(emotion).toDouble()));
    }
    return spots;
  }

  int _emotionValue(String emotion) {
    switch (emotion) {
      case 'happy':
        return 2;
      case 'frustrated':
        return 0;
      case 'neutral':
      default:
        return 1;
    }
  }
}

class _EmotionDistributionCard extends StatelessWidget {
  final GameRecord record;
  const _EmotionDistributionCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final counts = _emotionCounts(record);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.clayDecoration(
        color: AppColors.surface,
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('emotionDistribution'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (record.emotionLog.isEmpty)
            Text(
              l10n.get('analysisNoEmotion'),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          switch (value.toInt()) {
                            case 0:
                              return Text(l10n.frustrated);
                            case 1:
                              return Text(l10n.neutral);
                            case 2:
                              return Text(l10n.happy);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          toY: counts['frustrated']!.toDouble(),
                          color: AppColors.emotionFrustrated,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          toY: counts['neutral']!.toDouble(),
                          color: AppColors.emotionNeutral,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
                      barRods: [
                        BarChartRodData(
                          toY: counts['happy']!.toDouble(),
                          color: AppColors.emotionHappy,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Map<String, int> _emotionCounts(GameRecord record) {
    final counts = {'happy': 0, 'neutral': 0, 'frustrated': 0};
    for (final entry in record.emotionLog) {
      if (counts.containsKey(entry.emotion)) {
        counts[entry.emotion] = counts[entry.emotion]! + 1;
      }
    }
    return counts;
  }
}

class _ChatHistoryCard extends StatelessWidget {
  final GameRecord record;
  const _ChatHistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.clayDecoration(
        color: AppColors.surface,
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('chatHistory'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (record.chatHistory.isEmpty)
            Text(
              l10n.get('analysisNoChat'),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Column(
              children: record.chatHistory.map((chat) {
                final isAi = chat.sender == 'ai';
                return Align(
                  alignment: isAi
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: AppTheme.clayDecoration(
                      color: isAi
                          ? AppColors.surface
                          : AppColors.primaryLight,
                      borderRadius: 16,
                    ),
                    child: Text(
                      chat.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _MoveHistoryCard extends StatelessWidget {
  final GameRecord record;
  const _MoveHistoryCard({required this.record});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.clayDecoration(
        color: AppColors.surface,
        borderRadius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.get('moveHistory'),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          if (record.moves.isEmpty)
            Text(
              l10n.get('analysisNoMoves'),
              style: Theme.of(context).textTheme.bodyMedium,
            )
          else
            Column(
              children: record.moves.map((move) {
                final isWhite = move.player == 'white';
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: AppTheme.clayDecoration(
                    color: isWhite
                        ? AppColors.primaryLight.withValues(alpha: 0.4)
                        : AppColors.surface,
                    borderRadius: 16,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '#${move.moveNumber}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          move.san,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      Text(
                        isWhite ? 'W' : 'B',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
