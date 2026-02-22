import 'package:flutter/material.dart';
import 'package:pulsecare/core/constants/app_colors.dart';
import 'package:intl/intl.dart';

class ConsultationRecordScreen extends StatelessWidget {
  final Map<String, dynamic> consultation;

  const ConsultationRecordScreen({super.key, required this.consultation});

  @override
  Widget build(BuildContext context) {
    final DateTime scheduledAt = DateTime.parse(consultation['scheduled_at']);
    final doctorName =
        consultation['doctor']?['users']?['full_name'] ?? 'Doctor';
    final status = consultation['status']?.toString() ?? 'scheduled';
    final notes = consultation['notes']?.toString() ?? '';
    final prescription = consultation['prescription']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultation record'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                doctorName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('EEE, MMM d • hh:mm a').format(scheduledAt),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Doctor notes',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  notes.isEmpty
                      ? 'No notes added yet.'
                      : notes,
                  style: const TextStyle(height: 1.4),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Prescription',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  prescription.isEmpty
                      ? 'No prescription available yet.'
                      : prescription,
                  style: const TextStyle(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
