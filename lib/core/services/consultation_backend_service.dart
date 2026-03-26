import 'dart:convert';
import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:pulsecare/core/constants/app_config.dart';

class ConsultationBackendService {
  /// Base URL for consultation-related backend endpoints.
  static String get baseUrl => AppConfig.consultationsBaseUrl;
  static const Duration _requestTimeout = Duration(seconds: 60);
  static const int _maxAttempts = 2;

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

  String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  dynamic _decodeBody(http.Response response) {
    if (response.body.isEmpty) {
      return null;
    }

    try {
      return jsonDecode(response.body);
    } catch (_) {
      return response.body;
    }
  }

  Exception _httpError(http.Response response, String defaultMessage) {
    final body = _decodeBody(response);

    if (body is Map<String, dynamic>) {
      final error = body['error'] ?? body['message'];
      if (error != null) {
        return Exception(error.toString());
      }
    }

    return Exception('$defaultMessage (HTTP ${response.statusCode})');
  }

  Future<Map<String, dynamic>> createConsultation({
    required String patientId,
    required String doctorId,
    required DateTime scheduledAt,
    required double fee,
    String? symptoms,
  }) async {
    final response = await _executeWithRetry(
      () => http.post(
        Uri.parse(baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientId': patientId,
          'doctorId': doctorId,
          'scheduledAt': scheduledAt.toIso8601String(),
          'fee': fee,
          'symptoms': symptoms,
        }),
      ),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw _httpError(response, 'Failed to create consultation');
    }

    final decoded = _decodeBody(response);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid consultation response from backend');
    }

    final consultation = decoded['consultation'];
    if (consultation is! Map<String, dynamic>) {
      throw Exception('Consultation payload missing from backend response');
    }

    return consultation;
  }

  Future<List<Map<String, dynamic>>> getConsultations({
    required String userId,
  }) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {'userId': userId});
    final response = await _executeWithRetry(() => http.get(uri));

    if (response.statusCode != 200) {
      throw _httpError(response, 'Failed to fetch consultations');
    }

    final decoded = _decodeBody(response);
    if (decoded is! List) {
      return [];
    }

    return decoded
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<void> updateConsultation({
    required String id,
    String? status,
    String? notes,
    String? prescription,
  }) async {
    final payload = <String, dynamic>{};
    if (status != null) payload['status'] = status;
    if (notes != null) payload['notes'] = notes;
    if (prescription != null) payload['prescription'] = prescription;

    final response = await _executeWithRetry(
      () => http.patch(
        Uri.parse('$baseUrl/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ),
    );

    if (response.statusCode != 200) {
      throw _httpError(response, 'Failed to update consultation');
    }
  }

  Future<Map<String, dynamic>> getDoctorAvailability(String doctorId) async {
    final response = await _executeWithRetry(
      () => http.get(Uri.parse('$baseUrl/doctor/$doctorId/availability')),
    );

    if (response.statusCode != 200) {
      throw _httpError(response, 'Failed to fetch doctor availability');
    }

    final decoded = _decodeBody(response);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid doctor availability response');
    }

    return decoded;
  }

  Future<List<Map<String, dynamic>>> getDoctorAvailableSlots({
    required String doctorId,
    required DateTime date,
  }) async {
    final uri = Uri.parse('$baseUrl/doctor/$doctorId/slots').replace(
      queryParameters: {'date': _formatDate(date)},
    );

    final response = await _executeWithRetry(() => http.get(uri));

    if (response.statusCode != 200) {
      throw _httpError(response, 'Failed to fetch available slots');
    }

    final decoded = _decodeBody(response);
    if (decoded is! Map<String, dynamic>) {
      return [];
    }

    final rawSlots = decoded['slots'];
    if (rawSlots is! List) {
      return [];
    }

    return rawSlots
        .whereType<Map>()
        .map((slot) => Map<String, dynamic>.from(slot))
        .toList();
  }

  Future<void> sendScheduleEmail({
    required String patientId,
    required String doctorId,
    required DateTime scheduledAt,
    String? consultationId,
    String? roomCode,
  }) async {
    final uri = Uri.parse('$baseUrl/notify');
    final response = await _executeWithRetry(
      () => http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'patientId': patientId,
          'doctorId': doctorId,
          'scheduledAt': scheduledAt.toIso8601String(),
          'consultationId': consultationId,
          'roomCode': roomCode,
        }),
      ),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send schedule email: ${response.body}');
    }
  }

  // In the Jitsi-based implementation, the room code is stored directly in
  // the consultation record, so the client no longer needs to request an
  // Agora token from the backend.
}
