import 'dart:math';
import 'package:chess/chess.dart' as chess_lib;

/// A pure Dart Chess AI using Minimax algorithm with Alpha-Beta pruning
class SimpleChessAi {
  static const int _lostScore = -10000;

  // Piece values for evaluation
  // Using final instead of const because PieceType overrides ==
  static final Map<chess_lib.PieceType, int> _pieceValues = {
    chess_lib.PieceType.PAWN: 100,
    chess_lib.PieceType.KNIGHT: 320,
    chess_lib.PieceType.BISHOP: 330,
    chess_lib.PieceType.ROOK: 500,
    chess_lib.PieceType.QUEEN: 900,
    chess_lib.PieceType.KING: 20000,
  };

  /// Get the best move for the current position
  /// [fen] The current board state in FEN format
  /// [depth] Search depth (1-3 recommended for mobile)
  Future<String?> getBestMove(String fen, {int depth = 3}) async {
    // Run in a separate isolate or just async to not block UI too much
    return Future(() {
      final chess = chess_lib.Chess.fromFEN(fen);
      if (chess.game_over) return null;

      final moves = chess.moves({'verbose': true});
      if (moves.isEmpty) return null;

      // Randomly shuffle moves to vary play
      moves.shuffle();

      String? bestMove;
      int bestValue = -99999;
      int alpha = -99999;
      int beta = 99999;

      for (final move in moves) {
        chess.move(move);
        final val = -_minimax(chess, depth - 1, -beta, -alpha);
        chess.undo();

        if (val > bestValue) {
          bestValue = val;
          bestMove = '${move['from']}${move['to']}';
          if (move['promotion'] != null) {
            bestMove = '$bestMove${move['promotion']}';
          }
        }
        alpha = max(alpha, val);
      }

      return bestMove;
    });
  }

  /// Minimax algorithm with Alpha-Beta pruning
  int _minimax(chess_lib.Chess chess, int depth, int alpha, int beta) {
    if (depth == 0 || chess.game_over) {
      return _evaluateBoard(chess);
    }

    final moves = chess.moves({'verbose': true});
    if (moves.isEmpty) {
      return _evaluateBoard(chess);
    }

    int bestValue = -99999;

    for (final move in moves) {
      chess.move(move);
      final val = -_minimax(chess, depth - 1, -beta, -alpha);
      chess.undo();

      bestValue = max(bestValue, val);
      alpha = max(alpha, val);

      if (alpha >= beta) {
        break; // Pruning
      }
    }

    return bestValue;
  }

  /// Simple static evaluation of the board
  /// Returns score from the perspective of the player whose turn it is
  int _evaluateBoard(chess_lib.Chess chess) {
    if (chess.in_checkmate) {
      return _lostScore;
    }
    if (chess.in_draw || chess.in_stalemate || chess.in_threefold_repetition) {
      return 0;
    }

    int totalEvaluation = 0;

    // Use internal board representation if possible, or parse board state
    // chess.board is List<Piece?>
    final board = chess.board;

    // Iterate over 0x88 board representation (size 128)
    for (int i = 0; i < 128; i++) {
      if ((i & 0x88) != 0) continue;

      final piece = board[i];
      if (piece != null) {
        final value = _pieceValues[piece.type] ?? 0;

        // Add score if it's our piece, subtract if enemy
        // Note: score is relative to the player whose turn it is
        if (piece.color == chess.turn) {
          totalEvaluation += value;
        } else {
          totalEvaluation -= value;
        }
      }
    }

    return totalEvaluation;
  }

  /// Dispose (no-op)
  void dispose() {}
}
