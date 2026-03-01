import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:pulsecare/core/constants/app_config.dart';

class ConsultationBackendService {
  /// Base URL for consultation-related backend endpoints.
  static String get baseUrl => AppConfig.consultationsBaseUrl;

  Future<void> sendScheduleEmail({
    required String patientId,
    required String doctorId,
    required DateTime scheduledAt,
    String? consultationId,
    String? roomCode,
  }) async {
    final uri = Uri.parse('$baseUrl/notify');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'patientId': patientId,
        'doctorId': doctorId,
        'scheduledAt': scheduledAt.toIso8601String(),
        'consultationId': consultationId,
        'roomCode': roomCode,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send schedule email: ${response.body}');
    }
  }

  // In the Jitsi-based implementation, the room code is stored directly in
  // the consultation record, so the client no longer needs to request an
  // Agora token from the backend.
}
