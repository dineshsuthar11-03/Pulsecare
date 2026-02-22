import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:pulsecare/core/constants/api_constants.dart';
import 'package:pulsecare/data/models/medicine_model.dart';

class OpenFdaService {
  Future<List<MedicineModel>> searchMedicines(String query) async {
    if (query.trim().isEmpty) {
      return [];
    }

    try {
      // Build search query for OpenFDA
      final encodedQuery = Uri.encodeComponent(query);
      final searchField = _buildSearchQuery(encodedQuery);

      final url = Uri.parse(
        '${ApiConstants.openFdaBaseUrl}${ApiConstants.drugLabelEndpoint}'
        '?search=$searchField'
        '&limit=${ApiConstants.searchResultsLimit}',
      );

      final response = await http
          .get(url)
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => throw Exception('Request timeout'),
          );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;

        if (results == null || results.isEmpty) {
          return [];
        }

        return results
            .map(
              (item) => MedicineModel.fromOpenFDA(item as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 404) {
        return []; // No results found
      } else if (response.statusCode == 429) {
        throw Exception('API rate limit exceeded. Please try again later.');
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

  Future<MedicineModel?> getMedicineDetails(String medicineId) async {
    try {
      final url = Uri.parse(
        '${ApiConstants.openFdaBaseUrl}${ApiConstants.drugLabelEndpoint}'
        '?search=id:"$medicineId"',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;

        if (results != null && results.isNotEmpty) {
          return MedicineModel.fromOpenFDA(
            results.first as Map<String, dynamic>,
          );
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get medicine details: $e');
    }
  }

  Future<List<MedicineModel>> getAlternativeMedicines(
    String activeIngredient,
  ) async {
    try {
      final encodedIngredient = Uri.encodeComponent(activeIngredient);
      final url = Uri.parse(
        '${ApiConstants.openFdaBaseUrl}${ApiConstants.drugLabelEndpoint}'
        '?search=openfda.substance_name:"$encodedIngredient"'
        '&limit=10',
      );

      final response = await http.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final results = data['results'] as List<dynamic>?;

        if (results == null || results.isEmpty) {
          return [];
        }

        return results
            .map(
              (item) => MedicineModel.fromOpenFDA(item as Map<String, dynamic>),
            )
            .toList();
      }
      return [];
    } catch (e) {
      return []; // Return empty list on error for alternatives
    }
  }

  String _buildSearchQuery(String query) {
    // Search across multiple fields for better results
    return '(openfda.brand_name:"$query"+OR+openfda.generic_name:"$query"+OR+openfda.substance_name:"$query")';
  }
}
