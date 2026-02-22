import 'package:flutter/material.dart';
import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:pulsecare/core/services/auth_service.dart';
import 'package:pulsecare/core/services/backend_auth_service.dart';
import 'package:pulsecare/core/services/patient_service.dart';
import 'package:pulsecare/features/auth/otp_verification_screen.dart';

class PatientProfileScreen extends StatefulWidget {
  const PatientProfileScreen({super.key});

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  final AuthService _authService = AuthService();
  final BackendAuthService _backendAuthService = BackendAuthService();
  final PatientService _patientService = PatientService();

  bool _isLoading = false; // for password actions
  bool _isProfileLoading = true; // for health profile fetch

  // Health profile controllers
  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _medicalHistoryController =
      TextEditingController();
  final TextEditingController _allergiesController = TextEditingController();
  final TextEditingController _chronicConditionsController =
      TextEditingController();
  final TextEditingController _medicationsController =
      TextEditingController();
  final TextEditingController _surgeriesController = TextEditingController();
  final TextEditingController _familyHistoryController =
      TextEditingController();

  String? _gender;

  @override
  void initState() {
    super.initState();
    _loadHealthProfile();
  }

  @override
  void dispose() {
    _dobController.dispose();
    _medicalHistoryController.dispose();
    _allergiesController.dispose();
    _chronicConditionsController.dispose();
    _medicationsController.dispose();
    _surgeriesController.dispose();
    _familyHistoryController.dispose();
    super.dispose();
  }

  Future<void> _loadHealthProfile() async {
    try {
      final profile = await _patientService.getMyProfile();
      if (!mounted || profile == null) {
        setState(() => _isProfileLoading = false);
        return;
      }

      final dob = profile['date_of_birth']?.toString();
      final gender = profile['gender']?.toString();

      final List<dynamic>? historyList = profile['medical_history'] as List?;
      final List<dynamic>? allergiesList = profile['allergies'] as List?;
      final List<dynamic>? chronicList = profile['chronic_conditions'] as List?;
      final List<dynamic>? medsList = profile['current_medications'] as List?;
      final List<dynamic>? surgeriesList = profile['surgeries'] as List?;

      setState(() {
        _dobController.text = dob ?? '';
        _gender = gender;
        _medicalHistoryController.text =
            historyList != null ? historyList.join(', ') : '';
        _allergiesController.text =
            allergiesList != null ? allergiesList.join(', ') : '';
        _chronicConditionsController.text =
            chronicList != null ? chronicList.join(', ') : '';
        _medicationsController.text =
            medsList != null ? medsList.join(', ') : '';
        _surgeriesController.text =
            surgeriesList != null ? surgeriesList.join(', ') : '';
        _familyHistoryController.text =
            profile['family_history']?.toString() ?? '';
        _isProfileLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProfileLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load health profile: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  List<String> _splitToList(String value) {
    return value
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  Future<void> _saveHealthProfile() async {
    setState(() => _isProfileLoading = true);
    try {
      await _patientService.updateMyProfile(
        dateOfBirth:
            _dobController.text.isNotEmpty ? DateTime.tryParse(_dobController.text) : null,
        gender: _gender,
        medicalHistory: _splitToList(_medicalHistoryController.text),
        allergies: _splitToList(_allergiesController.text),
        chronicConditions: _splitToList(_chronicConditionsController.text),
        currentMedications: _splitToList(_medicationsController.text),
        surgeries: _splitToList(_surgeriesController.text),
        familyHistory: _familyHistoryController.text.trim().isEmpty
            ? null
            : _familyHistoryController.text.trim(),
      );

      if (mounted) {
        setState(() => _isProfileLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Health profile updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProfileLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update health profile: $e'),
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
    final user = _authService.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: SafeArea(
        child: _isProfileLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.background,
                        child: Icon(Icons.person, size: 50, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      user?.userMetadata?['full_name'] ?? 'Guest User',
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      user?.email ?? '',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Health profile',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _dobController,
                            decoration: const InputDecoration(
                              labelText: 'Date of birth (YYYY-MM-DD)',
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Gender',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: ['Male', 'Female', 'Other']
                                .map(
                                  (g) => ChoiceChip(
                                    label: Text(g),
                                    selected: _gender == g,
                                    onSelected: (selected) {
                                      setState(() => _gender = selected ? g : _gender);
                                    },
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _medicalHistoryController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Past medical history',
                              hintText: 'e.g. Diabetes, Hypertension',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _allergiesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Allergies',
                              hintText: 'e.g. Penicillin, Peanuts',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _chronicConditionsController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Chronic conditions',
                              hintText: 'e.g. Asthma, Thyroid issues',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _medicationsController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Current medications',
                              hintText: 'e.g. Metformin 500mg OD',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _surgeriesController,
                            maxLines: 2,
                            decoration: const InputDecoration(
                              labelText: 'Past surgeries',
                              hintText: 'e.g. Appendectomy 2018',
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _familyHistoryController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Family history',
                              hintText:
                                  'e.g. Father with heart disease, mother with diabetes',
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isProfileLoading ? null : _saveHealthProfile,
                              child: const Text('Save health profile'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 24),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _changePassword,
                      icon: const Icon(Icons.lock_reset),
                      label: const Text('Change Password'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        side: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () async {
                        await _authService.signOut();
                        if (mounted) {
                          Navigator.of(context)
                              .popUntil((route) => route.isFirst);
                        }
                      },
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
