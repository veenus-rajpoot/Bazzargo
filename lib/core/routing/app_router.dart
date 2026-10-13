import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/auth/presentation/screens/language_selection_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/otp_screen.dart';
import '../../features/auth/presentation/screens/profile_setup_screen.dart';
import '../../features/home/presentation/screens/main_scaffold.dart';
import '../../features/traveler/presentation/screens/post_journey_screen.dart';
import '../../features/sender/presentation/screens/send_parcel_screen.dart';
import '../../features/home/presentation/screens/notifications_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';

final appRouter = GoRouter(
  initialLocation: Supabase.instance.client.auth.currentSession != null ? '/home' : '/language',
  routes: [
    GoRoute(
      path: '/language',
      builder: (context, state) => const LanguageSelectionScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final phoneNumber = state.extra as String? ?? '';
        return OtpScreen(phoneNumber: phoneNumber);
      },
    ),
    GoRoute(
      path: '/profile-setup',
      builder: (context, state) => const ProfileSetupScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainScaffold(),
    ),
    GoRoute(
      path: '/post-journey',
      builder: (context, state) => const PostJourneyScreen(),
    ),
    GoRoute(
      path: '/send-parcel',
      builder: (context, state) => const SendParcelScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/chat/:deliveryRequestId',
      builder: (context, state) {
        final deliveryRequestId =
            state.pathParameters['deliveryRequestId']!;
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ChatScreen(
          deliveryRequestId: deliveryRequestId,
          roomId: extra['roomId'] as String? ?? '',
          otherUserId: extra['otherUserId'] as String? ?? '',
          otherUserName: extra['otherUserName'] as String? ?? 'User',
          otherUserAvatar: extra['otherUserAvatar'] as String?,
          itemType: extra['itemType'] as String? ?? 'Parcel',
          pickup: extra['pickup'] as String? ?? '',
          drop: extra['drop'] as String? ?? '',
        );
      },
    ),
  ],
);
