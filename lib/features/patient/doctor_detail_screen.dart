import 'package:flutter/material.dart';
import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:pulsecare/core/services/consultation_backend_service.dart';
import 'package:pulsecare/core/services/consultation_service.dart';
import 'package:pulsecare/features/consultation/widgets/booking_calendar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class DoctorDetailScreen extends StatefulWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailScreen({super.key, required this.doctor});

  @override
  State<DoctorDetailScreen> createState() => _DoctorDetailScreenState();
}

class _DoctorDetailScreenState extends State<DoctorDetailScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isBooking = false;
  DateTime? _pendingScheduledAt;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Premium Sliver App Bar
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [AppColors.primary, AppColors.primaryDark],
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.white24,
                          child: Icon(
                            Icons.person,
                            size: 80,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.doctor['users']?['full_name'] ?? 'Doctor',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.doctor['is_verified'] == true) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                color: Colors.greenAccent,
                                size: 22,
                              ),
                            ],
                          ],
                        ),
                        Text(
                          widget.doctor['specialization'] ?? 'Specialist',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // About Section
                  _buildSectionTitle('About Doctor'),
                  const SizedBox(height: 8),
                  Text(
                    'Dr. ${widget.doctor['users']?['full_name'] ?? 'Doctor'} is a specialized professional with over ${widget.doctor['experience_years'] ?? 5} years of experience in ${widget.doctor['specialization'] ?? 'healthcare'}. They are committed to providing personalized care and advanced treatment solutions.',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Stats section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatCard(
                        Icons.star,
                        'Rating',
                        '${widget.doctor['rating'] ?? 4.8}',
                      ),
                      _buildStatCard(Icons.people, 'Patients', '1,200+'),
                      _buildStatCard(
                        Icons.work,
                        'Exp',
                        '${widget.doctor['experience_years'] ?? 5} yrs',
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Calendar & Time Slots
                  BookingCalendar(
                    onDateSelected: (date) =>
                        setState(() => _selectedDate = date),
                    onTimeSelected: (time) =>
                        setState(() => _selectedTime = time),
                  ),
                  const SizedBox(height: 100), // Padding for Bottom Bar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String label, String value) {
    return Container(
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
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final fee = widget.doctor['consultation_fee'] ?? 500;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Consultation Fee',
                style: TextStyle(color: AppColors.textTertiary),
              ),
              Text(
                '₹$fee',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: ElevatedButton(
              onPressed:
                  (_selectedDate != null &&
                      _selectedTime != null &&
                      !_isBooking)
                  ? _handleBooking
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isBooking
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Book pulseCare Appointment',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBooking() async {
    setState(() => _isBooking = true);

    final scheduledAt = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    _pendingScheduledAt = scheduledAt;

    // Fake payment gateway: show a simple confirmation dialog instead of
    // calling a real payment provider. This keeps the flow similar while
    // you test the rest of the app.
    if (!mounted) {
      setState(() => _isBooking = false);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final fee = (widget.doctor['consultation_fee'] ?? 500).toDouble();
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirm Payment'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pay ₹$fee for your consultation with Dr. '
                "${widget.doctor['users']?['full_name'] ?? ''}.",
              ),
              const SizedBox(height: 12),
              const Text(
                'This is a test payment screen. No real money is charged.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Pay Now'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _createConsultationAfterPayment();
    } else {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  Future<void> _createConsultationAfterPayment() async {
    if (_pendingScheduledAt == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not complete booking: missing schedule info'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isBooking = false);
      }
      return;
    }

    try {
      final fee = (widget.doctor['consultation_fee'] ?? 500).toDouble();
      final scheduledAt = _pendingScheduledAt!;

      final service = ConsultationService();
      final consultation = await service.createConsultation(
        doctorId: widget.doctor['id'],
        scheduledAt: scheduledAt,
        fee: fee,
        symptoms: 'Scheduled Consultation',
      );

      // Trigger backend email notification for patient and doctor
      final user = Supabase.instance.client.auth.currentUser;
      String? emailError;
      if (user != null) {
        final backend = ConsultationBackendService();
        try {
          await backend.sendScheduleEmail(
            patientId: user.id,
            doctorId: widget.doctor['id'],
            scheduledAt: scheduledAt,
            consultationId: consultation['id'] as String?,
            roomCode: consultation['room_code'] as String?,
          );
        } catch (e) {
          emailError = e.toString();
        }
      }

      if (mounted) {
        if (emailError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Appointment booked, but email notification failed: $emailError',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
        _showSuccessDialog();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isBooking = false);
      }
    }
  }

  // The real payment callbacks have been removed in favor of a
  // simple fake payment flow used during development.

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: AppColors.success, size: 80),
            const SizedBox(height: 24),
            const Text(
              'Appointment Booked!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your appointment with Dr. ${widget.doctor['users']?['full_name']} is scheduled for ${DateFormat('MMM dd, hh:mm a').format(_selectedDate!)}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Payment confirmed (test gateway)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
                Navigator.pop(context); // Back to find doctor
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Back to Home',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
