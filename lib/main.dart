import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/constants/app_constants.dart';
import 'app/router/app_router.dart';
import 'app/theme/light_theme.dart';
import 'app/theme/dark_theme.dart';
import 'core/services/notification_service.dart';
import 'core/services/session_service.dart';
import 'core/supabase_client.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  // Ensure Flutter widgets binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Caching (Hive)
  await Hive.initFlutter();

  // Pre-open all session and local storage boxes
  await SessionService.initialize();

  // Validate session against the 1-month inactivity threshold
  SessionService.validateAndUpdateSession();

  // Initialize Supabase Auth & Database client
  await SupabaseClientHelper.initialize();

  // Initialize Local Notifications
  await NotificationService.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Validate session and record user activity when returning to app
      SessionService.validateAndUpdateSession();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Themes from Premium Emerald Fintech tokens
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,

      // Routing configuration via GoRouter
      routerConfig: router,
    );
  }
}
