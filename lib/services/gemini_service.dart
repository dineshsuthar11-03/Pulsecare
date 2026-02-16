import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:carelink/core/constants/api_constants.dart';

class GeminiService {
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  bool _isInitialized = false;

  static const String _systemPrompt = '''
You are a preliminary health assistant in the CareLink app. Your role is to help users understand their symptoms and guide them toward appropriate care.

CRITICAL GUIDELINES:
1. You are NOT a replacement for medical professionals
2. Always emphasize: "This is not medical advice. Consult a healthcare professional."
3. For serious or emergency symptoms, immediately advise seeking medical attention

When analyzing symptoms:
1. Ask clarifying questions about:
   - Duration and onset
   - Severity (mild/moderate/severe)
   - Associated symptoms
   - Any triggering factors
2. Suggest 2-3 possible conditions (ranked by likelihood)
3. Recommend appropriate over-the-counter medicines for common conditions
4. Provide multiple medicine options when available (e.g., both ibuprofen and acetaminophen for pain)
5. Indicate urgency level:
   - EMERGENCY: Seek immediate medical attention (chest pain, difficulty breathing, severe injuries)
   - HIGH: See doctor within 24 hours
   - MEDIUM: Schedule doctor appointment soon
   - LOW: Self-care with monitoring

MEDICINE RECOMMENDATIONS:
- Only suggest OTC (over-the-counter) medicines
- Always mention MULTIPLE options for the same condition
- Include generic names
- Warn about common side effects
- Remind about proper dosage (refer to package)
- Never recommend prescription medications

FORMAT YOUR RESPONSE:
- Be conversational and empathetic
- Use clear, simple language
- Structure information with bullet points when helpful
- Always end with the medical disclaimer

Remember: Your goal is education and guidance, not diagnosis or treatment.
''';

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await dotenv.load(fileName: '.env');
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null ||
          apiKey.isEmpty ||
          apiKey == 'your_gemini_api_key_here') {
        throw Exception(
          'Gemini API key not found. Please add your API key to the .env file.\n'
          'Get your free API key from: https://aistudio.google.com/app/apikey',
        );
      }

      _model = GenerativeModel(
        model: ApiConstants.geminiModel,
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: ApiConstants.geminiTemperature,
          maxOutputTokens: ApiConstants.geminiMaxTokens,
        ),
        systemInstruction: Content.system(_systemPrompt),
      );

      _chatSession = _model.startChat();
      _isInitialized = true;
    } catch (e) {
      throw Exception('Failed to initialize Gemini service: $e');
    }
  }

  Future<String> sendMessage(String message) async {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final response = await _chatSession.sendMessage(Content.text(message));
      return response.text ??
          'I apologize, but I couldn\'t generate a response. Please try again.';
    } catch (e) {
      if (e.toString().contains('429') || e.toString().contains('quota')) {
        throw Exception(
          'API rate limit reached. Please try again in a few minutes.',
        );
      }
      throw Exception('Failed to get AI response: $e');
    }
  }

  Stream<String> sendMessageStream(String message) async* {
    if (!_isInitialized) {
      await initialize();
    }

    try {
      final response = _chatSession.sendMessageStream(Content.text(message));
      await for (final chunk in response) {
        final text = chunk.text;
        if (text != null) {
          yield text;
        }
      }
    } catch (e) {
      if (e.toString().contains('429') || e.toString().contains('quota')) {
        throw Exception(
          'API rate limit reached. Please try again in a few minutes.',
        );
      }
      throw Exception('Failed to get AI response: $e');
    }
  }

  void resetConversation() {
    if (_isInitialized) {
      _chatSession = _model.startChat();
    }
  }

  bool get isInitialized => _isInitialized;
}
