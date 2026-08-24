import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/constants/app_constants.dart';
import 'app/router/app_router.dart';
import 'app/theme/light_theme.dart';
import 'app/theme/dark_theme.dart';
import 'core/supabase_client.dart';
import 'core/providers/theme_provider.dart';

void main() async {
  // Ensure Flutter widgets binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Local Caching (Hive)
  await Hive.initFlutter();

  // Initialize Supabase Auth & Database client
  await SupabaseClientHelper.initialize();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
