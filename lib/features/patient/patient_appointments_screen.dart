import 'package:flutter/material.dart';
import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:pulsecare/features/patient/consultation_record_screen.dart';
import 'package:pulsecare/core/services/consultation_service.dart';
import 'package:pulsecare/core/services/review_service.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class PatientAppointmentsScreen extends StatefulWidget {
  const PatientAppointmentsScreen({super.key});

  @override
  State<PatientAppointmentsScreen> createState() =>
      _PatientAppointmentsScreenState();
}

class _PatientAppointmentsScreenState extends State<PatientAppointmentsScreen> {
  final ConsultationService _service = ConsultationService();
  bool _isLoading = true;
  List<Map<String, dynamic>> _appointments = [];
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    setState(() => _isLoading = true);
    try {
      final results = await _service.getConsultations();
      if (!mounted) return;
      setState(() {
        _appointments = results;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _appointments = [];
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load appointments: $e'),
          backgroundColor: AppColors.error,
        ),
      );
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
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My appointments',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Track and join your consultations.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon:
                          const Icon(Icons.refresh, color: Colors.white70),
                      onPressed: _fetchAppointments,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildFilterChip('All'),
                      _buildFilterChip('Upcoming'),
                      _buildFilterChip('Completed'),
                      _buildFilterChip('Cancelled'),
                    ],
                  ),
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
                  child: RefreshIndicator(
                    onRefresh: _fetchAppointments,
                    child: _buildAppointmentsBody(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentsBody() {
    if (_isLoading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 200),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    if (_appointments.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 140),
          _buildEmptyState(),
        ],
      );
    }

    final now = DateTime.now();
    final filtered = _appointments.where((appt) {
      final status = (appt['status'] ?? '').toString().toLowerCase();
      final scheduledAt = DateTime.parse(appt['scheduled_at']);

      switch (_filter) {
        case 'Upcoming':
          return scheduledAt.isAfter(now) && status != 'cancelled';
        case 'Completed':
          return status == 'completed';
        case 'Cancelled':
          return status == 'cancelled';
        default:
          return true;
      }
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final appt = filtered[index];
        return _buildAppointmentCard(appt);
      },
    );
  }

  Widget _buildFilterChip(String label) {
    final bool selected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _filter = label),
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontSize: 12,
      ),
      backgroundColor: Colors.white,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildEmptyState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(
            Icons.event_busy,
            size: 80,
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'No appointments yet',
          style: TextStyle(
            fontSize: 20,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Schedule your first consultation today',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appt) {
    final doctorName = appt['doctor']?['users']?['full_name'] ?? 'Doctor';
    final DateTime scheduledAt = DateTime.parse(appt['scheduled_at']);
    final status = (appt['status'] ?? 'scheduled').toString().toLowerCase();

    Color statusColor = AppColors.primary;
    if (status == 'completed') statusColor = AppColors.success;
    if (status == 'cancelled') statusColor = AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: const Icon(Icons.person, color: AppColors.primary),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            DateFormat(
                              'EEE, MMM d • hh:mm a',
                            ).format(scheduledAt),
                            style: const TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Row(
                        children: [
                          Icon(
                            Icons.payment,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Payment confirmed (test)',
                            style: TextStyle(
                              color: AppColors.textTertiary,
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.videocam_outlined,
                      color: AppColors.accent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'PulseCare Video',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ConsultationRecordScreen(
                              consultation: appt,
                            ),
                          ),
                        );
                      },
                      child: const Text('View record'),
                    ),
                  ],
                ),
                if (scheduledAt.isAfter(DateTime.now()) &&
                    (status == 'scheduled' || status == 'ongoing'))
                  ElevatedButton(
                    onPressed: () => _startCallAndReview(appt),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Join Call'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startCallAndReview(Map<String, dynamic> appt) async {
    try {
      final consultationId = appt['id']?.toString();
      if (consultationId == null) {
        return;
      }

      final status = (appt['status'] ?? 'scheduled').toString().toLowerCase();
      if (status == 'cancelled' || status == 'completed') {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This consultation is not active for joining.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final roomCode = (appt['room_code'] ?? 'consult_$consultationId')
          .toString();
      final meetingUrl =
          'https://8x8.vc/vpaas-magic-cookie-948f154a99304c5ba7989ca1f6055ef6/$roomCode';

      final uri = Uri.parse(meetingUrl);
      await launchUrl(uri, mode: LaunchMode.platformDefault);

      if (!mounted) return;
      await _showReviewDialog(appt);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open video call: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _showReviewDialog(Map<String, dynamic> appt) async {
    int rating = 0;
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rate your consultation'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final starIndex = index + 1;
                  return IconButton(
                    icon: Icon(
                      starIndex <= rating
                          ? Icons.star
                          : Icons.star_border,
                      color: Colors.amber,
                    ),
                    onPressed: () {
                      rating = starIndex;
                      (context as Element).markNeedsBuild();
                    },
                  );
                }),
              ),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Optional feedback',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Skip'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (rating == 0) {
                  Navigator.of(context).pop();
                  return;
                }

                try {
                  final consultationId = appt['id']?.toString();
                  final doctorId = appt['doctor_id']?.toString();
                  if (consultationId != null && doctorId != null) {
                    final service = ReviewService();
                    await service.submitReview(
                      consultationId: consultationId,
                      doctorId: doctorId,
                      rating: rating,
                      comment:
                          controller.text.trim().isEmpty ? null : controller.text.trim(),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to submit review: $e'),
                      backgroundColor: AppColors.error,
                    ),
                  );
                } finally {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Submit'),
            ),
          ],
        );
      },
    );
  }
}
