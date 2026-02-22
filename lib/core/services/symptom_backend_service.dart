import 'dart:convert';
import 'package:http/http.dart' as http;

class SymptomBackendService {
  static const String baseUrl = 'http://localhost:5000/api/symptoms';

  /// Sends symptoms and patient info to the backend for RapidAPI analysis.
  Future<Map<String, dynamic>> analyzeSymptoms({
    required List<String> symptoms,
    required String gender,
    required int age,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/analyze'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'symptoms': symptoms, 'gender': gender, 'age': age}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'error': 'Failed to connect to backend: ${e.toString()}'};
    }
  }
}
