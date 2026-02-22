import 'package:supabase_flutter/supabase_flutter.dart';

class ReviewService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> submitReview({
    required String consultationId,
    required String doctorId,
    required int rating,
    String? comment,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw 'User not authenticated';
    }

    try {
      await _supabase.from('consultation_reviews').insert({
        'consultation_id': consultationId,
        'doctor_id': doctorId,
        'patient_id': user.id,
        'rating': rating,
        'comment': comment,
      });
    } catch (e) {
      print('Error submitting review: $e');
      throw 'Failed to submit review';
    }
  }

  Future<List<Map<String, dynamic>>> getReviewsForCurrentDoctor() async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw 'User not authenticated';
    }

    try {
      final response = await _supabase
          .from('consultation_reviews')
          .select(
              'rating, comment, created_at, consultation_id, patient:patients(users(full_name))')
          .eq('doctor_id', user.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching doctor reviews: $e');
      return [];
    }
  }
}
