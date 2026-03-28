import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/user_provider.dart';
import 'theme/app_theme.dart';
import 'routes/app_router.dart';
import 'config/supabase_config.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Initialize Firebase & push notification service.
  await NotificationService().initialize();

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

class _MyAppState extends ConsumerState<MyApp> {
  String? _lastLocationSyncUserId;

  @override
  void initState() {
    super.initState();
    NotificationService().setupInteractionHandlers();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    // Register FCM token whenever a user is signed in.
    ref.watch(notificationInitProvider);

    if (userId != null && userId != _lastLocationSyncUserId) {
      _lastLocationSyncUserId = userId;
      Future.microtask(() {
        ref.invalidate(refreshUserLocationProvider);
        ref.read(refreshUserLocationProvider.future);
      });
    }

    return MaterialApp.router(
      title: 'SkillBid',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      routerConfig: AppRouter.router,
    );
  }
}
