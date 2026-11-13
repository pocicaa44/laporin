import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/widgets/app_profile_bar.dart';
import 'package:laporin/core/widgets/user_avatar.dart';
import 'package:laporin/data/models/announcement_model.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/announcement_repository.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/notification_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/announcements/controllers/announcement_controller.dart';
import 'package:laporin/features/announcements/screens/announcements_screen.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/feed/screens/feed_screen.dart';
import 'package:laporin/features/my_reports/screens/my_reports_screen.dart';
import 'package:laporin/features/navigation/controllers/navigation_controller.dart';
import 'package:laporin/features/navigation/screens/main_navigation_screen.dart';
import 'package:laporin/features/navigation/widgets/app_drawer.dart';
import 'package:laporin/features/navigation/widgets/user_sidebar.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';
import 'package:laporin/features/notifications/screens/notifications_screen.dart';
import 'package:laporin/features/profile/screens/profile_screen.dart';
import 'package:laporin/features/settings/controllers/settings_controller.dart';
import 'package:laporin/features/settings/screens/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('User Desktop & Responsive UI Tests', () {
    late AuthRepository authRepo;
    late ReportRepository reportRepo;
    late AnnouncementRepository announcementRepo;
    late NotificationRepository notifRepo;

    const testUser = UserProfileModel(
      id: 'citizen-101',
      email: 'budi.santoso@warga.id',
      fullName: 'Budi Santoso',
      username: 'budisantoso',
      role: UserRole.user,
      avatarUrl: '',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authRepo = AuthRepository();
      reportRepo = ReportRepository();
      announcementRepo = AnnouncementRepository();
      notifRepo = NotificationRepository();
      authRepo.setCurrentUserProfileForTesting(testUser);
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
          Provider<NotificationRepository>.value(value: notifRepo),
          Provider<AnnouncementRepository>.value(value: announcementRepo),
          ChangeNotifierProvider(
            create: (_) => AuthController(authRepository: authRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => FeedController(reportRepository: reportRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => NotificationController(repository: notifRepo),
          ),
          ChangeNotifierProvider(
            create: (_) =>
                AnnouncementController(repository: announcementRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => navCtrl ?? NavigationController(),
          ),
          ChangeNotifierProvider(create: (_) => SettingsController()),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets(
      'Desktop Layout: MainNavigationScreen renders UserSidebar with 260px and removes bottom navbar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(child: const MainNavigationScreen()),
        );
        await tester.pumpAndSettle();

        // 1. UserSidebar is rendered
        expect(find.byType(UserSidebar), findsOneWidget);
        final sidebarFinder = find.byType(UserSidebar);
        final sidebarSize = tester.getSize(sidebarFinder);
        expect(sidebarSize.width, equals(UserSidebar.width));

        // 2. BottomNavigationBar is NOT rendered on desktop Scaffold
        final scaffoldFinder = find.byType(Scaffold).first;
        final scaffold = tester.widget<Scaffold>(scaffoldFinder);
        expect(scaffold.bottomNavigationBar, isNull);

        // 3. UserSidebar branding & action elements exist
        expect(
          find.descendant(
            of: find.byType(UserSidebar),
            matching: find.text('Laporin'),
          ),
          findsOneWidget,
        );
        expect(find.text('WARGA'), findsOneWidget);
        expect(find.text('Buat Laporan'), findsOneWidget);
        expect(find.text('MENU UTAMA'), findsOneWidget);
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Laporan Saya'), findsOneWidget);
        expect(find.text('Notifikasi'), findsOneWidget);
        expect(find.text('Pengumuman'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);

        // 4. AppProfileBar is rendered in the top app titlebar with citizen name
        expect(find.byType(AppProfileBar), findsOneWidget);
        expect(find.text('Budi Santoso'), findsOneWidget);
      },
    );

    testWidgets(
      'Mobile Layout: MainNavigationScreen renders bottom navbar and hides UserSidebar',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(child: const MainNavigationScreen()),
        );
        await tester.pumpAndSettle();

        // 1. UserSidebar is NOT present on mobile
        expect(find.byType(UserSidebar), findsNothing);

        // 2. Bottom navbar is present
        final scaffoldFinder = find.byType(Scaffold).first;
        final scaffold = tester.widget<Scaffold>(scaffoldFinder);
        expect(scaffold.bottomNavigationBar, isNotNull);

        // 3. Bottom bar items are accessible
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Laporan'), findsOneWidget);
        expect(find.text('Notifikasi'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);
      },
    );

    testWidgets(
      'Desktop Layout: Tapping sidebar item switches screens in MainNavigationScreen',
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
            child: const MainNavigationScreen(),
            navCtrl: navCtrl,
          ),
        );
        await tester.pumpAndSettle();

        // Initially at Beranda (FeedScreen)
        expect(navCtrl.currentIndex, equals(0));
        expect(find.byType(FeedScreen), findsOneWidget);

        // 1. Tap "Laporan Saya"
        await tester.tap(find.text('Laporan Saya'));
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(1));
        expect(find.byType(MyReportsScreen), findsOneWidget);

        // 2. Tap "Notifikasi"
        await tester.tap(find.text('Notifikasi'));
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(3));
        expect(find.byType(NotificationsScreen), findsOneWidget);

        // 3. Tap "Profil"
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(4));
        expect(find.byType(ProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      'AppProfileBar: displays only profile avatar and Profile Name (no subtitle/chevron)',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(
            child: const Scaffold(
              appBar: PreferredSize(
                preferredSize: Size.fromHeight(56),
                child: Row(
                  children: [
                    AppProfileBar(),
                  ],
                ),
              ),
              body: SizedBox(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Profile Name is displayed
        expect(find.text('Budi Santoso'), findsOneWidget);

        // 2. Avatar is displayed
        expect(find.byType(UserAvatar), findsOneWidget);

        // 3. Subtitle (e.g. @budisantoso, Warga, ADMIN) and dropdown chevron are omitted
        expect(find.text('@budisantoso'), findsNothing);
        expect(find.text('Warga'), findsNothing);
        expect(find.text('ADMIN'), findsNothing);
        expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
      },
    );

    testWidgets(
      'Desktop Layout: Tapping AppProfileBar in top app titlebar switches to Profile tab',
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
            child: const MainNavigationScreen(),
            navCtrl: navCtrl,
          ),
        );
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(0));
        expect(find.byType(AppProfileBar), findsOneWidget);

        // Tap the AppProfileBar in the top app titlebar
        await tester.tap(find.byType(AppProfileBar));
        await tester.pumpAndSettle();

        expect(navCtrl.currentIndex, equals(4));
        expect(find.byType(ProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      'MyReportsScreen: Responsive desktop layout renders 2-column grid and hides drawer button',
      (WidgetTester tester) async {
        final reports = [
          ReportModel(
            id: 'rep-1',
            reportNumber: 'LAP-2026-001',
            title: 'Lampu Jalan Padam',
            description: 'Lampu jalan mati total sejak dua hari lalu.',
            category: 'Infrastruktur',
            latitude: -6.2,
            longitude: 106.8,
            locationAddress: 'Jl. Merdeka No. 1',
            areaId: 'area-1',
            areaName: 'Kota Semarang',
            authorId: testUser.id,
            authorName: testUser.fullName,
            photoUrls: const [],
            handlingStatus: HandlingStatus.newReport,
            publicationState: PublicationState.published,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          ReportModel(
            id: 'rep-2',
            reportNumber: 'LAP-2026-002',
            title: 'Sampah Menumpuk di Saluran Air',
            description: 'Saluran air tersumbat sampah.',
            category: 'Lingkungan',
            latitude: -6.21,
            longitude: 106.81,
            locationAddress: 'Jl. Melati No. 5',
            areaId: 'area-1',
            areaName: 'Kota Semarang',
            authorId: testUser.id,
            authorName: testUser.fullName,
            photoUrls: const [],
            handlingStatus: HandlingStatus.inProgress,
            publicationState: PublicationState.published,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        reportRepo.setReportsForTesting(reports);

        // 1. Desktop Test (1280x800)
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(createTestApp(child: const MyReportsScreen()));
        await tester.pumpAndSettle();

        // DrawerMenuButton is hidden on desktop
        expect(find.byType(DrawerMenuButton), findsNothing);

        // Renders Wrap widget for multi-column grid
        expect(find.byType(Wrap), findsOneWidget);
        expect(find.text('LAP-2026-001'), findsOneWidget);
        expect(find.text('LAP-2026-002'), findsOneWidget);

        // Both cards have equal width (roughly half of available width)
        final card1Finder = find.ancestor(
          of: find.text('LAP-2026-001'),
          matching: find.byType(SizedBox),
        ).first;
        final cardSize = tester.getSize(card1Finder);
        expect(cardSize.width, greaterThan(300));
        expect(cardSize.width, lessThan(650));
      },
    );

    testWidgets(
      'AnnouncementsScreen: Responsive desktop layout renders 2-column Wrap grid',
      (WidgetTester tester) async {
        final announcements = [
          AnnouncementModel(
            id: 'ann-1',
            title: 'Pemadaman Listrik Terjadwal',
            content: 'Pemadaman akan dilakukan di area Semarang Barat.',
            category: 'Infrastruktur',
            authorId: 'admin-1',
            authorName: 'Admin PLN',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          AnnouncementModel(
            id: 'ann-2',
            title: 'Vaksinasi Massal Gratis',
            content: 'Puskesmas mengadakan vaksinasi gratis.',
            category: 'Layanan Publik',
            authorId: 'admin-2',
            authorName: 'Dinas Kesehatan',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        announcementRepo.setAnnouncementsForTesting(announcements);

        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(child: const AnnouncementsScreen()),
        );
        await tester.pumpAndSettle();

        // Renders Wrap widget for multi-column grid on desktop
        expect(find.byType(Wrap), findsOneWidget);
        expect(find.text('Pemadaman Listrik Terjadwal'), findsOneWidget);
        expect(find.text('Vaksinasi Massal Gratis'), findsOneWidget);
      },
    );

    testWidgets(
      'ProfileScreen and SettingsScreen: Desktop layout applies centered constraints',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // 1. ProfileScreen test
        await tester.pumpWidget(createTestApp(child: const ProfileScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Profil Saya'), findsOneWidget);
        expect(find.text('Budi Santoso'), findsOneWidget);
        expect(find.byType(DrawerMenuButton), findsNothing);

        // 2. SettingsScreen test
        await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
        await tester.pumpAndSettle();

        expect(find.text('Pengaturan'), findsOneWidget);
        expect(find.text('Tema & Tampilan'), findsOneWidget);
      },
    );
  });
}
