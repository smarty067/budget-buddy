import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';

/// Provider tracking if onboarding is completed.
final onboardingCompletedProvider = StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier();
});

class OnboardingNotifier extends StateNotifier<bool> {
  OnboardingNotifier() : super(false) {
    _loadStatus();
  }

  static const _boxName = 'settings_box';
  static const _key = 'onboarding_completed';

  Future<void> _loadStatus() async {
    try {
      final box = await Hive.openBox(_boxName);
      state = box.get(_key, defaultValue: false) as bool;
    } catch (_) {
      state = false;
    }
  }

  Future<void> completeOnboarding() async {
    state = true;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_key, true);
    } catch (_) {}
  }

  Future<void> resetOnboarding() async {
    state = false;
    try {
      final box = await Hive.openBox(_boxName);
      await box.put(_key, false);
    } catch (_) {}
  }
}
