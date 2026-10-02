import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import '../services/session_service.dart';

/// Manages local guest mode — backed by Hive so the session persists reliably across
/// app restarts. When in guest mode, data lives purely in local Hive boxes.
final guestModeProvider =
    StateNotifierProvider<GuestModeNotifier, bool>((ref) {
  return GuestModeNotifier();
});

class GuestModeNotifier extends StateNotifier<bool> {
  GuestModeNotifier() : super(_initialGuestState()) {
    _loadGuestMode();
  }

  static const _boxName = 'settings_box';
  static const _key = 'guest_mode';

  static bool _initialGuestState() {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        return Hive.box(_boxName).get(_key, defaultValue: false) as bool;
      }
    } catch (_) {}
    return false;
  }

  Future<void> _loadGuestMode() async {
    try {
      final box = Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      state = box.get(_key, defaultValue: false) as bool;
      if (state) {
        SessionService.recordActivity();
      }
    } catch (_) {
      // Retain synchronous initial state
    }
  }

  /// Activate guest mode — persist the flag, record session, and update state.
  Future<void> enableGuestMode() async {
    state = true;
    try {
      final box = Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      await box.put(_key, true);
      await SessionService.recordLogin(isGuest: true);
    } catch (_) {}
  }

  /// Deactivate guest mode and clear local session.
  Future<void> disableGuestMode() async {
    state = false;
    try {
      final box = Hive.isBoxOpen(_boxName)
          ? Hive.box(_boxName)
          : await Hive.openBox(_boxName);
      await box.put(_key, false);

      await SessionService.forceLogout();

      // Clear all guest data boxes
      await _clearBox('guest_transactions');
      await _clearBox('guest_budgets');
      await _clearBox('guest_goals');
      await _clearBox('local_calculations');
      await _clearBox('local_investments');
    } catch (_) {}
  }

  Future<void> _clearBox(String boxName) async {
    try {
      final box = Hive.isBoxOpen(boxName)
          ? Hive.box(boxName)
          : await Hive.openBox(boxName);
      await box.clear();
    } catch (_) {}
  }
}
