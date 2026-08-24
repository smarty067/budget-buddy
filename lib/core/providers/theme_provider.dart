import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Provider for managing ThemeMode (Light, Dark, System).
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _loadTheme();
  }

  static const _boxName = 'settings_box';
  static const _key = 'theme_preference';

  Future<void> _loadTheme() async {
    try {
      final box = await Hive.openBox(_boxName);
      final savedTheme = box.get(_key) as String?;
      if (savedTheme == 'light') {
        state = ThemeMode.light;
      } else if (savedTheme == 'dark') {
        state = ThemeMode.dark;
      } else {
        state = ThemeMode.system;
      }
    } catch (_) {
      // fallback to system default
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final box = await Hive.openBox(_boxName);
      if (mode == ThemeMode.light) {
        await box.put(_key, 'light');
      } else if (mode == ThemeMode.dark) {
        await box.put(_key, 'dark');
      } else {
        await box.delete(_key);
      }
    } catch (_) {}
  }
}
