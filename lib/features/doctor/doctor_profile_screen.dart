import 'package:flutter/material.dart';
import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:pulsecare/core/services/auth_service.dart';
import 'package:pulsecare/core/services/backend_auth_service.dart';
import 'package:pulsecare/core/services/doctor_service.dart';
import 'package:pulsecare/features/auth/otp_verification_screen.dart';
import 'package:pulsecare/features/auth/widgets/auth_text_field.dart';

class DoctorProfileScreen extends StatefulWidget {
  const DoctorProfileScreen({super.key});

  @override
  State<DoctorProfileScreen> createState() => _DoctorProfileScreenState();
}

class _DoctorProfileScreenState extends State<DoctorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final DoctorService _doctorService = DoctorService();
  final AuthService _authService = AuthService();
  final BackendAuthService _backendAuthService = BackendAuthService();

  // Controllers
  final _specializationController = TextEditingController();
  final _experienceController = TextEditingController();
  final _feeController = TextEditingController();
  final _aboutController = TextEditingController();
  final _licenseController = TextEditingController();
  final _clinicNameController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = true;
  String _verificationStatus = 'pending';
  bool _isVerified = false;

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
        _aboutController.text = profile['about'] ?? '';
        _licenseController.text = profile['medical_license'] ?? '';
        _clinicNameController.text = profile['clinic_name'] ?? '';
        _verificationStatus = profile['verification_status'] ?? 'pending';
        _isVerified = profile['is_verified'] == true ||
            profile['verification_status'] == 'verified';
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
    _licenseController.dispose();
    _clinicNameController.dispose();
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
        medicalLicense: _licenseController.text.trim(),
        clinicName: _clinicNameController.text.trim(),
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

  Future<void> _submitForVerification() async {
    final user = _authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await _doctorService.submitForVerification(user.id);
      if (mounted) {
        setState(() {
          _verificationStatus = 'pending';
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Verification request submitted. We will review your details.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit for verification: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final user = _authService.currentUser;
    if (user == null || user.email == null) return;

    setState(() => _isLoading = true);

    try {
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
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1F2937),
              Color(0xFF111827),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My profile',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Update how patients see you.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        _isEditing ? Icons.check : Icons.edit,
                        color: Colors.white,
                      ),
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
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                  ),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          padding:
                              const EdgeInsets.fromLTRB(20, 24, 20, 32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
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
                                            backgroundColor:
                                                AppColors.primary,
                                            child: IconButton(
                                              icon: const Icon(
                                                Icons.camera_alt,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                              onPressed: () {
                                                // TODO: implement image picker & upload
                                              },
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black
                                            .withOpacity(0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            _isVerified
                                                ? Icons.verified
                                                : Icons.verified_outlined,
                                            color: _isVerified
                                                ? Colors.green
                                                : Colors.orange,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            _isVerified
                                                ? 'Verified doctor'
                                                : _verificationStatus == 'rejected'
                                                    ? 'Verification rejected – update your details'
                                                    : 'Verification pending / not submitted',
                                            style: TextStyle(
                                              color: _isVerified
                                                  ? Colors.green
                                                  : AppColors.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      AuthTextField(
                                        controller: _specializationController,
                                        label: 'Specialization',
                                        icon: Icons.medical_services,
                                      ),
                                      const SizedBox(height: 16),
                                      AuthTextField(
                                        controller: _licenseController,
                                        label: 'Medical registration number',
                                        icon: Icons.badge,
                                      ),
                                      const SizedBox(height: 16),
                                      AuthTextField(
                                        controller: _clinicNameController,
                                        label: 'Clinic / hospital name',
                                        icon: Icons.local_hospital,
                                      ),
                                      const SizedBox(height: 16),
                                      AuthTextField(
                                        controller: _experienceController,
                                        label: 'Experience (years)',
                                        icon: Icons.work_history,
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 16),
                                      AuthTextField(
                                        controller: _feeController,
                                        label: 'Consultation fee (₹)',
                                        icon: Icons.currency_rupee,
                                        keyboardType: TextInputType.number,
                                      ),
                                      const SizedBox(height: 16),
                                      TextFormField(
                                        controller: _aboutController,
                                        maxLines: 4,
                                        decoration: InputDecoration(
                                          labelText: 'About you',
                                          alignLabelWithHint: true,
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                                if (_isEditing)
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _saveProfile,
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isLoading
                                          ? const CircularProgressIndicator(
                                              color: Colors.white,
                                            )
                                          : const Text('Save changes'),
                                    ),
                                  ),
                                if (!_isEditing) ...[
                                  const SizedBox(height: 24),
                                  if (!_isVerified)
                                    SizedBox(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: _isLoading
                                            ? null
                                            : _submitForVerification,
                                        icon: const Icon(Icons.verified_user),
                                        label: const Text('Submit for verification'),
                                        style: ElevatedButton.styleFrom(
                                          padding:
                                              const EdgeInsets.symmetric(vertical: 14),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                        ),
                                      ),
                                    ),
                                  if (!_isVerified)
                                    const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: _isLoading
                                        ? null
                                        : _changePassword,
                                    icon: const Icon(Icons.lock_reset),
                                    label: const Text('Change password'),
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      minimumSize:
                                          const Size(double.infinity, 50),
                                      side: const BorderSide(
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
