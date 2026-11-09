import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/services/boundary_service.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/edit_report/screens/edit_report_screen.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:laporin/features/report_detail/widgets/delete_report_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  group('1. ReportModel Soft Delete & Edit Invariants Tests', () {
    test('isDeleted getter and public visibility rules', () {
      final now = DateTime.now();
      final report = ReportModel(
        id: 'rep-1',
        reportNumber: 'LPR-2026-0001',
        authorId: 'user-1',
        authorName: 'Budi Santoso',
        areaId: 'area-jateng',
        areaName: 'Kota Semarang',
        title: 'Jalan Rusak di Simpang Lima',
        description: 'Lubang jalan cukup besar dan membahayakan pengendara.',
        category: 'Jalan & Infrastruktur',
        latitude: -6.9924,
        longitude: 110.4225,
        locationAddress: 'Jl. Simpang Lima, Semarang',
        handlingStatus: HandlingStatus.completed,
        publicationState: PublicationState.published,
        createdAt: now,
        updatedAt: now,
      );

      // Awalnya aktif
      expect(report.isDeleted, isFalse);
      expect(report.isPubliclyVisible, isTrue);
      expect(report.isTerminal, isFalse);

      // Setelah soft delete (deletedAt diisi)
      final deletedReport = report.copyWith(deletedAt: DateTime.now());
      expect(deletedReport.isDeleted, isTrue);
      expect(deletedReport.isPubliclyVisible, isFalse);
      expect(deletedReport.isTerminal, isTrue);
    });

    test('ReportModel serialization handles deleted_at correctly', () {
      final now = DateTime(2026, 10, 23, 14, 30);
      final json = {
        'id': 'rep-2',
        'report_number': 'LPR-2026-0002',
        'author_id': 'user-1',
        'author_name': 'Budi',
        'area_id': 'area-jateng',
        'area_name': 'Kota Semarang',
        'title': 'Lampu Jalan Mati',
        'description': 'Lampu penerangan jalan umum mati total di malam hari.',
        'category': 'Fasilitas Umum',
        'latitude': -6.9924,
        'longitude': 110.4225,
        'location_address': 'Semarang',
        'handling_status': 'cancelled',
        'publication_state': 'published',
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'deleted_at': now.toIso8601String(),
      };

      final parsed = ReportModel.fromJson(json);
      expect(parsed.isDeleted, isTrue);
      expect(parsed.deletedAt, equals(now));

      final serialized = parsed.toJson();
      expect(serialized['deleted_at'], equals(now.toUtc().toIso8601String()));
    });
  });

  group('2. ReportRepository CRUD Business Rules Tests', () {
    late ReportRepository repo;
    late ReportModel initialReport;

    setUp(() async {
      repo = ReportRepository();
      initialReport = await repo.createReport(
        authorId: 'user-1',
        authorName: 'Budi Santoso',
        title: 'Jalan Rusak di Tugu Muda',
        description: 'Terdapat lubang besar berdiameter 50cm di dekat Tugu Muda Semarang.',
        category: 'Jalan & Infrastruktur',
        latitude: -6.9840,
        longitude: 110.4090, // Semarang (Jawa Tengah)
        locationAddress: 'Jl. Pemuda, Semarang',
        photoUrls: ['https://example.com/photo1.jpg'],
      );
    });

    test('updateReportDetails succeeds for authorized owner with valid Central Java location', () async {
      final updated = await repo.updateReportDetails(
        reportId: initialReport.id,
        currentUserId: 'user-1',
        title: 'Jalan Rusak Parah di Tugu Muda',
        description: 'Deskripsi diperbarui: Lubang semakin dalam setelah hujan deras kemarin malam.',
        category: 'Jalan & Infrastruktur',
        latitude: -6.9850,
        longitude: 110.4100, // Tetap di Semarang
        locationAddress: 'Jl. Pemuda No. 10, Semarang',
        photoUrls: [
          'https://example.com/photo1.jpg',
          'https://example.com/photo2.jpg',
        ],
      );

      expect(updated.title, equals('Jalan Rusak Parah di Tugu Muda'));
      expect(updated.photoUrls.length, equals(2));
      expect(updated.locationAddress, contains('No. 10'));

      final fromRepo = await repo.getReportById(initialReport.id);
      expect(fromRepo?.title, equals('Jalan Rusak Parah di Tugu Muda'));
    });

    test('updateReportDetails rejects unauthorized user', () async {
      expect(
        () => repo.updateReportDetails(
          reportId: initialReport.id,
          currentUserId: 'imposter-user',
          title: 'Judul Diubah',
          description: 'Deskripsi baru yang sah dan panjang.',
          category: 'Jalan & Infrastruktur',
          latitude: -6.9840,
          longitude: 110.4090,
          locationAddress: 'Jl. Pemuda, Semarang',
          photoUrls: [],
        ),
        throwsA(predicate((e) => e.toString().contains('tidak memiliki izin'))),
      );
    });

    test('updateReportDetails rejects location outside Indonesia', () async {
      expect(
        () => repo.updateReportDetails(
          reportId: initialReport.id,
          currentUserId: 'user-1',
          title: 'Judul Baru yang Valid',
          description: 'Deskripsi baru yang sah dan panjang.',
          category: 'Jalan & Infrastruktur',
          latitude: 35.6762, // Tokyo (Di luar wilayah Indonesia)
          longitude: 139.6503,
          locationAddress: 'Tokyo, Japan',
          photoUrls: [],
        ),
        throwsA(
          predicate(
            (e) => e.toString().contains(
              BoundaryService.outsideIndonesiaErrorMessage,
            ),
          ),
        ),
      );
    });

    test('softDeleteReport marks report as deleted and cancelled', () async {
      await repo.updateHandlingStatus(
        reportId: initialReport.id,
        newStatus: HandlingStatus.cancelled,
        reason: 'Dibatalkan oleh pemohon',
      );
      final deleted = await repo.softDeleteReport(
        reportId: initialReport.id,
        currentUserId: 'user-1',
      );

      expect(deleted.isDeleted, isTrue);
      expect(deleted.handlingStatus, equals(HandlingStatus.cancelled));
      expect(deleted.terminalAt, isNotNull);
      expect(deleted.archiveAfter, isNotNull);
      expect(deleted.moderationReason, equals('Dihapus oleh pelapor'));

      // Verifikasi di getPublicFeed: laporan harus hilang
      final publicFeed = await repo.getPublicFeed();
      expect(publicFeed.any((r) => r.id == initialReport.id), isFalse);

      // Verifikasi di getMyReports: laporan tidak muncul di daftar aktif
      final myReports = await repo.getMyReports('user-1');
      expect(myReports.any((r) => r.id == initialReport.id), isFalse);
    });

    test('softDeleteReport rejects non-owner', () async {
      expect(
        () => repo.softDeleteReport(
          reportId: initialReport.id,
          currentUserId: 'intruder-user',
        ),
        throwsA(predicate((e) => e.toString().contains('tidak memiliki izin'))),
      );
    });

    test(
      'updateReportDetails rejects editing an already soft-deleted report',
      () async {
        await repo.updateHandlingStatus(
          reportId: initialReport.id,
          newStatus: HandlingStatus.completed,
          completionProofUrl: 'https://example.com/proof.jpg',
        );
        await repo.softDeleteReport(
          reportId: initialReport.id,
          currentUserId: 'user-1',
        );

        expect(
          () => repo.updateReportDetails(
            reportId: initialReport.id,
            currentUserId: 'user-1',
            title: 'Judul Baru',
            description: 'Deskripsi baru yang panjang.',
            category: 'Jalan & Infrastruktur',
            latitude: -6.9840,
            longitude: 110.4090,
            locationAddress: 'Semarang',
            photoUrls: [],
          ),
          throwsA(predicate((e) => e.toString().contains('sudah dihapus'))),
        );
      },
    );
  });

  group('3. Widget Tests for Edit and Soft Delete UI', () {
    late ReportModel dummyReport;
    late ReportRepository repo;
    late AuthRepository authRepo;

    setUp(() {
      repo = ReportRepository();
      authRepo = AuthRepository();
      dummyReport = ReportModel(
        id: 'rep-ui-1',
        reportNumber: 'LPR-2026-0001',
        authorId: 'usr-1',
        authorName: 'Budi Santoso',
        areaId: 'area-jateng',
        areaName: 'Kota Semarang',
        title: 'Sampah Menumpuk di Pasar Bulu',
        description: 'Tumpukan sampah meluap ke badan jalan dan menimbulkan bau menyengat.',
        category: 'Kebersihan',
        latitude: -6.9850,
        longitude: 110.4050,
        locationAddress: 'Pasar Bulu, Semarang',
        handlingStatus: HandlingStatus.completed,
        publicationState: PublicationState.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photoUrls: ['https://example.com/sampah1.jpg'],
      );
      repo.updateReport(dummyReport);
    });

    testWidgets(
      'EditReportScreen renders initial report data and manages photos',
      (tester) async {
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'usr-1',
            email: 'budi@test.com',
            fullName: 'Budi Santoso',
          ),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: repo),
              Provider.value(value: authRepo),
              ChangeNotifierProvider(
                create: (_) => AuthController(authRepository: authRepo),
              ),
            ],
            child: MaterialApp(home: EditReportScreen(report: dummyReport)),
          ),
        );

        await tester.pumpAndSettle();

        // Form harus terisi data awal
        expect(find.text('Edit Laporan'), findsOneWidget);
        expect(find.text('Sampah Menumpuk di Pasar Bulu'), findsOneWidget);
        expect(find.text('Kebersihan'), findsOneWidget);
        expect(find.text('Pasar Bulu, Semarang'), findsOneWidget);
        expect(find.text('Tersimpan'), findsOneWidget);

        // Hapus foto tersimpan
        await tester.tap(find.byIcon(Icons.close));
        await tester.pumpAndSettle();
        expect(find.text('0/5 Foto'), findsOneWidget);

        await tester.scrollUntilVisible(
          find.text('Simpan Perubahan'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Simpan Perubahan'), findsOneWidget);
      },
    );

    testWidgets('DeleteReportDialog cancels and confirms properly', (
      tester,
    ) async {
      bool deleteCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DeleteReportDialog(
              reportNumber: 'LPR-2026-0001',
              onConfirmDelete: () async {
                deleteCalled = true;
                return true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Hapus Laporan?'), findsOneWidget);
      expect(find.textContaining('LPR-2026-0001'), findsOneWidget);
      expect(find.text('Batal'), findsOneWidget);
      expect(find.text('Hapus Laporan'), findsOneWidget);

      // Tekan tombol Hapus
      await tester.tap(find.text('Hapus Laporan'));
      await tester.pumpAndSettle();

      expect(deleteCalled, isTrue);
    });

    testWidgets(
      'ReportDetailScreen shows Edit and Delete for owner and hides for non-owner',
      (tester) async {
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'usr-1', // Sama dengan authorId
            email: 'budi@test.com',
            fullName: 'Budi Santoso',
          ),
        );

        // 1. Render untuk pemilik laporan (usr-1)
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: repo),
              Provider.value(value: authRepo),
              Provider.value(value: CommentRepository()),
              ChangeNotifierProvider(
                create: (_) => AuthController(authRepository: authRepo),
              ),
            ],
            child: MaterialApp(
              home: ReportDetailScreen(
                reportId: dummyReport.id,
                initialReport: dummyReport,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Popup menu aksi harus ada untuk pemilik
        expect(find.byType(PopupMenuButton<String>), findsOneWidget);

        // Buka popup menu
        await tester.tap(find.byType(PopupMenuButton<String>));
        await tester.pumpAndSettle();

        expect(find.text('Edit Laporan'), findsOneWidget);
        expect(find.text('Hapus Laporan'), findsOneWidget);
      },
    );

    testWidgets('ReportDetailScreen hides Edit and Delete for non-owner', (
      tester,
    ) async {
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'other-user', // Berbeda dari authorId
          email: 'other@test.com',
          fullName: 'Orang Lain',
        ),
      );

      // 2. Render untuk orang lain (bukan pemilik)
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: repo),
            Provider.value(value: authRepo),
            Provider.value(value: CommentRepository()),
            ChangeNotifierProvider(
              create: (_) => AuthController(authRepository: authRepo),
            ),
          ],
          child: MaterialApp(
            home: ReportDetailScreen(
              reportId: dummyReport.id,
              initialReport: dummyReport,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Popup menu tidak boleh tampil untuk non-owner
      expect(find.byType(PopupMenuButton<String>), findsNothing);
    });
  });
}
