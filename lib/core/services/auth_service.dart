import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

/// Authentication service wrapping Supabase Auth (email/password only).
class AuthService {
  AuthService._();

  static final SupabaseClient _client = SupabaseClientHelper.client;

  /// Sign up a new user with email and password.
  /// Returns the [AuthResponse] on success, throws on failure.
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: fullName != null ? {'full_name': fullName} : null,
    );
    return response;
  }

  /// Sign in with email and password.
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response;
  }

  /// Sign out the current user.
  static Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Send a password reset email.
  static Future<void> resetPassword({required String email}) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Check if a user is currently logged in (Supabase session).
  static bool get isLoggedIn => _client.auth.currentUser != null;

  /// Get the current user's ID (throws if not logged in).
  static String get currentUserId {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No user is currently logged in');
    }
    return user.id;
  }

  /// Stream of auth state changes for reactive UI updates.
  static Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  // ── User-friendly error parsing ──

  /// Parse sign-in errors into user-friendly messages.
  static String parseSignInError(Object error) {
    final msg = error.toString();
    if (msg.contains('Invalid login credentials') ||
        msg.contains('invalid_credentials') ||
        msg.contains('400')) {
      return 'Unable to sign in. Please check your email and password.';
    }
    if (msg.contains('Email not confirmed')) {
      return 'Please verify your email address first.';
    }
    if (msg.contains('Too many requests') || msg.contains('rate_limit')) {
      return 'Too many attempts. Please try again later.';
    }
    if (msg.contains('SocketException') ||
        msg.contains('NetworkException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('Connection refused')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }

  /// Parse sign-up errors into user-friendly messages.
  static String parseSignUpError(Object error) {
    final msg = error.toString();
    if (msg.contains('User already registered') ||
        msg.contains('already_exists')) {
      return 'This email is already registered. Try signing in.';
    }
    if (msg.contains('Password should be at least') ||
        msg.contains('weak_password')) {
      return 'Password must be at least 8 characters.';
    }
    if (msg.contains('rate_limit') || msg.contains('Too many requests')) {
      return 'Too many attempts. Please try again later.';
    }
    if (msg.contains('invalid') && msg.contains('email')) {
      return 'Please enter a valid email address.';
    }
    if (msg.contains('SocketException') ||
        msg.contains('NetworkException') ||
        msg.contains('Failed host lookup') ||
        msg.contains('Connection refused')) {
      return 'Unable to connect. Please check your internet connection.';
    }
    return 'Something went wrong. Please try again.';
  }
}
