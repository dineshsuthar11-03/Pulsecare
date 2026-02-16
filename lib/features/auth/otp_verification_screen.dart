import 'package:flutter/material.dart';
import 'package:carelink/core/constants/app_colors.dart';
import 'package:carelink/features/auth/reset_password_screen.dart';
import 'package:carelink/features/auth/widgets/auth_text_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

enum AuthOtpType { signup, recovery, phone }

class OtpVerificationScreen extends StatefulWidget {
  final String email;
  final AuthOtpType type;

  const OtpVerificationScreen({
    super.key,
    required this.email,
    required this.type,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      supabase.OtpType supabaseType;
      switch (widget.type) {
        case AuthOtpType.recovery:
          supabaseType = supabase.OtpType.recovery;
          break;
        case AuthOtpType.signup:
          supabaseType = supabase.OtpType.signup;
          break;
        case AuthOtpType.phone:
          supabaseType = supabase.OtpType.sms;
          break;
      }

      await supabase.Supabase.instance.client.auth.verifyOTP(
        token: _otpController.text.trim(),
        type: supabaseType,
        email: widget.email,
      );

      if (mounted) {
        if (widget.type == AuthOtpType.recovery) {
          // Navigate to ResetPasswordScreen for password recovery
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => const ResetPasswordScreen(),
            ),
          );
        } else {
          // For other types, maybe go back or to login?
          // Assuming successful verification means we can go back with success or proceed.
          // For now, let's pop.
          Navigator.of(context).pop(true);
        }
      }
    } on supabase.AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error verifying OTP: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify OTP')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  Text(
                    'Enter Verification Code',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We have sent a verification code to ${widget.email}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  AuthTextField(
                    controller: _otpController,
                    label: 'OTP Code',
                    icon: Icons.lock_clock, // Using a relevant icon
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter the OTP';
                      }
                      if (value.length < 6) {
                        return 'OTP typically has 6 digits';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _verifyOtp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Verify', style: TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
