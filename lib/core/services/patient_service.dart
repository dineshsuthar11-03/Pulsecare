import 'package:supabase_flutter/supabase_flutter.dart';

class PatientService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, dynamic>?> getMyProfile() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('patients')
          .select('*, users(full_name, email)')
          .eq('id', user.id)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response as Map);
    } catch (e) {
      print('Error getting patient profile: $e');
      return null;
    }
  }

  Future<void> updateMyProfile({
    DateTime? dateOfBirth,
    String? gender,
    List<String>? medicalHistory,
    List<String>? allergies,
    List<String>? chronicConditions,
    List<String>? currentMedications,
    List<String>? surgeries,
    String? familyHistory,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw 'User not authenticated';
    }

    final data = <String, dynamic>{};
    if (dateOfBirth != null) {
      data['date_of_birth'] = dateOfBirth.toIso8601String();
    }
    if (gender != null) {
      data['gender'] = gender;
    }
    if (medicalHistory != null) {
      data['medical_history'] = medicalHistory;
    }
    if (allergies != null) {
      data['allergies'] = allergies;
    }
    if (chronicConditions != null) {
      data['chronic_conditions'] = chronicConditions;
    }
    if (currentMedications != null) {
      data['current_medications'] = currentMedications;
    }
    if (surgeries != null) {
      data['surgeries'] = surgeries;
    }
    if (familyHistory != null) {
      data['family_history'] = familyHistory;
    }

    if (data.isEmpty) return;

    try {
      await _supabase
          .from('patients')
          .update(data)
          .eq('id', user.id);
    } catch (e) {
      print('Error updating patient profile: $e');
      throw 'Failed to update health profile';
    }
  }
}
