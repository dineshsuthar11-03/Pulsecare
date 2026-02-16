import 'package:flutter/material.dart';
import 'package:carelink/core/constants/app_colors.dart';
import 'package:carelink/core/services/auth_service.dart';
import 'package:carelink/core/services/doctor_service.dart';
import 'package:carelink/features/auth/otp_verification_screen.dart';
import 'package:carelink/features/auth/widgets/auth_text_field.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final DoctorService _doctorService = DoctorService();
  final AuthService _authService = AuthService();

  // Controllers
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _aboutController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = _authService.currentUser;
    if (user == null) return;

    final profile = await _doctorService.getDoctorProfile(user.id);
    if (profile != null && mounted) {
      setState(() {
        _specializationController.text = profile['specialization'] ?? '';
        _experienceController.text = (profile['experience_years'] ?? 0)
            .toString();
        _feeController.text = (profile['consultation_fee'] ?? 0).toString();
        _aboutController.text = profile['bio'] ?? '';
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _specializationController.dispose();
    _experienceController.dispose();
    _feeController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);

    try {
      await _doctorService.updateDoctorProfile(
        id: user.id,
        specialization: _specializationController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text.trim()),
        consultationFee: double.tryParse(_feeController.text.trim()),
        bio: _aboutController.text.trim(),
      );

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isEditing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating profile: $e')));
      }
    }
  }

  Future<void> _changePassword() async {
    final user = _authService.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _isLoading = true);

    try {
      await _authService.sendPasswordResetEmail(user.email!);

      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => OtpVerificationScreen(
              email: user.email!,
              type: AuthOtpType.recovery,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
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
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.check : Icons.edit),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              } else {
                setState(() => _isEditing = true);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // Profile Image
                    Center(
                      child: Stack(
                        children: [
                          const CircleAvatar(
                            radius: 50,
                            backgroundColor: AppColors.background,
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                          if (_isEditing)
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: CircleAvatar(
                                radius: 18,
                                backgroundColor: AppColors.primary,
                                child: IconButton(
                                  icon: const Icon(
                                    Icons.camera_alt,
                                    size: 18,
                                    color: Colors.white,
                                  ),
                                  onPressed: () {
                                    // Pick image
                                  },
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Fields
                    AuthTextField(
                      controller: _specializationController,
                      label: 'Specialization',
                      icon: Icons.medical_services,
                      // enabled: _isEditing,
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: AuthTextField(
                            controller: _experienceController,
                            label: 'Experience (Years)',
                            icon: Icons.work_history,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: AuthTextField(
                            controller: _feeController,
                            label: 'Consultation Fee (₹)',
                            icon: Icons.currency_rupee,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _aboutController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'About',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    if (_isEditing)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Save Changes'),
                        ),
                      ),

                    if (!_isEditing) ...[
                      const SizedBox(height: 32),
                      OutlinedButton.icon(
                        onPressed: _isLoading ? null : _changePassword,
                        icon: const Icon(Icons.lock_reset),
                        label: const Text('Change Password'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }
}
