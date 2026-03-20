import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central configuration for Supabase and backend URLs.
class AppConfig {
  // Supabase configuration
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL']?.trim().isNotEmpty == true
          ? dotenv.env['SUPABASE_URL']!.trim()
          : _fallbackSupabaseUrl;

  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY']?.trim().isNotEmpty == true
          ? dotenv.env['SUPABASE_ANON_KEY']!.trim()
          : _fallbackSupabaseAnonKey;

  // Backend base URL (without trailing slash), e.g. https://your-backend.onrender.com
  static String get backendBaseUrl {
    final fromEnv = dotenv.env['BACKEND_BASE_URL']?.trim();

    // Use BACKEND_BASE_URL in all modes so the deployment target is explicit
    // and not tied to a hardcoded provider URL.
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return _stripTrailingSlash(fromEnv);
    }

    // Fallback to deployed backend if env is missing/unreadable in web builds.
    return _fallbackBackendBaseUrl;
  }

  static String get authBaseUrl => '$backendBaseUrl/api/auth';
  static String get consultationsBaseUrl => '$backendBaseUrl/api/consultations';
  static String get symptomsBaseUrl => '$backendBaseUrl/api/symptoms';

  static String _stripTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  static const String _fallbackBackendBaseUrl =
      'https://pulsecare-backend-ws9c.onrender.com';

  // These should match the constants previously hard-coded in main.dart
  static const String _fallbackSupabaseUrl =
      'https://rpyccvaakjhpsumgqarf.supabase.co';

  static const String _fallbackSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJweWNjdmFha2pocHN1bWdxYXJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4MjkyNDcsImV4cCI6MjA4NjQwNTI0N30.Pogb_nMKgv0WIbyHEb0V8LU8iNW9slwanKCTt_aNVwM';
}
