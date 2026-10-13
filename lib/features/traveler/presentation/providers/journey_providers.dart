import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/journey_repository.dart';

final ownLiveJourneysProvider = AsyncNotifierProvider.autoDispose<OwnLiveJourneysNotifier, List<Map<String, dynamic>>>(() {
  return OwnLiveJourneysNotifier();
});

class OwnLiveJourneysNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  RealtimeChannel? _channel;

  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final repo = ref.watch(journeyRepositoryProvider);

    // Subscribe to realtime Postgres changes for the journeys table
    final client = Supabase.instance.client;

    _channel = client.channel('public:journey_changes_${user.id}');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'journeys',
      callback: (payload) {
        ref.invalidateSelf();
      },
    ).onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'delivery_matches',
      callback: (payload) {
        ref.invalidateSelf();
      },
    ).subscribe();

    ref.onDispose(() {
      if (_channel != null) {
        client.removeChannel(_channel!);
      }
    });

    return repo.fetchOwnLiveJourneys(user.id);
  }
}
