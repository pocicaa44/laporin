import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/widgets/app_profile_bar.dart';
import 'package:laporin/core/widgets/user_avatar.dart';
import 'package:laporin/data/models/comment_model.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/feed/widgets/report_card.dart';
import 'package:laporin/features/report_detail/controllers/report_detail_controller.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:laporin/features/report_detail/widgets/comment_tile.dart';
import 'package:laporin/features/report_detail/widgets/status_timeline.dart';
import 'package:laporin/features/report_detail/widgets/vote_action_bar.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'ReportDetailScreen renders successfully with initialReport and photos without crashing',
    (tester) async {
      final testReport = ReportModel(
        id: 'rep-test-1',
        reportNumber: 'LPR-2026-0001',
        authorId: 'user-1',
        authorName: 'Budi Santoso',
        areaId: 'area-jateng',
        areaName: 'Kota Semarang',
        title: 'Jalan Rusak dan Berlubang di Simpang Lima',
        description: 'Lubang cukup dalam di badan jalan lajur kiri membahayakan pengendara motor.',
        category: 'Infrastruktur',
        latitude: -6.9924,
        longitude: 110.4225,
        locationAddress: 'Jl. Simpang Lima, Semarang',
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
        createdAt: DateTime(2026, 10, 22, 10, 0),
        updatedAt: DateTime(2026, 10, 22, 10, 0),
        photoUrls: [
          '/data/user/0/com.dewanto.laporin/cache/image_picker_1.jpg',
        ],
      );

      final authRepository = AuthRepository();
      final reportRepository = ReportRepository();
      final commentRepository = CommentRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: authRepository),
            Provider.value(value: reportRepository),
            Provider.value(value: commentRepository),
            ChangeNotifierProvider(
              create: (_) => AuthController(authRepository: authRepository),
            ),
          ],
          child: MaterialApp(
            home: ReportDetailScreen(
              reportId: testReport.id,
              initialReport: testReport,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('LPR-2026-0001'), findsOneWidget);
      expect(
        find.text('Jalan Rusak dan Berlubang di Simpang Lima'),
        findsOneWidget,
      );
      expect(find.text('Jl. Simpang Lima, Semarang'), findsOneWidget);
      expect(find.text('Infrastruktur'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Deskripsi Masalah'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Deskripsi Masalah'), findsOneWidget);
      expect(find.byType(ReportDetailScreen), findsOneWidget);
    },
  );

  testWidgets(
    'ReportDetailScreen displays completion notes and resolution card when report is completed',
    (tester) async {
      tester.view.physicalSize = const Size(1024, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final completedReport = ReportModel(
        id: 'rep-completed-1',
        reportNumber: 'LPR-2026-0888',
        authorId: 'user-1',
        authorName: 'Budi Santoso',
        areaId: 'area-jateng',
        areaName: 'Kota Semarang',
        title: 'Perbaikan Saluran Air Pasar',
        description: 'Saluran air meluap ke jalan.',
        category: 'Infrastruktur',
        latitude: -6.9924,
        longitude: 110.4225,
        locationAddress: 'Jl. Pemuda, Semarang',
        handlingStatus: HandlingStatus.completed,
        publicationState: PublicationState.published,
        createdAt: DateTime(2026, 10, 22, 10, 0),
        updatedAt: DateTime(2026, 10, 22, 14, 0),
        completionNotes: 'Pekerjaan perbaikan telah selesai',
        completionProofUrl: 'https://images.unsplash.com/completion_proof.jpg',
      );

      final authRepository = AuthRepository();
      final reportRepository = ReportRepository();
      final commentRepository = CommentRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: authRepository),
            Provider.value(value: reportRepository),
            Provider.value(value: commentRepository),
            ChangeNotifierProvider(
              create: (_) => AuthController(authRepository: authRepository),
            ),
          ],
          child: MaterialApp(
            home: ReportDetailScreen(
              reportId: completedReport.id,
              initialReport: completedReport,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify completion resolution card and notes are rendered
      expect(
        find.byKey(const Key('completion_resolution_card')),
        findsOneWidget,
      );
      expect(find.text('Penyelesaian Pekerjaan'), findsOneWidget);
      expect(find.text('Catatan Penyelesaian:'), findsOneWidget);
      expect(find.text('Pekerjaan perbaikan telah selesai'), findsWidgets);
    },
  );

  group('CommentRepository & ReportDetailController Tests', () {
    test('CommentRepository adds and retrieves comments for report', () async {
      final repo = CommentRepository();

      final c1 = await repo.addComment(
        reportId: 'rep-test-1',
        authorId: 'usr-1',
        authorName: 'Budi Santoso',
        authorRole: UserRole.user,
        body: 'Kondisi jalan ini memang sangat parah',
      );

      final c2 = await repo.addComment(
        reportId: 'rep-test-1',
        authorId: 'adm-1',
        authorName: 'Petugas PU Jateng',
        authorRole: UserRole.admin,
        body: 'Laporan telah kami terima dan tim inspeksi sedang meluncur.',
      );

      final comments = await repo.getComments('rep-test-1');
      expect(comments.length, equals(2));
      expect(comments.first.id, equals(c1.id));
      expect(comments.last.id, equals(c2.id));
      expect(
        comments.first.body,
        equals('Kondisi jalan ini memang sangat parah'),
      );
      expect(comments.last.authorRole, equals(UserRole.admin));
      expect(comments.last.isStaff, isTrue);

      // Comments for another report should be isolated
      final otherReportComments = await repo.getComments('rep-test-2');
      expect(otherReportComments, isEmpty);
    });

    test(
      'ReportDetailController submitComment adds comment and increments count',
      () async {
        final reportRepo = ReportRepository();
        final commentRepo = CommentRepository();

        final testReport = ReportModel(
          id: 'rep-comment-test',
          reportNumber: 'LPR-2026-0099',
          authorId: 'user-1',
          authorName: 'Dewanto',
          areaId: 'area-jateng',
          areaName: 'Kota Semarang',
          title: 'Jalan Rusak',
          description: 'Jalan rusak berlubang',
          category: 'Infrastruktur',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Semarang',
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          commentsCount: 0,
        );

        final controller = ReportDetailController(
          reportId: testReport.id,
          reportRepository: reportRepo,
          commentRepository: commentRepo,
          initialReport: testReport,
        );

        expect(controller.comments, isEmpty);
        expect(controller.report!.commentsCount, equals(0));

        // Submit empty comment should fail
        final emptyResult = await controller.submitComment(
          authorId: 'user-1',
          authorName: 'Dewanto',
          authorRole: UserRole.user,
          body: '   ',
        );
        expect(emptyResult, isFalse);
        expect(controller.comments, isEmpty);

        // Submit valid comment
        final success = await controller.submitComment(
          authorId: 'user-1',
          authorName: 'Dewanto',
          authorAvatarUrl: 'https://example.com/dewanto.png',
          authorRole: UserRole.user,
          body: 'Semoga segera diperbaiki ya pak',
        );

        expect(success, isTrue);
        expect(controller.comments.length, equals(1));
        expect(
          controller.comments.first.body,
          equals('Semoga segera diperbaiki ya pak'),
        );
        expect(
          controller.comments.first.authorAvatarUrl,
          equals('https://example.com/dewanto.png'),
        );
        expect(controller.report!.commentsCount, equals(1));

        // Verify ReportRepository was updated with new commentsCount
        final cachedReport = await reportRepo.getReportById(testReport.id);
        expect(cachedReport?.commentsCount, equals(1));

        // Verify FeedController/getPublicFeed returns the updated commentsCount
        final feed = await reportRepo.getPublicFeed();
        expect(
          feed.firstWhere((r) => r.id == testReport.id).commentsCount,
          equals(1),
        );

        controller.dispose();
      },
    );

    testWidgets('ReportCard displays correct number of comments', (
      tester,
    ) async {
      final reportWithComments = ReportModel(
        id: 'rep-card-test',
        reportNumber: 'LPR-2026-0088',
        authorId: 'usr-1',
        authorName: 'Budi Santoso',
        areaId: 'area-jateng',
        areaName: 'Kota Semarang',
        title: 'Lampu Penerangan Mati',
        description: 'Lampu jalan mati sejak kemarin',
        category: 'Penerangan',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Jl. Pemuda',
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        commentsCount: 3,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCard(
              report: reportWithComments,
              onTap: () {},
              onUpvote: () {},
              onDownvote: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('3 komentar'), findsOneWidget);
    });

    testWidgets(
      'CommentTile renders UserAvatar with avatarUrl and authorName',
      (tester) async {
        final commentWithAvatar = CommentModel(
          id: 'com-1',
          reportId: 'rep-1',
          authorId: 'user-1',
          authorName: 'Siti Rahma',
          authorAvatarUrl: 'https://example.com/avatar.jpg',
          authorRole: UserRole.user,
          body: 'Terima kasih atas laporannya!',
          createdAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(body: CommentTile(comment: commentWithAvatar)),
          ),
        );

        expect(find.byType(UserAvatar), findsOneWidget);
        final userAvatar = tester.widget<UserAvatar>(find.byType(UserAvatar));
        expect(userAvatar.name, equals('Siti Rahma'));
        expect(userAvatar.avatarUrl, equals('https://example.com/avatar.jpg'));
        expect(find.text('Siti Rahma'), findsOneWidget);
        expect(find.text('Terima kasih atas laporannya!'), findsOneWidget);
        expect(find.text('Petugas'), findsNothing);
      },
    );

    testWidgets('CommentTile renders Petugas badge for staff comment', (
      tester,
    ) async {
      final staffComment = CommentModel(
        id: 'com-2',
        reportId: 'rep-1',
        authorId: 'admin-1',
        authorName: 'Petugas PUPR',
        authorRole: UserRole.admin,
        body: 'Laporan sedang dalam penanganan tim teknis.',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CommentTile(comment: staffComment)),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.text('Petugas PUPR'), findsOneWidget);
      expect(find.text('Petugas'), findsOneWidget);
      expect(
        find.text('Laporan sedang dalam penanganan tim teknis.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'ReportDetailScreen shows CircularProgressIndicator while fetching report and then renders content',
      (tester) async {
        final authRepo = AuthRepository();
        final reportRepo = ReportRepository();
        final commentRepo = CommentRepository();

        final sampleReport = ReportModel(
          id: 'rep-from-notif-1',
          reportNumber: 'LPR-2026-9999',
          authorId: 'user-1',
          authorName: 'Budi Santoso',
          areaId: 'area-1',
          areaName: 'Kota Semarang',
          title: 'Lampu Jalan Padam',
          description: 'Lampu penerangan jalan padam sejak kemarin malam.',
          category: 'Penerangan',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Jl. Pemuda',
          handlingStatus: HandlingStatus.inProgress,
          publicationState: PublicationState.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Prepopulate repository so getReportById can find it
        reportRepo.updateReport(sampleReport);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: authRepo),
              Provider.value(value: reportRepo),
              Provider.value(value: commentRepo),
              ChangeNotifierProvider(
                create: (_) => AuthController(authRepository: authRepo),
              ),
            ],
            child: const MaterialApp(
              home: ReportDetailScreen(
                reportId: 'rep-from-notif-1',
                initialReport: null,
              ),
            ),
          ),
        );

        // On first frame, initialReport is null and controller is loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Memuat detail laporan...'), findsOneWidget);
        expect(find.text('Laporan Tidak Ditemukan'), findsNothing);

        // Let the async fetch complete
        await tester.pumpAndSettle();

        // Now the report should be displayed
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('LPR-2026-9999'), findsOneWidget);
        expect(find.text('Lampu Jalan Padam'), findsOneWidget);
      },
    );

    testWidgets(
      'ReportDetailScreen shows "Laporan Tidak Ditemukan" and retry button only after fetch fails',
      (tester) async {
        final authRepo = AuthRepository();
        final reportRepo = ReportRepository();
        final commentRepo = CommentRepository();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: authRepo),
              Provider.value(value: reportRepo),
              Provider.value(value: commentRepo),
              ChangeNotifierProvider(
                create: (_) => AuthController(authRepository: authRepo),
              ),
            ],
            child: const MaterialApp(
              home: ReportDetailScreen(
                reportId: 'rep-non-existent-999',
                initialReport: null,
              ),
            ),
          ),
        );

        // On initial frame, shows loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Laporan Tidak Ditemukan'), findsNothing);

        // Once async fetch finishes and report is not found
        await tester.pumpAndSettle();

        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.text('Laporan Tidak Ditemukan'), findsOneWidget);
        expect(find.text('Coba Muat Ulang'), findsOneWidget);
      },
    );

    testWidgets(
      'ReportDetailScreen shows delete confirmation dialog and deletes comment on confirm',
      (tester) async {
        tester.view.physicalSize = const Size(1024, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final authRepo = AuthRepository();
        final reportRepo = ReportRepository();
        final commentRepo = CommentRepository();

        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'user-current',
            email: 'user@example.com',
            fullName: 'User Saya',
            username: 'usersaya',
            role: UserRole.user,
          ),
        );
        final authController = AuthController(authRepository: authRepo);

        final testReport = ReportModel(
          id: 'rep-detail-del-test',
          reportNumber: 'LPR-2026-1122',
          authorId: 'user-other',
          authorName: 'Penulis Laporan',
          areaId: 'area-1',
          areaName: 'Kota Semarang',
          title: 'Laporan Uji Hapus Komentar',
          description: 'Deskripsi uji',
          category: 'Infrastruktur',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Jl. Uji',
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          commentsCount: 1,
        );

        await tester.runAsync(() async {
          await commentRepo.addComment(
            reportId: testReport.id,
            authorId: 'user-current',
            authorName: '@usersaya',
            authorRole: UserRole.user,
            body: 'Komentar saya di halaman detail',
          );
        });

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: authRepo),
              Provider.value(value: reportRepo),
              Provider.value(value: commentRepo),
              ChangeNotifierProvider.value(value: authController),
            ],
            child: MaterialApp(
              home: ReportDetailScreen(
                reportId: testReport.id,
                initialReport: testReport,
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));
        await tester.pumpAndSettle();

        // Verifikasi komentar dan tombol Balas & Hapus muncul
        expect(find.text('Komentar saya di halaman detail'), findsOneWidget);
        expect(find.text('Balas'), findsOneWidget);
        expect(find.text('Hapus'), findsOneWidget);

        // Tap Hapus -> Muncul Dialog Konfirmasi
        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();

        expect(find.text('Hapus Komentar?'), findsOneWidget);
        expect(find.text('Batal'), findsOneWidget);

        // Tap Batal -> Dialog tertutup, komentar tetap ada
        await tester.tap(find.text('Batal'));
        await tester.pumpAndSettle();

        expect(find.text('Hapus Komentar?'), findsNothing);
        expect(find.text('Komentar saya di halaman detail'), findsOneWidget);

        // Tap Hapus lagi -> Dialog muncul lagi
        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();

        // Tap Hapus di dalam dialog -> Komentar terhapus, SnackBar muncul
        final dialogHapusButton = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Hapus'),
        );
        await tester.tap(dialogHapusButton);
        await tester.pumpAndSettle();

        expect(find.text('Komentar berhasil dihapus'), findsOneWidget);
        expect(find.text('Komentar saya di halaman detail'), findsNothing);
      },
    );

    testWidgets(
      'Desktop Layout: ReportDetailScreen renders 2 columns with detail, progress, vote on left and comments on right',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        final desktopReport = ReportModel(
          id: 'rep-desk-1',
          reportNumber: 'LPR-2026-DESK',
          authorId: 'user-1',
          authorName: 'Budi Santoso',
          authorUsername: 'budisantoso',
          areaId: 'area-jateng',
          areaName: 'Kota Semarang',
          title: 'Perbaikan Lampu Jalan Simpang Lima',
          description:
              'Lampu jalan mati total sepanjang 200 meter di area Simpang Lima.',
          category: 'Penerangan Jalan',
          latitude: -6.9924,
          longitude: 110.4225,
          locationAddress: 'Jl. Simpang Lima, Semarang',
          handlingStatus: HandlingStatus.inProgress,
          publicationState: PublicationState.published,
          createdAt: DateTime(2026, 10, 22, 10, 0),
          updatedAt: DateTime(2026, 10, 22, 10, 0),
        );

        final authRepo = AuthRepository();
        final reportRepo = ReportRepository();
        final commentRepo = CommentRepository();
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'user-curr',
            email: 'user@test.id',
            fullName: 'User Penguji',
            username: 'userpenguji',
            role: UserRole.user,
          ),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: authRepo),
              Provider.value(value: reportRepo),
              Provider.value(value: commentRepo),
              ChangeNotifierProvider(
                create: (_) => AuthController(authRepository: authRepo),
              ),
            ],
            child: MaterialApp(
              home: ReportDetailScreen(
                reportId: desktopReport.id,
                initialReport: desktopReport,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Verifikasi AppProfileBar di AppBar pada mode desktop
        expect(find.byType(AppProfileBar), findsOneWidget);

        // 2. Verifikasi pemisah vertikal antar kolom (VerticalDivider)
        expect(find.byType(VerticalDivider), findsOneWidget);

        // 3. Verifikasi Bagian Kiri: Detail Laporan, Progress (StatusTimeline), dan Vote (VoteActionBar)
        expect(find.text('Perbaikan Lampu Jalan Simpang Lima'), findsOneWidget);
        expect(find.text('LPR-2026-DESK'), findsOneWidget);
        expect(find.byType(StatusTimeline), findsOneWidget);
        expect(find.byType(VoteActionBar), findsOneWidget);

        // 4. Verifikasi Bagian Kanan: Header Diskusi & Komentar serta Composer TextField
        expect(find.textContaining('Diskusi & Komentar'), findsOneWidget);
        expect(find.byType(TextField), findsOneWidget);
        expect(find.text('Tulis komentar atau tanggapan...'), findsOneWidget);
      },
    );
  });
}
