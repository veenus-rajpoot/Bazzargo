import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/chat_repository.dart';

// ─── Chat Room Provider ────────────────────────────────────────────────────────

final chatRoomProvider = FutureProvider.family<Map<String, dynamic>?, String>(
  (ref, deliveryRequestId) async {
    final repo = ref.read(chatRepositoryProvider);
    return repo.getChatRoom(deliveryRequestId);
  },
);

// ─── Chat Messages Provider (Realtime) ────────────────────────────────────────

final chatMessagesProvider = AsyncNotifierProvider.autoDispose
    .family<ChatMessagesNotifier, List<Map<String, dynamic>>, String>(
  () => ChatMessagesNotifier(),
);

class ChatMessagesNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<Map<String, dynamic>>, String> {
  RealtimeChannel? _channel;

  @override
  FutureOr<List<Map<String, dynamic>>> build(String roomId) async {
    final repo = ref.watch(chatRepositoryProvider);
    final client = Supabase.instance.client;

    // Subscribe to realtime inserts on chat_messages
    _channel = client.channel('chat_room_$roomId');
    _channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            // Append the new message to state without re-fetching all messages
            final current = state.valueOrNull ?? [];
            final newMsg = Map<String, dynamic>.from(payload.newRecord);
            state = AsyncValue.data([...current, newMsg]);
          },
        )
        .subscribe();

    ref.onDispose(() {
      if (_channel != null) {
        client.removeChannel(_channel!);
      }
    });

    return repo.getMessages(roomId);
  }
}

// ─── Unread Count Provider ─────────────────────────────────────────────────────

final chatUnreadCountProvider =
    FutureProvider.family<int, ({String roomId, String userId})>(
  (ref, args) async {
    final repo = ref.read(chatRepositoryProvider);
    return repo.getUnreadCount(roomId: args.roomId, userId: args.userId);
  },
);
