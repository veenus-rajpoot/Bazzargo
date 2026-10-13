import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final journeyRepositoryProvider = Provider<JourneyRepository>((ref) {
  return JourneyRepository(Supabase.instance.client);
});

class JourneyRepository {
  final SupabaseClient _supabase;
  JourneyRepository(this._supabase);

  Future<List<Map<String, dynamic>>> fetchOwnLiveJourneys(String userId) async {
    final List<dynamic> response = await _supabase
        .from('journeys')
        .select('*, delivery_matches(*, delivery_requests(*))')
        .eq('traveler_id', userId)
        .eq('status', 'live')
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> cancelJourney(String journeyId) async {
    // 1. Fetch matches to notify affected customers
    final matches = await _supabase
        .from('delivery_matches')
        .select('*, delivery_requests(*)')
        .eq('journey_id', journeyId);

    for (final match in matches) {
      final matchStatus = match['status'];
      final request = match['delivery_requests'];

      if (matchStatus == 'accepted' && request != null) {
        final requestId = request['id'];
        final customerId = request['sender_id'];
        final pickup = request['pickup_location'];
        final drop = request['drop_location'];

        // Reset delivery request back to pending so it can be re-matched
        await _supabase
            .from('delivery_requests')
            .update({'status': 'pending'})
            .eq('id', requestId);

        // Notify the customer
        await _supabase.from('notifications').insert({
          'user_id': customerId,
          'title': 'Traveler Cancelled Journey',
          'message': 'Your traveler from $pickup to $drop cancelled. Finding a new match...',
          'type': 'general',
          'related_id': requestId,
        });
      }
    }

    // 2. Reject all associated matches
    await _supabase
        .from('delivery_matches')
        .update({'status': 'rejected'})
        .eq('journey_id', journeyId);

    // 3. Mark journey status as 'cancelled'
    await _supabase
        .from('journeys')
        .update({'status': 'cancelled'})
        .eq('id', journeyId);
  }
}
