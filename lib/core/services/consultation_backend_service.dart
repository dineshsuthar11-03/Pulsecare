import 'dart:convert';

import 'package:http/http.dart' as http;

class ConsultationBackendService {
  // For Android emulator, replace localhost with 10.0.2.2
  static const String baseUrl = 'http://localhost:5000/api/consultations';

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
