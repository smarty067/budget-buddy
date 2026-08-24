import 'package:supabase_flutter/supabase_flutter.dart';
import '../app/constants/app_constants.dart';

/// Initializes and provides access to the Supabase client singleton.
class SupabaseClientHelper {
  SupabaseClientHelper._();

  /// Call this once in main() before runApp().
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppConstants.supabaseUrl,
      anonKey: AppConstants.supabaseAnonKey,
    );
  }

  /// The global Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;

  /// Shortcut to the current authenticated user (null if not logged in).
  static User? get currentUser => client.auth.currentUser;

  /// Shortcut to the auth state change stream.
  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
