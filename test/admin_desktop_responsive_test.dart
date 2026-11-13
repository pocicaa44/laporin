import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/widgets/app_profile_bar.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/announcement_repository.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/notification_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/admin/screens/admin_announcements_screen.dart';
import 'package:laporin/features/admin/screens/admin_dashboard_screen.dart';
import 'package:laporin/features/admin/screens/admin_navigation_screen.dart';
import 'package:laporin/features/admin/widgets/admin_sidebar.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/feed/screens/feed_screen.dart';
import 'package:laporin/features/feed/widgets/report_card.dart';
import 'package:laporin/features/navigation/controllers/navigation_controller.dart';
import 'package:laporin/features/navigation/widgets/app_drawer.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';
import 'package:laporin/features/profile/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Admin Desktop & Responsive UI Tests', () {
    late AuthRepository authRepo;
    late ReportRepository reportRepo;
    late AnnouncementRepository announcementRepo;

    const testAdmin = UserProfileModel(
      id: 'admin-100',
      email: 'admin.utama@laporin.go.id',
      fullName: 'Kepala Dinas Admin',
      username: 'admin_dinas',
      role: UserRole.admin,
      avatarUrl: '',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authRepo = AuthRepository();
      reportRepo = ReportRepository();
      announcementRepo = AnnouncementRepository();
      authRepo.setCurrentUserProfileForTesting(testAdmin);
    });

    Widget createTestApp({
      required Widget child,
      NavigationController? navCtrl,
    }) {
      return MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: authRepo),
          Provider<ReportRepository>.value(value: reportRepo),
          Provider<CommentRepository>(create: (_) => CommentRepository()),
          Provider<NotificationRepository>(
            create: (_) => NotificationRepository(),
          ),
          Provider<AnnouncementRepository>.value(value: announcementRepo),
          ChangeNotifierProvider(
            create: (_) => AuthController(authRepository: authRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => FeedController(reportRepository: reportRepo),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                NotificationController(repository: NotificationRepository()),
          ),
          ChangeNotifierProvider(
            create: (_) => navCtrl ?? NavigationController(),
          ),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets(
      'Desktop Layout: Renders AdminSidebar, removes BottomNavigationBar on wide screens',
      (WidgetTester tester) async {
        // Set desktop screen resolution (1280x800, devicePixelRatio = 1.0)
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(child: const AdminNavigationScreen()),
        );
        await tester.pumpAndSettle();

        // 1. Sidebar is rendered with width 260
        expect(find.byType(AdminSidebar), findsOneWidget);
        final sidebarFinder = find.byType(AdminSidebar);
        final sidebarSize = tester.getSize(sidebarFinder);
        expect(sidebarSize.width, equals(AdminSidebar.width));

        // 2. BottomNavigationBar is NOT rendered on desktop
        final scaffoldFinder = find.byType(Scaffold).first;
        final scaffold = tester.widget<Scaffold>(scaffoldFinder);
        expect(scaffold.bottomNavigationBar, isNull);

        // 3. Navigation items exist in the sidebar
        expect(
          find.descendant(
            of: find.byType(AdminSidebar),
            matching: find.text('Laporin'),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(AdminSidebar),
            matching: find.text('ADMIN'),
          ),
          findsOneWidget,
        );
        expect(find.text('MENU UTAMA'), findsOneWidget);
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Panel'), findsOneWidget);
        expect(find.text('Pengumuman'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);
      },
    );

    testWidgets(
      'Mobile Layout: Renders BottomNavigationBar and hides AdminSidebar on narrow screens',
      (WidgetTester tester) async {
        // Set mobile screen resolution (400x800, devicePixelRatio = 1.0)
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(child: const AdminNavigationScreen()),
        );
        await tester.pumpAndSettle();

        // 1. AdminSidebar is NOT rendered on mobile
        expect(find.byType(AdminSidebar), findsNothing);

        // 2. BottomNavigationBar is present on mobile
        final scaffoldFinder = find.byType(Scaffold).first;
        final scaffold = tester.widget<Scaffold>(scaffoldFinder);
        expect(scaffold.bottomNavigationBar, isNotNull);

        // 3. All 4 navigation tabs are accessible
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Panel'), findsOneWidget);
        expect(find.text('Pengumuman'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);
      },
    );

    testWidgets(
      'Desktop Layout: Tapping sidebar item switches screen and updates active tab',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final navCtrl = NavigationController(initialIndex: 0);

        await tester.pumpWidget(
          createTestApp(
            child: const AdminNavigationScreen(),
            navCtrl: navCtrl,
          ),
        );
        await tester.pumpAndSettle();

        // Initial active tab is Beranda
        expect(navCtrl.currentIndex, equals(0));

        // Tap 'Panel' in the sidebar
        await tester.tap(find.text('Panel'));
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(1));
        expect(find.byType(AdminDashboardScreen), findsOneWidget);

        // Tap 'Pengumuman' in the sidebar
        await tester.tap(find.text('Pengumuman'));
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(2));
        expect(find.byType(AdminAnnouncementsScreen), findsOneWidget);

        // Tap AppProfileBar in top AppBar
        expect(find.byType(AppProfileBar), findsOneWidget);
        await tester.tap(find.byType(AppProfileBar));
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(4));
        expect(find.byType(ProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      'AdminDashboardScreen: Renders 4 KPI cards in a single row on desktop, and 2 rows on mobile',
      (WidgetTester tester) async {
        // 1. Test on Desktop
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          createTestApp(child: const AdminDashboardScreen()),
        );
        await tester.pumpAndSettle();

        expect(find.text('Total Laporan'), findsOneWidget);
        expect(find.text('Baru'), findsOneWidget);
        expect(find.text('Diproses'), findsOneWidget);
        expect(find.text('Selesai'), findsOneWidget);

        // On desktop, the top-level row of KPI cards contains all 4 cards
        final totalPos = tester.getTopLeft(find.text('Total Laporan'));
        final baruPos = tester.getTopLeft(find.text('Baru'));
        final diprosesPos = tester.getTopLeft(find.text('Diproses'));
        final selesaiPos = tester.getTopLeft(find.text('Selesai'));

        // Y positions should be identical on desktop (same row)
        expect(totalPos.dy, equals(baruPos.dy));
        expect(baruPos.dy, equals(diprosesPos.dy));
        expect(diprosesPos.dy, equals(selesaiPos.dy));

        // 2. Test on Mobile
        tester.view.physicalSize = const Size(400, 800);
        await tester.pumpWidget(
          createTestApp(child: const AdminDashboardScreen()),
        );
        await tester.pumpAndSettle();

        final totalPosMobile = tester.getTopLeft(find.text('Total Laporan'));
        final diprosesPosMobile = tester.getTopLeft(find.text('Diproses'));

        // On mobile, 'Diproses' is in the second row, so its Y coordinate is greater than 'Total Laporan'
        expect(diprosesPosMobile.dy, greaterThan(totalPosMobile.dy));

        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      },
    );

    testWidgets(
      'AdminAnnouncementsScreen: Desktop displays Buat Pengumuman header action button',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(child: const AdminAnnouncementsScreen()),
        );
        await tester.pumpAndSettle();

        // Both header action button and FAB are available on desktop
        expect(find.text('Buat Pengumuman'), findsOneWidget);
        expect(find.byKey(const Key('admin_add_announcement_fab')), findsOneWidget);
      },
    );

    testWidgets(
      'ReportCard: Desktop caps thumbnail height to 220px and displays multi-photo indicator',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final testReport = ReportModel(
          id: 'rep-desk-1',
          reportNumber: 'LAP-2026-001',
          authorId: 'author-1',
          areaId: 'area-1',
          areaName: 'DKI Jakarta',
          authorName: 'Budi Santoso',
          authorUsername: 'budis',
          authorAvatarUrl: null,
          title: 'Lubang Besar di Jalan Utama',
          description: 'Ada lubang besar membahayakan pengendara',
          category: 'Jalan & Jembatan',
          locationAddress: 'Jl. Sudirman No. 12',
          latitude: -6.2,
          longitude: 106.8,
          photoUrls: [
            'assets/generic-avatar-profile.png',
            'assets/logo_laporin.png',
            'assets/generic-avatar-profile.png',
          ],
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: ReportCard(
                report: testReport,
                onTap: () {},
                onUpvote: () {},
                onDownvote: () {},
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        // 1. Verify multi-photo indicator '+2 Foto' is displayed
        expect(find.text('+2 Foto'), findsOneWidget);

        // 2. Find thumbnail SizedBox and verify height is capped at 220px on desktop
        final sizedBoxFinder = find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == 220.0,
        );
        expect(sizedBoxFinder, findsOneWidget);
      },
    );

    testWidgets(
      'FeedScreen: Desktop constrains body container to maxWidth 760',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1440, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(child: const FeedScreen()),
        );
        await tester.pumpAndSettle();

        // Verify that the body container has maxWidth 760
        final containerFinder = find.byWidgetPredicate(
          (widget) =>
              widget is Container &&
              widget.constraints != null &&
              widget.constraints!.maxWidth == 760.0,
        );
        expect(containerFinder, findsOneWidget);
      },
    );

    testWidgets(
      'Desktop Layout: Removes AppBar toggler (DrawerMenuButton) across all tabs in AdminNavigationScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final navCtrl = NavigationController(initialIndex: 0);

        await tester.pumpWidget(
          createTestApp(
            child: const AdminNavigationScreen(),
            navCtrl: navCtrl,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Tab 0: Beranda (FeedScreen) on desktop - no drawer menu button
        expect(find.byType(DrawerMenuButton), findsNothing);
        expect(find.byTooltip('Menu Utama'), findsNothing);

        // 2. Tab 1: Panel Laporan (AdminDashboardScreen) on desktop - no drawer menu button
        await tester.tap(find.text('Panel'));
        await tester.pumpAndSettle();
        expect(find.byType(DrawerMenuButton), findsNothing);
        expect(find.byTooltip('Menu Utama'), findsNothing);

        // 3. Tab 2: Pengumuman (AdminAnnouncementsScreen) on desktop - no drawer menu button
        await tester.tap(find.text('Pengumuman'));
        await tester.pumpAndSettle();
        expect(find.byType(DrawerMenuButton), findsNothing);
        expect(find.byTooltip('Menu Utama'), findsNothing);

        // 4. Tab 3: Profil (ProfileScreen) on desktop - no drawer menu button
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle();
        expect(find.byType(DrawerMenuButton), findsNothing);
        expect(find.byTooltip('Menu Utama'), findsNothing);
      },
    );

    testWidgets(
      'Standalone Desktop: FeedScreen, AdminDashboardScreen, and AdminAnnouncementsScreen omit DrawerMenuButton',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Test standalone FeedScreen
        await tester.pumpWidget(createTestApp(child: const FeedScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(DrawerMenuButton), findsNothing);
        expect(find.byTooltip('Menu Utama'), findsNothing);

        // Test standalone AdminDashboardScreen
        await tester.pumpWidget(createTestApp(child: const AdminDashboardScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(DrawerMenuButton), findsNothing);
        expect(find.byTooltip('Menu Utama'), findsNothing);

        // Test standalone AdminAnnouncementsScreen
        await tester.pumpWidget(createTestApp(child: const AdminAnnouncementsScreen()));
        await tester.pumpAndSettle();
        expect(find.byType(DrawerMenuButton), findsNothing);
        expect(find.byTooltip('Menu Utama'), findsNothing);
      },
    );
  });
}
