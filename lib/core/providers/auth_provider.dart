import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';
import 'guest_provider.dart';

/// Provider that exposes the current auth user, auto-updating on state changes.
final authUserProvider = StreamProvider<User?>((ref) {
  return SupabaseClientHelper.authStateChanges.map((event) => event.session?.user);
});

/// Provider indicating if the user is currently logged in
/// (either via Supabase or local guest mode).
final isLoggedInProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(authUserProvider);
  final isGuest = ref.watch(guestModeProvider);
  return userAsync.valueOrNull != null || isGuest;
});

/// Provider indicating if the current user is a local guest.
final isGuestProvider = Provider<bool>((ref) {
  return ref.watch(guestModeProvider);
});
