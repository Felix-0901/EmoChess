import 'emotion_state.dart';

class AiTurnContext {
  final String preFen;
  final String postFen;
  final String moveSan;
  final String? opponentPreFen;
  final String? opponentPostFen;
  final String? opponentMoveSan;
  final int moveNumber;
  final bool isCheck;
  final bool isCapture;
  final bool? opponentIsCheck;
  final bool? opponentIsCapture;
  final String? pieceMovedType;
  final String? capturedPieceType;
  final String? opponentPieceMovedType;
  final String? opponentCapturedPieceType;
  final String playerColor; // 'white'
  final EmotionLevel emotionLevel;
  final String language;
  final DateTime timestamp;

  const AiTurnContext({
    required this.preFen,
    required this.postFen,
    required this.moveSan,
    this.opponentPreFen,
    this.opponentPostFen,
    this.opponentMoveSan,
    required this.moveNumber,
    required this.isCheck,
    required this.isCapture,
    this.opponentIsCheck,
    this.opponentIsCapture,
    this.pieceMovedType,
    this.capturedPieceType,
    this.opponentPieceMovedType,
    this.opponentCapturedPieceType,
    this.playerColor = 'white',
    required this.emotionLevel,
    required this.language,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'preFen': preFen,
    'postFen': postFen,
    'moveSan': moveSan,
    if (opponentPreFen != null) 'opponentPreFen': opponentPreFen,
    if (opponentPostFen != null) 'opponentPostFen': opponentPostFen,
    if (opponentMoveSan != null) 'opponentMoveSan': opponentMoveSan,
    'moveNumber': moveNumber,
    'isCheck': isCheck,
    'isCapture': isCapture,
    if (opponentIsCheck != null) 'opponentIsCheck': opponentIsCheck,
    if (opponentIsCapture != null) 'opponentIsCapture': opponentIsCapture,
    if (pieceMovedType != null) 'pieceMovedType': pieceMovedType,
    if (capturedPieceType != null) 'capturedPieceType': capturedPieceType,
    if (opponentPieceMovedType != null)
      'opponentPieceMovedType': opponentPieceMovedType,
    if (opponentCapturedPieceType != null)
      'opponentCapturedPieceType': opponentCapturedPieceType,
    'playerColor': playerColor,
    'emotionLevel': emotionLevel.name,
    'language': language,
    'timestamp': timestamp.toIso8601String(),
  };
}
