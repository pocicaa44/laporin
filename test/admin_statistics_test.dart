import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/announcement_repository.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/notification_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/admin/controllers/admin_statistics_controller.dart';
import 'package:laporin/features/admin/screens/admin_navigation_screen.dart';
import 'package:laporin/features/admin/screens/admin_statistics_screen.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/navigation/controllers/navigation_controller.dart';
import 'package:laporin/features/navigation/widgets/app_drawer.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Admin Statistics Feature Tests', () {
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

    const testCitizen = UserProfileModel(
      id: 'user-001',
      email: 'budi@warga.id',
      fullName: 'Budi Santoso',
      username: 'budis',
      role: UserRole.user,
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

    test(
      'Requirement 3: Statistics retain and display monthly count even after report is permanently deleted',
      () async {
        // 1. Tambahkan 3 laporan pada November 2026
        final repNov1 = ReportModel(
          id: 'rep-nov-1',
          reportNumber: 'LAP-NOV-1',
          authorId: testCitizen.id,
          authorName: testCitizen.fullName,
          authorUsername: testCitizen.username,
          title: 'Jalan Rusak November 1',
          description: 'Lubang jalan di November',
          category: 'Jalan & Jembatan',
          locationAddress: 'Jl. Sudirman',
          latitude: -6.2,
          longitude: 106.8,
          areaId: 'area-1',
          areaName: 'DKI Jakarta',
          handlingStatus: HandlingStatus.completed,
          publicationState: PublicationState.published,
          createdAt: DateTime(2026, 11, 5, 10, 0),
          updatedAt: DateTime(2026, 11, 5, 10, 0),
        );

        final repNov2 = ReportModel(
          id: 'rep-nov-2',
          reportNumber: 'LAP-NOV-2',
          authorId: testCitizen.id,
          authorName: testCitizen.fullName,
          authorUsername: testCitizen.username,
          title: 'Sampah Menumpuk November 2',
          description: 'Sampah di trotoar November',
          category: 'Sampah & Kebersihan',
          locationAddress: 'Jl. Thamrin',
          latitude: -6.21,
          longitude: 106.81,
          areaId: 'area-1',
          areaName: 'DKI Jakarta',
          handlingStatus: HandlingStatus.inProgress,
          publicationState: PublicationState.published,
          createdAt: DateTime(2026, 11, 10, 14, 0),
          updatedAt: DateTime(2026, 11, 10, 14, 0),
        );

        final repNov3 = ReportModel(
          id: 'rep-nov-3',
          reportNumber: 'LAP-NOV-3',
          authorId: testCitizen.id,
          authorName: testCitizen.fullName,
          authorUsername: testCitizen.username,
          title: 'Lampu Padam November 3',
          description: 'Lampu jalan mati di November',
          category: 'Lampu Jalan',
          locationAddress: 'Jl. Gatot Subroto',
          latitude: -6.22,
          longitude: 106.82,
          areaId: 'area-1',
          areaName: 'DKI Jakarta',
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime(2026, 11, 15, 20, 0),
          updatedAt: DateTime(2026, 11, 15, 20, 0),
        );

        // 2. Tambahkan 2 laporan pada Oktober 2026
        final repOkt1 = ReportModel(
          id: 'rep-okt-1',
          reportNumber: 'LAP-OKT-1',
          authorId: testCitizen.id,
          authorName: testCitizen.fullName,
          authorUsername: testCitizen.username,
          title: 'Pohon Tumbang Oktober 1',
          description: 'Pohon tumbang di Oktober',
          category: 'Ketertiban Umum',
          locationAddress: 'Jl. Merdeka',
          latitude: -6.19,
          longitude: 106.83,
          areaId: 'area-1',
          areaName: 'DKI Jakarta',
          handlingStatus: HandlingStatus.completed,
          publicationState: PublicationState.published,
          createdAt: DateTime(2026, 10, 12, 8, 0),
          updatedAt: DateTime(2026, 10, 12, 8, 0),
        );

        final repOkt2 = ReportModel(
          id: 'rep-okt-2',
          reportNumber: 'LAP-OKT-2',
          authorId: testCitizen.id,
          authorName: testCitizen.fullName,
          authorUsername: testCitizen.username,
          title: 'Saluran Tersumbat Oktober 2',
          description: 'Drainase meluap di Oktober',
          category: 'Jalan & Jembatan',
          locationAddress: 'Jl. Kebon Sirih',
          latitude: -6.18,
          longitude: 106.84,
          areaId: 'area-1',
          areaName: 'DKI Jakarta',
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime(2026, 10, 25, 11, 0),
          updatedAt: DateTime(2026, 10, 25, 11, 0),
        );

        reportRepo.setReportsForTesting([
          repNov1,
          repNov2,
          repNov3,
          repOkt1,
          repOkt2,
        ]);

        // Verifikasi sebelum penghapusan:
        final statsBefore = await reportRepo.getMonthlyStatistics();
        expect(statsBefore.length, equals(2));

        final novBefore = statsBefore.firstWhere((s) => s.periodYearMonth == '2026-11');
        final oktBefore = statsBefore.firstWhere((s) => s.periodYearMonth == '2026-10');
        expect(novBefore.totalReports, equals(3));
        expect(oktBefore.totalReports, equals(2));

        // 3. Lakukan penghapusan dua belah pihak (Dual-Party Deletion -> Hard Delete Fisik)
        // Step 1: User soft-deletes
        await reportRepo.softDeleteReport(
          reportId: repNov1.id,
          currentUserId: testCitizen.id,
          isCallerAdmin: false,
        );

        // Step 2: Admin confirms hard-delete
        final deletedResult = await reportRepo.softDeleteReport(
          reportId: repNov1.id,
          currentUserId: testAdmin.id,
          isCallerAdmin: true,
        );
        expect(deletedResult.deletedByUser, isTrue);
        expect(deletedResult.deletedByAdmin, isTrue);

        // Verifikasi laporan sudah terhapus secara fisik dari active reports
        final activeCheck = await reportRepo.getReportById(repNov1.id);
        expect(activeCheck, isNull);

        // 4. Verifikasi bahwa statistik TETAP BERFUNGSI dan jumlah laporan November TIDAK BERKURANG!
        final statsAfter = await reportRepo.getMonthlyStatistics();
        final novAfter = statsAfter.firstWhere((s) => s.periodYearMonth == '2026-11');
        final oktAfter = statsAfter.firstWhere((s) => s.periodYearMonth == '2026-10');

        // Total laporan November TETAP 3 meskipun 1 laporan telah dihapus permanen!
        expect(novAfter.totalReports, equals(3));
        expect(novAfter.deletedReports, equals(1)); // 1 tercatat sebagai laporan terhapus historis
        expect(oktAfter.totalReports, equals(2));

        // Summary all-time juga tetap mencakup 5 laporan
        final summary = await reportRepo.getStatisticsSummary();
        expect(summary.totalReports, equals(5));
        expect(summary.deletedReports, equals(1));
      },
    );

    test('AdminStatisticsController loads data and filters by month properly', () async {
      final repNov = ReportModel(
        id: 'rep-nov',
        reportNumber: 'LAP-NOV',
        authorId: testCitizen.id,
        authorName: testCitizen.fullName,
        authorUsername: testCitizen.username,
        title: 'Laporan 1',
        description: 'Desc 1',
        category: 'Jalan & Jembatan',
        locationAddress: 'Alamat',
        latitude: -6.2,
        longitude: 106.8,
        areaId: 'area-1',
        areaName: 'DKI Jakarta',
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
        createdAt: DateTime(2026, 11, 1),
        updatedAt: DateTime(2026, 11, 1),
      );

      final repOkt = ReportModel(
        id: 'rep-okt',
        reportNumber: 'LAP-OKT',
        authorId: testCitizen.id,
        authorName: testCitizen.fullName,
        authorUsername: testCitizen.username,
        title: 'Laporan 2',
        description: 'Desc 2',
        category: 'Sampah & Kebersihan',
        locationAddress: 'Alamat',
        latitude: -6.2,
        longitude: 106.8,
        areaId: 'area-1',
        areaName: 'DKI Jakarta',
        handlingStatus: HandlingStatus.completed,
        publicationState: PublicationState.published,
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 10, 1),
      );

      reportRepo.setReportsForTesting([repNov, repOkt]);

      final controller = AdminStatisticsController(reportRepository: reportRepo);
      expect(controller.isLoading, isFalse);

      await controller.fetchStatistics();

      expect(controller.monthlyStats.length, equals(2));
      expect(controller.availablePeriods, containsAll(['2026-11', '2026-10']));
      expect(controller.totalReports, equals(2));

      // Filter ke periode November 2026
      await controller.selectPeriod('2026-11');
      expect(controller.selectedPeriod, equals('2026-11'));
      expect(controller.totalReports, equals(1));
      expect(controller.selectedMonthlyStat?.monthName, contains('November 2026'));

      // Reset ke Semua Bulan
      await controller.selectPeriod(null);
      expect(controller.selectedPeriod, isNull);
      expect(controller.totalReports, equals(2));
    });

    testWidgets(
      'Desktop Layout: Renders AdminStatisticsScreen with responsive charts and omits AppBar toggler',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Seed 1 laporan
        reportRepo.setReportsForTesting([
          ReportModel(
            id: 'rep-desk-1',
            reportNumber: 'LAP-DESK-1',
            authorId: testCitizen.id,
            authorName: testCitizen.fullName,
            authorUsername: testCitizen.username,
            title: 'Laporan Desktop',
            description: 'Desc Desktop',
            category: 'Jalan & Jembatan',
            locationAddress: 'Alamat',
            latitude: -6.2,
            longitude: 106.8,
            areaId: 'area-1',
            areaName: 'DKI Jakarta',
            handlingStatus: HandlingStatus.newReport,
            publicationState: PublicationState.published,
            createdAt: DateTime(2026, 11, 2),
            updatedAt: DateTime(2026, 11, 2),
          ),
        ]);

        await tester.pumpWidget(
          createTestApp(child: const AdminStatisticsScreen()),
        );
        await tester.pumpAndSettle();

        // 1. Verifikasi judul halaman
        expect(find.text('Statistik Laporan'), findsOneWidget);

        // 2. Verifikasi AppBar toggler (hamburger) TIDAK ADA di desktop
        expect(find.byType(DrawerMenuButton), findsNothing);
        expect(find.byTooltip('Menu Utama'), findsNothing);

        // 3. Verifikasi metrik KPI cards
        expect(find.text('Total Laporan'), findsOneWidget);
        expect(find.text('Selesai'), findsWidgets);
        expect(find.text('Diproses / Baru'), findsOneWidget);
        expect(find.text('Ditolak'), findsWidgets);
        expect(find.text('Dihapus'), findsWidgets);

        // 4. Verifikasi Grafik Tren Bulanan & Distribusi
        expect(find.text('Grafik Tren Laporan Bulanan'), findsOneWidget);
        expect(find.text('Status Penanganan Laporan'), findsOneWidget);
        expect(find.text('Distribusi Kategori Laporan'), findsOneWidget);
        expect(find.text('Rincian Histori Bulanan'), findsOneWidget);

        // 5. Verifikasi Dropdown Filter Bulan
        expect(find.text('Semua Bulan (Keseluruhan)'), findsWidgets);
      },
    );

    testWidgets(
      'Mobile Layout: Renders DrawerMenuButton when embedded and displays responsive vertical layout',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        reportRepo.setReportsForTesting([
          ReportModel(
            id: 'rep-mob-1',
            reportNumber: 'LAP-MOB-1',
            authorId: testCitizen.id,
            authorName: testCitizen.fullName,
            authorUsername: testCitizen.username,
            title: 'Laporan Mobile',
            description: 'Desc Mobile',
            category: 'Sampah & Kebersihan',
            locationAddress: 'Alamat Mobile',
            latitude: -6.2,
            longitude: 106.8,
            areaId: 'area-1',
            areaName: 'DKI Jakarta',
            handlingStatus: HandlingStatus.newReport,
            publicationState: PublicationState.published,
            createdAt: DateTime(2026, 11, 2),
            updatedAt: DateTime(2026, 11, 2),
          ),
        ]);

        await tester.pumpWidget(
          createTestApp(
            child: const AdminStatisticsScreen(isEmbedded: true),
          ),
        );
        await tester.pumpAndSettle();

        // Di layar mobile dengan isEmbedded: true, DrawerMenuButton harus tampil
        expect(find.byType(DrawerMenuButton), findsOneWidget);

        // Komponen statistik tetap lengkap
        expect(find.text('Statistik Laporan'), findsOneWidget);
        expect(find.text('Total Laporan'), findsOneWidget);
        expect(find.text('Grafik Tren Laporan Bulanan'), findsOneWidget);
      },
    );

    testWidgets(
      'AdminNavigationScreen integrates Statistik tab on desktop and mobile',
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

        // 1. Item 'Statistik' ada di navigasi
        expect(find.text('Statistik'), findsOneWidget);

        // 2. Ketuk 'Statistik' di sidebar desktop
        await tester.tap(find.text('Statistik'));
        await tester.pumpAndSettle();

        // 3. Tab index berpindah ke 3 dan AdminStatisticsScreen ditampilkan
        expect(navCtrl.currentIndex, equals(3));
        expect(find.byType(AdminStatisticsScreen), findsOneWidget);
      },
    );

    test(
      'Daily Statistics: Aggregates reports per date and retains deleted reports',
      () async {
        final repDay1 = ReportModel(
          id: 'rep-day-1',
          reportNumber: 'LAP-DAY-1',
          authorId: testCitizen.id,
          authorName: testCitizen.fullName,
          authorUsername: testCitizen.username,
          title: 'Laporan Hari 1',
          description: 'Desc 1',
          category: 'Jalan & Jembatan',
          locationAddress: 'Alamat 1',
          latitude: -6.2,
          longitude: 106.8,
          areaId: 'area-1',
          areaName: 'DKI Jakarta',
          handlingStatus: HandlingStatus.completed,
          publicationState: PublicationState.published,
          createdAt: DateTime(2026, 11, 15, 10, 0),
          updatedAt: DateTime(2026, 11, 15, 10, 0),
        );

        final repDay2 = ReportModel(
          id: 'rep-day-2',
          reportNumber: 'LAP-DAY-2',
          authorId: testCitizen.id,
          authorName: testCitizen.fullName,
          authorUsername: testCitizen.username,
          title: 'Laporan Hari 2 (Sama tanggal)',
          description: 'Desc 2',
          category: 'Sampah & Kebersihan',
          locationAddress: 'Alamat 2',
          latitude: -6.21,
          longitude: 106.81,
          areaId: 'area-1',
          areaName: 'DKI Jakarta',
          handlingStatus: HandlingStatus.inProgress,
          publicationState: PublicationState.published,
          createdAt: DateTime(2026, 11, 15, 14, 0),
          updatedAt: DateTime(2026, 11, 15, 14, 0),
        );

        final repDay3 = ReportModel(
          id: 'rep-day-3',
          reportNumber: 'LAP-DAY-3',
          authorId: testCitizen.id,
          authorName: testCitizen.fullName,
          authorUsername: testCitizen.username,
          title: 'Laporan Tanggal Lain',
          description: 'Desc 3',
          category: 'Lampu Jalan',
          locationAddress: 'Alamat 3',
          latitude: -6.22,
          longitude: 106.82,
          areaId: 'area-1',
          areaName: 'DKI Jakarta',
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime(2026, 11, 16, 9, 0),
          updatedAt: DateTime(2026, 11, 16, 9, 0),
        );

        reportRepo.setReportsForTesting([repDay1, repDay2, repDay3]);

        final dailyStats = await reportRepo.getDailyStatistics();
        expect(dailyStats.length, equals(2));

        final stat15 = dailyStats.firstWhere((d) => d.dateString == '2026-11-15');
        expect(stat15.totalReports, equals(2));
        expect(stat15.completedReports, equals(1));
        expect(stat15.inProgressReports, equals(1));
        expect(stat15.categoryCounts['Jalan & Jembatan'], equals(1));
        expect(stat15.categoryCounts['Sampah & Kebersihan'], equals(1));

        final stat16 = dailyStats.firstWhere((d) => d.dateString == '2026-11-16');
        expect(stat16.totalReports, equals(1));
        expect(stat16.newReports, equals(1));

        // Test filtering via AdminStatisticsController
        final controller = AdminStatisticsController(reportRepository: reportRepo);
        await controller.fetchStatistics();
        await controller.setFilterMode(StatisticsFilterMode.daily);

        expect(controller.filterMode, equals(StatisticsFilterMode.daily));
        expect(controller.totalReports, equals(3));
        expect(controller.availableDates, containsAll(['2026-11-15', '2026-11-16']));

        // Filter ke tanggal spesifik 15 Nov 2026
        controller.selectDate('2026-11-15');
        expect(controller.selectedDate, equals('2026-11-15'));
        expect(controller.totalReports, equals(2));
        expect(controller.completedReports, equals(1));
        expect(controller.inProgressReports, equals(1));

        // Reset filter tanggal
        controller.selectDate(null);
        expect(controller.selectedDate, isNull);
        expect(controller.totalReports, equals(3));
      },
    );

    testWidgets(
      'Widget: Switching to Per Hari mode displays daily chart and date filtering',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        reportRepo.setReportsForTesting([
          ReportModel(
            id: 'rep-daily-w1',
            reportNumber: 'LAP-W-1',
            authorId: testCitizen.id,
            authorName: testCitizen.fullName,
            authorUsername: testCitizen.username,
            title: 'Laporan Hari A',
            description: 'Desc A',
            category: 'Jalan & Jembatan',
            locationAddress: 'Alamat A',
            latitude: -6.2,
            longitude: 106.8,
            areaId: 'area-1',
            areaName: 'DKI Jakarta',
            handlingStatus: HandlingStatus.newReport,
            publicationState: PublicationState.published,
            createdAt: DateTime(2026, 11, 10, 8, 0),
            updatedAt: DateTime(2026, 11, 10, 8, 0),
          ),
          ReportModel(
            id: 'rep-daily-w2',
            reportNumber: 'LAP-W-2',
            authorId: testCitizen.id,
            authorName: testCitizen.fullName,
            authorUsername: testCitizen.username,
            title: 'Laporan Hari B',
            description: 'Desc B',
            category: 'Sampah & Kebersihan',
            locationAddress: 'Alamat B',
            latitude: -6.2,
            longitude: 106.8,
            areaId: 'area-1',
            areaName: 'DKI Jakarta',
            handlingStatus: HandlingStatus.completed,
            publicationState: PublicationState.published,
            createdAt: DateTime(2026, 11, 12, 10, 0),
            updatedAt: DateTime(2026, 11, 12, 10, 0),
          ),
        ]);

        await tester.pumpWidget(
          createTestApp(child: const AdminStatisticsScreen()),
        );
        await tester.pumpAndSettle();

        // 1. Verifikasi mode default adalah Per Bulan
        expect(find.text('Per Bulan'), findsOneWidget);
        expect(find.text('Per Hari'), findsOneWidget);
        expect(find.text('Grafik Tren Laporan Bulanan'), findsOneWidget);

        // 2. Ketuk tombol 'Per Hari'
        await tester.tap(find.text('Per Hari'));
        await tester.pumpAndSettle();

        // 3. Verifikasi grafik berubah ke 'Grafik Laporan Masuk per Tanggal'
        expect(find.text('Grafik Laporan Masuk per Tanggal'), findsOneWidget);
        expect(find.text('Rincian Laporan Masuk per Tanggal'), findsOneWidget);

        // 4. Verifikasi tanggal muncul di daftar
        expect(find.text('10 Nov'), findsWidgets);
        expect(find.text('12 Nov'), findsWidgets);

        // 5. Ketuk salah satu batang tanggal untuk memfilter
        await tester.tap(find.text('10 Nov').first);
        await tester.pumpAndSettle();

        // 6. Tombol reset muncul
        expect(find.text('Reset Filter Tanggal'), findsOneWidget);

        // 7. Ketuk reset
        await tester.tap(find.text('Reset Filter Tanggal'));
        await tester.pumpAndSettle();
        expect(find.text('Reset Filter Tanggal'), findsNothing);
      },
    );

    testWidgets(
      'Widget: AdminStatisticsScreen auto-refreshes data when opening tab in AdminNavigationScreen',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        // Awal: 1 laporan
        reportRepo.setReportsForTesting([
          ReportModel(
            id: 'rep-initial',
            reportNumber: 'LAP-INIT',
            authorId: testCitizen.id,
            authorName: testCitizen.fullName,
            authorUsername: testCitizen.username,
            title: 'Laporan Awal',
            description: 'Desc',
            category: 'Jalan & Jembatan',
            locationAddress: 'Alamat',
            latitude: -6.2,
            longitude: 106.8,
            areaId: 'area-1',
            areaName: 'DKI Jakarta',
            handlingStatus: HandlingStatus.newReport,
            publicationState: PublicationState.published,
            createdAt: DateTime(2026, 11, 1),
            updatedAt: DateTime(2026, 11, 1),
          ),
        ]);

        final navCtrl = NavigationController(initialIndex: 0);

        await tester.pumpWidget(
          createTestApp(
            child: const AdminNavigationScreen(),
            navCtrl: navCtrl,
          ),
        );
        await tester.pumpAndSettle();

        // Sementara admin berada di tab 0, tambahkan laporan baru ke repository
        reportRepo.setReportsForTesting([
          ReportModel(
            id: 'rep-initial',
            reportNumber: 'LAP-INIT',
            authorId: testCitizen.id,
            authorName: testCitizen.fullName,
            authorUsername: testCitizen.username,
            title: 'Laporan Awal',
            description: 'Desc',
            category: 'Jalan & Jembatan',
            locationAddress: 'Alamat',
            latitude: -6.2,
            longitude: 106.8,
            areaId: 'area-1',
            areaName: 'DKI Jakarta',
            handlingStatus: HandlingStatus.newReport,
            publicationState: PublicationState.published,
            createdAt: DateTime(2026, 11, 1),
            updatedAt: DateTime(2026, 11, 1),
          ),
          ReportModel(
            id: 'rep-baru-masuk',
            reportNumber: 'LAP-BARU',
            authorId: testCitizen.id,
            authorName: testCitizen.fullName,
            authorUsername: testCitizen.username,
            title: 'Laporan Baru Masuk',
            description: 'Desc Baru',
            category: 'Sampah & Kebersihan',
            locationAddress: 'Alamat Baru',
            latitude: -6.2,
            longitude: 106.8,
            areaId: 'area-1',
            areaName: 'DKI Jakarta',
            handlingStatus: HandlingStatus.newReport,
            publicationState: PublicationState.published,
            createdAt: DateTime(2026, 11, 16),
            updatedAt: DateTime(2026, 11, 16),
          ),
        ]);

        // Buka tab Statistik (index 3)
        await tester.tap(find.text('Statistik'));
        await tester.pumpAndSettle();

        // Verifikasi otomatis refresh menampilkan 2 laporan
        expect(find.text('2 Laporan'), findsWidgets);
      },
    );
  });
}
