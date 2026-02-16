import 'package:flutter/material.dart';
import 'package:carelink/core/constants/app_colors.dart';
import 'package:carelink/core/services/auth_service.dart';
import 'package:carelink/features/auth/role_selection_screen.dart';
import 'package:carelink/features/doctor/doctor_profile_screen.dart';
import 'package:carelink/features/doctor/availability_screen.dart';
import 'package:carelink/features/doctor/consultations_screen.dart';
import 'package:carelink/core/services/doctor_service.dart';
import 'package:carelink/core/services/consultation_service.dart';

class DoctorDashboardScreen extends StatefulWidget {
  const DoctorDashboardScreen({super.key});

  @override
  State<DoctorDashboardScreen> createState() => _DoctorDashboardScreenState();
}

class _DoctorDashboardScreenState extends State<DoctorDashboardScreen> {
  final AuthService _authService = AuthService();
  final DoctorService _doctorService = DoctorService();
  final ConsultationService _consultationService = ConsultationService();

  bool _isLoading = true;
  String _verificationStatus = 'pending';
  int _patientCount = 0;
  double _earnings = 0.0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    final user = _authService.currentUser;
    if (user == null) return;

    try {
      final profile = await _doctorService.getDoctorProfile(user.id);
      final consults = await _consultationService.getConsultations();

      if (mounted) {
        setState(() {
          _verificationStatus = profile?['verification_status'] ?? 'pending';
          _patientCount = consults.length;
          _earnings = consults.fold(
            0.0,
            (sum, item) =>
                sum + (double.tryParse(item['fee'].toString()) ?? 0.0),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DoctorProfileScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(
                    builder: (context) => const RoleSelectionScreen(),
                  ),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_verificationStatus != 'verified')
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verification Pending',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text(
                            'Complete your profile to start accepting consultations.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const DoctorProfileScreen(),
                          ),
                        );
                      },
                      child: const Text('Complete'),
                    ),
                  ],
                ),
              ),

            // Stats Row
            Row(
              children: [
                _buildStatCard(
                  'Earnings',
                  '₹${_earnings.toStringAsFixed(0)}',
                  Icons.currency_rupee,
                  Colors.green,
                ),
                const SizedBox(width: 16),
                _buildStatCard(
                  'Patients',
                  '$_patientCount',
                  Icons.people_outline,
                  Colors.blue,
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildActionCard(
                  'Availability',
                  Icons.calendar_month,
                  AppColors.primary,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AvailabilityScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  'Consultations',
                  Icons.video_call,
                  AppColors.accent,
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConsultationsScreen(),
                      ),
                    );
                  },
                ),
                _buildActionCard(
                  'Reviews',
                  Icons.star_outline,
                  Colors.amber,
                  () {
                    // Navigate to reviews
                  },
                ),
                _buildActionCard(
                  'Settings',
                  Icons.settings_outlined,
                  Colors.grey,
                  () {
                    // Navigate to settings
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
