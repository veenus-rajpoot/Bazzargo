import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>((ref) {
  return DeliveryRepository(Supabase.instance.client);
});

class DeliveryRepository {
  final SupabaseClient _supabase;
  DeliveryRepository(this._supabase);

  Future<List<Map<String, dynamic>>> fetchActiveDeliveries(String userId) async {
    final List<dynamic> response = await _supabase
        .from('delivery_requests')
        .select('*, delivery_matches(*, journeys(*))')
        .eq('sender_id', userId)
        .neq('status', 'cancelled')
        .neq('status', 'delivered')
        .neq('status', 'completed')
        .order('created_at', ascending: false);

    final List<String> travelerIds = [];
    for (final d in response) {
      final matches = d['delivery_matches'] as List<dynamic>? ?? [];
      for (final m in matches) {
        final j = m['journeys'];
        if (j != null && j['traveler_id'] != null) {
          travelerIds.add(j['traveler_id'] as String);
        }
      }
    }

    Map<String, Map<String, dynamic>> profilesMap = {};
    if (travelerIds.isNotEmpty) {
      final profilesRes = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', travelerIds.toSet().toList());
      for (final p in profilesRes) {
        profilesMap[p['id'] as String] = Map<String, dynamic>.from(p);
      }
    }

    final List<Map<String, dynamic>> finalDeliveries = [];
    for (final d in response) {
      final Map<String, dynamic> deliveryCopy = Map<String, dynamic>.from(d);
      final matchesCopy = <Map<String, dynamic>>[];
      final matches = d['delivery_matches'] as List<dynamic>? ?? [];
      for (final m in matches) {
        final Map<String, dynamic> matchCopy = Map<String, dynamic>.from(m);
        final journey = m['journeys'];
        if (journey != null) {
          final Map<String, dynamic> journeyCopy = Map<String, dynamic>.from(journey);
          final travelerId = journey['traveler_id'] as String?;
          if (travelerId != null && profilesMap.containsKey(travelerId)) {
            journeyCopy['profiles'] = profilesMap[travelerId];
          }
          matchCopy['journeys'] = journeyCopy;
        }
        matchesCopy.add(matchCopy);
      }
      deliveryCopy['delivery_matches'] = matchesCopy;
      finalDeliveries.add(deliveryCopy);
    }
    return finalDeliveries;
  }

  Future<void> cancelDeliveryRequest(String requestId) async {
    // 1. Fetch matches to identify if any traveler was accepted
    final matches = await _supabase
        .from('delivery_matches')
        .select('*, journeys(*)')
        .eq('delivery_request_id', requestId);

    for (final m in matches) {
      final matchStatus = m['status'];
      final journey = m['journeys'];
      if (journey == null) continue;
      final travelerId = journey['traveler_id'];

      if (matchStatus == 'accepted') {
        await _supabase.from('notifications').insert({
          'user_id': travelerId,
          'title': 'Delivery Cancelled',
          'message': 'A customer cancelled their parcel request on your route.',
          'type': 'general',
          'related_id': requestId,
        });
      }
    }

    // 2. Reject matches in DB
    await _supabase
        .from('delivery_matches')
        .update({'status': 'rejected'})
        .eq('delivery_request_id', requestId);

    // 3. Mark delivery request status as 'cancelled'
    await _supabase
        .from('delivery_requests')
        .update({'status': 'cancelled'})
        .eq('id', requestId);
  }

  Future<void> sendVerificationPin(String matchId, String customerId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('You must be logged in');
    final travelerName = user.userMetadata?['full_name'] ?? 'your traveler';

    // Generate a secure 5-digit PIN
    final random = Random.secure();
    final pin = (random.nextInt(90000) + 10000).toString(); // e.g. 10000 to 99999

    // Update match with PIN and expiration (valid for 30 mins)
    final expiresAt = DateTime.now().add(const Duration(minutes: 30)).toUtc().toIso8601String();
    
    await _supabase.from('delivery_matches').update({
      'verification_pin': pin,
      'pin_expires_at': expiresAt,
      'verification_status': 'pending',
    }).eq('id', matchId);

    // Send notification to customer
    await _supabase.from('notifications').insert({
      'user_id': customerId,
      'title': 'Delivery Verification Code',
      'message': 'Your verification code is: $pin. Give this to $travelerName to complete the delivery.',
      'type': 'verification',
      'related_id': matchId,
    });
  }

  Future<bool> verifyDelivery(String matchId, String requestId, String journeyId, String enteredPin) async {
    // Fetch match
    final matchRes = await _supabase.from('delivery_matches').select().eq('id', matchId).single();
    
    final storedPin = matchRes['verification_pin'] as String?;
    final expiresStr = matchRes['pin_expires_at'] as String?;
    final status = matchRes['verification_status'] as String?;

    if (storedPin == null || expiresStr == null || status == 'verified') {
      throw Exception('Verification not available or already completed');
    }

    final expiresAt = DateTime.parse(expiresStr);
    if (DateTime.now().isAfter(expiresAt)) {
      throw Exception('PIN has expired. Please resend a new PIN.');
    }

    if (storedPin != enteredPin) {
      throw Exception('Incorrect PIN.');
    }

    final userId = _supabase.auth.currentUser?.id;

    // PIN is correct, update statuses
    await _supabase.from('delivery_matches').update({
      'verification_status': 'verified',
      'status': 'completed',
      'completed_at': DateTime.now().toUtc().toIso8601String(),
      'completed_by': userId,
    }).eq('id', matchId);

    await _supabase.from('delivery_requests').update({'status': 'completed'}).eq('id', requestId);
    await _supabase.from('journeys').update({'status': 'completed'}).eq('id', journeyId);

    return true;
  }

  Future<List<Map<String, dynamic>>> fetchUnratedDeliveries(String userId) async {
    final List<dynamic> response = await _supabase
        .from('delivery_requests')
        .select('*, delivery_matches(*, journeys(*))')
        .eq('sender_id', userId)
        .eq('status', 'completed')
        .order('created_at', ascending: false);

    final List<String> travelerIds = [];
    for (final d in response) {
      final matches = d['delivery_matches'] as List<dynamic>? ?? [];
      for (final m in matches) {
        if (m['status'] == 'completed' && m['is_rated'] != true) {
          final j = m['journeys'];
          if (j != null && j['traveler_id'] != null) {
            travelerIds.add(j['traveler_id'] as String);
          }
        }
      }
    }

    Map<String, Map<String, dynamic>> profilesMap = {};
    if (travelerIds.isNotEmpty) {
      final profilesRes = await _supabase
          .from('profiles')
          .select()
          .inFilter('id', travelerIds.toSet().toList());
      for (final p in profilesRes) {
        profilesMap[p['id'] as String] = Map<String, dynamic>.from(p);
      }
    }

    final List<Map<String, dynamic>> unrated = [];
    for (final req in response) {
      final matches = req['delivery_matches'] as List<dynamic>? ?? [];
      for (final m in matches) {
        if (m['status'] == 'completed' && m['is_rated'] != true) {
          final Map<String, dynamic> deliveryCopy = Map<String, dynamic>.from(req);
          final Map<String, dynamic> matchCopy = Map<String, dynamic>.from(m);
          final journey = m['journeys'];
          if (journey != null) {
            final Map<String, dynamic> journeyCopy = Map<String, dynamic>.from(journey);
            final travelerId = journey['traveler_id'] as String?;
            if (travelerId != null && profilesMap.containsKey(travelerId)) {
              journeyCopy['profiles'] = profilesMap[travelerId];
            }
            matchCopy['journeys'] = journeyCopy;
          }
          deliveryCopy['delivery_matches'] = [matchCopy];
          unrated.add(deliveryCopy);
        }
      }
    }
    return unrated;
  }

  Future<void> rateTraveler(String matchId, String travelerId, int rating) async {
    try {
      await _supabase.rpc('rate_traveler', params: {
        'p_match_id': matchId,
        'p_traveler_id': travelerId,
        'p_rating': rating,
      });
    } catch (e) {
      // Fallback in case the user hasn't created the RPC function yet
      // This will fail if RLS is enabled and strictly enforced, 
      // but we will provide the SQL to the user.
      await _supabase.from('delivery_matches').update({'is_rated': true}).eq('id', matchId);
      final profileRes = await _supabase.from('profiles').select('rating_sum, rating_count').eq('id', travelerId).maybeSingle();
      if (profileRes != null) {
        final currentSum = profileRes['rating_sum'] as int? ?? 0;
        final currentCount = profileRes['rating_count'] as int? ?? 0;

        await _supabase.from('profiles').update({
          'rating_sum': currentSum + rating,
          'rating_count': currentCount + 1,
        }).eq('id', travelerId);
      }
    }
  }
}
