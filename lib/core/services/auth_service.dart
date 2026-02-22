import 'package:supabase_flutter/supabase_flutter.dart';

enum UserRole { patient, doctor, admin }

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get current session
  Session? get currentSession => _supabase.auth.currentSession;

  // Get current user
  User? get currentUser => _supabase.auth.currentUser;

  // Get current user stream
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // Get user role
  Future<UserRole?> getUserRole(String uid) async {
    try {
      final response = await _supabase
          .from('users')
          .select('role')
          .eq('id', uid)
          .maybeSingle();

      if (response == null) return null;

      final roleString = response['role'] as String?;
      if (roleString == null) return null;

      return UserRole.values.firstWhere(
        (role) => role.name == roleString,
        orElse: () => UserRole.patient,
      );
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Sign up with email and password
  Future<AuthResponse> signUpWithEmailPassword({
    required String email,
    required String password,
    required String name,
    required UserRole role,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      // Sign up with metadata
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name, 'role': role.name, ...?additionalData},
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An error occurred during sign up. Please try again.';
    }
  }

  // Sign in with email and password
  Future<AuthResponse> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'An error occurred during sign in. Please try again.';
    }
  }

  // Password reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: 'io.supabase.pulsecare://reset-password/',
      );
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error sending password reset email. Please try again.';
    }
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      await _supabase.auth.updateUser(UserAttributes(password: newPassword));
    } on AuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'Error updating password. Please try again.';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw 'Error signing out. Please try again.';
    }
  }

  // Handle Supabase Auth exceptions
  String _handleAuthException(AuthException e) {
    if (e.statusCode == '429' || e.message.contains('rate limit')) {
      return 'Email rate limit exceeded. Please go to Supabase Dashboard -> Authentication -> Rate Limits and increase "Emails per hour", or wait 15 minutes.';
    }
    if (e.message.contains('Error sending confirmation email')) {
      return 'Supabase failed to send the email. This usually happens if the built-in email service rate limit is hit. Please check your Supabase Dashboard -> Authentication -> Auth Settings.';
    }
    return e.message;
  }
}
