import 'package:flutter/foundation.dart';
import '../services/game_history_service.dart';

/// Provider for GameRecord (JSON) analysis data
class GameRecordProvider extends ChangeNotifier {
  final GameHistoryService _historyService = GameHistoryService();
  bool _isLoading = false;
  List<GameRecord> _records = [];

  bool get isLoading => _isLoading;
  List<GameRecord> get records => List.unmodifiable(_records);

  Future<void> initialize() async {
    if (_records.isNotEmpty) return;
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    _records = await _historyService.loadAllGameRecords();
    _isLoading = false;
    notifyListeners();
  }

  GameRecord? getRecord(String sessionId) {
    try {
      return _records.firstWhere((r) => r.sessionId == sessionId);
    } catch (_) {
      return null;
    }
  }

  Future<void> deleteRecord(String sessionId) async {
    final success = await _historyService.deleteGameRecord(sessionId);
    if (success) {
      _records.removeWhere((r) => r.sessionId == sessionId);
      notifyListeners();
    }
  }
}
