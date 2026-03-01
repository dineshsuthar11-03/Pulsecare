import 'package:flutter/foundation.dart';
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

  // Backend base URL (without trailing slash), e.g. http://localhost:3000 or https://pulsecare-production-...railway.app
  static String get backendBaseUrl {
    final fromEnv = dotenv.env['BACKEND_BASE_URL']?.trim();
    const railway = 'https://pulsecare-production-ae31.up.railway.app';
    
    // In production (release builds), always use the deployed Railway backend
    // regardless of what is in the local .env. This ensures that web/Play
    // Store/App Store builds talk to the live API, not localhost.
    if (kReleaseMode) {
      return railway;
    }

    // Development: allow overriding via BACKEND_BASE_URL in .env.
    if (fromEnv != null && fromEnv.isNotEmpty) {
      return _stripTrailingSlash(fromEnv);
    }

    // Default local dev URL if env is missing. Note: your backend's PORT in
    // backend/.env is 5000, so we default to that here.
    return 'http://localhost:5000';
  }

  static String get authBaseUrl => '$backendBaseUrl/api/auth';
  static String get consultationsBaseUrl => '$backendBaseUrl/api/consultations';
  static String get symptomsBaseUrl => '$backendBaseUrl/api/symptoms';

  static String _stripTrailingSlash(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }

  // These should match the constants previously hard-coded in main.dart
  static const String _fallbackSupabaseUrl =
      'https://rpyccvaakjhpsumgqarf.supabase.co';

  static const String _fallbackSupabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJweWNjdmFha2pocHN1bWdxYXJmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzA4MjkyNDcsImV4cCI6MjA4NjQwNTI0N30.Pogb_nMKgv0WIbyHEb0V8LU8iNW9slwanKCTt_aNVwM';
}
