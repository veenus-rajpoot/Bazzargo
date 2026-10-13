import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Top-level function to handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Background Firebase init error: $e');
  }
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  FirebaseMessaging get _fcm => FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    try {
      // Set background handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Initialize Local Notifications for foreground display
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/launcher_icon');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(settings: initSettings);

      // Create Android Notification Channel for high importance
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        description: 'This channel is used for important notifications.',
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // Listen to foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        final RemoteNotification? notification = message.notification;
        final AndroidNotification? android = message.notification?.android;

        if (notification != null && android != null) {
          _localNotifications.show(
            id: notification.hashCode,
            title: notification.title,
            body: notification.body,
            notificationDetails: NotificationDetails(
              android: AndroidNotificationDetails(
                channel.id,
                channel.name,
                channelDescription: channel.description,
                icon: '@mipmap/launcher_icon',
              ),
            ),
          );
        }
      });

      // Listen to token refresh
      _fcm.onTokenRefresh.listen((newToken) {
        _syncTokenToSupabase(newToken);
      });

      // Run permission request and initial token sync in background (non-blocking)
      unawaited(_setupPermissionsAndToken());
    } catch (e) {
      debugPrint('NotificationService initialize error: $e');
    }
  }

  Future<void> _setupPermissionsAndToken() async {
    try {
      // Request permission in background
      await _fcm
          .requestPermission(
            alert: true,
            badge: true,
            sound: true,
          )
          .timeout(const Duration(seconds: 4));

      // Save token if user is already logged in
      await saveTokenToDatabase();
    } catch (e) {
      debugPrint('Permission or token sync error: $e');
    }
  }

  Future<void> saveTokenToDatabase() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final token = await _fcm.getToken().timeout(const Duration(seconds: 5));
      if (token != null) {
        await _syncTokenToSupabase(token);
      }
    } catch (e) {
      debugPrint('FCM Token fetch error: $e');
    }
  }

  Future<void> _syncTokenToSupabase(String token) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final fullName = user.userMetadata?['full_name'];
        final Map<String, dynamic> payload = {
          'id': user.id,
          'fcm_token': token,
        };
        if (fullName != null) {
          payload['full_name'] = fullName;
        }
        await Supabase.instance.client
            .from('profiles')
            .upsert(payload)
            .timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint('FCM Token Supabase sync error: $e');
    }
  }

  // Use this when user logs out
  Future<void> clearToken() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('profiles')
            .update({'fcm_token': null})
            .eq('id', userId)
            .timeout(const Duration(seconds: 4));
      }
    } catch (e) {
      debugPrint('Error clearing FCM token: $e');
    }
  }
}
