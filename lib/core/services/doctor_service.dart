import 'package:supabase_flutter/supabase_flutter.dart';

class DoctorService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get doctor profile
  Future<Map<String, dynamic>?> getDoctorProfile(String id) async {
    try {
      final response = await _supabase
          .from('doctors')
          .select('*, users(full_name, email)')
          .eq('id', id)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting doctor profile: $e');
      return null;
    }
  }

  // Update doctor profile
  Future<void> updateDoctorProfile({
    required String id,
    String? specialization,
    int? experienceYears,
    double? consultationFee,
    String? bio,
    Map<String, dynamic>? availability,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (specialization != null) data['specialization'] = specialization;
      if (experienceYears != null) data['experience_years'] = experienceYears;
      if (consultationFee != null) data['consultation_fee'] = consultationFee;
      if (bio != null) data['about'] = bio; // matching about column in schema
      if (availability != null) data['availability'] = availability;

      await _supabase.from('doctors').update(data).eq('id', id);
    } catch (e) {
      print('Error updating doctor profile: $e');
      throw 'Failed to update profile';
    }
  }

  // Submit for verification (Mock)
  Future<void> submitForVerification(String id) async {
    try {
      await _supabase
          .from('doctors')
          .update({'verification_status': 'pending'})
          .eq('id', id);
    } catch (e) {
      print('Error submitting for verification: $e');
      throw 'Failed to submit for verification';
    }
  }

  // Get patient profile for doctor
  Future<Map<String, dynamic>?> getPatientProfile(String patientId) async {
    try {
      final response = await _supabase
          .from('patients')
          .select('*, users(full_name, email)')
          .eq('id', patientId)
          .maybeSingle();
      return response;
    } catch (e) {
      print('Error getting patient profile: $e');
      return null;
    }
  }
}
