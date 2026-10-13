import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/delivery_repository.dart';

final activeDeliveriesProvider = AsyncNotifierProvider.autoDispose<ActiveDeliveriesNotifier, List<Map<String, dynamic>>>(() {
  return ActiveDeliveriesNotifier();
});

class ActiveDeliveriesNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  RealtimeChannel? _channel;

  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final repo = ref.watch(deliveryRepositoryProvider);

    // Subscribe to realtime Postgres changes for both delivery_requests and delivery_matches
    final client = Supabase.instance.client;
    
    _channel = client.channel('public:delivery_changes_${user.id}');
    _channel!.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'delivery_requests',
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

    return repo.fetchActiveDeliveries(user.id);
  }
}

final unratedDeliveriesProvider = AsyncNotifierProvider.autoDispose<UnratedDeliveriesNotifier, List<Map<String, dynamic>>>(() {
  return UnratedDeliveriesNotifier();
});

class UnratedDeliveriesNotifier extends AutoDisposeAsyncNotifier<List<Map<String, dynamic>>> {
  RealtimeChannel? _channel;

  @override
  FutureOr<List<Map<String, dynamic>>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return [];

    final repo = ref.watch(deliveryRepositoryProvider);

    final client = Supabase.instance.client;
    
    _channel = client.channel('public:unrated_deliveries_${user.id}');
    _channel!.onPostgresChanges(
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

    return repo.fetchUnratedDeliveries(user.id);
  }
}
