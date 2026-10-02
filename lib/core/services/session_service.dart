import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../supabase_client.dart';

/// Manages user session state and activity tracking.
///
/// Rules:
/// 1. User remains logged in across app restarts.
/// 2. User is ONLY automatically logged out if inactive for more than 30 days (1 month).
/// 3. Session state is pre-warmed synchronously from Hive before UI renders.
class SessionService {
  SessionService._();

  static const String sessionBoxName = 'session_box';
  static const String settingsBoxName = 'settings_box';

  static const String _keyLastActive = 'last_active_timestamp';
  static const String _keyIsLoggedIn = 'is_logged_in';
  static const String _keyAuthType = 'auth_type'; // 'supabase' or 'guest'
  static const String _keyGuestMode = 'guest_mode';

  static const int inactivityThresholdDays = 30; // 1 month

  /// Initializes session boxes on app startup.
  static Future<void> initialize() async {
    await Hive.openBox(sessionBoxName);
    await Hive.openBox(settingsBoxName);
    await Hive.openBox('local_calculations');
    await Hive.openBox('local_investments');
    await Hive.openBox('guest_transactions');
    await Hive.openBox('guest_budgets');
    await Hive.openBox('guest_goals');
  }

  /// Check if the session is still valid (within 30 days of inactivity).
  /// If expired (> 30 days inactive), clears session and returns false.
  /// If valid, updates last active time and returns true.
  static bool validateAndUpdateSession() {
    try {
      final sessionBox = Hive.box(sessionBoxName);
      final settingsBox = Hive.box(settingsBoxName);

      final isGuest = settingsBox.get(_keyGuestMode, defaultValue: false) as bool;
      final isSupabaseUser = SupabaseClientHelper.currentUser != null;
      final wasLoggedIn = sessionBox.get(_keyIsLoggedIn, defaultValue: false) as bool;

      if (!isGuest && !isSupabaseUser && !wasLoggedIn) {
        return false;
      }

      final lastActiveMillis = sessionBox.get(_keyLastActive) as int?;
      if (lastActiveMillis != null) {
        final lastActive = DateTime.fromMillisecondsSinceEpoch(lastActiveMillis);
        final inactiveDuration = DateTime.now().difference(lastActive);

        if (inactiveDuration.inDays >= inactivityThresholdDays) {
          debugPrint('[SessionService] User inactive for ${inactiveDuration.inDays} days (> $inactivityThresholdDays days). Logging out.');
          forceLogout();
          return false;
        }
      }

      // Session is valid - update last active timestamp
      recordActivity();
      return true;
    } catch (e) {
      debugPrint('[SessionService] Error validating session: $e');
      return true; // Keep logged in on read error
    }
  }

  /// Updates the last active timestamp to current time.
  static void recordActivity() {
    try {
      final sessionBox = Hive.box(sessionBoxName);
      sessionBox.put(_keyLastActive, DateTime.now().millisecondsSinceEpoch);
    } catch (_) {}
  }

  /// Record user login (either guest or Supabase).
  static Future<void> recordLogin({required bool isGuest}) async {
    try {
      final sessionBox = Hive.box(sessionBoxName);
      final settingsBox = Hive.box(settingsBoxName);

      await sessionBox.put(_keyIsLoggedIn, true);
      await sessionBox.put(_keyAuthType, isGuest ? 'guest' : 'supabase');
      await sessionBox.put(_keyLastActive, DateTime.now().millisecondsSinceEpoch);

      if (isGuest) {
        await settingsBox.put(_keyGuestMode, true);
      }
    } catch (e) {
      debugPrint('[SessionService] Error recording login: $e');
    }
  }

  /// Check whether user is logged in (guest mode or authenticated session).
  static bool get isLoggedIn {
    try {
      final sessionBox = Hive.box(sessionBoxName);
      final settingsBox = Hive.box(settingsBoxName);

      final isGuest = settingsBox.get(_keyGuestMode, defaultValue: false) as bool;
      final isSupabaseUser = SupabaseClientHelper.currentUser != null;
      final wasLoggedIn = sessionBox.get(_keyIsLoggedIn, defaultValue: false) as bool;

      return isGuest || isSupabaseUser || wasLoggedIn;
    } catch (_) {
      return SupabaseClientHelper.currentUser != null;
    }
  }

  /// Force logout when 30 days inactivity reached or user manually signs out.
  static Future<void> forceLogout() async {
    try {
      final sessionBox = Hive.box(sessionBoxName);
      final settingsBox = Hive.box(settingsBoxName);

      await sessionBox.put(_keyIsLoggedIn, false);
      await sessionBox.delete(_keyLastActive);
      await sessionBox.delete(_keyAuthType);
      await settingsBox.put(_keyGuestMode, false);

      if (SupabaseClientHelper.currentUser != null) {
        await SupabaseClientHelper.client.auth.signOut();
      }
    } catch (e) {
      debugPrint('[SessionService] Error logging out: $e');
    }
  }
}
