import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';


import '../../core/providers/guest_provider.dart';
import '../../core/providers/onboarding_provider.dart';
import '../../core/supabase_client.dart';
import '../../features/onboarding/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/dashboard/dashboard_shell.dart';

/// Converts a [Stream] into a [ChangeNotifier] so GoRouter can listen for
/// refresh signals without recreating the entire router instance.
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    notifyListeners(); // fire once on creation so initial redirect runs
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  /// Public wrapper so external code can trigger a route refresh
  /// without accessing the protected [notifyListeners] directly.
  void refresh() => notifyListeners();

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

/// Provider that exposes the GoRouter configuration.
/// The router is created ONCE and uses [refreshListenable] to react to
/// auth state changes — this avoids the old bug where the entire GoRouter
/// was recreated on every auth event, losing navigation state.
final routerProvider = Provider<GoRouter>((ref) {
  final onboardingCompleted = ref.watch(onboardingCompletedProvider);

  // Create a refresh notifier from the Supabase auth stream.
  // GoRouter will re-evaluate its redirect whenever this fires.
  final refreshNotifier =
      GoRouterRefreshStream(SupabaseClientHelper.authStateChanges);

  // Also listen to guest mode changes to trigger GoRouter redirection refresh
  ref.listen<bool>(guestModeProvider, (previous, next) {
    if (previous != next) {
      refreshNotifier.refresh();
    }
  });

  // Dispose the notifier when the provider is disposed.
  ref.onDispose(() => refreshNotifier.dispose());

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refreshNotifier,
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => SplashScreen(
          onComplete: () {
            // Check auth state synchronously (session is already loaded).
            final isLoggedIn =
                SupabaseClientHelper.currentUser != null || ref.read(guestModeProvider);
            if (!onboardingCompleted) {
              context.go('/onboarding');
            } else if (isLoggedIn) {
              context.go('/');
            } else {
              context.go('/login');
            }
          },
        ),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => OnboardingScreen(
          onComplete: () {
            ref.read(onboardingCompletedProvider.notifier).completeOnboarding();
            context.go('/login');
          },
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginScreen(
          onSignUpTap: () => context.go('/signup'),
          onLoginSuccess: () => context.go('/'),
        ),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => SignupScreen(
          onLoginTap: () => context.go('/login'),
          onSignupSuccess: () => context.go('/login'),
        ),
      ),
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardShell(),
      ),
    ],
    redirect: (context, state) {
      // Use the synchronous currentUser getter — this works even before
      // the auth stream emits its first event (e.g. on cold start with a
      // persisted session).
      final isLoggedIn =
          SupabaseClientHelper.currentUser != null || ref.read(guestModeProvider);
      final isGoingToAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isGoingToSplash = state.matchedLocation == '/splash';
      final isGoingToOnboarding = state.matchedLocation == '/onboarding';

      // Let splash finish its animation without redirecting.
      if (isGoingToSplash) return null;

      // Force onboarding if not completed.
      if (!onboardingCompleted) {
        if (isGoingToOnboarding) return null;
        return '/onboarding';
      }

      if (!isLoggedIn) {
        // Not logged in → must be on an auth page.
        if (!isGoingToAuth) return '/login';
      } else {
        // Logged in → don't allow going back to auth or onboarding.
        if (isGoingToAuth || isGoingToOnboarding) return '/';
      }

      return null;
    },
  );
});
