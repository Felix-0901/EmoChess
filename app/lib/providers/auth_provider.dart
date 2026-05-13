import 'package:flutter/material.dart';
import '../services/auth_service.dart';

/// Auth state provider with XP/Level/Stats
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  bool _isLoading = false;
  bool _isLoggedIn = false;
  Map<String, dynamic>? _user;
  String? _errorKey;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  bool get isLoggedIn => _isLoggedIn;
  Map<String, dynamic>? get user => _user;
  String? get errorKey => _errorKey;
  String? get errorMessage => _errorMessage;

  // ─── 基本資訊 ─────────────────────────────
  String get displayName => _user?['displayName'] as String? ?? '';
  String get email => _user?['email'] as String? ?? '';

  // ─── XP / 等級 ────────────────────────────
  int get totalXp => _user?['totalXp'] as int? ?? 0;
  int get level => _user?['level'] as int? ?? 1;
  int get gamesPlayed => _user?['gamesPlayed'] as int? ?? 0;
  int get gamesWon => _user?['gamesWon'] as int? ?? 0;
  int get winRate => _user?['winRate'] as int? ?? 0;

  // levelProgress 來自後端
  Map<String, dynamic>? get levelProgress =>
      _user?['levelProgress'] as Map<String, dynamic>?;

  Map<String, dynamic>? get equippedTitle =>
      (_user?['equippedTitle'] as Map?)?.cast<String, dynamic>();

  List<Map<String, dynamic>> get titles =>
      (_user?['titles'] as List?)
          ?.whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList() ??
      const [];

  int get xpInCurrentLevel => levelProgress?['xpInCurrentLevel'] as int? ?? 0;
  int get xpNeededForNextLevel =>
      levelProgress?['xpNeededForNextLevel'] as int? ?? 100;
  double get xpProgress =>
      (levelProgress?['progress'] as num?)?.toDouble() ?? 0.0;

  /// 初始化：檢查是否已登入
  Future<void> initialize() async {
    _isLoading = true;
    _isLoggedIn = false;
    _user = null;
    notifyListeners();

    try {
      await Future.wait<void>([
        _restoreSavedSession(),
        Future<void>.delayed(const Duration(milliseconds: 850)),
      ]);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _restoreSavedSession() async {
    final hasToken = await _authService.isLoggedIn();
    if (!hasToken) return;

    final savedUser = await _authService.getSavedUser();
    _user = savedUser ?? await _authService.getProfile();
    _isLoggedIn = _user != null;
  }

  /// 從後台抓取最新個人資料
  Future<void> fetchProfile() async {
    final profile = await _authService.getProfile();
    if (profile != null) {
      _user = profile;
      notifyListeners();
    }
  }

  /// 註冊
  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _isLoading = true;
    _errorKey = null;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.register(
      email: email,
      password: password,
      displayName: displayName,
    );

    _isLoading = false;

    if (result.isSuccess) {
      _user = result.user;
      _isLoggedIn = true;
      _errorKey = null;
      _errorMessage = null;
    } else {
      _errorKey = result.errorKey;
      _errorMessage = result.errorMessage;
    }

    notifyListeners();
    return result.isSuccess;
  }

  /// 登入
  Future<bool> login({required String email, required String password}) async {
    _isLoading = true;
    _errorKey = null;
    _errorMessage = null;
    notifyListeners();

    final result = await _authService.login(email: email, password: password);

    _isLoading = false;

    if (result.isSuccess) {
      _user = result.user;
      _isLoggedIn = true;
      _errorKey = null;
      _errorMessage = null;
    } else {
      _errorKey = result.errorKey;
      _errorMessage = result.errorMessage;
    }

    notifyListeners();
    return result.isSuccess;
  }

  /// 登出
  Future<void> logout() async {
    await _authService.logout();
    _user = null;
    _isLoggedIn = false;
    _errorKey = null;
    _errorMessage = null;
    notifyListeners();
  }

  /// 清除錯誤訊息
  void clearError() {
    _errorKey = null;
    _errorMessage = null;
    notifyListeners();
  }
}
