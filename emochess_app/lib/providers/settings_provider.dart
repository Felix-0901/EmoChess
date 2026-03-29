import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Settings provider for app configuration
class SettingsProvider extends ChangeNotifier {
  String _locale = 'en';
  bool _showMoveHints = true;

  String get locale => _locale;
  bool get showMoveHints => _showMoveHints;
  bool get isEnglish => _locale == 'en';
  bool get isChinese => _locale == 'zh';

  /// Load settings from storage
  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _locale = prefs.getString('locale') ?? 'en';
    _showMoveHints = prefs.getBool('showMoveHints') ?? true;
    notifyListeners();
  }

  /// Save settings to storage
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale', _locale);
    await prefs.setBool('showMoveHints', _showMoveHints);
  }

  /// Set locale
  void setLocale(String locale) {
    _locale = locale;
    _saveSettings();
    notifyListeners();
  }

  /// Toggle English/Chinese
  void toggleLanguage() {
    _locale = _locale == 'en' ? 'zh' : 'en';
    _saveSettings();
    notifyListeners();
  }

  /// Toggle move hints
  void toggleMoveHints() {
    _showMoveHints = !_showMoveHints;
    _saveSettings();
    notifyListeners();
  }
}
