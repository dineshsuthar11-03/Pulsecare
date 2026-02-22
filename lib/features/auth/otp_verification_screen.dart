import 'package:flutter/material.dart';
import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:pulsecare/core/services/backend_auth_service.dart';
import 'package:pulsecare/features/auth/widgets/auth_text_field.dart';

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
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final BackendAuthService _backendAuthService = BackendAuthService();
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final otp = _otpController.text.trim();

      if (widget.type == AuthOtpType.signup) {
        final response = await _backendAuthService.verifySignupOtp(
          widget.email,
          otp,
        );

        if (response['error'] != null) {
          throw response['error'];
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Email verified successfully. You can now log in.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
      } else if (widget.type == AuthOtpType.recovery) {
        if (_passwordController.text.isEmpty ||
            _passwordController.text.length < 6) {
          throw 'Please enter a new password with at least 6 characters.';
        }
        if (_passwordController.text != _confirmPasswordController.text) {
          throw 'Passwords do not match.';
        }

        final response = await _backendAuthService.resetPasswordWithOtp(
          email: widget.email,
          otp: otp,
          newPassword: _passwordController.text,
        );

        if (response['error'] != null) {
          throw response['error'];
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content:
                  Text('Password reset successfully. Please log in again.'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.of(context).pop();
        }
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

  Future<void> _sendOtp() async {
    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> response;

      if (widget.type == AuthOtpType.signup) {
        response = await _backendAuthService.resendSignupOtp(widget.email);
      } else {
        response = await _backendAuthService.forgotPassword(widget.email);
      }

      if (response['error'] != null) {
        throw response['error'];
      }

      if (mounted) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.type == AuthOtpType.signup
                  ? 'Verification OTP sent to your email.'
                  : 'Password reset OTP sent to your email.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending OTP: $e'),
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
    final isRecovery = widget.type == AuthOtpType.recovery;

    final title = isRecovery ? 'Reset Password' : 'Verify Email';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Text(title),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primaryDark, AppColors.primary, AppColors.background],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 8),
                  Text(
                    isRecovery
                        ? 'We\'ll help you reset it safely.'
                        : 'Verify your email to secure your account.',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(color: Colors.white.withOpacity(0.9)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Enter Verification Code',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isRecovery
                              ? 'Tap "Send OTP" to receive a reset code at ${widget.email}.'
                              : 'Tap "Send OTP" to receive a verification code at ${widget.email}.',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isLoading ? null : _sendOtp,
                          icon: const Icon(Icons.send),
                          label: Text(_otpSent ? 'Resend OTP' : 'Send OTP'),
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        AuthTextField(
                          controller: _otpController,
                          label: 'OTP Code',
                          icon: Icons.lock_clock,
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
                        if (isRecovery) ...[
                          const SizedBox(height: 24),
                          AuthTextField(
                            controller: _passwordController,
                            label: 'New Password',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            validator: (value) {
                              if (widget.type != AuthOtpType.recovery) {
                                return null;
                              }
                              if (value == null || value.isEmpty) {
                                return 'Please enter a new password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm New Password',
                            icon: Icons.lock_reset,
                            isPassword: true,
                            validator: (value) {
                              if (widget.type != AuthOtpType.recovery) {
                                return null;
                              }
                              if (value != _passwordController.text) {
                                return 'Passwords do not match';
                              }
                              return null;
                            },
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _verifyOtp,
                          style: ElevatedButton.styleFrom(
                            padding:
                                const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
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
                              : Text(
                                  isRecovery
                                      ? 'Verify & Reset Password'
                                      : 'Verify Email',
                                  style: const TextStyle(fontSize: 16),
                                ),
                        ),
                      ],
                    ),
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
