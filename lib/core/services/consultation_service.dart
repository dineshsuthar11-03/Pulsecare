import 'package:supabase_flutter/supabase_flutter.dart';

class ConsultationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create a new consultation
  Future<Map<String, dynamic>> createConsultation({
    required String doctorId,
    required DateTime scheduledAt,
    required double fee,
    String? symptoms,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Generate a simple Jitsi room code for this consultation.
      // It must be URL-safe: use only letters, numbers, dashes, underscores.
      final roomCode = 'consult_${DateTime.now().millisecondsSinceEpoch}';

      final response = await _supabase
          .from('consultations')
          .insert({
            'patient_id': user.id,
            'doctor_id': doctorId,
            'scheduled_at': scheduledAt.toIso8601String(),
            'fee': fee,
            'symptoms': symptoms,
            'status': 'scheduled',
            'room_code': roomCode,
          })
          .select()
          .single();

      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('Error creating consultation: $e');
      throw 'Failed to book appointment: $e';
    }
  }

  // Get consultations for the current user (as patient or doctor)
  Future<List<Map<String, dynamic>>> getConsultations() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw 'User not authenticated';

      // Fetch consultations first without the problematic join
      // We keep doctor join as it wasn't reported as broken, but removing patient:users join
      final response = await _supabase
          .from('consultations')
          .select('*, doctor:doctors(users(full_name))')
          .or('patient_id.eq.${user.id},doctor_id.eq.${user.id}')
          .order('scheduled_at', ascending: true);

      final List<Map<String, dynamic>> consultations =
          List<Map<String, dynamic>>.from(response);

      // Manually fetch patient details to fix the missing relationship issue
      final patientIds = consultations
          .map((c) => c['patient_id'] as String?)
          .where((id) => id != null)
          .toSet()
          .toList();

      if (patientIds.isNotEmpty) {
        try {
          // Attempt to fetch from 'users' table
          final patientsResponse = await _supabase
              .from('users')
              .select('id, full_name')
              .filter('id', 'in', patientIds);

          final patientsMap = {for (var p in patientsResponse) p['id']: p};

          for (var c in consultations) {
            if (c['patient_id'] != null &&
                patientsMap.containsKey(c['patient_id'])) {
              c['patient'] = patientsMap[c['patient_id']];
            }
          }
        } catch (e) {
          print('Warning: Could not fetch patient details manually: $e');
          // If public.users doesn't exist or permissions fail, we just leave patient as null
          // The UI handles null/missing patient gracefully (showing "Unknown Patient" or "P")
        }
      }

      return consultations;
    } catch (e) {
      print('Error fetching consultations: $e');
      return [];
    }
  }

  // Update consultation status (for doctors)
  Future<void> updateStatus(String id, String status) async {
    try {
      await _supabase
          .from('consultations')
          .update({'status': status})
          .eq('id', id);
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

      await _supabase
          .from('consultations')
          .update(data)
          .eq('id', id);
    } catch (e) {
      print('Error updating consultation details: $e');
      throw 'Failed to update consultation details';
    }
  }
}
