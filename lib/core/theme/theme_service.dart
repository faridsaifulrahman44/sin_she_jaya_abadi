import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages theme mode persistence across app sessions.
class ThemeService {
  static const String _key = 'app_theme_mode';

  /// Returns the persisted [ThemeMode], defaulting to [ThemeMode.light].
  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_key);
    switch (value) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.light;
    }
  }

  /// Persists the given [ThemeMode].
  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, mode.name);
  }

  /// Returns the display label for the current mode.
  static String label(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.system:
        return 'System';
    }
  }

  /// Cycles to the next mode: light -> dark -> light.
  static ThemeMode next(ThemeMode current) {
    return current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
  }
}

/// A simple [ChangeNotifier] that wraps [ThemeService] for use in
/// [ChangeNotifierProvider] / [InheritedNotifier].
class ThemeNotifier extends ChangeNotifier {
  ThemeMode _mode = ThemeMode.light;

  ThemeMode get mode => _mode;

  ThemeNotifier() {
    _load();
  }

  Future<void> _load() async {
    _mode = await ThemeService.getThemeMode();
    notifyListeners();
  }

  Future<void> toggle() async {
    _mode = ThemeService.next(_mode);
    await ThemeService.setThemeMode(_mode);
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    await ThemeService.setThemeMode(mode);
    notifyListeners();
  }
}
