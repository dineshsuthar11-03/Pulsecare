import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SymptomCheckerService {
  // NIH Clinical Tables Search API (v3)
  // Documentation: https://clinicaltables.nlm.nih.gov/api/conditions/v3/search
  static const String _baseUrl =
      'https://clinicaltables.nlm.nih.gov/api/conditions/v3/search';

  /// Searches for symptoms or conditions using the NIH Clinical Tables API.
  /// Returns a list of condition names.
  Future<List<String>> searchConditions(String query) async {
    if (query.isEmpty) return [];

    try {
      final url = Uri.parse(
        _baseUrl,
      ).replace(queryParameters: {'terms': query, 'maxList': '20'});

      debugPrint('NIH Search: $url');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // NIH Format: [total_count, codes, extra_fields, display_names]
        // We want the display names, which are in the 4th element (index 3).
        if (data.length >= 4 && data[3] is List) {
          final List<dynamic> results = data[3];
          // Each result is an array itself (usually just one string for conditions)
          return results.map((item) => item[0].toString()).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('NIH API Error: $e');
      return [];
    }
  }

  /// Searches for symptoms locally from Symptoms.json
  Future<List<Map<String, dynamic>>> searchLocalSymptoms(String query) async {
    try {
      final String response = await rootBundle.loadString('Symptoms.json');
      final data = await json.decode(response);
      final List symptoms = data['symptoms'];

      if (query.isEmpty) {
        return symptoms.map((s) => s as Map<String, dynamic>).toList();
      }

      return symptoms
          .where(
            (s) => s['name'].toString().toLowerCase().contains(
              query.toLowerCase(),
            ),
          )
          .map((s) => s as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Local Symptoms Error: $e');
      return [];
    }
  }

  /// Since the NIH API is stateless and doesn't provide a "diagnosis" engine like EndlessMedical,
  /// we now use Gemini in the screen logic to perform the analysis based on these verified NIH terms.
  /// This service now acts primarily as a medical catalog provider.
}
