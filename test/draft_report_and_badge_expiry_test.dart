import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/utils/date_formatter.dart';
import 'package:laporin/core/widgets/status_badge.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/create_report/controllers/create_report_controller.dart';
import 'package:laporin/features/create_report/screens/create_report_screen.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('1. Draft Report Model & Repository Invariants', () {
    late ReportRepository repo;

    setUp(() {
      repo = ReportRepository();
    });

    test(
      'Creating a report as draft sets isDraft true and pendingReview',
      () async {
        final report = await repo.createReport(
          authorId: 'user-123',
          authorName: 'Warga Satu',
          title: 'Lampu PJU Padam di Simpang Lima',
          description:
              'Lampu penerangan padam sejak semalam dan rawan kecelakaan.',
          category: 'Jalan & Infrastruktur',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Simpang Lima, Semarang',
          isDraft: true,
        );

        expect(report.isDraft, isTrue);
        expect(report.publicationState, equals(PublicationState.pendingReview));
        expect(report.publishedAt, isNull);
        expect(report.isPubliclyVisible, isFalse);
        expect(report.canAuthorDelete, isTrue);
      },
    );

    test(
      'Draft reports are hidden from public feed but visible in myReports',
      () async {
        await repo.createReport(
          authorId: 'user-123',
          authorName: 'Warga Satu',
          title: 'Draft Laporan 1',
          description: 'Deskripsi laporan yang masih berupa draft oleh warga.',
          category: 'Fasilitas Publik',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Semarang',
          isDraft: true,
        );

        await repo.createReport(
          authorId: 'user-123',
          authorName: 'Warga Satu',
          title: 'Laporan Publik 1',
          description:
              'Deskripsi laporan yang langsung dipublikasikan oleh warga.',
          category: 'Fasilitas Publik',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Semarang',
          isDraft: false,
        );

        final publicFeed = await repo.getPublicFeed();
        expect(publicFeed.length, equals(1));
        expect(publicFeed.first.title, equals('Laporan Publik 1'));

        final myReports = await repo.getMyReports('user-123');
        expect(myReports.length, equals(2));
        expect(myReports.any((r) => r.isDraft), isTrue);
        expect(myReports.any((r) => !r.isDraft), isTrue);
      },
    );

    test('publishDraft transitions report to published state', () async {
      final draft = await repo.createReport(
        authorId: 'user-123',
        authorName: 'Warga Satu',
        title: 'Draft Yang Akan Dipublikasikan',
        description: 'Deskripsi lengkap masalah yang siap dipublikasikan.',
        category: 'Kebersihan',
        latitude: -6.9932,
        longitude: 110.4203,
        locationAddress: 'Semarang',
        isDraft: true,
      );

      expect(draft.isDraft, isTrue);
      expect(draft.isPubliclyVisible, isFalse);

      final published = await repo.publishDraft(draft.id);
      expect(published.isDraft, isFalse);
      expect(published.publicationState, equals(PublicationState.published));
      expect(published.publishedAt, isNotNull);
      expect(published.isPubliclyVisible, isTrue);

      final publicFeed = await repo.getPublicFeed();
      expect(publicFeed.any((r) => r.id == draft.id), isTrue);
    });
  });

  group('2. Badge "Baru" Expiry After 1 Hour Tests', () {
    testWidgets(
      'HandlingStatusBadge displays "Baru" when report is less than 1 hour old',
      (tester) async {
        final recentDate = DateTime.now().subtract(const Duration(minutes: 20));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandlingStatusBadge(
                status: HandlingStatus.newReport,
                createdAt: recentDate,
              ),
            ),
          ),
        );

        expect(find.text('Baru'), findsOneWidget);
        expect(find.byIcon(Icons.fiber_new_rounded), findsOneWidget);
      },
    );

    testWidgets(
      'HandlingStatusBadge hides "Baru" when report is older than 1 hour (>= 60 min)',
      (tester) async {
        final olderDate = DateTime.now().subtract(const Duration(minutes: 65));

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: HandlingStatusBadge(
                status: HandlingStatus.newReport,
                createdAt: olderDate,
              ),
            ),
          ),
        );

        expect(find.text('Baru'), findsNothing);
        expect(find.byIcon(Icons.fiber_new_rounded), findsNothing);
      },
    );

    testWidgets('HandlingStatusBadge displays "Draft" when isDraft is true', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandlingStatusBadge(
              status: HandlingStatus.newReport,
              isDraft: true,
            ),
          ),
        ),
      );

      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Baru'), findsNothing);
      expect(find.byIcon(Icons.edit_note_rounded), findsOneWidget);
    });

    test(
      'DateTimeFormatX.toReportTimeLabel does not return "Baru" after 1 hour',
      () {
        final recent = DateTime.now().subtract(const Duration(minutes: 15));
        final older = DateTime.now().subtract(const Duration(hours: 2));

        // Untuk admin yang belum melihat:
        expect(
          recent.toReportTimeLabel(isAdmin: true, isViewedByAdmin: false),
          equals('Baru'),
        );
        expect(
          older.toReportTimeLabel(isAdmin: true, isViewedByAdmin: false),
          equals('2 jam lalu'),
        );

        // Untuk user biasa:
        expect(recent.toReportTimeLabel(isAdmin: false), equals('Baru saja'));
        expect(older.toReportTimeLabel(isAdmin: false), equals('2 jam lalu'));
      },
    );
  });

  group('3. CreateReportScreen Confirmation Dialog Tests', () {
    late AuthRepository authRepo;
    late ReportRepository reportRepo;
    late CommentRepository commentRepo;

    setUp(() {
      authRepo = AuthRepository();
      reportRepo = ReportRepository();
      commentRepo = CommentRepository();
    });

    Widget createTestApp({required Widget child}) {
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'usr-tester-1',
          email: 'warga@laporin.id',
          fullName: 'Warga Teladan',
          role: UserRole.user,
        ),
      );

      return MultiProvider(
        providers: [
          Provider<ReportRepository>.value(value: reportRepo),
          Provider<AuthRepository>.value(value: authRepo),
          Provider<CommentRepository>.value(value: commentRepo),
          ChangeNotifierProvider(
            create: (_) => AuthController(authRepository: authRepo),
          ),
        ],
        child: MaterialApp(home: child),
      );
    }

    testWidgets(
      'Clicking "Kirim Laporan" opens confirmation dialog with "Simpan Draft" and "Publikasikan"',
      (tester) async {
        final controller = CreateReportController(reportRepository: reportRepo);
        controller.setLocation(
          address: 'Jl. Pemuda No. 10, Semarang',
          lat: -6.9820,
          lng: 110.4200,
          areaName: 'Kota Semarang',
        );

        await tester.pumpWidget(
          createTestApp(child: CreateReportScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        // Isi form
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Judul Laporan *'),
          'Jalan Rusak Depan Kantor Kelurahan',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Deskripsi Masalah *'),
          'Terdapat lubang jalan berdiameter 50cm cukup membahayakan lalu lintas.',
        );

        // Klik tombol Kirim Laporan
        final submitBtn = find.text('Kirim Laporan');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Dialog konfirmasi harus muncul dengan kedua pilihan
        expect(find.text('Kirim Laporan'), findsWidgets);
        expect(
          find.text(
            'Apakah Anda ingin menyimpan laporan ini sebagai draft atau langsung mempublikasikannya?',
          ),
          findsOneWidget,
        );
        expect(find.text('Simpan Draft'), findsOneWidget);
        expect(find.text('Publikasikan'), findsOneWidget);

        // Klik Simpan Draft
        await tester.tap(find.text('Simpan Draft'));
        await tester.pumpAndSettle();

        // Laporan berhasil disimpan sebagai draft
        expect(
          find.text('Laporan berhasil disimpan ke dalam Draft.'),
          findsOneWidget,
        );

        // Verifikasi di repository bahwa laporan yang tersimpan adalah draft
        final myReports = await reportRepo.getMyReports('usr-tester-1');
        expect(myReports.length, equals(1));
        expect(myReports.first.isDraft, isTrue);
        expect(
          myReports.first.publicationState,
          equals(PublicationState.pendingReview),
        );
      },
    );

    testWidgets(
      'Clicking "Publikasikan" in confirmation dialog publishes report immediately',
      (tester) async {
        final controller = CreateReportController(reportRepository: reportRepo);
        controller.setLocation(
          address: 'Jl. Pemuda No. 10, Semarang',
          lat: -6.9820,
          lng: 110.4200,
          areaName: 'Kota Semarang',
        );

        await tester.pumpWidget(
          createTestApp(child: CreateReportScreen(controller: controller)),
        );
        await tester.pumpAndSettle();

        // Isi form
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Judul Laporan *'),
          'Pohon Tumbang Menutup Jalan',
        );
        await tester.enterText(
          find.widgetWithText(TextFormField, 'Deskripsi Masalah *'),
          'Pohon tumbang menghalangi jalan raya utama setelah hujan lebat.',
        );

        // Klik tombol Kirim Laporan
        final submitBtn = find.text('Kirim Laporan');
        await tester.ensureVisible(submitBtn);
        await tester.tap(submitBtn);
        await tester.pumpAndSettle();

        // Dialog konfirmasi harus muncul
        expect(find.text('Publikasikan'), findsOneWidget);

        // Klik Publikasikan
        await tester.tap(find.text('Publikasikan'));
        await tester.pumpAndSettle();

        // Laporan berhasil dipublikasikan
        expect(
          find.text('Laporan berhasil dikirim dan siap dipantau.'),
          findsOneWidget,
        );

        // Verifikasi di repository bahwa laporan yang tersimpan bukan draft
        final myReports = await reportRepo.getMyReports('usr-tester-1');
        expect(myReports.length, equals(1));
        expect(myReports.first.isDraft, isFalse);
        expect(
          myReports.first.publicationState,
          equals(PublicationState.published),
        );
      },
    );

    testWidgets('Detail screen allows owner to publish a draft report', (
      tester,
    ) async {
      final draft = await reportRepo.createReport(
        authorId: 'usr-tester-1',
        authorName: 'Warga Teladan',
        title: 'Draft Laporan Baru',
        description:
            'Laporan dalam draft yang akan dipublikasikan dari layar detail.',
        category: 'Fasilitas Umum',
        latitude: -6.9932,
        longitude: 110.4203,
        locationAddress: 'Semarang',
        isDraft: true,
      );

      await tester.pumpWidget(
        createTestApp(
          child: ReportDetailScreen(reportId: draft.id, initialReport: draft),
        ),
      );
      await tester.pumpAndSettle();

      // Banner draft tampil
      expect(find.text('Draft Laporan'), findsOneWidget);
      expect(find.text('Publikasikan Sekarang'), findsOneWidget);

      // Klik tombol Publikasikan Sekarang
      await tester.tap(find.text('Publikasikan Sekarang'));
      await tester.pumpAndSettle();

      // Konfirmasi publikasi muncul
      expect(find.text('Publikasikan Laporan?'), findsOneWidget);
      await tester.tap(find.widgetWithText(ElevatedButton, 'Publikasikan'));
      await tester.pumpAndSettle();

      // Sukses dipublikasikan
      expect(find.text('Laporan berhasil dipublikasikan!'), findsOneWidget);

      // Banner draft hilang karena sudah dipublikasikan
      expect(find.text('Draft Laporan'), findsNothing);
    });
  });
}
