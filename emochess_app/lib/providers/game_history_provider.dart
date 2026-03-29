import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/game_session.dart';
import '../models/emotion_state.dart';

/// Provider for managing game history storage with Hive
class GameHistoryProvider extends ChangeNotifier {
  static const String _boxName = 'game_history';
  Box<Map>? _box;
  List<GameSession> _games = [];
  bool _isLoading = false;

  List<GameSession> get games => List.unmodifiable(_games);
  bool get isLoading => _isLoading;

  /// Initialize Hive and load games
  Future<void> initialize() async {
    if (_box != null) return;

    _isLoading = true;
    notifyListeners();

    try {
      await Hive.initFlutter();
      _box = await Hive.openBox<Map>(_boxName);
      await _loadGames();
    } catch (_) {
      // Initialization error handled silently
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load all games from storage
  Future<void> _loadGames() async {
    if (_box == null) return;

    _games = _box!.values.map((json) {
      return _gameSessionFromJson(Map<String, dynamic>.from(json));
    }).toList();

    // Sort by start time (newest first)
    _games.sort((a, b) => b.startTime.compareTo(a.startTime));
  }

  /// Save a completed game session
  Future<void> saveGame(GameSession game) async {
    if (_box == null) await initialize();

    await _box?.put(game.id, game.toJson());
    await _loadGames();
    notifyListeners();
  }

  /// Delete a game by ID
  Future<void> deleteGame(String id) async {
    if (_box == null) return;

    await _box?.delete(id);
    _games.removeWhere((g) => g.id == id);
    notifyListeners();
  }

  /// Clear all game history
  Future<void> clearAll() async {
    if (_box == null) return;

    await _box?.clear();
    _games.clear();
    notifyListeners();
  }

  /// Get a game by ID
  GameSession? getGame(String id) {
    try {
      return _games.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Convert JSON to GameSession
  GameSession _gameSessionFromJson(Map<String, dynamic> json) {
    return GameSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      emotionHistory: (json['emotionHistory'] as List?)
          ?.map((e) => _emotionStateFromJson(Map<String, dynamic>.from(e)))
          .toList(),
      moves: (json['moves'] as List?)
          ?.map((m) => _gameMoveFromJson(Map<String, dynamic>.from(m)))
          .toList(),
      behaviorEvents: (json['behaviorEvents'] as List?)
          ?.map((b) => _behaviorEventFromJson(Map<String, dynamic>.from(b)))
          .toList(),
      result: json['result'] != null
          ? GameResult.values.firstWhere((r) => r.name == json['result'])
          : null,
    );
  }

  EmotionState _emotionStateFromJson(Map<String, dynamic> json) {
    return EmotionState(
      level: EmotionLevel.values.firstWhere((l) => l.name == json['level']),
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String?,
      source: EmotionSource.values.firstWhere((s) => s.name == json['source']),
    );
  }

  GameMove _gameMoveFromJson(Map<String, dynamic> json) {
    return GameMove(
      from: json['from'] as String,
      to: json['to'] as String,
      piece: json['piece'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isUndo: json['isUndo'] as bool? ?? false,
      isCapture: json['isCapture'] as bool? ?? false,
      isAiMove: json['isAiMove'] as bool? ?? false,
    );
  }

  BehaviorEvent _behaviorEventFromJson(Map<String, dynamic> json) {
    return BehaviorEvent(
      trigger: BehaviorTrigger.values.firstWhere(
        (t) => t.name == json['trigger'],
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      count: json['count'] as int? ?? 0,
    );
  }
}
