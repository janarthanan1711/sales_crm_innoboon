import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Holds the user's light/dark/system preference and persists it.
///
/// A [ChangeNotifier] rather than a bloc: the app root is the only listener,
/// and theme has no async states worth modelling. Registered as a singleton so
/// the header menu can flip it from anywhere without plumbing.
class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode initial = ThemeMode.system}) : _mode = initial;

  static const String _prefsKey = 'theme_mode';

  ThemeMode _mode;
  ThemeMode get mode => _mode;

  /// Reads the stored preference. Called during startup so the first frame is
  /// already in the right theme — setting it after the app builds would show a
  /// flash of light mode for anyone using dark.
  static Future<ThemeMode> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _decode(prefs.getString(_prefsKey));
    } catch (_) {
      // Storage being unavailable shouldn't stop the app from starting; the
      // system default is a perfectly good fallback.
      return ThemeMode.system;
    }
  }

  /// Seeds the mode from [load] at startup, before any listener exists — so it
  /// deliberately doesn't notify or write back what it just read.
  void hydrate(ThemeMode mode) => _mode = mode;

  Future<void> setMode(ThemeMode mode) async {
    if (mode == _mode) return;
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _encode(mode));
    } catch (_) {
      // The switch already took effect in memory — it just won't survive a
      // restart. Not worth surfacing an error over.
    }
  }

  /// Flips between light and dark. From [ThemeMode.system] it resolves against
  /// [platformIsDark] first, so the toggle always moves *away* from what the
  /// user is currently looking at rather than appearing to do nothing.
  Future<void> toggle({required bool platformIsDark}) {
    final effectiveIsDark = switch (_mode) {
      ThemeMode.dark => true,
      ThemeMode.light => false,
      ThemeMode.system => platformIsDark,
    };
    return setMode(effectiveIsDark ? ThemeMode.light : ThemeMode.dark);
  }

  static String _encode(ThemeMode mode) => switch (mode) {
    ThemeMode.dark => 'dark',
    ThemeMode.light => 'light',
    ThemeMode.system => 'system',
  };

  static ThemeMode _decode(String? raw) => switch (raw) {
    'dark' => ThemeMode.dark,
    'light' => ThemeMode.light,
    _ => ThemeMode.system,
  };
}
