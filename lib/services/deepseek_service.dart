import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class DeepSeekService {
  static const String _baseUrl = 'https://api.deepseek.com/chat/completions';

  Future<String> analyzeSymptoms({
    required List<String> symptoms,
    required String gender,
    required int age,
    required double temperature,
  }) async {
    final apiKey = dotenv.env['DEEPSEEK_API'];
    if (apiKey == null || apiKey.isEmpty) {
      return 'DeepSeek API key is missing. Please check your .env file.';
    }

    final prompt =
        '''
As a professional medical AI assistant powered by DeepSeek, provide a detailed diagnostic analysis for the following patient:
- Gender: $gender
- Age: $age
- Body Temperature: $temperature°C
- Selected Symptoms/Conditions: ${symptoms.join(', ')}

Please provide your analysis in the following Markdown format:

## 🔍 DeepSeek Diagnostic Analysis
Identify the most likely conditions (maximum 3) with a brief professional explanation for each based on DeepSeek's medical knowledge base.

## ⚠️ Severity Breakdown
Rate the urgency as: EMERGENCY, HIGH, MEDIUM, or LOW. 
Explain the risk associated with these specific symptoms.

## 🩺 Clinical Recommendations
1. Type of specialist to consult.
2. Potential diagnostic tests.
3. Immediate care instructions.

---
**Disclaimer:** This is a DeepSeek-powered AI analysis. It is NOT a medical diagnosis. Consult a doctor immediately.
''';

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'deepseek-chat',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful medical assistant.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        debugPrint(
          'DeepSeek API Error: ${response.statusCode} - ${response.body}',
        );
        return 'DeepSeek Analysis failed (Status: ${response.statusCode}). Please fallback to Gemini.';
      }
    } catch (e) {
      debugPrint('DeepSeek Service Error: $e');
      return 'An error occurred during DeepSeek analysis: $e';
    }
  }
}
