import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../providers/emotion_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/game_record_provider.dart';
import '../providers/auth_provider.dart';
import '../models/game_session.dart';
import '../models/chat_message.dart';
import '../models/ai_turn_context.dart';
import '../services/game_cloud_service.dart';
import '../widgets/chat_area.dart';
import '../widgets/chess_board.dart';
import '../widgets/interaction_area.dart';
import '../widgets/game_over_dialog.dart';
import '../theme/app_colors.dart';
import '../l10n/app_localizations.dart';

/// Main chess game screen with emotion companion
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _gameOverDialogShown = false;
  final GameCloudService _cloudService = GameCloudService();

  @override
  void initState() {
    super.initState();
    // Initialize AI and start a new game when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final gameProvider = context.read<GameProvider>();
      final emotionProvider = context.read<EmotionProvider>();
      final settingsProvider = context.read<SettingsProvider>();

      // Set language for AI responses
      gameProvider.setLanguage(settingsProvider.locale);
      emotionProvider.setLanguage(settingsProvider.locale);

      gameProvider.onInteractionGenerated = (interaction) {
        emotionProvider.setInteraction(interaction);
      };

      // bridge EmotionProvider completion to GameProvider move
      emotionProvider.onInteractionCompleted = () {
        gameProvider.proceedWithAiMove();
      };

      // Provide recent chat context to AI
      gameProvider.getConversationContext = () => emotionProvider.chatHistory;
      gameProvider.getConversationRounds = () =>
          emotionProvider.conversationRounds;
      gameProvider.isAwaitingUserResponse = () =>
          emotionProvider.isAwaitingResponse || emotionProvider.isResponding;

      // Log chat messages to game record
      emotionProvider.onChatLogged = (
        ChatSender sender,
        String message, {
        String? userChoice,
        String? aiResponse,
        String? roundId,
        AiTurnContext? turnContext,
      }) {
        gameProvider.recordChatWithContext(
          sender: sender == ChatSender.ai ? 'ai' : 'user',
          message: message,
          userChoice: userChoice,
          aiResponse: aiResponse,
          roundId: roundId,
          turnContext: turnContext,
        );
      };

      // Log emotion changes to game record
      emotionProvider.onEmotionLogged = (level, source) {
        gameProvider.recordEmotion(level.name, trigger: source.name);
      };

      // Handle AI Connection Errors
      gameProvider.onAiConnectionError = (errorMsg) {
        // Navigate to AI Error Screen using GoRouter
        context.go('/ai-error?msg=${Uri.encodeComponent(errorMsg)}');
      };

      // NOTE: Emotion changes are now SILENT per user spec.
      // The updated emotion will affect the NEXT API call (after user's next move).
      // No immediate AI chat is triggered when emotion changes.
      emotionProvider.onEmotionChanged = (level) {
        gameProvider.setPlayerEmotion(level);
      };

      gameProvider.initializeAi();

      // Reset emotion and chat history for a fresh game
      final initialEmotion = emotionProvider.currentLevel;
      emotionProvider.reset(initialEmotion: initialEmotion);

      gameProvider.startNewGame(initialEmotion: initialEmotion.name);
      gameProvider.setPlayerEmotion(initialEmotion);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.emoChess),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => _showExitConfirmation(context),
        ),
        actions: [
          // Undo button
          Consumer<GameProvider>(
            builder: (context, game, _) {
              return IconButton(
                icon: const Icon(Icons.undo_rounded),
                onPressed: game.moveHistory.isNotEmpty
                    ? () => game.undo()
                    : null,
                tooltip: l10n.undoMove,
              );
            },
          ),
          // Analysis button
          IconButton(
            icon: const Icon(Icons.analytics_outlined),
            onPressed: () => context.push('/analysis'),
            tooltip: l10n.get('emotionAnalysis'),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Area (Replaces Emotion Indicator)
            Expanded(flex: 3, child: const ChatArea()),

            // Chess board
            Expanded(
              flex: 4,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const ChessBoard(),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Game status - also handles game over detection
            Consumer<GameProvider>(
              builder: (context, game, _) {
                // Check for game over and show dialog
                if (game.isGameOver && !_gameOverDialogShown) {
                  _gameOverDialogShown = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _showGameOverDialog(context, game);
                  });
                }
                return _buildGameStatus(context, game, l10n);
              },
            ),

            const SizedBox(height: 8),

            // Interactive Bottom Area (Purely for emotion recording now)
            const InteractionArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStatus(
    BuildContext context,
    GameProvider game,
    AppLocalizations l10n,
  ) {
    String statusText;
    Color statusColor;

    if (game.isCheckmate) {
      statusText = game.turn == 'white' ? l10n.blackWins : l10n.whiteWins;
      statusColor = AppColors.success;
    } else if (game.isDraw) {
      statusText = l10n.draw;
      statusColor = AppColors.textSecondary;
    } else if (game.isCheck) {
      statusText = l10n.check;
      statusColor = AppColors.emotionFrustrated;
    } else if (game.isAnalyzing) {
      statusText = l10n.get('analyzing');
      statusColor = AppColors.primary;
    } else if (game.isAiThinking) {
      statusText = l10n.get('aiThinking');
      statusColor = AppColors.primary;
    } else {
      statusText = game.turn == 'white' ? l10n.whiteTurn : l10n.blackTurn;
      statusColor = AppColors.textPrimary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: game.turn == 'white'
                  ? Colors.white
                  : AppColors.textPrimary,
              border: Border.all(color: AppColors.border, width: 2),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              statusText,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(color: statusColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          l10n.leaveGame,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        content: Text(
          l10n.leaveGameMessage,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.stay, style: TextStyle(color: AppColors.primary)),
          ),
          ElevatedButton(
            onPressed: () async {
              final gameProvider = context.read<GameProvider>();
              final recordProvider = context.read<GameRecordProvider>();
              final authProvider = context.read<AuthProvider>();
              gameProvider.endGame(GameResult.abandoned);
              gameProvider.completeCurrentGameRecord(GameResult.abandoned.name);
              await _uploadCurrentGame(context, gameProvider, authProvider);
              await recordProvider.refresh();
              if (!context.mounted) return;
              Navigator.pop(context);
              context.go('/');
            },
            child: Text(l10n.leave),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog(BuildContext context, GameProvider game) {
    // Determine result
    GameOverResult result;
    if (game.isCheckmate) {
      // Player plays white, so if it's white's turn and checkmate, player lost
      result = game.turn == 'white'
          ? GameOverResult.playerLose
          : GameOverResult.playerWin;
    } else {
      result = GameOverResult.draw;
    }

    // Save game to history
    final recordProvider = context.read<GameRecordProvider>();
    final authProvider = context.read<AuthProvider>();
    final gameResult = result == GameOverResult.playerWin
        ? GameResult.win
        : (result == GameOverResult.playerLose
              ? GameResult.loss
              : GameResult.draw);
    game.endGame(gameResult);
    Future(() async {
      try {
        game.completeCurrentGameRecord(gameResult.name);
        await _uploadCurrentGame(context, game, authProvider);
        await recordProvider.refresh();
      } catch (_) {}
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => GameOverDialog(
        result: result,
        onGoHome: () {
          Navigator.pop(context);
          context.go('/');
        },
        onViewAnalysis: () {
          Navigator.pop(context);
          Future(() async {
            await _syncBeforeNavigate(context, game, authProvider, recordProvider);
            if (!context.mounted) return;
            context.go('/analysis');
          });
        },
        onPlayAgain: () {
          Navigator.pop(context);
          _gameOverDialogShown = false;
          final gameProvider = context.read<GameProvider>();
          final emotionProvider = context.read<EmotionProvider>();
          gameProvider.startNewGame();
          emotionProvider.reset();
        },
      ),
    );
  }

  Future<void> _syncBeforeNavigate(
    BuildContext context,
    GameProvider gameProvider,
    AuthProvider authProvider,
    GameRecordProvider recordProvider,
  ) async {
    final l10n = AppLocalizations.of(context);
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
                Expanded(child: Text(l10n.get('analyzing'))),
              ],
            ),
          ),
    );
    try {
      await _uploadCurrentGame(context, gameProvider, authProvider);
      await recordProvider.refresh();
    } finally {
      if (!context.mounted) return;
      Navigator.of(context).pop();
    }
  }

  Future<void> _uploadCurrentGame(
    BuildContext context,
    GameProvider gameProvider,
    AuthProvider authProvider,
  ) async {
    final l10n = AppLocalizations.of(context);
    final record = gameProvider.currentGameRecord;
    if (record == null) return;
    if (record.cloudId != null && record.cloudId!.trim().isNotEmpty) return;

    final cloudId = await _cloudService.uploadGameRecord(record);
    if (cloudId == null || cloudId.trim().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.get('gameSyncFailed'))),
      );
      return;
    }

    record.cloudId = cloudId.trim();
    await authProvider.fetchProfile();
  }
}
