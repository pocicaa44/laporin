import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/announcement_repository.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/notification_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/create_report/controllers/create_report_controller.dart';
import 'package:laporin/features/create_report/screens/create_report_screen.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/my_reports/screens/my_reports_screen.dart';
import 'package:laporin/features/navigation/controllers/navigation_controller.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:laporin/features/report_detail/widgets/vote_action_bar.dart';
import 'package:laporin/features/settings/controllers/settings_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('Private Report & MyReports Screen Tests', () {
    late AuthRepository authRepo;
    late ReportRepository reportRepo;
    late CommentRepository commentRepo;
    late AnnouncementRepository announcementRepo;
    late NotificationRepository notifRepo;
    late SettingsController settingsCtrl;

    const testUser = UserProfileModel(
      id: 'citizen-101',
      email: 'warga@laporin.go.id',
      fullName: 'Ahmad Warga',
      username: 'ahmad_warga',
      role: UserRole.user,
      avatarUrl: '',
    );

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      authRepo = AuthRepository();
      reportRepo = ReportRepository();
      commentRepo = CommentRepository();
      announcementRepo = AnnouncementRepository();
      notifRepo = NotificationRepository();
      settingsCtrl = SettingsController();

      authRepo.setCurrentUserProfileForTesting(testUser);
    });

    Widget createTestApp({required Widget child}) {
      return MultiProvider(
        providers: [
          Provider<AuthRepository>.value(value: authRepo),
          Provider<ReportRepository>.value(value: reportRepo),
          Provider<CommentRepository>.value(value: commentRepo),
          Provider<NotificationRepository>.value(value: notifRepo),
          Provider<AnnouncementRepository>.value(value: announcementRepo),
          ChangeNotifierProvider<SettingsController>.value(value: settingsCtrl),
          ChangeNotifierProvider(
            create: (_) => AuthController(authRepository: authRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => FeedController(reportRepository: reportRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => NotificationController(
              repository: notifRepo,
              settingsController: settingsCtrl,
            ),
          ),
          ChangeNotifierProvider(create: (_) => NavigationController()),
          ChangeNotifierProvider(
            create: (_) => CreateReportController(reportRepository: reportRepo),
          ),
        ],
        child: MaterialApp(home: child),
      );
    }

    test('ReportModel: isPrivate defaults to false and sets invariants', () {
      final now = DateTime.now();
      final publicReport = ReportModel(
        id: 'rep-public-1',
        reportNumber: 'LPR-2026-0001',
        authorId: 'citizen-101',
        authorName: 'Ahmad Warga',
        areaId: 'area-jateng',
        areaName: 'Kota Semarang',
        title: 'Jalan Rusak Parah',
        description: 'Jalan berlubang besar membahayakan',
        category: 'Jalan & Jembatan',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Jl. Pemuda No. 1',
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
        createdAt: now,
        updatedAt: now,
      );

      expect(publicReport.isPrivate, isFalse);
      expect(publicReport.isPubliclyVisible, isTrue);
      expect(publicReport.isVotingActive, isTrue);
      expect(publicReport.canAddComment, isTrue);

      final privateReport = publicReport.copyWith(isPrivate: true);
      expect(privateReport.isPrivate, isTrue);
      // Laporan privat tidak terlihat di feed publik
      expect(privateReport.isPubliclyVisible, isFalse);
      // Laporan privat tidak dapat divote
      expect(privateReport.isVotingActive, isFalse);
      // Laporan privat tidak dapat dikomentari
      expect(privateReport.canAddComment, isFalse);

      // JSON serialization & deserialization
      final json = privateReport.toJson();
      expect(json['is_private'], isTrue);

      final fromJson = ReportModel.fromJson(json);
      expect(fromJson.isPrivate, isTrue);
      expect(fromJson.isPubliclyVisible, isFalse);
    });

    test('ReportRepository: Private report is excluded from public feed, but accessible to author and admin', () async {
      // 1. Create public report
      final publicReport = await reportRepo.createReport(
        authorId: testUser.id,
        authorName: testUser.fullName,
        title: 'Lampu Jalan Mati',
        description: 'Lampu PJU mati di perempatan',
        category: 'Penerangan Jalan',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Jl. Gajah Mada',
        isPrivate: false,
      );

      // 2. Create private report
      final privateReport = await reportRepo.createReport(
        authorId: testUser.id,
        authorName: testUser.fullName,
        title: 'Pungutan Liar Parkir',
        description: 'Ada oknum meminta pungutan liar',
        category: 'Ketertiban Umum',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Pasar Johar',
        isPrivate: true,
      );

      expect(publicReport.isPrivate, isFalse);
      expect(privateReport.isPrivate, isTrue);

      // 3. Verify public feed: only contains public report
      final publicFeed = await reportRepo.getPublicFeed();
      expect(publicFeed.any((r) => r.id == publicReport.id), isTrue);
      expect(publicFeed.any((r) => r.id == privateReport.id), isFalse);

      // 4. Verify my reports: contains both public and private reports
      final myReports = await reportRepo.getMyReports(testUser.id);
      expect(myReports.any((r) => r.id == publicReport.id), isTrue);
      expect(myReports.any((r) => r.id == privateReport.id), isTrue);

      // 5. Verify admin reports: contains both public and private reports
      final adminReports = await reportRepo.getAdminReports();
      expect(adminReports.any((r) => r.id == publicReport.id), isTrue);
      expect(adminReports.any((r) => r.id == privateReport.id), isTrue);

      // 6. Verify voting is rejected on private report
      expect(
        () => reportRepo.voteReport(
          reportId: privateReport.id,
          userId: 'voter-1',
          voteType: 'up',
        ),
        throwsA(isA<Exception>()),
      );
    });

    testWidgets('CreateReportController: supports toggling isPrivate', (WidgetTester tester) async {
      final controller = CreateReportController(reportRepository: reportRepo);
      expect(controller.isPrivate, isFalse);

      controller.setIsPrivate(true);
      expect(controller.isPrivate, isTrue);

      controller.setIsPrivate(false);
      expect(controller.isPrivate, isFalse);
    });

    testWidgets('CreateReportScreen: Visibility options display strictly "Publik" and "Privat" without subtitles or over-helpfulness', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(child: const CreateReportScreen()));
      await tester.pumpAndSettle();

      // Options display strictly 'Publik' and 'Privat'
      expect(find.text('Publik'), findsOneWidget);
      expect(find.text('Privat'), findsOneWidget);

      // Verifies absence of verbose subtitles / context leak
      expect(find.text('Feed Publik'), findsNothing);
      expect(find.textContaining('Dapat dilihat & didukung'), findsNothing);
      expect(find.textContaining('Komentar & vote dinonaktifkan'), findsNothing);

      // Tapping 'Privat' toggles selection
      await tester.ensureVisible(find.text('Privat'));
      await tester.tap(find.text('Privat'));
      await tester.pumpAndSettle();

      // Check checkmark icon is rendered next to Privat
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('MyReportsScreen: Stats KPI cards are dropped, only reports list and filter chips rendered', (WidgetTester tester) async {
      // Create reports with different statuses
      await reportRepo.createReport(
        authorId: testUser.id,
        authorName: testUser.fullName,
        title: 'Laporan 1 Menunggu',
        description: 'Deskripsi laporan satu',
        category: 'Fasilitas Umum',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Alamat 1',
      );

      await reportRepo.createReport(
        authorId: testUser.id,
        authorName: testUser.fullName,
        title: 'Laporan 2 Privat',
        description: 'Deskripsi laporan dua privat',
        category: 'Ketertiban Umum',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Alamat 2',
        isPrivate: true,
      );

      await tester.pumpWidget(createTestApp(child: const MyReportsScreen()));
      await tester.pumpAndSettle();

      // 1. Stats KPI cards (Total Laporan, Menunggu, Diproses, Selesai) are DROPPED
      expect(find.text('Total Laporan'), findsNothing);
      expect(find.byIcon(Icons.assignment_outlined), findsNothing);
      expect(find.byIcon(Icons.engineering_outlined), findsNothing);

      // 2. Filter chips are present without count stats
      expect(find.text('Semua'), findsOneWidget);
      expect(find.text('Menunggu'), findsOneWidget);
      expect(find.text('Diproses'), findsOneWidget);
      expect(find.text('Selesai'), findsOneWidget);

      // 3. Reports are displayed directly
      expect(find.text('Laporan 1 Menunggu'), findsOneWidget);
      expect(find.text('Laporan 2 Privat'), findsOneWidget);

      // 4. Private report displays the 'Privat' badge
      expect(find.text('Privat'), findsOneWidget);
    });

    testWidgets('MyReportsScreen: Card header does not overflow on narrow mobile screens (360px)', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await reportRepo.createReport(
        authorId: testUser.id,
        authorName: testUser.fullName,
        title: 'pppppppppppppppppppppppppppppppppppppppp',
        description: 'Laporan sempit',
        category: 'Fasilitas Umum',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Kel. Sekayu, Semarang',
        isPrivate: true,
      );

      await tester.pumpWidget(createTestApp(child: const MyReportsScreen()));
      await tester.pumpAndSettle();

      // No overflow exceptions thrown
      expect(tester.takeException(), isNull);
      expect(find.text('Privat'), findsOneWidget);
      expect(find.text('Fasilitas Umum'), findsWidgets);
    });

    testWidgets('ReportDetailScreen: Private report eliminates comments and vote features', (WidgetTester tester) async {
      final privateReport = await reportRepo.createReport(
        authorId: testUser.id,
        authorName: testUser.fullName,
        title: 'Laporan Rahasia Privat',
        description: 'Laporan ini tidak boleh ada komentar atau vote',
        category: 'Pelayanan Publik',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Kantor Kelurahan',
        isPrivate: true,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ReportDetailScreen(
            reportId: privateReport.id,
            initialReport: privateReport,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Vote action bar is eliminated / NOT rendered
      expect(find.byType(VoteActionBar), findsNothing);

      // 2. Comments header is eliminated / NOT rendered
      expect(find.textContaining('Komentar & Diskusi'), findsNothing);
      expect(find.textContaining('Diskusi & Komentar'), findsNothing);

      // 3. Comment composer text field is eliminated / NOT rendered
      expect(find.byType(TextField), findsNothing);
      expect(find.byTooltip('Kirim Komentar'), findsNothing);

      // 4. Private report info banner is rendered
      expect(find.text('Laporan Privat'), findsWidgets);
      expect(
        find.textContaining('Fitur komentar dan penilaian suara (vote) dinonaktifkan.'),
        findsOneWidget,
      );
    });

    testWidgets('ReportDetailScreen: Public report retains comments and vote features', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final publicReport = await reportRepo.createReport(
        authorId: testUser.id,
        authorName: testUser.fullName,
        title: 'Laporan Publik Normal',
        description: 'Laporan ini ada komentar dan vote',
        category: 'Jalan & Jembatan',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Jl. Malioboro',
        isPrivate: false,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ReportDetailScreen(
            reportId: publicReport.id,
            initialReport: publicReport,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Vote action bar IS rendered
      expect(find.byType(VoteActionBar), findsOneWidget);

      // 2. Comments header IS rendered
      expect(find.textContaining('Komentar & Diskusi'), findsOneWidget);

      // 3. Comment composer text field IS rendered
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
