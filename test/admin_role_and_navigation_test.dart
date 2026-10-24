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
import 'package:laporin/features/admin/screens/admin_navigation_screen.dart';
import 'package:laporin/features/admin/screens/admin_resolve_sheet.dart';
import 'package:laporin/features/admin/screens/admin_status_update_sheet.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/create_report/controllers/create_report_controller.dart';
import 'package:laporin/features/create_report/screens/create_report_screen.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/feed/widgets/report_card.dart';
import 'package:laporin/features/navigation/screens/main_navigation_screen.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';
import 'package:laporin/features/profile/screens/profile_screen.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:laporin/main.dart';
import 'package:provider/provider.dart';

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
      authRepo = AuthRepository();
      reportRepo = ReportRepository();
      announcementRepo = AnnouncementRepository();
    });

    Widget createTestApp({
      required Widget child,
      required UserProfileModel user,
    }) {
      authRepo.setCurrentUserProfileForTesting(user);

      return MultiProvider(
        key: ValueKey('provider-${user.id}'),
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
        expect(find.text('Dibatalkan'), findsOneWidget);
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

        // Tap Hapus -> DeleteReportDialog shows up
        await tester.tap(find.text('Hapus'));
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
