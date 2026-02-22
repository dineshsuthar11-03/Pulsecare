import 'package:flutter/material.dart';
import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:pulsecare/core/services/doctor_service.dart';
import 'package:pulsecare/core/services/consultation_service.dart';
import 'package:pulsecare/features/doctor/consultation_detail_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final DoctorService _doctorService = DoctorService();
  final ConsultationService _consultationService = ConsultationService();
  Map<String, dynamic>? _fullProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPatientProfile();
  }

  Future<void> _loadPatientProfile() async {
    final profile = await _doctorService.getPatientProfile(
      widget.patient['id'],
    );
    if (mounted) {
      setState(() {
        _fullProfile = profile;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.patient['full_name'] ?? 'Patient';

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        name[0],
                        style: const TextStyle(
                          fontSize: 40,
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildInfoSection('Basic Information', [
                    _buildInfoRow(
                      Icons.email_outlined,
                      'Email',
                      _fullProfile?['users']?['email'] ?? 'N/A',
                    ),
                    _buildInfoRow(
                      Icons.cake_outlined,
                      'Date of Birth',
                      _fullProfile?['date_of_birth'] ?? 'Not set',
                    ),
                    _buildInfoRow(
                      Icons.person_outline,
                      'Gender',
                      _fullProfile?['gender'] ?? 'Not specified',
                    ),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection('Medical History', [
                    if (_fullProfile?['medical_history'] != null &&
                        (_fullProfile!['medical_history'] as List).isNotEmpty)
                      ...(_fullProfile!['medical_history'] as List).map(
                        (item) => ListTile(
                          leading: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.green,
                          ),
                          title: Text(item.toString()),
                          dense: true,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No medical history records found.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection('Allergies', [
                    if (_fullProfile?['allergies'] != null &&
                        (_fullProfile!['allergies'] as List).isNotEmpty)
                      ...(_fullProfile!['allergies'] as List).map(
                        (item) => ListTile(
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.redAccent,
                          ),
                          title: Text(item.toString()),
                          dense: true,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No recorded allergies.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection('Chronic Conditions', [
                    if (_fullProfile?['chronic_conditions'] != null &&
                        (_fullProfile!['chronic_conditions'] as List)
                            .isNotEmpty)
                      ...(_fullProfile!['chronic_conditions'] as List).map(
                        (item) => ListTile(
                          leading: const Icon(
                            Icons.healing_outlined,
                            color: AppColors.primary,
                          ),
                          title: Text(item.toString()),
                          dense: true,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No chronic conditions recorded.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection('Current Medications', [
                    if (_fullProfile?['current_medications'] != null &&
                        (_fullProfile!['current_medications'] as List)
                            .isNotEmpty)
                      ...(_fullProfile!['current_medications'] as List).map(
                        (item) => ListTile(
                          leading: const Icon(
                            Icons.medication_outlined,
                            color: AppColors.accent,
                          ),
                          title: Text(item.toString()),
                          dense: true,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No current medications recorded.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection('Past Surgeries', [
                    if (_fullProfile?['surgeries'] != null &&
                        (_fullProfile!['surgeries'] as List).isNotEmpty)
                      ...(_fullProfile!['surgeries'] as List).map(
                        (item) => ListTile(
                          leading: const Icon(
                            Icons.local_hospital_outlined,
                            color: Colors.purple,
                          ),
                          title: Text(item.toString()),
                          dense: true,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No surgeries recorded.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 24),
                  _buildInfoSection('Family History', [
                    if ((_fullProfile?['family_history'] ?? '').toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          _fullProfile!['family_history'].toString(),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'No family history recorded.',
                          style: TextStyle(fontStyle: FontStyle.italic),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _openLatestConsultationForNotes,
                    icon: const Icon(Icons.edit_note),
                    label: const Text('Add Consultation Note'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Future<void> _openLatestConsultationForNotes() async {
    try {
      final consultations = await _consultationService.getConsultations();
      final patientId = widget.patient['id']?.toString();

      if (patientId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Patient ID not available for this record.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final related = consultations
          .where((c) => c['patient_id']?.toString() == patientId)
          .toList();

      if (related.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No consultations found with this patient yet.'),
          ),
        );
        return;
      }

      // Pick the latest by scheduled_at
      related.sort((a, b) {
        final da = DateTime.parse(a['scheduled_at']);
        final db = DateTime.parse(b['scheduled_at']);
        return db.compareTo(da);
      });

      final latest = related.first;

      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ConsultationDetailScreen(
            consultation: latest,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open consultation note: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey.shade600, size: 20),
      title: Text(
        label,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      subtitle: Text(
        value,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Colors.black,
        ),
      ),
      dense: true,
    );
  }
}
