import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'package:firebase_core/firebase_core.dart';

import 'core/config/app_config.dart';
import 'core/services/fcm_service.dart';
import 'core/services/network_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';
import 'data/repositories/announcement_repository.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/comment_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'data/repositories/report_repository.dart';
import 'data/services/supabase_service.dart';
import 'features/announcements/controllers/announcement_controller.dart';
import 'features/auth/controllers/auth_controller.dart';
import 'features/auth/screens/app_gate.dart';
import 'features/feed/controllers/feed_controller.dart';
import 'features/navigation/controllers/navigation_controller.dart';
import 'features/notifications/controllers/notification_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Indonesian locale formatting for DateFormat
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('DateFormat locale initialization: $e');
  }

  // Tune Flutter image cache for low-end device memory safety (35 MB max memory, 100 items)
  PaintingBinding.instance.imageCache.maximumSizeBytes = 35 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 100;

  // Safely load .env and initialize Supabase client
  await AppConfig.initialize();
  await SupabaseService.instance.initialize();

  // Initialize Firebase and Cloud Messaging
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await FcmService.instance.initialize();
  } catch (e) {
    debugPrint('Firebase/FCM initialization notice: $e');
  }

  // Initialize native Google Sign-In with platform-safe configuration
  try {
    await GoogleSignIn.instance.initialize(
      clientId: kIsWeb
          ? (AppConfig.googleWebClient.isNotEmpty
                ? AppConfig.googleWebClient
                : null)
          : (AppConfig.googleIosClient.isNotEmpty
                ? AppConfig.googleIosClient
                : null),
      serverClientId: !kIsWeb && AppConfig.googleWebClient.isNotEmpty
          ? AppConfig.googleWebClient
          : null,
    );
  } catch (e) {
    debugPrint('Google Sign-In initialization: $e');
  }

  // Restore authenticated session from Supabase local storage before first frame
  final authRepository = AuthRepository();
  await authRepository.initSessionFromSupabase();

  // Initialize network connectivity monitoring
  await NetworkService.instance.initialize();

  runApp(LaporinApp(authRepository: authRepository));
}

/// Custom ScrollBehavior that enables AlwaysScrollableScrollPhysics across platforms,
/// allowing RefreshIndicator / swipe-to-refresh to trigger smoothly on Android release builds
/// even when the list content is empty or does not exceed the viewport.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics());
  }
}

class LaporinApp extends StatelessWidget {
  const LaporinApp({
    super.key,
    this.authRepository,
    this.reportRepository,
    this.announcementRepository,
    this.networkService,
  });

  final AuthRepository? authRepository;
  final ReportRepository? reportRepository;
  final AnnouncementRepository? announcementRepository;
  final NetworkService? networkService;

  @override
  Widget build(BuildContext context) {
    final effectiveNetworkService = networkService ?? NetworkService.instance;

    return MultiProvider(
      providers: [
        // Network connectivity monitoring
        ChangeNotifierProvider<NetworkService>.value(
          value: effectiveNetworkService,
        ),

        // Repositories
        Provider(
          create: (_) {
            if (authRepository != null) return authRepository!;
            final repo = AuthRepository();
            repo.initSessionFromSupabase();
            return repo;
          },
        ),
        Provider(create: (_) => reportRepository ?? ReportRepository()),
        Provider(create: (_) => CommentRepository()),
        Provider(create: (_) => NotificationRepository()),
        Provider(
          create: (_) => announcementRepository ?? AnnouncementRepository(),
        ),

        // Global Controllers
        ChangeNotifierProvider(
          create: (context) =>
              AuthController(authRepository: context.read<AuthRepository>()),
        ),
        ChangeNotifierProvider(
          create: (context) => FeedController(
            reportRepository: context.read<ReportRepository>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => NotificationController(
            repository: context.read<NotificationRepository>(),
          ),
        ),
        ChangeNotifierProvider(create: (context) => NavigationController()),
        ChangeNotifierProvider(
          create: (context) => AnnouncementController(
            repository: context.read<AnnouncementRepository>(),
          )..fetchAnnouncements(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: FcmService.navigatorKey,
        scaffoldMessengerKey: NetworkService.scaffoldMessengerKey,
        navigatorObservers: [NetworkService.routeObserver],
        title: 'Laporin',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        scrollBehavior: const AppScrollBehavior(),
        home: const AppGate(),
      ),
    );
  }
}
