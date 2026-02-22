import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  final String _serviceId = dotenv.env['EMAILJS_SERVICE_ID'] ?? '';
  final String _publicKey = dotenv.env['EMAILJS_PUBLIC_KEY'] ?? '';

  /// Welcome email is now handled by the Node.js backend.
  Future<void> sendWelcomeEmail(String email, String name) async {
    // Redundant: Handled by Node.js backend via NodeMailer
    print('Welcome email for $email is handled by the backend server.');
  }
}
