import 'package:flutter/foundation.dart';
import '../services/game_cloud_service.dart';
import '../models/game_record.dart';

/// Provider for GameRecord (JSON) analysis data
class GameRecordProvider extends ChangeNotifier {
  final GameCloudService _cloudService = GameCloudService();
  bool _isLoading = false;
  List<GameRecord> _records = [];

  bool get isLoading => _isLoading;
  List<GameRecord> get records => List.unmodifiable(_records);

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    final cloud = await _cloudService.fetchGameList(limit: 100);
    _records =
        cloud
            .where((r) => (r.cloudId ?? '').trim().isNotEmpty)
            .toList()
          ..sort((a, b) => b.startTime.compareTo(a.startTime));
    _isLoading = false;
    notifyListeners();
  }

  String recordKey(GameRecord record) => record.cloudId ?? record.sessionId;

  GameRecord? getRecord(String id) {
    try {
      return _records.firstWhere((r) => r.cloudId == id || r.sessionId == id);
    } catch (_) {
      return null;
    }
  }

  Future<GameRecord?> ensureRecordLoaded(String id) async {
    final current = getRecord(id);
    if (current == null) {
      final direct = await _cloudService.fetchGameDetail(id);
      if (direct == null) return null;
      _records = [direct, ..._records.where((r) => r.cloudId != direct.cloudId)];
      notifyListeners();
      return direct;
    }
    if (current.cloudId == null || current.cloudId!.trim().isEmpty) {
      return current;
    }
    if (current.moves.isNotEmpty ||
        current.chatHistory.isNotEmpty ||
        current.emotionLog.isNotEmpty) {
      return current;
    }
    final detail = await _cloudService.fetchGameDetail(current.cloudId!);
    if (detail == null) return current;
    final idx = _records.indexOf(current);
    if (idx >= 0) {
      _records[idx] = detail;
      notifyListeners();
    }
    return detail;
  }

  Future<void> deleteRecord(String id) async {
    final record = getRecord(id);
    if (record == null) return;

    if (record.cloudId != null) {
      final ok = await _cloudService.deleteGame(record.cloudId!);
      if (!ok) return;
    }
    _records.removeWhere((r) => r.cloudId == id || r.sessionId == id);
    notifyListeners();
  }
}
