import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/services/notification_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:easy_localization/easy_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize localization prerequisite
  await EasyLocalization.ensureInitialized();

  // Concurrently initialize essential core services in parallel
  await Future.wait([
    dotenv.load(fileName: '.env').catchError((e) {
      debugPrint('dotenv load warning: $e');
    }),
    Firebase.initializeApp().catchError((e) {
      debugPrint('Firebase init warning: $e');
      return Firebase.app();
    }),
    Supabase.initialize(
      url: 'https://cavjvejlywrvbkqiuugi.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNhdmp2ZWpseXdydmJrcWl1dWdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzkwODU5OTEsImV4cCI6MjA5NDY2MTk5MX0.ktFAy81McBcp9_4HVQTm6VxWJSaF_rh0s6KKet9Mmlc',
    ),
  ]);

  // Render first frame immediately
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('hi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: const ProviderScope(child: BazzarGoApp()),
    ),
  );

  // Initialize background notification services non-blockingly after first frame
  unawaited(NotificationService().initialize());
}

class BazzarGoApp extends ConsumerWidget {
  const BazzarGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ScreenUtilInit(
      // Design baseline: 390×844 (mid-range Android / iPhone 14)
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp.router(
          title: 'BazzarGo',
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          routerConfig: appRouter,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}
