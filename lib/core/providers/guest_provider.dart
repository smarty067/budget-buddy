import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Manages local guest mode — backed by Hive so the session persists across
/// app restarts. When in guest mode, data lives purely in local Hive boxes
/// and no Supabase operations are attempted.
final guestModeProvider =
    StateNotifierProvider<GuestModeNotifier, bool>((ref) {
  return GuestModeNotifier();
});

class GuestModeNotifier extends StateNotifier<bool> {
  GuestModeNotifier() : super(false) {
    _loadGuestMode();
  }

  static const _boxName = 'settings_box';
  static const _key = 'guest_mode';

  Future<void> _loadGuestMode() async {
    try {
      final box = await Hive.openBox(_boxName);
      state = box.get(_key, defaultValue: false) as bool;
    } catch (_) {
      state = false;
    }
  }

  /// Activate guest mode — persist the flag and set state.
  Future<void> enableGuestMode() async {
    state = true;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_key, true);
    } catch (_) {}
  }

  /// Deactivate guest mode and clear all local guest data boxes.
  Future<void> disableGuestMode() async {
    state = false;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_key, false);

      // Clear all guest data boxes
      await _clearBox('guest_transactions');
      await _clearBox('guest_budgets');
      await _clearBox('guest_goals');
    } catch (_) {}
  }

  Future<void> _clearBox(String boxName) async {
    try {
      final box = await Hive.openBox(boxName);
      await box.clear();
    } catch (_) {}
  }
}
