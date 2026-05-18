import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';
import '../theme/app_colors.dart';

/// Chess board widget with Claymorphism design
/// High contrast, low stimulation for ASD children
class ChessBoard extends StatelessWidget {
  const ChessBoard({super.key});

  static const List<String> _files = ['a', 'b', 'c', 'd', 'e', 'f', 'g', 'h'];
  static const List<String> _ranks = ['8', '7', '6', '5', '4', '3', '2', '1'];

  @override
  Widget build(BuildContext context) {
    return Consumer<GameProvider>(
      builder: (context, game, _) {
        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border, width: 4),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowDark,
                  offset: const Offset(6, 6),
                  blurRadius: 0,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
              ),
              itemCount: 64,
              itemBuilder: (context, index) {
                final file = index % 8;
                final rank = index ~/ 8;
                final square = '${_files[file]}${_ranks[rank]}';
                final isLight = (file + rank) % 2 == 0;
                final isSelected = game.selectedSquare == square;
                final isLegalMove = game.legalMoves.contains(square);
                final piece = game.getPieceAt(square);

                return _ChessSquare(
                  square: square,
                  isLight: isLight,
                  isSelected: isSelected,
                  isLegalMove: isLegalMove,
                  piece: piece,
                  onTap: () => game.selectSquare(square),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _ChessSquare extends StatelessWidget {
  final String square;
  final bool isLight;
  final bool isSelected;
  final bool isLegalMove;
  final String? piece;
  final VoidCallback onTap;

  const _ChessSquare({
    required this.square,
    required this.isLight,
    required this.isSelected,
    required this.isLegalMove,
    required this.piece,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor = isLight
        ? AppColors.boardLight
        : AppColors.boardDark;

    if (isSelected) {
      backgroundColor = AppColors.moveHighlight.withValues(alpha: 0.7);
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Legal move indicator
            if (isLegalMove)
              Center(
                child: Container(
                  width: piece != null ? 32 : 16,
                  height: piece != null ? 32 : 16,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: piece != null
                        ? AppColors.captureHighlight.withValues(alpha: 0.5)
                        : AppColors.moveHighlight.withValues(alpha: 0.6),
                    border: piece != null
                        ? Border.all(
                            color: AppColors.captureHighlight,
                            width: 3,
                          )
                        : null,
                  ),
                ),
              ),
            // Chess piece
            if (piece != null) Center(child: _ChessPiece(piece: piece!)),
          ],
        ),
      ),
    );
  }
}

class _ChessPiece extends StatelessWidget {
  final String piece;

  const _ChessPiece({required this.piece});

  @override
  Widget build(BuildContext context) {
    final isWhite = piece.startsWith('w');
    final pieceType = piece.substring(1).toLowerCase();
    final pieceUnicode = _getPieceUnicode(pieceType, isWhite: isWhite);
    final tokenColor = isWhite ? Colors.white : const Color(0xFF111827);
    final outlineColor = isWhite ? const Color(0xFF0F172A) : Colors.white;

    return FractionallySizedBox(
      widthFactor: 0.82,
      heightFactor: 0.82,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: tokenColor,
          border: Border.all(color: outlineColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              offset: const Offset(1, 2),
              blurRadius: 3,
            ),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  pieceUnicode,
                  style: TextStyle(
                    fontSize: 36,
                    height: 1,
                    fontFamily: 'serif',
                    foreground: Paint()
                      ..style = PaintingStyle.stroke
                      ..strokeWidth = 1.8
                      ..color = outlineColor,
                  ),
                ),
                Text(
                  pieceUnicode,
                  style: TextStyle(
                    fontSize: 36,
                    height: 1,
                    fontFamily: 'serif',
                    color: tokenColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPieceUnicode(String type, {required bool isWhite}) {
    const vs = '\uFE0E'; // Variation selector for text rendering
    final whitePieces = {
      'k': '\u2654$vs', // ♔
      'q': '\u2655$vs', // ♕
      'r': '\u2656$vs', // ♖
      'b': '\u2657$vs', // ♗
      'n': '\u2658$vs', // ♘
      'p': '\u2659$vs', // ♙
    };
    final blackPieces = {
      'k': '\u265A$vs', // ♚
      'q': '\u265B$vs', // ♛
      'r': '\u265C$vs', // ♜
      'b': '\u265D$vs', // ♝
      'n': '\u265E$vs', // ♞
      'p': '\u265F$vs', // ♟
    };
    final pieces = isWhite ? whitePieces : blackPieces;
    return pieces[type] ?? '?';
  }
}
