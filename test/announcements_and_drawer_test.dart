import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/announcement_model.dart';
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
import 'package:laporin/features/navigation/controllers/navigation_controller.dart';
import 'package:laporin/features/navigation/screens/main_navigation_screen.dart';
import 'package:laporin/features/navigation/widgets/app_drawer.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AnnouncementRepository & Controller unread tracking', () {
    test('tracks unread count and marks as read properly', () async {
      SharedPreferences.setMockInitialValues({});
      final repo = AnnouncementRepository();
      final dummyList = [
        AnnouncementModel(
          id: 'anc-1',
          title: 'Pemeliharaan Jalan',
          content: 'Pekerjaan perbaikan jalan berlangsung selama 3 hari.',
          authorId: 'adm-1',
          authorName: 'Admin DPUPR',
          category: 'Infrastruktur',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
        AnnouncementModel(
          id: 'anc-2',
          title: 'Sosialisasi Kebersihan',
          content: 'Kerja bakti serentak pada hari Minggu.',
          authorId: 'adm-2',
          authorName: 'Admin DLH',
          category: 'Layanan Publik',
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

      repo.setAnnouncementsForTesting(dummyList);
      final controller = AnnouncementController(repository: repo);

      expect(controller.unreadCount, 2);
      expect(controller.isRead('anc-1'), false);
      expect(controller.isRead('anc-2'), false);

      // Mark single announcement as read
      controller.markAsRead('anc-1');
      expect(controller.unreadCount, 1);
      expect(controller.isRead('anc-1'), true);
      expect(controller.isRead('anc-2'), false);

      // Mark all as read
      controller.markAllAsRead();
      expect(controller.unreadCount, 0);
      expect(controller.isRead('anc-2'), true);
    });

    test('marks announcements as read even if markAllAsRead is called before data arrives', () async {
      final repo = AnnouncementRepository();
      final controller = AnnouncementController(repository: repo);

      // User opens page while data hasn't loaded yet
      expect(controller.announcements.isEmpty, isTrue);
      controller.setViewingAnnouncements(true);
      controller.markAllAsRead();
      expect(controller.unreadCount, 0);

      // Data arrives subsequently
      final dummyList = [
        AnnouncementModel(
          id: 'anc-late-1',
          title: 'Sosialisasi Vaksinasi',
          content: 'Puskesmas mengadakan vaksinasi gratis.',
          authorId: 'adm-dinkes',
          authorName: 'Dinkes',
          category: 'Layanan Publik',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Simulate repository getAnnouncements loading
      repo.cachedAnnouncements;
      repo.getAnnouncements();
      repo.addAnnouncementForTesting(dummyList[0]);

      // Unread count stays 0 because user was viewing or marked read
      expect(controller.unreadCount, 0);

      // Leaving screen maintains read status
      controller.setViewingAnnouncements(false);
      expect(controller.unreadCount, 0);
      expect(controller.isRead('anc-late-1'), isTrue);
    });
  });

  Widget buildTestApp({
    required AuthRepository authRepo,
    required AnnouncementRepository announcementRepo,
    required NavigationController navCtrl,
    required NotificationRepository notifRepo,
    required ReportRepository reportRepo,
    Widget? home,
  }) {
    return MultiProvider(
      providers: [
        Provider<AuthRepository>.value(value: authRepo),
        Provider<AnnouncementRepository>.value(value: announcementRepo),
        Provider<NotificationRepository>.value(value: notifRepo),
        Provider<ReportRepository>.value(value: reportRepo),
        Provider<CommentRepository>(create: (_) => CommentRepository()),
        ChangeNotifierProvider<AuthController>(
          create: (_) => AuthController(authRepository: authRepo),
        ),
        ChangeNotifierProvider<NavigationController>.value(value: navCtrl),
        ChangeNotifierProvider<AnnouncementController>(
          create: (_) => AnnouncementController(repository: announcementRepo),
        ),
        ChangeNotifierProvider<NotificationController>(
          create: (_) => NotificationController(repository: notifRepo),
        ),
        ChangeNotifierProvider<FeedController>(
          create: (_) => FeedController(reportRepository: reportRepo),
        ),
      ],
      child: MaterialApp(home: home ?? const MainNavigationScreen()),
    );
  }

  group('AppDrawer menu items and announcement badge flow', () {
    late AuthRepository authRepo;
    late AnnouncementRepository announcementRepo;
    late NavigationController navCtrl;
    late NotificationRepository notifRepo;
    late ReportRepository reportRepo;

    setUp(() {
      authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'user-warga',
          email: 'warga@laporin.id',
          fullName: 'Siti Aminah',
          username: 'siti_aminah',
          role: UserRole.user,
        ),
      );

      announcementRepo = AnnouncementRepository();
      announcementRepo.setAnnouncementsForTesting([
        AnnouncementModel(
          id: 'anc-101',
          title: 'Jadwal Pemadaman Bergilir',
          content: 'Pemeliharaan jaringan listrik wilayah utara.',
          authorId: 'adm-pln',
          authorName: 'PLN Jawa Tengah',
          category: 'Layanan Publik',
          createdAt: DateTime.now().subtract(const Duration(hours: 3)),
          updatedAt: DateTime.now().subtract(const Duration(hours: 3)),
        ),
        AnnouncementModel(
          id: 'anc-102',
          title: 'Banjir Rob Pantura',
          content: 'Waspada potensi rob di sepanjang jalur Pantura.',
          authorId: 'adm-bpbd',
          authorName: 'BPBD Jateng',
          category: 'Darurat',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
          updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
        ),
      ]);

      navCtrl = NavigationController();
      notifRepo = NotificationRepository();
      reportRepo = ReportRepository();
    });

    testWidgets(
      'renders all 5 drawer menu items in exact order: Beranda, Laporan, Pengumuman, Notifikasi, Profil',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            authRepo: authRepo,
            announcementRepo: announcementRepo,
            navCtrl: navCtrl,
            notifRepo: notifRepo,
            reportRepo: reportRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Tap hamburger button to open drawer
        final menuFinder = find.byType(DrawerMenuButton).first;
        expect(menuFinder, findsOneWidget);
        await tester.tap(menuFinder);
        await tester.pumpAndSettle();

        // Drawer is visible
        expect(find.byType(AppDrawer), findsOneWidget);

        // Verify the 5 menu items in the drawer
        expect(find.text('Beranda'), findsWidgets);
        expect(find.text('Laporan'), findsWidgets);
        expect(find.text('Pengumuman'), findsOneWidget);
        expect(find.text('Notifikasi'), findsWidgets);
        expect(find.text('Profil'), findsWidgets);

        // Verify relative vertical positions to ensure exact required order
        final berandaY = tester
            .getTopLeft(
              find.descendant(
                of: find.byType(AppDrawer),
                matching: find.text('Beranda'),
              ),
            )
            .dy;
        final laporanY = tester
            .getTopLeft(
              find.descendant(
                of: find.byType(AppDrawer),
                matching: find.text('Laporan'),
              ),
            )
            .dy;
        final pengumumanY = tester
            .getTopLeft(
              find.descendant(
                of: find.byType(AppDrawer),
                matching: find.text('Pengumuman'),
              ),
            )
            .dy;
        final notifikasiY = tester
            .getTopLeft(
              find.descendant(
                of: find.byType(AppDrawer),
                matching: find.text('Notifikasi'),
              ),
            )
            .dy;
        final profilY = tester
            .getTopLeft(
              find.descendant(
                of: find.byType(AppDrawer),
                matching: find.text('Profil'),
              ),
            )
            .dy;

        expect(
          berandaY < laporanY,
          isTrue,
          reason: 'Beranda must precede Laporan',
        );
        expect(
          laporanY < pengumumanY,
          isTrue,
          reason: 'Laporan must precede Pengumuman',
        );
        expect(
          pengumumanY < notifikasiY,
          isTrue,
          reason: 'Pengumuman must precede Notifikasi',
        );
        expect(
          notifikasiY < profilY,
          isTrue,
          reason: 'Notifikasi must precede Profil',
        );
      },
    );

    testWidgets(
      'shows badge count on Pengumuman menu and clears badge when AnnouncementsScreen is opened',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            authRepo: authRepo,
            announcementRepo: announcementRepo,
            navCtrl: navCtrl,
            notifRepo: notifRepo,
            reportRepo: reportRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Check unread count is initially 2
        expect(announcementRepo.unreadCount, 2);

        // Open AppDrawer
        await tester.tap(find.byType(DrawerMenuButton).first);
        await tester.pumpAndSettle();

        // Pengumuman menu item displays badge with count '2'
        expect(find.text('2'), findsWidgets);

        // Tap 'Pengumuman' menu item in Drawer
        await tester.tap(
          find.descendant(
            of: find.byType(AppDrawer),
            matching: find.text('Pengumuman'),
          ),
        );
        await tester.pumpAndSettle();

        // Navigates to AnnouncementsScreen
        expect(find.byType(AnnouncementsScreen), findsOneWidget);
        expect(find.text('Pengumuman Resmi'), findsOneWidget);
        expect(find.text('Jadwal Pemadaman Bergilir'), findsOneWidget);
        expect(find.text('Banjir Rob Pantura'), findsOneWidget);

        // When AnnouncementsScreen opened, markAllAsRead() was triggered
        expect(announcementRepo.unreadCount, 0);

        // Pop back to main navigation
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Re-open AppDrawer
        await tester.tap(find.byType(DrawerMenuButton).first);
        await tester.pumpAndSettle();

        // Badge '2' is now gone!
        expect(find.text('2'), findsNothing);
      },
    );

    testWidgets('tapping drawer tabs switches the active screen', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepo: authRepo,
          announcementRepo: announcementRepo,
          navCtrl: navCtrl,
          notifRepo: notifRepo,
          reportRepo: reportRepo,
        ),
      );
      await tester.pumpAndSettle();

      // Initial tab is 0 (Beranda)
      expect(navCtrl.currentIndex, 0);

      // Open Drawer and tap 'Laporan'
      await tester.tap(find.byType(DrawerMenuButton).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('Laporan'),
        ),
      );
      await tester.pumpAndSettle();

      expect(navCtrl.currentIndex, 1);

      // Open Drawer and tap 'Notifikasi'
      await tester.tap(find.byType(DrawerMenuButton).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('Notifikasi'),
        ),
      );
      await tester.pumpAndSettle();

      expect(navCtrl.currentIndex, 3);

      // Open Drawer and tap 'Profil'
      await tester.tap(find.byType(DrawerMenuButton).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('Profil'),
        ),
      );
      await tester.pumpAndSettle();

      expect(navCtrl.currentIndex, 4);

      // Open Drawer and tap 'Beranda'
      await tester.tap(find.byType(DrawerMenuButton).first);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('Beranda'),
        ),
      );
      await tester.pumpAndSettle();

      expect(navCtrl.currentIndex, 0);
    });

    testWidgets(
      'AnnouncementsScreen category filter and detail bottom sheet work',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildTestApp(
            authRepo: authRepo,
            announcementRepo: announcementRepo,
            navCtrl: navCtrl,
            notifRepo: notifRepo,
            reportRepo: reportRepo,
            home: const AnnouncementsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Shows both announcements under 'Semua'
        expect(find.text('Jadwal Pemadaman Bergilir'), findsOneWidget);
        expect(find.text('Banjir Rob Pantura'), findsOneWidget);

        // Tap category chip 'Layanan Publik'
        await tester.tap(find.widgetWithText(ChoiceChip, 'Layanan Publik'));
        await tester.pumpAndSettle();

        // Only 'Jadwal Pemadaman Bergilir' is visible
        expect(find.text('Jadwal Pemadaman Bergilir'), findsOneWidget);
        expect(find.text('Banjir Rob Pantura'), findsNothing);

        // Tap announcement card to open detail bottom sheet
        await tester.tap(find.text('Jadwal Pemadaman Bergilir'));
        await tester.pumpAndSettle();

        // Detail sheet opened
        expect(
          find.text('Pemeliharaan jaringan listrik wilayah utara.'),
          findsWidgets,
        );
        expect(find.text('PLN Jawa Tengah'), findsWidgets);
      },
    );

    testWidgets(
      'AnnouncementsScreen renders Edit button in detail sheet and card when accessed by admin',
      (WidgetTester tester) async {
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'admin-01',
            email: 'admin@laporin.id',
            fullName: 'Admin Utama',
            username: 'admin_utama',
            role: UserRole.admin,
          ),
        );

        await tester.pumpWidget(
          buildTestApp(
            authRepo: authRepo,
            announcementRepo: announcementRepo,
            navCtrl: navCtrl,
            notifRepo: notifRepo,
            reportRepo: reportRepo,
            home: const AnnouncementsScreen(),
          ),
        );
        await tester.pumpAndSettle();

        // Admin sees Edit button on cards
        expect(find.text('Edit'), findsWidgets);

        // Tap announcement card to open detail sheet
        await tester.tap(find.text('Jadwal Pemadaman Bergilir'));
        await tester.pumpAndSettle();

        // Bottom sheet contains 'Edit Pengumuman' button for admin
        expect(find.text('Edit Pengumuman'), findsOneWidget);
      },
    );

    testWidgets('AppDrawer has sharp right border without rounded corners', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildTestApp(
          authRepo: authRepo,
          announcementRepo: announcementRepo,
          navCtrl: navCtrl,
          notifRepo: notifRepo,
          reportRepo: reportRepo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(DrawerMenuButton).first);
      await tester.pumpAndSettle();

      final drawerWidget = tester.widget<Drawer>(find.byType(Drawer));
      final shape = drawerWidget.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.zero);
    });

    testWidgets(
      'realtime announcement badge flow: increments unread, clears on open, resets on new arrival',
      (WidgetTester tester) async {
        // Start with no announcements or all marked as read
        announcementRepo.setAnnouncementsForTesting([], readIds: {});

        await tester.pumpWidget(
          buildTestApp(
            authRepo: authRepo,
            announcementRepo: announcementRepo,
            navCtrl: navCtrl,
            notifRepo: notifRepo,
            reportRepo: reportRepo,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Initial state: unreadCount is 0, no badge displayed
        expect(announcementRepo.unreadCount, 0);

        // 2. A new announcement arrives in REALTIME
        final newAnn1 = AnnouncementModel(
          id: 'realtime-1',
          title: 'Peringatan Cuaca Ekstrem',
          content: 'Waspada hujan lebat disertai angin kencang.',
          authorId: 'adm-bmkg',
          authorName: 'BMKG Jateng',
          category: 'Darurat',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        announcementRepo.addAnnouncementForTesting(newAnn1);
        await tester.pumpAndSettle();

        // Unread count is now 1, badge shows '1'
        expect(announcementRepo.unreadCount, 1);

        // Open drawer to verify badge '1' on Pengumuman menu item
        await tester.tap(find.byType(DrawerMenuButton).first);
        await tester.pumpAndSettle();
        expect(find.text('1'), findsWidgets);

        // Close drawer
        await tester.tapAt(const Offset(700, 300));
        await tester.pumpAndSettle();

        // 3. Another new announcement arrives while page is NOT opened yet
        final newAnn2 = AnnouncementModel(
          id: 'realtime-2',
          title: 'Rekayasa Lalu Lintas',
          content: 'Penutupan jalan sementara untuk perbaikan jembatan.',
          authorId: 'adm-dishub',
          authorName: 'Dishub Jateng',
          category: 'Infrastruktur',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        announcementRepo.addAnnouncementForTesting(newAnn2);
        await tester.pumpAndSettle();

        // Unread count increments to 2
        expect(announcementRepo.unreadCount, 2);

        // Open drawer: badge now shows '2'
        await tester.tap(find.byType(DrawerMenuButton).first);
        await tester.pumpAndSettle();
        expect(find.text('2'), findsWidgets);

        // 4. User opens AnnouncementsScreen: badge must clear
        await tester.tap(
          find.descendant(
            of: find.byType(AppDrawer),
            matching: find.text('Pengumuman'),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AnnouncementsScreen), findsOneWidget);
        expect(announcementRepo.unreadCount, 0);

        // Pop back to main navigation
        await tester.pageBack();
        await tester.pumpAndSettle();

        // Open drawer: badge is gone!
        await tester.tap(find.byType(DrawerMenuButton).first);
        await tester.pumpAndSettle();
        expect(find.text('1'), findsNothing);
        expect(find.text('2'), findsNothing);

        // Close drawer
        await tester.tapAt(const Offset(700, 300));
        await tester.pumpAndSettle();

        // 5. Subsequent new announcement arrives: count resets and starts at 1
        final newAnn3 = AnnouncementModel(
          id: 'realtime-3',
          title: 'Pelayanan KTP Keliling',
          content: 'Layanan administrasi kependudukan di balai desa.',
          authorId: 'adm-dukcapil',
          authorName: 'Dukcapil',
          category: 'Layanan Publik',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        announcementRepo.addAnnouncementForTesting(newAnn3);
        await tester.pumpAndSettle();

        // Count is now 1 again
        expect(announcementRepo.unreadCount, 1);

        // Open drawer: badge '1' is displayed
        await tester.tap(find.byType(DrawerMenuButton).first);
        await tester.pumpAndSettle();
        expect(find.text('1'), findsWidgets);
      },
    );
  });
}
