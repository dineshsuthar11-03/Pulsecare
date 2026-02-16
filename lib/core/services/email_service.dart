import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class EmailService {
  final String _serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
  final String _publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';

  /// Sends a welcome email to the new user.
  Future<void> sendWelcomeEmail(String email, String name) async {
    final String welcomeTemplateId =
        dotenv.env['EMAILJS_WELCOME_TEMPLATE_ID'] ?? '';

    if (_serviceId.isEmpty || welcomeTemplateId.isEmpty || _publicKey.isEmpty) {
      print('Welcome Email credentials not fully configured. Skipping.');
      return;
    }

    try {
      print('DEBUG: Sending welcome email to: $email');
      final response = await http.post(
        Uri.parse('https://api.emailjs.com/api/v1.0/email/send'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'service_id': _serviceId,
          'template_id': welcomeTemplateId,
          'user_id': _publicKey,
          'template_params': {
            'to_email': email,
            'user_name': name,
            'project_name': 'CareLink',
          },
        }),
      );

      if (response.statusCode != 200) {
        print(
          'EmailJS Welcome Error: ${response.statusCode} - ${response.body}',
        );
      } else {
        print('EmailJS Welcome Success');
      }
    } catch (e) {
      print('Error sending welcome email: $e');
    }
  }
}
