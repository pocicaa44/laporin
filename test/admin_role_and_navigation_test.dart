import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/widgets/access_denied_screen.dart';
import 'package:laporin/data/models/announcement_model.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/announcement_repository.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/notification_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/admin/controllers/admin_announcement_controller.dart';
import 'package:laporin/features/admin/controllers/admin_report_controller.dart';
import 'package:laporin/features/admin/screens/admin_announcements_screen.dart';
import 'package:laporin/features/admin/screens/admin_dashboard_screen.dart';
import 'package:laporin/features/admin/screens/admin_create_announcement_screen.dart';
import 'package:laporin/features/admin/screens/admin_edit_announcement_screen.dart';
import 'package:laporin/features/admin/screens/admin_navigation_screen.dart';
import 'package:laporin/features/admin/screens/admin_resolve_sheet.dart';
import 'package:laporin/features/admin/screens/admin_status_update_sheet.dart';
import 'package:laporin/features/admin/widgets/admin_delete_announcement_dialog.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/auth/screens/app_gate.dart';
import 'package:laporin/features/auth/screens/splash_screen.dart';
import 'package:laporin/features/create_report/controllers/create_report_controller.dart';
import 'package:laporin/features/create_report/screens/create_report_screen.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/feed/screens/feed_screen.dart';
import 'package:laporin/features/feed/widgets/report_card.dart';
import 'package:laporin/features/announcements/controllers/announcement_controller.dart';
import 'package:laporin/features/navigation/controllers/navigation_controller.dart';
import 'package:laporin/features/navigation/widgets/app_drawer.dart';
import 'package:laporin/features/navigation/screens/main_navigation_screen.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';
import 'package:laporin/features/profile/screens/profile_screen.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:laporin/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Admin Role and Navigation Test Suite', () {
    late AuthRepository authRepo;
    late ReportRepository reportRepo;
    late AnnouncementRepository announcementRepo;

    const testAdmin = UserProfileModel(
      id: 'admin-001',
      email: 'admin@laporin.go.id',
      fullName: 'Bapak Administrator',
      username: 'admin_resmi',
      role: UserRole.admin,
      avatarUrl: 'https://images.unsplash.com/admin.jpg',
    );

    const testUser = UserProfileModel(
      id: 'user-001',
      email: 'warga@laporin.id',
      fullName: 'Warga Biasa',
      username: 'warga_biasa',
      role: UserRole.user,
      avatarUrl: 'https://images.unsplash.com/warga.jpg',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authRepo = AuthRepository();
      reportRepo = ReportRepository();
      announcementRepo = AnnouncementRepository();
    });

    Widget createTestApp({
      required Widget child,
      required UserProfileModel user,
      Key? key,
    }) {
      authRepo.setCurrentUserProfileForTesting(user);

      return MultiProvider(
        key: key ?? UniqueKey(),
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
          ChangeNotifierProvider(create: (_) => NavigationController()),
          ChangeNotifierProvider(
            create: (_) => AnnouncementController(repository: announcementRepo),
          ),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets(
      'Admin Navigation Screen renders exactly 4 tabs: Beranda, Panel, Pengumuman, Profil',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(child: const AdminNavigationScreen(), user: testAdmin),
        );
        await tester.pumpAndSettle();

        // Verify exactly the 4 admin menu tabs exist
        expect(find.text('Beranda'), findsOneWidget);
        expect(find.text('Panel'), findsOneWidget);
        expect(find.text('Pengumuman'), findsOneWidget);
        expect(find.text('Profil'), findsOneWidget);

        // Verify '+' (create report) and 'Laporan Saya' do not exist
        expect(find.byIcon(Icons.add), findsNothing);
        expect(find.text('Laporan Saya'), findsNothing);
      },
    );

    testWidgets(
      'Admin AppDrawer displays correct 4 admin menus and navigates between tabs properly',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 1600);
        addTearDown(() => tester.view.resetPhysicalSize());

        await tester.pumpWidget(
          createTestApp(child: const AdminNavigationScreen(), user: testAdmin),
        );
        await tester.pumpAndSettle();

        // 1. Open drawer using DrawerMenuButton on FeedScreen
        final menuBtn = find.byType(DrawerMenuButton);
        expect(menuBtn, findsOneWidget);
        await tester.tap(menuBtn);
        await tester.pumpAndSettle();

        // 2. Verify drawer content for admin
        expect(find.byType(AppDrawer), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(AppDrawer),
            matching: find.text('ADMIN'),
          ),
          findsWidgets,
        );
        expect(
          find.descendant(
            of: find.byType(AppDrawer),
            matching: find.text('Panel Laporan'),
          ),
          findsOneWidget,
        );
        // Notifikasi and Laporan Saya should NOT be present in admin drawer
        expect(
          find.descendant(
            of: find.byType(AppDrawer),
            matching: find.text('Notifikasi'),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(AppDrawer),
            matching: find.text('Laporan Saya'),
          ),
          findsNothing,
        );

        // 3. Tap 'Panel Laporan' in drawer
        final panelDrawerItem = find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('Panel Laporan'),
        );
        await tester.tap(panelDrawerItem);
        await tester.pumpAndSettle();

        // Drawer is closed and AdminDashboardScreen is displayed
        expect(find.byType(AdminDashboardScreen), findsOneWidget);

        // 4. Open drawer again from AdminDashboardScreen (which now has DrawerMenuButton)
        final menuBtnOnDashboard = find.byType(DrawerMenuButton);
        expect(menuBtnOnDashboard, findsOneWidget);
        await tester.tap(menuBtnOnDashboard);
        await tester.pumpAndSettle();

        // 5. Tap 'Pengumuman' in drawer
        final announcementsDrawerItem = find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('Pengumuman'),
        );
        await tester.tap(announcementsDrawerItem);
        await tester.pumpAndSettle();

        // Tab changes to AdminAnnouncementsScreen
        expect(find.byType(AdminAnnouncementsScreen), findsOneWidget);

        // 6. Open drawer again from AdminAnnouncementsScreen
        final menuBtnOnAnnouncements = find.byType(DrawerMenuButton);
        expect(menuBtnOnAnnouncements, findsOneWidget);
        await tester.tap(menuBtnOnAnnouncements);
        await tester.pumpAndSettle();

        // 7. Tap 'Profil' in drawer
        final profileDrawerItem = find.descendant(
          of: find.byType(AppDrawer),
          matching: find.text('Profil'),
        );
        await tester.tap(profileDrawerItem);
        await tester.pumpAndSettle();

        // Tab changes to ProfileScreen
        expect(find.byType(ProfileScreen), findsOneWidget);
      },
    );

    testWidgets(
      'AppGate renders AdminNavigationScreen for authenticated admin',
      (WidgetTester tester) async {
        authRepo.setCurrentUserProfileForTesting(testAdmin);
        await tester.pumpWidget(
          LaporinApp(
            key: const ValueKey('app-admin'),
            authRepository: authRepo,
            reportRepository: reportRepo,
            announcementRepository: announcementRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AdminNavigationScreen), findsOneWidget);
        expect(find.byType(MainNavigationScreen), findsNothing);
        expect(find.text('Panel'), findsOneWidget);
        expect(find.text('Pengumuman'), findsOneWidget);
      },
    );

    testWidgets(
      'AppGate renders MainNavigationScreen for authenticated citizen user',
      (WidgetTester tester) async {
        authRepo.setCurrentUserProfileForTesting(testUser);
        await tester.pumpWidget(
          LaporinApp(
            key: const ValueKey('app-user'),
            authRepository: authRepo,
            reportRepository: reportRepo,
            announcementRepository: announcementRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MainNavigationScreen), findsOneWidget);
        expect(find.byType(AdminNavigationScreen), findsNothing);
        expect(find.text('Laporan'), findsOneWidget);
        expect(find.text('Notifikasi'), findsOneWidget);
      },
    );

    testWidgets('Login flow resets navigation and opens Beranda/Feed', (
      WidgetTester tester,
    ) async {
      final authController = AuthController(authRepository: authRepo);
      final navController = NavigationController(initialIndex: 3);
      authRepo.setCurrentUserProfileForTesting(null);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider<AuthRepository>.value(value: authRepo),
            Provider<ReportRepository>.value(value: reportRepo),
            Provider<CommentRepository>(create: (_) => CommentRepository()),
            Provider<NotificationRepository>(
              create: (_) => NotificationRepository(),
            ),
            Provider<AnnouncementRepository>.value(value: announcementRepo),
            ChangeNotifierProvider<AuthController>.value(value: authController),
            ChangeNotifierProvider(
              create: (_) => FeedController(reportRepository: reportRepo),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  NotificationController(repository: NotificationRepository()),
            ),
            ChangeNotifierProvider<NavigationController>.value(
              value: navController,
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  AnnouncementController(repository: announcementRepo),
            ),
          ],
          child: const MaterialApp(home: AppGate()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SplashScreen), findsOneWidget);
      expect(navController.currentIndex, equals(3));

      // Simulate user successfully logging in
      authRepo.setCurrentUserProfileForTesting(testUser);
      authController.notifyListeners();
      await tester.pumpAndSettle();

      expect(find.byType(MainNavigationScreen), findsOneWidget);
      expect(navController.currentIndex, equals(0));
      expect(find.byType(FeedScreen), findsOneWidget);
    });

    testWidgets(
      'CreateReportScreen shows AccessDeniedScreen when accessed by admin',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(child: const CreateReportScreen(), user: testAdmin),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AccessDeniedScreen), findsOneWidget);
        expect(find.text('Akses Ditolak'), findsOneWidget);
        expect(
          find.textContaining(
            'Petugas / Admin tidak dapat membuat laporan baru',
          ),
          findsOneWidget,
        );
        // Form field should not be visible
        expect(find.text('Buat Laporan Baru'), findsNothing);
      },
    );

    testWidgets(
      'AdminDashboardScreen shows AccessDeniedScreen when accessed by regular user',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(child: const AdminDashboardScreen(), user: testUser),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AccessDeniedScreen), findsOneWidget);
        expect(find.text('Akses Khusus Petugas'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminAnnouncementsScreen shows AccessDeniedScreen when accessed by regular user',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const AdminAnnouncementsScreen(),
            user: testUser,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(AccessDeniedScreen), findsOneWidget);
        expect(find.text('Akses Khusus Petugas'), findsOneWidget);
      },
    );

    testWidgets(
      'ProfileScreen hides "Laporan Saya" for admin, but shows it for user',
      (WidgetTester tester) async {
        // Admin
        await tester.pumpWidget(
          createTestApp(child: const ProfileScreen(), user: testAdmin),
        );
        await tester.pumpAndSettle();

        expect(find.text('Laporan Saya'), findsNothing);
        expect(find.text('Peran: Petugas / Admin'), findsOneWidget);

        // User
        await tester.pumpWidget(
          createTestApp(child: const ProfileScreen(), user: testUser),
        );
        await tester.pumpAndSettle();

        expect(find.text('Laporan Saya'), findsOneWidget);
        expect(find.text('Peran: Warga'), findsOneWidget);
      },
    );

    test(
      'CreateReportController fails immediately if caller is admin',
      () async {
        final controller = CreateReportController(reportRepository: reportRepo);

        final result = await controller.submitReport(
          authorId: testAdmin.id,
          authorName: testAdmin.fullName,
          authorUsername: testAdmin.username,
          authorAvatarUrl: testAdmin.avatarUrl,
          title: 'Uji Laporan Admin',
          description: 'Deskripsi laporan oleh admin',
          isCallerAdmin: true,
        );

        expect(result, isNull);
        expect(
          controller.errorMessage,
          equals('Petugas / Admin tidak dapat membuat laporan baru.'),
        );
      },
    );

    test(
      'ReportRepository.createReport throws Exception when isCallerAdmin: true',
      () async {
        expect(
          () async => await reportRepo.createReport(
            authorId: testAdmin.id,
            authorName: testAdmin.fullName,
            authorUsername: testAdmin.username,
            authorAvatarUrl: testAdmin.avatarUrl,
            title: 'Uji Laporan Admin',
            description: 'Deskripsi uji coba',
            category: 'Infrastruktur',
            latitude: -6.99,
            longitude: 110.42,
            locationAddress: 'Jl. Pemuda',
            isCallerAdmin: true,
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'AnnouncementModel serialization and deserialization works correctly',
      () {
        final now = DateTime.now();
        final announcement = AnnouncementModel(
          id: 'ann-1',
          title: 'Kerja Bakti Akbar',
          content: 'Kerja bakti pembersihan saluran air',
          category: 'Kegiatan Warga',
          authorId: 'admin-001',
          authorName: 'Admin Kelurahan',
          createdAt: now,
          updatedAt: now,
        );

        final json = announcement.toJson();
        expect(json['title'], equals('Kerja Bakti Akbar'));
        expect(json['category'], equals('Kegiatan Warga'));

        final fromJson = AnnouncementModel.fromJson(json);
        expect(fromJson.id, equals('ann-1'));
        expect(fromJson.title, equals('Kerja Bakti Akbar'));
        expect(fromJson.authorName, equals('Admin Kelurahan'));
      },
    );

    test(
      'AdminAnnouncementController input validation and anti-double-submission',
      () async {
        final controller = AdminAnnouncementController(
          repository: announcementRepo,
        );

        // 1. Validation error on empty title or content in repo
        expect(
          () async => await announcementRepo.createAnnouncement(
            title: '',
            content: '',
            authorId: testAdmin.id,
            authorName: testAdmin.fullName,
          ),
          throwsA(isA<Exception>()),
        );

        // 2. Successful creation via controller
        final successResult = await controller.createAnnouncement(
          title: 'Pemberitahuan Perbaikan Jalan',
          content: 'Jalan ditutup sementara dari pukul 08:00 - 16:00 WIB.',
          category: 'Infrastruktur',
          authorId: testAdmin.id,
          authorName: testAdmin.fullName,
        );
        expect(successResult, isTrue);
        expect(controller.errorMessage, isNull);

        // Verify created announcement is in repo
        final announcements = await announcementRepo.getAnnouncements();
        expect(
          announcements.any((a) => a.title == 'Pemberitahuan Perbaikan Jalan'),
          isTrue,
        );

        final created = announcements.firstWhere(
          (a) => a.title == 'Pemberitahuan Perbaikan Jalan',
        );

        // 3. Update announcement
        final updateSuccess = await controller.updateAnnouncement(
          id: created.id,
          title: 'Judul Diperbarui Admin',
          content: 'Isi pengumuman telah diperbarui oleh admin yang bertugas.',
          category: 'Darurat',
        );
        expect(updateSuccess, isTrue);
        final updated = controller.announcements.firstWhere(
          (a) => a.id == created.id,
        );
        expect(updated.title, 'Judul Diperbarui Admin');
        expect(updated.category, 'Darurat');

        // 4. Delete announcement
        final deleteSuccess = await controller.deleteAnnouncement(created.id);
        expect(deleteSuccess, isTrue);
        expect(
          controller.announcements.any((a) => a.id == created.id),
          isFalse,
        );
      },
    );

    testWidgets(
      'Admin does NOT receive badge icon on DrawerMenuButton or AppDrawer when there are new announcements',
      (WidgetTester tester) async {
        announcementRepo.setAnnouncementsForTesting([
          AnnouncementModel(
            id: 'ann-1',
            title: 'Pengumuman Baru Warga',
            content: 'Informasi pengumuman penting untuk seluruh warga.',
            category: 'Umum',
            authorId: 'admin-001',
            authorName: 'Petugas Admin',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        expect(announcementRepo.unreadCount, 1);

        // 1. Test as Admin
        await tester.pumpWidget(
          createTestApp(child: const AdminNavigationScreen(), user: testAdmin),
        );
        await tester.pumpAndSettle();

        // DrawerMenuButton should NOT show badge label for admin
        final adminMenuBtn = tester.widget<DrawerMenuButton>(
          find.byType(DrawerMenuButton).first,
        );
        final adminBadgeFinder = find.descendant(
          of: find.byWidget(adminMenuBtn),
          matching: find.byType(Badge),
        );
        final adminBadge = tester.widget<Badge>(adminBadgeFinder);
        expect(adminBadge.isLabelVisible, isFalse);

        // Open drawer and check Pengumuman item
        await tester.tap(find.byWidget(adminMenuBtn));
        await tester.pumpAndSettle();

        // Admin announcement item in drawer has NO badge count
        expect(
          find.descendant(of: find.byType(AppDrawer), matching: find.text('1')),
          findsNothing,
        );
      },
    );

    testWidgets(
      'AdminAnnouncementsScreen allows admin to edit and delete announcement',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        announcementRepo.setAnnouncementsForTesting([
          AnnouncementModel(
            id: 'ann-edit-1',
            title: 'Pengumuman Awal',
            content: 'Isi pengumuman awal yang akan diedit oleh admin.',
            category: 'Umum',
            authorId: 'admin-001',
            authorName: 'Petugas Admin',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ]);

        await tester.pumpWidget(
          createTestApp(
            child: const AdminAnnouncementsScreen(isEmbedded: true),
            user: testAdmin,
          ),
        );
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Pengumuman Awal'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Pengumuman Awal'), findsOneWidget);

        // 1. Open popup menu
        final popupMenu = find.byTooltip('Opsi Pengumuman');
        expect(popupMenu, findsOneWidget);
        await tester.tap(popupMenu);
        await tester.pumpAndSettle();

        // 2. Tap 'Edit Pengumuman'
        await tester.tap(find.text('Edit Pengumuman'));
        await tester.pumpAndSettle();

        // Edit screen appears
        expect(find.byType(AdminEditAnnouncementScreen), findsOneWidget);
        final editTitleField = find
            .descendant(
              of: find.byType(AdminEditAnnouncementScreen),
              matching: find.byType(TextFormField),
            )
            .first;
        await tester.enterText(editTitleField, 'Pengumuman Telah Diedit');
        await tester.pumpAndSettle();

        final saveBtn = find.descendant(
          of: find.byType(AdminEditAnnouncementScreen),
          matching: find.text('Simpan Perubahan'),
        );
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verify edited title appears
        expect(find.text('Pengumuman Telah Diedit'), findsOneWidget);

        // 3. Open popup menu again for Delete
        await tester.tap(find.byTooltip('Opsi Pengumuman'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Hapus Pengumuman'));
        await tester.pumpAndSettle();

        // Delete dialog appears
        expect(find.byType(AdminDeleteAnnouncementDialog), findsOneWidget);
        final confirmDeleteBtn = find.descendant(
          of: find.byType(AdminDeleteAnnouncementDialog),
          matching: find.text('Hapus'),
        );
        await tester.tap(confirmDeleteBtn);
        await tester.pumpAndSettle();

        // Announcement is removed, empty state appears
        expect(find.text('Pengumuman Telah Diedit'), findsNothing);
        expect(find.text('Belum Ada Pengumuman'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminEditAnnouncementScreen validates minimum characters and displays error',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final dummyAnnouncement = AnnouncementModel(
          id: 'ann-dialog-test',
          title: 'Judul Asli Awal',
          content: 'Isi pengumuman awal sebelum diedit oleh admin penguji.',
          category: 'Umum',
          authorId: testAdmin.id,
          authorName: testAdmin.fullName,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final controller = AdminAnnouncementController(
          repository: announcementRepo,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: AdminEditAnnouncementScreen(
              announcement: dummyAnnouncement,
              controller: controller,
            ),
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify initial fields populated
        expect(find.text('Judul Asli Awal'), findsOneWidget);
        expect(
          find.text('Isi pengumuman awal sebelum diedit oleh admin penguji.'),
          findsOneWidget,
        );

        // 2. Clear title and content to test validation
        final textFields = find.byType(TextFormField);
        final titleField = textFields.at(0);
        final contentField = textFields.at(1);

        await tester.enterText(titleField, 'abc');
        await tester.enterText(contentField, 'pendek');
        await tester.pumpAndSettle();

        final saveBtn = find.text('Simpan Perubahan');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Expect validation errors
        expect(find.text('Judul minimal 5 karakter'), findsOneWidget);
        expect(find.text('Isi pengumuman minimal 10 karakter'), findsOneWidget);

        // 3. Select different category chip
        await tester.tap(find.widgetWithText(ChoiceChip, 'Darurat'));
        await tester.pumpAndSettle();

        // 4. Fill valid data and save
        await tester.enterText(titleField, 'Judul Baru Valid');
        await tester.enterText(
          contentField,
          'Isi pengumuman baru yang sangat lengkap dan valid.',
        );
        await tester.pumpAndSettle();

        // Set announcements in repo for test
        announcementRepo.setAnnouncementsForTesting([dummyAnnouncement]);

        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        final updatedInRepo = announcementRepo.cachedAnnouncements.firstWhere(
          (a) => a.id == dummyAnnouncement.id,
        );
        expect(updatedInRepo.title, 'Judul Baru Valid');
        expect(updatedInRepo.category, 'Darurat');
      },
    );

    testWidgets(
      'AdminAnnouncementsScreen FAB navigates to AdminCreateAnnouncementScreen and publishes announcement',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1200, 2000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await tester.pumpWidget(
          createTestApp(
            child: const AdminAnnouncementsScreen(isEmbedded: true),
            user: testAdmin,
          ),
        );
        await tester.pumpAndSettle();

        // 1. Verify FAB is present and tap it
        final fab = find.byKey(const Key('admin_add_announcement_fab'));
        expect(fab, findsOneWidget);
        await tester.tap(fab);
        await tester.pumpAndSettle();

        // 2. AdminCreateAnnouncementScreen is opened
        expect(find.byType(AdminCreateAnnouncementScreen), findsOneWidget);
        expect(find.text('Tambah Pengumuman'), findsWidgets);

        // 3. Fill form
        final textFields = find.descendant(
          of: find.byType(AdminCreateAnnouncementScreen),
          matching: find.byType(TextFormField),
        );
        final titleField = textFields.at(0);
        final contentField = textFields.at(1);

        await tester.enterText(titleField, 'Pemberitahuan Terbit FAB');
        await tester.enterText(
          contentField,
          'Isi pengumuman lengkap yang diterbitkan lewat form layar penuh.',
        );
        await tester.pumpAndSettle();

        // 4. Select category
        await tester.tap(find.widgetWithText(ChoiceChip, 'Pemeliharaan'));
        await tester.pumpAndSettle();

        // 5. Tap Terbitkan Pengumuman
        final publishBtn = find.text('Terbitkan Pengumuman');
        expect(publishBtn, findsOneWidget);
        await tester.tap(publishBtn);
        await tester.pumpAndSettle();

        // 6. Pop back to AdminAnnouncementsScreen and verify list updated
        expect(find.byType(AdminCreateAnnouncementScreen), findsNothing);
        expect(find.text('Pemberitahuan Terbit FAB'), findsOneWidget);
      },
    );

    test(
      'ReportRepository status transitions for admin panel management',
      () async {
        // Create user report
        final rep = await reportRepo.createReport(
          authorId: testUser.id,
          authorName: testUser.fullName,
          authorUsername: testUser.username,
          authorAvatarUrl: testUser.avatarUrl,
          title: 'Tiang Listrik Miring',
          description: 'Tiang listrik miring membahayakan warga di RT 02.',
          category: 'Infrastruktur',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Jl. Gajahmada No. 5',
        );

        // Admin accepts report
        final accepted = await reportRepo.updateHandlingStatus(
          reportId: rep.id,
          newStatus: HandlingStatus.accepted,
        );
        expect(accepted.handlingStatus, equals(HandlingStatus.accepted));

        // Admin transitions to in_progress
        final inProgress = await reportRepo.updateHandlingStatus(
          reportId: rep.id,
          newStatus: HandlingStatus.inProgress,
        );
        expect(inProgress.handlingStatus, equals(HandlingStatus.inProgress));

        // Admin completes report with proof photo
        final completed = await reportRepo.updateHandlingStatus(
          reportId: rep.id,
          newStatus: HandlingStatus.completed,
          completionProofUrl: 'https://images.unsplash.com/proof.jpg',
        );
        expect(completed.handlingStatus, equals(HandlingStatus.completed));
        expect(completed.completionProofUrl, isNotNull);
      },
    );

    test(
      'AdminReportController updates status and updates cached report',
      () async {
        final controller = AdminReportController(reportRepository: reportRepo);
        await controller.fetchReports();

        final rep = await reportRepo.createReport(
          authorId: testUser.id,
          authorName: testUser.fullName,
          authorUsername: testUser.username,
          authorAvatarUrl: testUser.avatarUrl,
          title: 'Jalan Rusak',
          description: 'Lubang besar di tengah jalan',
          category: 'Infrastruktur',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Jl. Pemuda',
        );

        await controller.fetchReports(forceRefresh: true);
        final success = await controller.updateStatus(
          reportId: rep.id,
          newStatus: HandlingStatus.inProgress,
        );

        expect(success, isTrue);
        expect(controller.errorMessage, isNull);
        final updatedInList = controller.reports.firstWhere(
          (r) => r.id == rep.id,
        );
        expect(updatedInList.handlingStatus, equals(HandlingStatus.inProgress));
      },
    );

    test('AdminReportController totalReports and KPI counts are not distorted by filter', () async {
      final rep1 = await reportRepo.createReport(
        authorId: testUser.id,
        authorName: testUser.fullName,
        authorUsername: testUser.username,
        authorAvatarUrl: testUser.avatarUrl,
        title: 'Laporan 1',
        description: 'Desc 1',
        category: 'Infrastruktur',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Jl. Pemuda',
      );
      await reportRepo.updateHandlingStatus(
        reportId: rep1.id,
        newStatus: HandlingStatus.completed,
        completionProofUrl: 'https://example.com/proof.jpg',
      );

      final rep2 = await reportRepo.createReport(
        authorId: testUser.id,
        authorName: testUser.fullName,
        authorUsername: testUser.username,
        authorAvatarUrl: testUser.avatarUrl,
        title: 'Laporan 2',
        description: 'Desc 2',
        category: 'Keamanan',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Jl. Sudirman',
      );
      await reportRepo.updateHandlingStatus(
        reportId: rep2.id,
        newStatus: HandlingStatus.accepted,
      );

      final controller = AdminReportController(reportRepository: reportRepo);
      await controller.fetchReports();

      final initialTotal = controller.totalReports;
      expect(initialTotal, greaterThanOrEqualTo(2));
      expect(controller.completedCount, equals(1));
      expect(controller.acceptedCount, equals(1));

      // When switching to 'completed' filter
      controller.setFilter('completed');
      expect(controller.filter, equals('completed'));
      // totalReports must still represent the overall total, NOT just the completed ones!
      expect(controller.totalReports, equals(initialTotal));
      expect(controller.acceptedCount, equals(1));
      expect(controller.completedCount, equals(1));
      for (final r in controller.reports) {
        expect(r.handlingStatus, equals(HandlingStatus.completed));
      }

      // When switching to 'accepted' filter
      controller.setFilter('accepted');
      expect(controller.filter, equals('accepted'));
      expect(controller.totalReports, equals(initialTotal));
      expect(controller.acceptedCount, equals(1));
      expect(controller.completedCount, equals(1));
      for (final r in controller.reports) {
        expect(r.handlingStatus, equals(HandlingStatus.accepted));
      }

      // Reset to all
      controller.setFilter('all');
      expect(controller.reports.length, equals(initialTotal));
    });

    testWidgets(
      'AdminStatusUpdateSheet renders all status options including Baru',
      (WidgetTester tester) async {
        final rep = await reportRepo.createReport(
          authorId: testUser.id,
          authorName: testUser.fullName,
          authorUsername: testUser.username,
          authorAvatarUrl: testUser.avatarUrl,
          title: 'Sampah Menumpuk',
          description: 'Sampah menumpuk di tepi kali',
          category: 'Kebersihan',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Kali Semarang',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: AdminStatusUpdateSheet(report: rep)),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Ubah Status Penanganan'), findsOneWidget);
        expect(find.text('Baru'), findsOneWidget);
        expect(find.text('Diterima'), findsOneWidget);
        expect(find.text('Diproses'), findsOneWidget);
        expect(find.text('Ditolak'), findsOneWidget);
        expect(find.text('Dibatalkan'), findsNothing);
      },
    );

    testWidgets(
      'ReportDetailScreen shows admin action card for admin, hides for regular user',
      (WidgetTester tester) async {
        final rep = await reportRepo.createReport(
          authorId: testUser.id,
          authorName: testUser.fullName,
          authorUsername: testUser.username,
          authorAvatarUrl: testUser.avatarUrl,
          title: 'Pohon Tumbang',
          description: 'Menutupi jalan warga',
          category: 'Infrastruktur',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Jl. Rinjani',
        );

        // 1. Admin viewing ReportDetailScreen
        await tester.pumpWidget(
          createTestApp(
            child: ReportDetailScreen(reportId: rep.id, initialReport: rep),
            user: testAdmin,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Aksi Penanganan Petugas'), findsOneWidget);
        expect(find.text('Ubah Status'), findsOneWidget);
        expect(find.text('Selesaikan'), findsOneWidget);

        // 2. Regular user viewing ReportDetailScreen
        await tester.pumpWidget(
          createTestApp(
            child: ReportDetailScreen(reportId: rep.id, initialReport: rep),
            user: testUser,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Aksi Penanganan Petugas'), findsNothing);
      },
    );

    testWidgets(
      'ReportCard renders "Baru saja" for user, "Baru" for admin, and "Baru" disappears when detail is opened',
      (WidgetTester tester) async {
        final rep = await reportRepo.createReport(
          authorId: testUser.id,
          authorName: testUser.fullName,
          authorUsername: testUser.username,
          authorAvatarUrl: testUser.avatarUrl,
          title: 'Lampu Jalan Padam',
          description: 'Lampu jalan padam di perempatan',
          category: 'Infrastruktur',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Jl. Pemuda No. 10',
        );

        // 1. Regular user sees "Baru saja" on timelabel, and 1 "Baru" from HandlingStatusBadge
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: ReportCard(
                report: rep,
                onTap: () {},
                onUpvote: () {},
                onDownvote: () {},
              ),
            ),
            user: testUser,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Baru saja'), findsOneWidget);
        expect(find.text('Baru'), findsOneWidget); // From HandlingStatusBadge

        // 2. Admin sees "Baru" on both HandlingStatusBadge and timelabel (total 2)
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: ReportCard(
                report: rep,
                onTap: () {},
                onUpvote: () {},
                onDownvote: () {},
              ),
            ),
            user: testAdmin,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Baru'), findsNWidgets(2)); // Badge + TimeLabel
        expect(find.text('Baru saja'), findsNothing);

        // 3. Admin opens detail -> markReportAsViewedByAdmin is called
        reportRepo.markReportAsViewedByAdmin(rep.id);

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: ReportCard(
                report: rep,
                onTap: () {},
                onUpvote: () {},
                onDownvote: () {},
              ),
            ),
            user: testAdmin,
          ),
        );
        await tester.pumpAndSettle();

        // "Baru" timelabel has disappeared! Only 1 remains (HandlingStatusBadge)
        expect(find.text('Baru'), findsOneWidget);
      },
    );

    test('Repository throws exception when trying to updateHandlingStatus on completed or rejected reports', () async {
      final rep = await reportRepo.createReport(
        authorId: testUser.id,
        authorName: testUser.fullName,
        authorUsername: testUser.username,
        authorAvatarUrl: testUser.avatarUrl,
        title: 'Lampu Jalan Rusak',
        description: 'Lampu jalan mati sejak seminggu lalu',
        category: 'Infrastruktur',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Jl. Pemuda',
      );

      // Transition to in-progress then completed
      await reportRepo.updateHandlingStatus(
        reportId: rep.id,
        newStatus: HandlingStatus.inProgress,
      );
      final completedRep = await reportRepo.updateHandlingStatus(
        reportId: rep.id,
        newStatus: HandlingStatus.completed,
        completionProofUrl: 'https://images.unsplash.com/proof.jpg',
      );
      expect(completedRep.handlingStatus, HandlingStatus.completed);

      // Attempting to update completed report must throw Exception
      expect(
        () => reportRepo.updateHandlingStatus(
          reportId: rep.id,
          newStatus: HandlingStatus.inProgress,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'Laporan yang sudah selesai atau ditolak tidak dapat diubah statusnya lagi',
            ),
          ),
        ),
      );

      // Test rejected report
      final rep2 = await reportRepo.createReport(
        authorId: testUser.id,
        authorName: testUser.fullName,
        authorUsername: testUser.username,
        authorAvatarUrl: testUser.avatarUrl,
        title: 'Laporan Tidak Valid',
        description: 'Deskripsi tidak sesuai',
        category: 'Lainnya',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Jl. Mataram',
      );
      final rejectedRep = await reportRepo.updateHandlingStatus(
        reportId: rep2.id,
        newStatus: HandlingStatus.rejected,
        reason: 'Laporan tidak memenuhi kriteria verifikasi.',
      );
      expect(rejectedRep.handlingStatus, HandlingStatus.rejected);

      // Attempting to update rejected report must throw Exception
      expect(
        () => reportRepo.updateHandlingStatus(
          reportId: rep2.id,
          newStatus: HandlingStatus.inProgress,
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains(
              'Laporan yang sudah selesai atau ditolak tidak dapat diubah statusnya lagi',
            ),
          ),
        ),
      );
    });

    testWidgets(
      'Admin Dashboard panel displays ONLY Detail and Hapus for completed or rejected reports',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final rep = await reportRepo.createReport(
          authorId: testUser.id,
          authorName: testUser.fullName,
          authorUsername: testUser.username,
          authorAvatarUrl: testUser.avatarUrl,
          title: 'Jalan Rusak Selesai',
          description: 'Perbaikan jalan sudah rampung',
          category: 'Infrastruktur',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Jl. Pandanaran',
        );

        // Mark report as completed
        await reportRepo.updateHandlingStatus(
          reportId: rep.id,
          newStatus: HandlingStatus.inProgress,
        );
        await reportRepo.updateHandlingStatus(
          reportId: rep.id,
          newStatus: HandlingStatus.completed,
          completionProofUrl: 'https://images.unsplash.com/proof.jpg',
        );

        await tester.pumpWidget(
          createTestApp(child: const AdminDashboardScreen(), user: testAdmin),
        );
        await tester.pumpAndSettle();

        // Filter to completed reports
        await tester.tap(find.text('Selesai').first);
        await tester.pumpAndSettle();

        // Check buttons: ONLY Detail and Hapus are visible
        expect(find.text('Detail'), findsOneWidget);
        expect(find.text('Hapus'), findsOneWidget);
        expect(find.text('Ubah Status'), findsNothing);
        expect(find.text('Selesaikan'), findsNothing);
        expect(find.text('Pulihkan Publikasi'), findsNothing);

        // Before user deletes: Admin cannot delete (button is disabled)
        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();
        expect(find.text('Hapus Laporan?'), findsNothing);

        // Now citizen soft-deletes the report first
        await reportRepo.softDeleteReport(
          reportId: rep.id,
          currentUserId: testUser.id,
          isCallerAdmin: false,
        );

        // Re-render admin dashboard screen
        await tester.pumpWidget(
          createTestApp(child: const AdminDashboardScreen(), user: testAdmin),
        );
        await tester.pumpAndSettle();

        // Filter to completed reports
        await tester.tap(find.text('Selesai').first);
        await tester.pumpAndSettle();

        // Check button becomes 'Hapus Permanen' and is now active
        expect(find.text('Hapus Permanen'), findsOneWidget);

        // Tap Hapus Permanen -> DeleteReportDialog shows up
        await tester.ensureVisible(find.text('Hapus Permanen'));
        await tester.tap(find.text('Hapus Permanen'));
        await tester.pumpAndSettle();

        expect(find.text('Hapus Laporan?'), findsOneWidget);
        expect(
          find.text('Hapus Laporan'),
          findsOneWidget,
        ); // Confirm button in dialog

        // Confirm deletion
        await tester.tap(find.text('Hapus Laporan'));
        await tester.pumpAndSettle();

        // SnackBar appears
        expect(
          find.text('Laporan ${rep.reportNumber} berhasil dihapus.'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'AdminResolveSheet enforces proof image and populates notes from resolution templates',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1024, 1200);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final rep = await reportRepo.createReport(
          authorId: testUser.id,
          authorName: testUser.fullName,
          authorUsername: testUser.username,
          authorAvatarUrl: testUser.avatarUrl,
          title: 'Perbaikan Saluran Air',
          description: 'Saluran air tersumbat sampah',
          category: 'Lingkungan',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Jl. Ahmad Yani',
        );

        Map<String, dynamic>? resolveResult;

        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      resolveResult =
                          await showModalBottomSheet<Map<String, dynamic>>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => AdminResolveSheet(report: rep),
                          );
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
            user: testAdmin,
          ),
        );
        await tester.pumpAndSettle();

        // Open sheet
        await tester.tap(find.text('Open Sheet'));
        await tester.pumpAndSettle();

        // 1. Verify 4 template chips are present
        expect(find.text('Pekerjaan perbaikan telah selesai'), findsOneWidget);
        expect(
          find.text('Permasalahan telah berhasil ditangani'),
          findsOneWidget,
        );
        expect(
          find.text('Keluhan telah ditindaklanjuti dan diselesaikan'),
          findsOneWidget,
        );
        expect(
          find.text('Tindak lanjut atas laporan telah selesai dilakukan'),
          findsOneWidget,
        );

        // 2. Message box is initially empty
        final notesField = tester.widget<TextFormField>(
          find.byKey(const Key('admin_resolve_notes_field')),
        );
        expect(notesField.controller?.text, isEmpty);

        // 3. Tap on a template chip -> text populates the message box
        await tester.tap(
          find.text('Keluhan telah ditindaklanjuti dan diselesaikan'),
        );
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const Key('admin_resolve_notes_field')),
            matching: find.text(
              'Keluhan telah ditindaklanjuti dan diselesaikan',
            ),
          ),
          findsOneWidget,
        );

        // 4. Try submitting without proof image -> fails with error message
        await tester.tap(find.byKey(const Key('admin_confirm_resolve_button')));
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('admin_proof_error_text')), findsOneWidget);
        expect(
          find.text('Foto bukti penyelesaian wajib dilampirkan.'),
          findsOneWidget,
        );
        expect(resolveResult, isNull);

        // Close the current sheet
        Navigator.pop(tester.element(find.byType(AdminResolveSheet)));
        await tester.pumpAndSettle();

        // 5. Test with initialProofUrl provided (simulating selected proof image)
        await tester.pumpWidget(
          createTestApp(
            child: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () async {
                      resolveResult =
                          await showModalBottomSheet<Map<String, dynamic>>(
                            context: context,
                            isScrollControlled: true,
                            builder: (_) => AdminResolveSheet(
                              report: rep,
                              initialProofUrl: 'https://images.unsplash.com/completion_proof.jpg',
                            ),
                          );
                    },
                    child: const Text('Open Sheet With Proof'),
                  );
                },
              ),
            ),
            user: testAdmin,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Open Sheet With Proof'));
        await tester.pumpAndSettle();

        // Verify "Bukti Foto Terlampir" badge is visible
        expect(find.text('Bukti Foto Terlampir'), findsOneWidget);

        // Tap another template
        await tester.tap(find.text('Permasalahan telah berhasil ditangani'));
        await tester.pumpAndSettle();

        // Confirm resolve
        await tester.tap(find.byKey(const Key('admin_confirm_resolve_button')));
        await tester.pumpAndSettle();

        // Sheet closed and returned expected map
        expect(resolveResult, isNotNull);
        expect(
          resolveResult!['proofUrl'],
          'https://images.unsplash.com/completion_proof.jpg',
        );
        expect(
          resolveResult!['notes'],
          'Permasalahan telah berhasil ditangani',
        );
      },
    );
  });
}
