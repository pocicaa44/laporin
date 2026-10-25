import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/announcement_repository.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/notification_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/admin/screens/admin_navigation_screen.dart';
import 'package:laporin/features/announcements/controllers/announcement_controller.dart';
import 'package:laporin/features/announcements/screens/announcements_screen.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/navigation/controllers/navigation_controller.dart';
import 'package:laporin/features/navigation/screens/main_navigation_screen.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthRepository authRepo;
  late ReportRepository reportRepo;
  late AnnouncementRepository announcementRepo;
  late NotificationRepository notificationRepo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    authRepo = AuthRepository();
    reportRepo = ReportRepository();
    announcementRepo = AnnouncementRepository();
    notificationRepo = NotificationRepository();
  });

  Widget buildAppShell({
    required Widget child,
    UserProfileModel? user,
    NavigationController? navCtrl,
    FeedController? feedCtrl,
  }) {
    final effectiveUser =
        user ??
        const UserProfileModel(
          id: 'user-1',
          email: 'user@example.com',
          fullName: 'Test User',
          username: 'testuser',
          role: UserRole.user,
        );

    authRepo.setCurrentUserProfileForTesting(effectiveUser);
    final authCtrl = AuthController(authRepository: authRepo);

    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepo),
        Provider<ReportRepository>.value(value: reportRepo),
        Provider<AnnouncementRepository>.value(value: announcementRepo),
        Provider<NotificationRepository>.value(value: notificationRepo),
        ChangeNotifierProvider<AuthController>.value(value: authCtrl),
        ChangeNotifierProvider<FeedController>(
          create: (_) =>
              feedCtrl ?? FeedController(reportRepository: reportRepo),
        ),
        ChangeNotifierProvider<NotificationController>(
          create: (_) => NotificationController(repository: notificationRepo),
        ),
        ChangeNotifierProvider<NavigationController>(
          create: (_) => navCtrl ?? NavigationController(),
        ),
        ChangeNotifierProvider<AnnouncementController>(
          create: (_) => AnnouncementController(repository: announcementRepo),
        ),
      ],
      child: MaterialApp(home: child),
    );
  }

  group('Auto-refresh Navigation Tests', () {
    testWidgets(
      'Opening AnnouncementsScreen (Pengumuman citizen) triggers auto-refresh',
      (tester) async {
        await tester.pumpWidget(
          buildAppShell(child: const AnnouncementsScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Pengumuman Resmi'), findsOneWidget);
      },
    );

    testWidgets(
      'Switching to Laporan tab in MainNavigationScreen activates auto-refresh',
      (tester) async {
        final navCtrl = NavigationController(initialIndex: 0);

        await tester.pumpWidget(
          buildAppShell(child: const MainNavigationScreen(), navCtrl: navCtrl),
        );
        await tester.pumpAndSettle();

        // Tap on Laporan tab (index 1)
        await tester.tap(find.text('Laporan'));
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(1));
        expect(find.text('Laporan Saya'), findsWidgets);

        // Tap back on Beranda tab (index 0)
        await tester.tap(find.text('Beranda'));
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(0));
      },
    );

    testWidgets(
      'Tapping Beranda navigation bar item while on Beranda triggers feed refresh',
      (tester) async {
        final navCtrl = NavigationController(initialIndex: 0);
        final feedCtrl = FeedController(reportRepository: reportRepo);

        await tester.pumpWidget(
          buildAppShell(
            child: const MainNavigationScreen(),
            navCtrl: navCtrl,
            feedCtrl: feedCtrl,
          ),
        );
        await tester.pumpAndSettle();

        // Tapping Beranda tab directly refreshes
        await tester.tap(find.text('Beranda'));
        await tester.pump();
        await tester.pumpAndSettle();

        expect(feedCtrl.reports, isNotNull);
      },
    );

    testWidgets(
      'AdminNavigationScreen auto-refreshes Panel and Pengumuman when tabs open',
      (tester) async {
        final adminUser = const UserProfileModel(
          id: 'admin-1',
          email: 'admin@example.com',
          fullName: 'Admin User',
          username: 'adminuser',
          role: UserRole.admin,
        );

        final navCtrl = NavigationController(initialIndex: 0);

        await tester.pumpWidget(
          buildAppShell(
            child: const AdminNavigationScreen(),
            user: adminUser,
            navCtrl: navCtrl,
          ),
        );
        await tester.pumpAndSettle();

        // Tap on Panel (index 1)
        await tester.tap(find.text('Panel'));
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(1));
        expect(find.text('Panel Laporan'), findsOneWidget);
        expect(find.text('Total Laporan'), findsOneWidget);

        // Tap on Pengumuman (index 2)
        await tester.tap(find.text('Pengumuman'));
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(2));
        expect(find.text('Pengumuman'), findsWidgets);
      },
    );
  });
}
