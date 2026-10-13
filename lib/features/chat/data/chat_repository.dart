import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(Supabase.instance.client);
});

class ChatRepository {
  final SupabaseClient _supabase;
  ChatRepository(this._supabase);

  /// Creates a chat room or returns the existing one for this delivery request.
  Future<Map<String, dynamic>> createOrGetChatRoom({
    required String deliveryRequestId,
    required String matchId,
    required String customerId,
    required String travelerId,
  }) async {
    // ── 1. Return existing room immediately ──────────────────────────────
    final existing = await _supabase
        .from('chat_rooms')
        .select()
        .eq('delivery_request_id', deliveryRequestId)
        .maybeSingle();

    if (existing != null) return Map<String, dynamic>.from(existing);

    // ── 2. Safety net: ensure both users have a profile row ──────────────
    // The chat_rooms table may have a FK to profiles(id).
    // Users who signed in via OTP may not have a profile row yet.
    // We upsert a minimal placeholder so the FK is never violated.
    final currentUser = _supabase.auth.currentUser;
    final myId = currentUser?.id;

    for (final uid in {customerId, travelerId}) {
      if (uid.isEmpty) continue;
      try {
        // Only upsert the bare minimum — full_name and phone can be
        // filled in later by the profile setup flow.
        await _supabase.from('profiles').upsert(
          {
            'id': uid,
            'full_name': uid == myId
                ? (currentUser?.userMetadata?['full_name'] ??
                    currentUser?.phone ??
                    'User')
                : 'User',
            'phone': uid == myId
                ? (currentUser?.phone ?? currentUser?.email ?? uid)
                : uid,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'id',
          ignoreDuplicates: true, // never overwrite real data
        );
      } catch (_) {
        // Silently skip — the profile already exists or there is a
        // permissions issue; either way don't block chat room creation.
      }
    }

    // ── 3. Create the chat room ──────────────────────────────────────────
    final created = await _supabase
        .from('chat_rooms')
        .insert({
          'delivery_request_id': deliveryRequestId,
          'match_id': matchId,
          'customer_id': customerId,
          'traveler_id': travelerId,
        })
        .select()
        .single();

    return Map<String, dynamic>.from(created);
  }

  /// Fetches the chat room for a given delivery request.
  Future<Map<String, dynamic>?> getChatRoom(String deliveryRequestId) async {
    final result = await _supabase
        .from('chat_rooms')
        .select()
        .eq('delivery_request_id', deliveryRequestId)
        .maybeSingle();

    return result != null ? Map<String, dynamic>.from(result) : null;
  }

  /// Fetches all messages for a room, ordered oldest first.
  Future<List<Map<String, dynamic>>> getMessages(String roomId) async {
    final result = await _supabase
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true);

    return List<Map<String, dynamic>>.from(result);
  }

  /// Sends a message to a chat room.
  Future<void> sendMessage({
    required String roomId,
    required String senderId,
    required String message,
    String messageType = 'text',
  }) async {
    // Ensure sender profile exists to avoid FK violation on chat_messages
    final currentUser = _supabase.auth.currentUser;
    if (currentUser != null && currentUser.id == senderId) {
      try {
        await _supabase.from('profiles').upsert(
          {
            'id': senderId,
            'full_name': currentUser.userMetadata?['full_name'] ??
                currentUser.phone ??
                'User',
            'phone':
                currentUser.phone ?? currentUser.email ?? senderId,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'id',
          ignoreDuplicates: true,
        );
      } catch (_) {}
    }

    await _supabase.from('chat_messages').insert({
      'room_id': roomId,
      'sender_id': senderId,
      'message': message.trim(),
      'message_type': messageType,
    });
  }

  /// Uploads an audio file to Supabase storage and returns the public URL.
  Future<String> uploadAudioMessage(String roomId, String filePath) async {
    final file = File(filePath);
    final ext = filePath.split('.').last;
    final fileName = '${const Uuid().v4()}.$ext';
    final storagePath = '$roomId/$fileName';

    await _supabase.storage.from('chat_audio').upload(
          storagePath,
          file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    return _supabase.storage.from('chat_audio').getPublicUrl(storagePath);
  }

  /// Marks all unread messages in a room as read (for the given recipient).
  Future<void> markMessagesRead({
    required String roomId,
    required String recipientId,
  }) async {
    await _supabase
        .from('chat_messages')
        .update({'is_read': true})
        .eq('room_id', roomId)
        .eq('is_read', false)
        .neq('sender_id', recipientId);
  }

  /// Returns the count of unread messages in a room for the current user.
  Future<int> getUnreadCount({
    required String roomId,
    required String userId,
  }) async {
    final result = await _supabase
        .from('chat_messages')
        .select('id')
        .eq('room_id', roomId)
        .eq('is_read', false)
        .neq('sender_id', userId);

    return (result as List).length;
  }
}
