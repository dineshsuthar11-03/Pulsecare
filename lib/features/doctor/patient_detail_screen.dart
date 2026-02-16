import 'package:flutter/material.dart';
import 'package:carelink/core/constants/app_colors.dart';
import 'package:carelink/core/services/doctor_service.dart';

class PatientDetailScreen extends StatefulWidget {
  final Map<String, dynamic> patient;

  const PatientDetailScreen({super.key, required this.patient});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  final DoctorService _doctorService = DoctorService();
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
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigate to consultation notes / prescription
                    },
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
