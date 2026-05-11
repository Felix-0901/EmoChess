import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/game_record_provider.dart';
import '../providers/settings_provider.dart';
import '../services/report_service.dart';
import '../models/game_record.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../l10n/app_localizations.dart';

class AnalysisDetailScreen extends StatefulWidget {
  final String recordId;

  const AnalysisDetailScreen({super.key, required this.recordId});

  @override
  State<AnalysisDetailScreen> createState() => _AnalysisDetailScreenState();
}

class _AnalysisDetailScreenState extends State<AnalysisDetailScreen> {
  Future<GameRecord?>? _loadFuture;
  final ReportService _reportService = ReportService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _loadFuture = context
            .read<GameRecordProvider>()
            .ensureRecordLoaded(widget.recordId);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('emotionAnalysis')),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded),
            tooltip: l10n.get('aiReport'),
            onPressed: () => _onGenerateReport(context),
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (GoRouter.of(context).canPop()) {
              context.pop();
              return;
            }
            context.go('/analysis');
          },
        ),
      ),
      body: SafeArea(
        child: Consumer<GameRecordProvider>(
          builder: (context, provider, _) {
            final future = _loadFuture;
            if (provider.isLoading || future == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return FutureBuilder<GameRecord?>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final record =
                    snapshot.data ?? provider.getRecord(widget.recordId);
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
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: Container(
                          decoration: AppTheme.clayDecoration(
                            color: AppColors.error,
                            borderRadius: 16,
                            borderColor: AppColors.dangerBorder,
                            shadowDarkColor: AppColors.dangerShadowDark,
                            shadowLightColor: AppColors.dangerShadowLight,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => _onDeleteGame(context, record),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                  ),
                                  child: Center(
                                    child: Text(
                                      l10n.get('deleteGame'),
                                      style:
                                          Theme.of(context).textTheme.labelLarge,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _onGenerateReport(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final provider = context.read<GameRecordProvider>();
    final record = provider.getRecord(widget.recordId);
    final gameId = record?.cloudId;
    if (gameId == null || gameId.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('reportNeedsUpload'))),
      );
      return;
    }

    final lang = context.read<SettingsProvider>().locale;

    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => AlertDialog(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(child: Text(l10n.get('reportGenerating'))),
              ],
            ),
          ),
    );

    Map<String, dynamic>? report;
    String? errorText;
    try {
      report = await _reportService.generateGameReport(
        gameId: gameId,
        language: lang,
      );
    } on ReportServiceException catch (e) {
      report = null;
      errorText = kDebugMode ? e.toString() : e.message;
    } catch (_) {
      report = null;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop();

    if (report == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorText ?? l10n.get('reportFailed'))),
      );
      return;
    }

    if (!context.mounted) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final pretty = const JsonEncoder.withIndent('  ').convert(report);
        return SafeArea(
          child: SizedBox(
            height: MediaQuery.of(context).size.height * 0.85,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          l10n.get('aiReport'),
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          await Clipboard.setData(ClipboardData(text: pretty));
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(l10n.get('copied'))),
                          );
                        },
                        child: Text(l10n.get('copy')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(l10n.get('close')),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView(
                      children: [
                      _ReportSection(
                        title: l10n.get('reportSummaryTitle'),
                        child: Text(
                          (() {
                            final v =
                                (report?['analysis_report'] ?? report?['summary'])
                                    ?.toString()
                                    .trim();
                            if (v != null && v.isNotEmpty) return v;
                            return pretty;
                          })(),
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ReportSection(
                        title: l10n.get('reportEmotionOverviewTitle'),
                        child: Text(
                          (() {
                            final v = report?['emotion_overview']
                                ?.toString()
                                .trim();
                            if (v != null && v.isNotEmpty) return v;
                            return '';
                          })(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ReportSection(
                        title: l10n.get('reportRecommendationsTitle'),
                        child: Text(
                          (() {
                            final v = report?['recommendations']
                                ?.toString()
                                .trim();
                            if (v != null && v.isNotEmpty) return v;
                            return '';
                          })(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if ((report?['disclaimer']?.toString().trim() ?? '')
                          .isNotEmpty)
                        _ReportSection(
                          title: l10n.get('reportDisclaimerTitle'),
                          child: Text('${report?['disclaimer']}'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onDeleteGame(BuildContext context, GameRecord record) async {
    final l10n = AppLocalizations.of(context);
    final provider = context.read<GameRecordProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(l10n.get('deleteGameConfirmTitle')),
            content: Text(l10n.get('deleteGameConfirmMessage')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.get('cancel')),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: Text(l10n.get('delete')),
              ),
            ],
          ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => const Center(
            child: CircularProgressIndicator(),
          ),
    );

    final recordKey = provider.recordKey(record);
    await provider.deleteRecord(recordKey);

    if (!context.mounted) return;
    Navigator.of(context).pop();

    final stillExists = provider.getRecord(recordKey) != null;
    if (stillExists) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.get('deleteGameFailed'))));
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.get('deleteGameSuccess'))));
    if (GoRouter.of(context).canPop()) {
      context.pop();
      return;
    }
    context.go('/analysis');
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
      case 'anxious':
        return l10n.anxious;
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
      case 'white_wins':
        return l10n.get('resultWin');
      case 'loss':
      case 'black_wins':
        return l10n.get('resultLoss');
      case 'draw':
        return l10n.get('resultDraw');
      case 'abandoned':
      case 'incomplete':
        return l10n.get('resultAbandoned');
      default:
        return l10n.get('resultUnknown');
    }
  }
}

class _ReportSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _ReportSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
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
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
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
                              l10n.anxious,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          if (value == 2) {
                            return Text(
                              l10n.neutral,
                              style: const TextStyle(fontSize: 10),
                            );
                          }
                          if (value == 3) {
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
                  maxY: 3,
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
        return 3;
      case 'neutral':
        return 2;
      case 'anxious':
        return 1;
      case 'frustrated':
        return 0;
      default:
        return 2;
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
                              return Text(
                                l10n.frustrated,
                                style: const TextStyle(fontSize: 10),
                              );
                            case 1:
                              return Text(
                                l10n.anxious,
                                style: const TextStyle(fontSize: 10),
                              );
                            case 2:
                              return Text(
                                l10n.neutral,
                                style: const TextStyle(fontSize: 10),
                              );
                            case 3:
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
                          toY: counts['anxious']!.toDouble(),
                          color: AppColors.emotionAnxious,
                          width: 18,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 2,
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
                      x: 3,
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
    final counts = {'happy': 0, 'neutral': 0, 'anxious': 0, 'frustrated': 0};
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
      width: double.infinity,
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
      width: double.infinity,
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
