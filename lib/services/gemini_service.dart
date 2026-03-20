import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:pulsecare/core/constants/app_config.dart';

/// Groq-backed AI service that keeps the same interface as the old GeminiService.
///
/// It calls Groq's OpenAI-compatible Chat Completions API under the hood.
class GeminiService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  // You can change this to any Groq-supported chat model if needed.
  static const String _modelName = 'llama-3.1-8b-instant';

  // Optional compile-time override via --dart-define=GROQ_API_KEY=...
  static const String _definedGroqKey =
      String.fromEnvironment('GROQ_API_KEY', defaultValue: '');

  bool _isInitialized = false;
  bool _useBackendProxy = false;
  String _activeModelName = _modelName;
  String? _apiKey;

  String _preferredLanguage = 'English';

  /// Conversation history for the chat-style assistant screen.
  /// Each entry is a map with 'role' (system|user|assistant) and 'content'.
  final List<Map<String, String>> _chatHistory = [];

  void setPreferredLanguage(String language) {
    _preferredLanguage = language;
  }

  Future<void> initialize() async {
    if (_isInitialized) return;

    String? key;

    // 1) Prefer compile-time key (works reliably on web/hosting builds).
    if (_definedGroqKey.isNotEmpty) {
      key = _definedGroqKey.trim();
    } else {
      // 2) Fallback to runtime .env file (useful for local dev).
      try {
        await dotenv.load(fileName: '.env');
      } catch (_) {}

      key = dotenv.env['GROQ_API_KEY']?.trim();
    }

    if (key == null || key.isEmpty) {
      // Web builds may miss .env at runtime; fallback to backend proxy API.
      _useBackendProxy = true;
      _isInitialized = true;
      _activeModelName = 'backend-proxy';
      debugPrint('[Groq] No client key found. Using backend proxy mode.');
      return;
    }

    _apiKey = key;
    _isInitialized = true;
    _activeModelName = _modelName;
    debugPrint('[Groq] ✅ Initialized with model: $_activeModelName');
  }

  Future<String> _callBackendProxy(String input) async {
    final response = await http.post(
      Uri.parse('${AppConfig.backendBaseUrl}/api/ai/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'symptoms': input}),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Backend AI Error: HTTP ${response.statusCode}. Please try again later.',
      );
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final analysis = data['analysis'] as String?;
    if (analysis == null || analysis.isEmpty) {
      throw Exception('Backend AI response was empty');
    }

    return analysis;
  }

  /// Internal helper to call Groq Chat Completions.
  Future<String> _callGroq(List<Map<String, String>> messages,
      {double temperature = 0.7}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      throw Exception('Groq API key not set');
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      },
      body: jsonEncode({
        'model': _modelName,
        'messages': messages,
        'temperature': temperature,
        'stream': false,
      }),
    );

    if (response.statusCode != 200) {
      debugPrint(
          '[Groq] Error ${response.statusCode}: ${response.body.substring(0, response.body.length.clamp(0, 500))}');
      throw Exception(
          'Groq API Error: HTTP ${response.statusCode}. Please try again later.');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) {
      throw Exception('Groq response contained no choices');
    }

    final message = choices.first['message'] as Map<String, dynamic>?;
    final content = message?['content'] as String?;
    if (content == null || content.isEmpty) {
      throw Exception('Groq response had empty content');
    }
    return content;
  }

  /// Performs a detailed clinical analysis of selected symptoms using Groq.
  Future<String> analyzeSymptoms({
    required List<String> symptoms,
    required String gender,
    required int age,
    required double temperature,
    String? language,
  }) async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        return
            '⚠️ AI is currently unavailable. Please consult a doctor directly.\n\nError: $e';
      }
    }

    final targetLanguage = language ?? _preferredLanguage;

    final prompt = '''
As a professional medical AI assistant, provide a detailed diagnostic analysis for the following patient:
- Gender: $gender
- Age: $age
- Body Temperature: ${temperature.toStringAsFixed(1)}°C
- Reported Symptoms: ${symptoms.join(', ')}

Respond in this exact Markdown format:

## 🔍 Potential Conditions
List the top 3 most likely conditions with a brief clinical explanation.

## ⚠️ Severity & Urgency
Rate urgency as one of: **EMERGENCY**, **HIGH**, **MEDIUM**, or **LOW**.
Explain why these symptoms together might indicate an underlying issue.

## 🩺 Recommended Next Steps
1. Type of specialist to consult.
2. Common diagnostic tests.
3. Lifestyle or immediate monitoring advice.

## 💊 Common OTC Management
Safe over-the-counter options if applicable, with emphasis on professional consultation.

---
**Disclaimer:** AI-generated analysis — NOT medical advice. Consult a licensed physician immediately.

Respond entirely in $targetLanguage.
''';

    try {
      final content = _useBackendProxy
          ? await _callBackendProxy(prompt)
          : await _callGroq([
              {
                'role': 'system',
                'content':
                    'You are a careful, conservative medical triage assistant. Never provide definitive diagnoses; always encourage consultation with a doctor. Always answer in $targetLanguage.',
              },
              {'role': 'user', 'content': prompt},
            ]);
      return content;
    } catch (e) {
      debugPrint('[Groq] analyzeSymptoms error: $e');
      return
          '⚠️ AI analysis failed ($_activeModelName): $e\n\nPlease consult a doctor directly.';
    }
  }

  /// Provides safety-focused information about a specific medicine using Groq.
  Future<String> analyzeMedicine({
    required String name,
    required List<String> activeIngredients,
    String? purpose,
    String? warnings,
    String? dosageAndAdministration,
    String? language,
  }) async {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        return
            '⚠️ AI is currently unavailable. Please consult a doctor or pharmacist.\n\nError: $e';
      }
    }

    final targetLanguage = language ?? _preferredLanguage;

    final prompt = '''
You are a clinical pharmacist AI assistant. Explain this medicine in clear, patient-friendly language.

Medicine name: $name
Active ingredients: ${activeIngredients.join(', ')}
Purpose / indications: ${purpose ?? 'Not clearly specified in the label.'}
Important warnings: ${warnings ?? 'Not clearly specified in the label.'}
Dosage & administration notes: ${dosageAndAdministration ?? 'Not clearly specified in the label.'}

Respond in this Markdown structure:

## 🧾 What this medicine is for
Short overview of how it is typically used and what it treats.

## ⚠️ Safety checks
- Who should be extra careful using it (age, pregnancy, kidney/liver issues, allergies, etc.).
- Important interactions to mention in general (do **not** guess exact drug–drug interactions, but call out common classes if relevant).

## 💊 How to use it safely (general guidance)
High-level tips matching common label guidance: with/without food, not exceeding prescribed dose, what to avoid (alcohol, driving if drowsy, etc.).

## 🚨 When to call a doctor or emergency
List a few serious symptoms that would require urgent medical help.

---
**Strong disclaimer:** This is general AI-generated information based on a public label and may be incomplete or inaccurate. It is **not** medical advice. Always follow your own doctor's or pharmacist's instructions and the official package insert.

Respond entirely in $targetLanguage.
''';

    try {
      final content = _useBackendProxy
          ? await _callBackendProxy(prompt)
          : await _callGroq([
              {
                'role': 'system',
                'content':
                    'You are a cautious clinical pharmacist. Never give dosing specific to an individual patient and never override a doctor. Always answer in $targetLanguage.',
              },
              {'role': 'user', 'content': prompt},
            ]);
      return content;
    } catch (e) {
      debugPrint('[Groq] analyzeMedicine error: $e');
      return
          '⚠️ AI medicine explanation failed ($_activeModelName): $e\n\nPlease consult your doctor or pharmacist.';
    }
  }

  /// One-off chat call (non-streaming) used by other parts of the app.
  Future<String> sendMessage(String message) async {
    if (!_isInitialized) await initialize();

    try {
      _chatHistory.add({'role': 'user', 'content': message});

      final messages = [
        {
          'role': 'system',
          'content':
              'You are a friendly medical assistant helping users describe and understand their symptoms. Do not give definitive diagnoses. Always respond in $_preferredLanguage.',
        },
        ..._chatHistory,
      ];

      final reply = _useBackendProxy
          ? await _callBackendProxy(message)
          : await _callGroq(messages);
      _chatHistory.add({'role': 'assistant', 'content': reply});
      return reply;
    } catch (e) {
      debugPrint('[Groq] sendMessage error: $e');
      return 'AI Error: $e';
    }
  }

  /// Streaming-style interface used by SymptomInputScreen.
  /// Groq is called once and the full answer is yielded as a single chunk.
  Stream<String> sendMessageStream(String message) async* {
    if (!_isInitialized) {
      try {
        await initialize();
      } catch (e) {
        yield
            '⚠️ AI Initialization failed: $e. Please type your symptoms and try again.';
        return;
      }
    }

    try {
      _chatHistory.add({'role': 'user', 'content': message});

      final messages = [
        {
          'role': 'system',
          'content':
              'You are a friendly, safe medical assistant. Ask clarifying questions when needed and keep language simple. Avoid definitive diagnoses. Always respond in $_preferredLanguage.',
        },
        ..._chatHistory,
      ];

      final reply = _useBackendProxy
          ? await _callBackendProxy(message)
          : await _callGroq(messages);
      _chatHistory.add({'role': 'assistant', 'content': reply});

      // Yield as a single chunk (UI already supports streaming semantics).
      yield reply;
    } catch (e) {
      debugPrint('[Groq] sendMessageStream error: $e');
      yield 'AI Stream Error: $e';
    }
  }

  void resetConversation() {
    _chatHistory.clear();
  }

  bool get isInitialized => _isInitialized;
  String get activeModel => _activeModelName;
}
