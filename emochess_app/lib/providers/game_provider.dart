import 'package:flutter/foundation.dart';
import 'package:chess/chess.dart' as chess_lib;
import '../services/analysis_service.dart';
import '../models/companion_interaction.dart';
import '../models/game_session.dart';
import '../models/emotion_state.dart';
import '../models/chat_message.dart';
import '../models/conversation_round.dart';
import '../models/ai_turn_context.dart';
import '../models/game_record.dart';
import '../services/simple_chess_ai.dart';

/// Game state provider for chess game management
class GameProvider extends ChangeNotifier {
  chess_lib.Chess _chess = chess_lib.Chess();
  GameSession? _currentSession;
  String? _selectedSquare;
  List<String> _legalMoves = [];
  final List<String> _moveHistory = [];

  // Services
  final SimpleChessAi _aiService = SimpleChessAi();
  final AnalysisService _analysisService = AnalysisService();

  // Game record for saving history
  GameRecord? _currentGameRecord;

  // Callback for interaction generation (to be set by UI)
  Function(CompanionInteraction)? onInteractionGenerated;
  // Callback to get recent chat history for AI context
  List<ChatMessage> Function()? getConversationContext;
  // Callback to get recent structured conversation rounds for AI context
  List<ConversationRound> Function()? getConversationRounds;

  // Callback for AI connection errors (triggers UI navigation)
  Function(String error)? onAiConnectionError;
  // Callback to check if user response is pending (locks board while waiting)
  bool Function()? isAwaitingUserResponse;

  bool _isAiEnabled = true;
  bool _isAiThinking = false;
  bool _isAnalyzing = false;
  bool _isTerminated = false;
  int _aiDifficulty = 2; // Depth 2 is good for default
  _PendingAiMove? _pendingAiMove;

  // ... (Behavior tracking fields unchanged) ...

  // ... (getters) ...
  bool get isAnalyzing => _isAnalyzing;
  bool get isTerminated => _isTerminated;

  // ... (isAiEnabled etc getters unchanged) ...

  // ... (initializeAi, setAiDifficulty, toggleAi, startNewGame, selectSquare methods unchanged) ...

  // ... (_getLegalMovesFrom, _makeMove methods unchanged until _analyzeAndProcessAiMove call) ...

  /// Generate an immediate emotion check-in interaction
  CompanionInteraction createEmotionCheckin(EmotionLevel level) {
    return _analysisService.createEmotionCheckin(level);
  }

  /// Analyze player's move and then make AI move
  Future<void> _analyzeAndProcessAiMove(
    String from,
    String to,
    bool isCapture,
    bool isCheck,
    String? pieceType,
    String? capturedPieceType,
    String preFen, // FEN before the move
    String moveSan, // SAN for the move
    _PendingAiMove? pendingAiMove,
  ) async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      // 1. Trigger Analysis with FULL context per user spec
      final interaction = await _analysisService.analyzeMove(
        preFen: preFen,
        postFen: _chess.fen,
        moveSan: moveSan,
        isCheck: isCheck,
        isCapture: isCapture,
        moveNumber: _moveHistory.length,
        opponentPreFen: pendingAiMove?.preFen,
        opponentPostFen: pendingAiMove?.postFen,
        opponentMoveSan: pendingAiMove?.san,
        opponentIsCheck: pendingAiMove?.isCheck,
        opponentIsCapture: pendingAiMove?.isCapture,
        pieceMovedType: pieceType,
        capturedPieceType: capturedPieceType,
        opponentPieceMovedType: pendingAiMove?.pieceMovedType,
        opponentCapturedPieceType: pendingAiMove?.capturedPieceType,
        recentMessages: getConversationContext?.call(),
        recentRounds: getConversationRounds?.call(),
      );

      if (interaction != null) {
        onInteractionGenerated?.call(interaction);
        // CRITICAL: We STOP here and wait for user interaction to complete.
        // The UI (EmotionProvider) will call proceedWithAiMove() when done.
        return;
      }
    } catch (e) {
      // Trigger error screen
      onAiConnectionError?.call(e.toString());
      _isTerminated = true;
      _isAiEnabled = false;
      _isAiThinking = false;
      // We do NOT proceed with AI move if analysis failed, per user request to stop game.
      // But we should stop the analyzing spinner
      _isAnalyzing = false;
      notifyListeners();
      return;
    } finally {
      if (_isAnalyzing) {
        _isAnalyzing = false;
        notifyListeners();
      }
    }

    // If no interaction was generated (rare), proceed immediately
    proceedWithAiMove();
  }

  /// Trigger AI move manually (called after interaction completes)
  void proceedWithAiMove() {
    _tryProceedWithAiMove();
  }

  void _tryProceedWithAiMove() {
    if (_isTerminated || !_isAiEnabled || _chess.game_over) return;
    if (_isAiThinking) return;
    if (_isAnalyzing) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _tryProceedWithAiMove();
      });
      return;
    }
    _makeAiMove();
  }

  // Behavior tracking
  DateTime? _lastMoveTime;
  int _recentUndoCount = 0;
  DateTime? _lastUndoTime;

  chess_lib.Chess get chess => _chess;
  GameSession? get currentSession => _currentSession;
  String? get selectedSquare => _selectedSquare;
  List<String> get legalMoves => _legalMoves;
  List<String> get moveHistory => _moveHistory;
  bool get isGameOver => _chess.game_over;
  bool get isCheck => _chess.in_check;
  bool get isCheckmate => _chess.in_checkmate;
  bool get isDraw => _chess.in_draw;
  String get turn => _chess.turn == chess_lib.Color.WHITE ? 'white' : 'black';

  // AI properties
  bool get isAiEnabled => _isAiEnabled;
  bool get isAiThinking => _isAiThinking;
  int get aiDifficulty => _aiDifficulty;
  bool get isPlayerTurn => _chess.turn == chess_lib.Color.WHITE;

  /// Initialize AI service (no-op for pure Dart AI)
  Future<void> initializeAi() async {
    // No initialization needed for SimpleChessAi
  }

  /// Set AI difficulty level (Depth 1-4)
  void setAiDifficulty(int level) {
    _aiDifficulty = level.clamp(1, 4);
    notifyListeners();
  }

  /// Set language for AI responses
  void setLanguage(String locale) {
    _analysisService.setLanguage(locale);
  }

  /// Update current player emotion for AI context
  void setPlayerEmotion(EmotionLevel emotion) {
    _analysisService.setPlayerEmotion(emotion);
  }

  /// Toggle AI opponent
  void toggleAi(bool enabled) {
    _isAiEnabled = enabled;
    notifyListeners();
  }

  /// Start a new game with initial emotion
  void startNewGame({String initialEmotion = 'neutral'}) {
    _chess = chess_lib.Chess();
    _currentSession = GameSession.create();
    _selectedSquare = null;
    _legalMoves = [];
    _moveHistory.clear();
    _lastMoveTime = DateTime.now();
    _recentUndoCount = 0;
    _isAiThinking = false;
    _isAiEnabled = true;
    _isTerminated = false;

    // Create new game record for history
    _currentGameRecord = GameRecord(
      sessionId: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      initialEmotion: initialEmotion,
    );
    recordEmotion(initialEmotion, trigger: 'initial');

    notifyListeners();
  }

  /// Record a move in game history
  void recordMove(String san, String player, String preFen, String postFen) {
    if (_currentGameRecord != null) {
      _currentGameRecord!.addMove(
        MoveRecord(
          moveNumber: _moveHistory.length,
          san: san,
          player: player,
          timestamp: DateTime.now(),
          preFen: preFen,
          postFen: postFen,
        ),
      );
    }
  }

  /// Record a chat message in game history
  void recordChat({
    required String sender,
    required String message,
    String? userChoice,
    String? aiResponse,
    int? moveNumber,
    String? whitePreFen,
    String? whitePostFen,
    String? blackPostFen,
    String? roundId,
  }) {
    if (_currentGameRecord != null) {
      _currentGameRecord!.addChat(
        ChatRecord(
          timestamp: DateTime.now(),
          sender: sender,
          message: message,
          userChoice: userChoice,
          aiResponse: aiResponse,
          moveNumber: moveNumber,
          whitePreFen: whitePreFen,
          whitePostFen: whitePostFen,
          blackPostFen: blackPostFen,
          roundId: roundId,
        ),
      );
    }
  }

  void recordChatWithContext({
    required String sender,
    required String message,
    String? userChoice,
    String? aiResponse,
    String? roundId,
    AiTurnContext? turnContext,
  }) {
    recordChat(
      sender: sender,
      message: message,
      userChoice: userChoice,
      aiResponse: aiResponse,
      moveNumber: turnContext?.moveNumber ?? _moveHistory.length,
      whitePreFen: turnContext?.preFen,
      whitePostFen: turnContext?.postFen,
      blackPostFen: turnContext?.opponentPostFen,
      roundId: roundId,
    );
  }

  /// Record an emotion change in game history
  void recordEmotion(String emotion, {String? trigger}) {
    if (_currentGameRecord != null) {
      _currentGameRecord!.addEmotion(
        EmotionRecord(
          timestamp: DateTime.now(),
          emotion: emotion,
          moveNumber: _moveHistory.length,
          trigger: trigger,
        ),
      );
    }
  }

  void completeCurrentGameRecord(String result) {
    if (_currentGameRecord == null) return;
    final rounds = getConversationRounds?.call();
    if (rounds != null) {
      _currentGameRecord!.setConversationRounds(rounds);
    }
    _currentGameRecord!.completeGame(_normalizeResult(result));
  }

  String _normalizeResult(String result) {
    switch (result) {
      case 'win':
        return 'white_wins';
      case 'loss':
        return 'black_wins';
      case 'draw':
        return 'draw';
      case 'abandoned':
        return 'incomplete';
      default:
        return result;
    }
  }

  /// Get current game record
  GameRecord? get currentGameRecord => _currentGameRecord;

  /// Select a square
  void selectSquare(String square) {
    if (_isTerminated) return;
    // Don't allow selection when AI is thinking or it's AI's turn
    if (_isAiThinking) return;
    if (_isAnalyzing) return;
    if (_isAiEnabled && !isPlayerTurn) return;
    if (isAwaitingUserResponse?.call() == true) return;

    // If we already have a selection and tapping a legal move, make the move
    if (_selectedSquare != null && _legalMoves.contains(square)) {
      _makeMove(_selectedSquare!, square);
      return;
    }

    // Check if the square has a piece of the current player
    final piece = _chess.get(square);
    if (piece != null && piece.color == _chess.turn) {
      // Only allow player to select white pieces when AI is enabled
      if (_isAiEnabled && piece.color != chess_lib.Color.WHITE) {
        return;
      }
      _selectedSquare = square;
      _legalMoves = _getLegalMovesFrom(square);
      notifyListeners();
    } else {
      // Deselect
      _selectedSquare = null;
      _legalMoves = [];
      notifyListeners();
    }
  }

  /// Get legal moves from a square
  List<String> _getLegalMovesFrom(String from) {
    final moves = _chess.moves({'square': from, 'verbose': true});
    return moves.map((m) => m['to'] as String).toList();
  }

  String _getLastSan(String fallback) {
    try {
      final sanMoves = _chess.san_moves();
      if (sanMoves.isNotEmpty) {
        final last = sanMoves.last;
        if (last != null && last.trim().isNotEmpty) {
          return last.trim();
        }
      }
    } catch (_) {
      // Ignore and use fallback
    }
    return fallback;
  }

  /// Make a move
  Future<void> _makeMove(String from, String to) async {
    if (_isTerminated) return;
    // Get info about the target square before the move
    final targetPiece = _chess.get(to);
    final isCapture = targetPiece != null;
    final movingPiece = _chess.get(from);

    // Capture FEN BEFORE the move (per user spec)
    final preFen = _chess.fen;

    final moveResult = _chess.move({'from': from, 'to': to});

    if (moveResult) {
      final now = DateTime.now();

      // Record the move
      _currentSession?.addMove(
        GameMove(
          from: from,
          to: to,
          piece: movingPiece?.type.toString(),
          timestamp: now,
          isCapture: isCapture,
        ),
      );

      // Track move timing for behavior detection
      if (_lastMoveTime != null) {
        final timeSinceLastMove = now.difference(_lastMoveTime!);
        // Check for rapid moves (potential frustration indicator)
        if (timeSinceLastMove.inSeconds < 2 && _moveHistory.length >= 5) {
          final startIndex = _moveHistory.length > 5
              ? _moveHistory.length - 5
              : 0;
          final recentMoves = _moveHistory.sublist(startIndex);
          final rapidMoves = recentMoves.length;
          if (rapidMoves >= 5) {
            _currentSession?.addBehaviorEvent(
              BehaviorEvent(
                trigger: BehaviorTrigger.rapidRandomMoves,
                timestamp: now,
                count: rapidMoves,
              ),
            );
          }
        }
      }

      _lastMoveTime = now;
      _moveHistory.add('$from-$to');
      final moveSan = _getLastSan('$from-$to');
      recordMove(
        moveSan,
        movingPiece?.color == chess_lib.Color.WHITE ? 'white' : 'black',
        preFen,
        _chess.fen,
      );
      _selectedSquare = null;
      _legalMoves = [];
      notifyListeners();

      // Trigger Analysis and AI move
      if (!_chess.game_over && !isPlayerTurn) {
        _isAiThinking = true;
        notifyListeners();
        final pending = await _computePendingAiMove();
        _pendingAiMove = pending;
        _isAiThinking = false;
        notifyListeners();

        _analyzeAndProcessAiMove(
          from,
          to,
          isCapture,
          isCheck,
          movingPiece?.type.toString(),
          targetPiece?.type.toString(),
          preFen,
          moveSan,
          pending,
        );
      }
    }
  }

  /// Make AI move
  Future<void> _makeAiMove() async {
    if (_isTerminated) return;
    if (_isAiThinking || _chess.game_over) return;

    _isAiThinking = true;
    notifyListeners();

    try {
      // Add a small delay for better UX
      await Future.delayed(const Duration(milliseconds: 500));

      if (_pendingAiMove != null) {
        _applyPendingAiMove(_pendingAiMove!);
        _pendingAiMove = null;
        return;
      }

      final pending = await _computePendingAiMove();
      if (pending != null) {
        _applyPendingAiMove(pending);
      }
    } catch (_) {
    } finally {
      _isAiThinking = false;
      notifyListeners();
    }
  }

  Future<_PendingAiMove?> _computePendingAiMove() async {
    if (_chess.game_over) return null;
    final preFen = _chess.fen;
    final clone = chess_lib.Chess.fromFEN(preFen);

    String? uciMove = await _aiService.getBestMove(
      preFen,
      depth: _aiDifficulty,
    );
    if (uciMove == null) {
      final moves = clone.moves({'verbose': true});
      if (moves.isNotEmpty) {
        final randomMove = (moves..shuffle()).first;
        uciMove = '${randomMove['from']}${randomMove['to']}';
        if (randomMove['promotion'] != null) {
          uciMove = '$uciMove${randomMove['promotion']}';
        }
      }
    }
    if (uciMove == null) return null;

    final from = uciMove.substring(0, 2);
    final to = uciMove.substring(2, 4);
    final promotion = uciMove.length > 4 ? uciMove.substring(4) : null;

    final targetPiece = clone.get(to);
    final movingPiece = clone.get(from);
    final isCapture = targetPiece != null;

    final moveMap = {'from': from, 'to': to};
    if (promotion != null) moveMap['promotion'] = promotion;

    final moveResult = clone.move(moveMap);
    if (!moveResult) return null;

    final postFen = clone.fen;
    final san = _getLastSanFrom(clone, '$from-$to');
    final isCheck = clone.in_check;

    return _PendingAiMove(
      from: from,
      to: to,
      promotion: promotion,
      preFen: preFen,
      postFen: postFen,
      san: san,
      isCapture: isCapture,
      isCheck: isCheck,
      pieceMovedType: movingPiece?.type.toString(),
      capturedPieceType: targetPiece?.type.toString(),
    );
  }

  void _applyPendingAiMove(_PendingAiMove pending) {
    final moveMap = {'from': pending.from, 'to': pending.to};
    if (pending.promotion != null) {
      moveMap['promotion'] = pending.promotion!;
    }
    final moveResult = _chess.move(moveMap);
    if (!moveResult) return;

    final now = DateTime.now();
    final piece = _chess.get(pending.to);
    _currentSession?.addMove(
      GameMove(
        from: pending.from,
        to: pending.to,
        piece: piece?.type.toString(),
        timestamp: now,
        isCapture: pending.isCapture,
        isAiMove: true,
      ),
    );
    _moveHistory.add('${pending.from}-${pending.to}');
    recordMove(pending.san, 'black', pending.preFen, pending.postFen);
  }

  String _getLastSanFrom(chess_lib.Chess chess, String fallback) {
    try {
      final sanMoves = chess.san_moves();
      if (sanMoves.isNotEmpty) {
        final last = sanMoves.last;
        if (last != null && last.trim().isNotEmpty) {
          return last.trim();
        }
      }
    } catch (_) {}
    return fallback;
  }

  /// Undo last move (undoes AI move too if applicable)
  bool undo() {
    // Undo AI move first if it was the last move
    if (_isAiEnabled && isPlayerTurn && _moveHistory.isNotEmpty) {
      final result1 = _chess.undo();
      if (result1 != null && _moveHistory.isNotEmpty) {
        _moveHistory.removeLast();
        // Now undo player's move
        final result2 = _chess.undo();
        if (result2 != null && _moveHistory.isNotEmpty) {
          _moveHistory.removeLast();
        }
      }
      _selectedSquare = null;
      _legalMoves = [];
      notifyListeners();
      return true;
    }

    final result = _chess.undo();
    if (result != null) {
      final now = DateTime.now();

      // Track undo for behavior detection
      if (_lastUndoTime != null &&
          now.difference(_lastUndoTime!).inSeconds < 30) {
        _recentUndoCount++;
      } else {
        _recentUndoCount = 1;
      }
      _lastUndoTime = now;

      // Check for rapid undos (frustration indicator)
      if (_recentUndoCount > 3) {
        _currentSession?.addBehaviorEvent(
          BehaviorEvent(
            trigger: BehaviorTrigger.rapidUndos,
            timestamp: now,
            count: _recentUndoCount,
          ),
        );
      }

      _currentSession?.addMove(
        GameMove(
          from: result['to'] as String,
          to: result['from'] as String,
          piece: result['piece']?.toString(),
          timestamp: now,
          isUndo: true,
        ),
      );

      if (_moveHistory.isNotEmpty) {
        _moveHistory.removeLast();
      }
      _selectedSquare = null;
      _legalMoves = [];
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Get piece at square
  String? getPieceAt(String square) {
    final piece = _chess.get(square);
    if (piece == null) return null;

    final color = piece.color == chess_lib.Color.WHITE ? 'w' : 'b';
    final type = piece.type.toString().toUpperCase();
    return '$color$type';
  }

  /// Check for long pause (should be called periodically)
  bool checkForLongPause() {
    if (_lastMoveTime == null) return false;
    final pauseDuration = DateTime.now().difference(_lastMoveTime!);
    if (pauseDuration.inSeconds > 60) {
      _currentSession?.addBehaviorEvent(
        BehaviorEvent(
          trigger: BehaviorTrigger.longPause,
          timestamp: DateTime.now(),
        ),
      );
      return true;
    }
    return false;
  }

  /// End the game and return the session for saving
  GameSession? endGame(GameResult result, {EmotionState? postEmotion}) {
    _currentSession?.endGame(result: result, postEmotion: postEmotion);
    _isAiThinking = false;
    notifyListeners();
    return _currentSession;
  }

  /// Clear selection
  void clearSelection() {
    _selectedSquare = null;
    _legalMoves = [];
    notifyListeners();
  }

  /// Dispose AI service
  @override
  void dispose() {
    _aiService.dispose();
    super.dispose();
  }
}

class _PendingAiMove {
  final String from;
  final String to;
  final String? promotion;
  final String preFen;
  final String postFen;
  final String san;
  final bool isCapture;
  final bool isCheck;
  final String? pieceMovedType;
  final String? capturedPieceType;

  _PendingAiMove({
    required this.from,
    required this.to,
    this.promotion,
    required this.preFen,
    required this.postFen,
    required this.san,
    required this.isCapture,
    required this.isCheck,
    this.pieceMovedType,
    this.capturedPieceType,
  });
}
