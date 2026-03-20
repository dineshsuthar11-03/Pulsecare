import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pulsecare/core/services/consultation_backend_service.dart';

class ConsultationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ConsultationBackendService _backend = ConsultationBackendService();

  // Create a new consultation
  Future<Map<String, dynamic>> createConsultation({
    required String doctorId,
    required DateTime scheduledAt,
    required double fee,
    String? symptoms,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw 'User not authenticated';
    }

    try {
      return await _backend.createConsultation(
        patientId: user.id,
        doctorId: doctorId,
        scheduledAt: scheduledAt,
        fee: fee,
        symptoms: symptoms,
      );
    } catch (e) {
      print('Error creating consultation: $e');
      throw 'Failed to book appointment: $e';
    }
  }

  // Get consultations for the current user (as patient or doctor)
  Future<List<Map<String, dynamic>>> getConsultations() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw 'User not authenticated';
    }

    try {
      return await _backend.getConsultations(userId: user.id);
    } catch (e) {
      print('Error fetching consultations: $e');
      return [];
    }
  }

  // Update consultation status (for doctors)
  Future<void> updateStatus(String id, String status) async {
    try {
      await _backend.updateConsultation(id: id, status: status);
    } catch (e) {
      print('Error updating status: $e');
      throw 'Failed to update status';
    }
  }

  // Update consultation notes and prescription (for doctors)
  Future<void> updateDetails({
    required String id,
    String? notes,
    String? prescription,
    String? status,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (notes != null) data['notes'] = notes;
      if (prescription != null) data['prescription'] = prescription;
      if (status != null) data['status'] = status;

      if (data.isEmpty) return;

      await _backend.updateConsultation(
        id: id,
        status: status,
        notes: notes,
        prescription: prescription,
      );
    } catch (e) {
      print('Error updating consultation details: $e');
      throw 'Failed to update consultation details';
    }
  }
}
