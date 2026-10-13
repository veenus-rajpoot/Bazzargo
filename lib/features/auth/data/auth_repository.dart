import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/services/notification_service.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider).value;
  return authState?.session?.user ?? Supabase.instance.client.auth.currentUser;
});

class AuthRepository {
  final SupabaseClient _supabase;
  AuthRepository(this._supabase);

  Future<AuthResponse> signInWithGoogle({required String webClientId, String? iosClientId}) async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      clientId: iosClientId,
    );
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw Exception('Google sign in was cancelled');
    }
    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw Exception('No ID Token found');
    }

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    // Ensure profile entry exists safely
    if (response.user != null) {
      try {
        final user = response.user!;
        final fullName = user.userMetadata?['full_name'] ?? googleUser.displayName ?? 'Traveler';
        final avatarUrl = user.userMetadata?['avatar_url'] ?? googleUser.photoUrl;
        final intendedPhone = user.phone ?? user.email ?? user.id;

        final existing = await _supabase.from('profiles').select('id').eq('id', user.id).maybeSingle();

        if (existing != null) {
          // Update existing user, but avoid touching 'phone' unless it's a real phone update from user
          await _supabase.from('profiles').update({
            'full_name': fullName,
            'avatar_url': avatarUrl,
            'updated_at': DateTime.now().toIso8601String(),
          }).eq('id', user.id);
        } else {
          // Try to insert new user
          try {
            await _supabase.from('profiles').insert({
              'id': user.id,
              'full_name': fullName,
              'avatar_url': avatarUrl,
              'phone': intendedPhone,
              'updated_at': DateTime.now().toIso8601String(),
            });
          } catch (e) {
            debugPrint('Insert failed (likely duplicate phone/email): $e');
            // Fallback: insert with guaranteed unique phone string
            await _supabase.from('profiles').insert({
              'id': user.id,
              'full_name': fullName,
              'avatar_url': avatarUrl,
              'phone': 'fallback_${user.id}',
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
        }
        
        try {
          await NotificationService().saveTokenToDatabase();
        } catch (e) {
          debugPrint('FCM Token save error: $e');
        }
      } catch (e) {
        debugPrint('Profile sync error: $e');
      }
    }

    return response;
  }

  Future<void> updateProfile({required String fullName}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('No user logged in');

    // Update user metadata in Supabase Auth
    await _supabase.auth.updateUser(UserAttributes(data: {
      'full_name': fullName,
    }));

    // Also update public.profiles table
    try {
      await _supabase.from('profiles').update({
        'full_name': fullName,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', user.id);
    } catch (e) {
      debugPrint('Note: public.profiles table update note: $e');
    }
  }

  Future<void> signOut() async {
    try {
      await NotificationService().clearToken();
    } catch (_) {}
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    await _supabase.auth.signOut();
  }

  Future<void> deleteAccount() async {
    try {
      // Calls a custom Postgres function to delete the auth.users record
      await _supabase.rpc('delete_user_account');
      await signOut();
    } catch (e) {
      debugPrint('Error deleting account: $e');
      throw Exception('Failed to delete account. Please try again or contact support.');
    }
  }
}
