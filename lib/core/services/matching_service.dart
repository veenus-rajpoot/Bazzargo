import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchingService {
  /// Checks similarity between two locations (e.g. pickup vs from, drop vs to)
  /// Checks substring matches, exact matches, and word-level overlaps (length >= 3).
  static int levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = _min3(v1[j] + 1, v0[j + 1] + 1, v0[j] + cost);
      }

      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }

  static int _min3(int a, int b, int c) {
    int m = a;
    if (b < m) m = b;
    if (c < m) m = c;
    return m;
  }

  /// Checks similarity between two locations (e.g. pickup vs from, drop vs to)
  /// Incorporates exact matches, substring containment, and typo-tolerant Levenshtein similarity.
  static bool locationsMatch(String loc1, String loc2) {
    final clean1 = loc1.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();
    final clean2 = loc2.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').trim();

    if (clean1.isEmpty || clean2.isEmpty) return false;
    
    // 1. Exact match
    if (clean1 == clean2) return true;
    
    // 2. Substring match for longer words
    if ((clean1.length >= 4 && clean2.contains(clean1)) || 
        (clean2.length >= 4 && clean1.contains(clean2))) {
      return true;
    }

    // 3. Word-level similarity check (handling typos per word)
    final words1 = clean1.split(RegExp(r'\s+')).where((w) => w.length >= 3).toList();
    final words2 = clean2.split(RegExp(r'\s+')).where((w) => w.length >= 3).toList();

    for (final w1 in words1) {
      for (final w2 in words2) {
        final dist = levenshtein(w1, w2);
        final maxLen = w1.length > w2.length ? w1.length : w2.length;
        final sim = 1.0 - (dist / maxLen);
        if (sim >= 0.70) { // 70% similarity threshold for word matching
          return true;
        }
      }
    }

    // 4. Whole string similarity check
    final wholeDist = levenshtein(clean1, clean2);
    final maxWholeLen = clean1.length > clean2.length ? clean1.length : clean2.length;
    final wholeSim = 1.0 - (wholeDist / maxWholeLen);
    return wholeSim >= 0.70;
  }

  /// Triggers matching when a customer posts a delivery request.
  /// Checks against all live traveler journeys.
  static Future<void> performMatchingForRequest(Map<String, dynamic> request) async {
    try {
      final client = Supabase.instance.client;
      final requestId = request['id'];
      final senderId = request['sender_id'];
      final pickup = request['pickup_location'] as String? ?? '';
      final drop = request['drop_location'] as String? ?? '';

      if (pickup.isEmpty || drop.isEmpty) return;

      // Query all live journeys where the traveler is not the sender
      final journeys = await client
          .from('journeys')
          .select()
          .eq('status', 'live')
          .neq('traveler_id', senderId);

      for (final journey in journeys) {
        final fromLoc = journey['from_location'] as String? ?? '';
        final toLoc = journey['to_location'] as String? ?? '';

        if (locationsMatch(pickup, fromLoc) && locationsMatch(drop, toLoc)) {
          // Found a match! Insert into delivery_matches
          final matchData = await client
              .from('delivery_matches')
              .insert({
                'journey_id': journey['id'],
                'delivery_request_id': requestId,
                'status': 'pending',
              })
              .select()
              .maybeSingle();

          if (matchData != null) {
            final matchId = matchData['id'];

            // Insert notification for the traveler
            await client.from('notifications').insert({
              'user_id': journey['traveler_id'],
              'title': 'New Delivery Match Found!',
              'message': 'A package matches your route from $fromLoc to $toLoc.',
              'type': 'match_found',
              'related_id': matchId,
            });

            // Insert notification for the customer
            await client.from('notifications').insert({
              'user_id': senderId,
              'title': 'Traveler Found for your Parcel!',
              'message': 'A traveler is going from $pickup to $drop.',
              'type': 'match_found',
              'related_id': matchId,
            });
          }
        }
      }
    } catch (e) {
      // Fail silently or log in debug
      debugPrint('Matching error for request: $e');
    }
  }

  /// Triggers matching when a traveler posts a journey.
  /// Checks against all pending customer delivery requests.
  static Future<void> performMatchingForJourney(Map<String, dynamic> journey) async {
    try {
      final client = Supabase.instance.client;
      final journeyId = journey['id'];
      final travelerId = journey['traveler_id'];
      final fromLoc = journey['from_location'] as String? ?? '';
      final toLoc = journey['to_location'] as String? ?? '';

      if (fromLoc.isEmpty || toLoc.isEmpty) return;

      // Query all pending requests where sender is not this traveler
      final requests = await client
          .from('delivery_requests')
          .select()
          .eq('status', 'pending')
          .neq('sender_id', travelerId);

      for (final request in requests) {
        final pickup = request['pickup_location'] as String? ?? '';
        final drop = request['drop_location'] as String? ?? '';

        if (locationsMatch(pickup, fromLoc) && locationsMatch(drop, toLoc)) {
          // Found a match! Insert into delivery_matches
          final matchData = await client
              .from('delivery_matches')
              .insert({
                'journey_id': journeyId,
                'delivery_request_id': request['id'],
                'status': 'pending',
              })
              .select()
              .maybeSingle();

          if (matchData != null) {
            final matchId = matchData['id'];

            // Insert notification for the traveler
            await client.from('notifications').insert({
              'user_id': travelerId,
              'title': 'New Delivery Match Found!',
              'message': 'A package matches your route from $fromLoc to $toLoc.',
              'type': 'match_found',
              'related_id': matchId,
            });

            // Insert notification for the customer
            await client.from('notifications').insert({
              'user_id': request['sender_id'],
              'title': 'Traveler Found for your Parcel!',
              'message': 'A traveler is going from $pickup to $drop.',
              'type': 'match_found',
              'related_id': matchId,
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Matching error for journey: $e');
    }
  }
}
