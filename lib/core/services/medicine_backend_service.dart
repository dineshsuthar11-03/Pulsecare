import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:pulsecare/core/constants/api_constants.dart';
import 'package:pulsecare/data/models/medicine_model.dart';
import 'package:http/http.dart' as http;

class MedicineBackendService {
  // NOTE:
  // - For Android emulator, use 10.0.2.2 instead of localhost.
  // - For web/desktop/iOS, localhost works when the backend runs on the same machine.
  // You can point this to your production URL when deploying.
  static const String _prodBaseUrl =
      'https://pulsecare-production-ae31.up.railway.app/api/medicines';

  static String get baseUrl {
    // In release builds (Firebase Hosting, Play Store, etc.),
    // always use the deployed Railway backend.
    if (kReleaseMode) {
      return _prodBaseUrl;
    }

    // Local development URLs
    if (kIsWeb) {
      return 'http://localhost:5000/api/medicines';
    }

    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:5000/api/medicines';
    }

    // iOS, Windows, macOS, Linux (local dev)
    return 'http://localhost:5000/api/medicines';
  }

  Future<List<MedicineModel>> searchMedicines(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      final uri = Uri.parse('$baseUrl/search').replace(
        queryParameters: {
          'q': query,
          'limit': ApiConstants.searchResultsLimit.toString(),
        },
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map(
              (item) => MedicineModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } else {
        throw Exception('Failed to search medicines: ${response.statusCode}');
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception(
          'Request timeout. Please check your internet connection.',
        );
      }
      rethrow;
    }
  }

  Future<List<MedicineModel>> getAlternativeMedicines(
    String activeIngredient, {
    String? excludeId,
  }) async {
    if (activeIngredient.trim().isEmpty) {
      return [];
    }

    try {
      final uri = Uri.parse('$baseUrl/alternatives').replace(
        queryParameters: {
          'activeIngredient': activeIngredient,
          if (excludeId != null) 'excludeId': excludeId,
          'limit': '5',
        },
      );

      final response = await http
          .get(uri)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
        return data
            .map(
              (item) => MedicineModel.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      } else {
        throw Exception(
          'Failed to load alternative medicines: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e.toString().contains('timeout')) {
        throw Exception(
          'Request timeout. Please check your internet connection.',
        );
      }
      rethrow;
    }
  }
}
