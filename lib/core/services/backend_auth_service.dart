import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pulsecare/core/constants/app_config.dart';

class BackendAuthService {
  /// Base URL for auth endpoints. Respects BACKEND_BASE_URL from .env
  /// and falls back to sensible defaults via AppConfig.
  static String get baseUrl => AppConfig.authBaseUrl;
  static const Duration _requestTimeout = Duration(seconds: 60);
  static const int _maxAttempts = 2;
  static const Duration _sessionSyncTimeout = Duration(seconds: 10);

  Future<http.Response> _executeWithRetry(
    Future<http.Response> Function() request,
  ) async {
    Object? lastError;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        return await request().timeout(_requestTimeout);
      } on TimeoutException catch (e) {
        lastError = e;
      } catch (e) {
        lastError = e;
        final text = e.toString().toLowerCase();
        final isTransient = text.contains('failed host lookup') ||
            text.contains('connection closed') ||
            text.contains('connection timed out') ||
            text.contains('clientexception');
        if (!isTransient) rethrow;
      }

      if (attempt < _maxAttempts) {
        await Future.delayed(const Duration(milliseconds: 1200));
      }
    }

    throw lastError ?? Exception('Request failed after retries.');
  }

  Map<String, dynamic> _safeDecode(http.Response response) {
    if (response.body.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'data': decoded};
    } catch (_) {
      return {'error': response.body};
    }
  }

  Map<String, dynamic> _normalizeResponse(
    http.Response response,
    String fallbackError,
  ) {
    final decoded = _safeDecode(response);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded['error'] ??
        decoded['message'] ??
        '$fallbackError (HTTP ${response.statusCode})';
    return {'error': message.toString()};
  }

  Future<Map<String, dynamic>> signup({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      final response = await _executeWithRetry(
        () => http.post(
          Uri.parse('$baseUrl/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'password': password,
            'full_name': name,
            'role': role,
          }),
        ),
      );

      return _normalizeResponse(response, 'Signup failed');
    } on TimeoutException {
      return {
        'error':
            'Request timed out. Please check your internet and try again.',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _executeWithRetry(
        () => http.post(
          Uri.parse('$baseUrl/login'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'password': password}),
        ),
      );

      final data = _normalizeResponse(response, 'Login failed');

      if (data['error'] != null) {
        return data;
      }

      if (data['token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);

        // SYNC WITH SUPABASE: Tell the app we are logged in
        if (data['session'] != null) {
          final accessToken = data['session']['access_token'];
          final refreshToken = data['session']['refresh_token'];

          if (accessToken != null && refreshToken != null) {
            try {
              await Supabase.instance.client.auth
                  .setSession(refreshToken)
                  .timeout(_sessionSyncTimeout);
              debugPrint('DEBUG: Supabase session synchronized successfully.');
            } on TimeoutException {
              debugPrint('WARN: Supabase session sync timed out. Continuing login.');
            } catch (e) {
              debugPrint('WARN: Supabase session sync failed: $e');
            }
          }
        }
      }

      return data;
    } on TimeoutException {
      return {
        'error':
            'Login timed out. Please try again in a few seconds.',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _executeWithRetry(
        () => http.post(
          Uri.parse('$baseUrl/forgot-password'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        ),
      );

      return _normalizeResponse(response, 'Failed to send OTP');
    } on TimeoutException {
      return {
        'error':
            'Request timed out. Please check your internet and try again.',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resendSignupOtp(String email) async {
    try {
      final response = await _executeWithRetry(
        () => http.post(
          Uri.parse('$baseUrl/resend-signup-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email}),
        ),
      );

      return _normalizeResponse(response, 'Failed to resend OTP');
    } on TimeoutException {
      return {
        'error':
            'Request timed out. Please check your internet and try again.',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> verifySignupOtp(
    String email,
    String otp,
  ) async {
    try {
      final response = await _executeWithRetry(
        () => http.post(
          Uri.parse('$baseUrl/verify-signup-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': email, 'otp': otp}),
        ),
      );

      return _normalizeResponse(response, 'Failed to verify OTP');
    } on TimeoutException {
      return {
        'error':
            'Request timed out. Please check your internet and try again.',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await _executeWithRetry(
        () => http.post(
          Uri.parse('$baseUrl/reset-password-with-otp'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': email,
            'otp': otp,
            'newPassword': newPassword,
          }),
        ),
      );

      return _normalizeResponse(response, 'Failed to reset password');
    } on TimeoutException {
      return {
        'error':
            'Request timed out. Please check your internet and try again.',
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }
}
