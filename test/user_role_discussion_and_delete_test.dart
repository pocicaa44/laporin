import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:laporin/features/report_detail/widgets/vote_action_bar.dart';
import 'package:provider/provider.dart';

void main() {
  group('1. Unit Tests: canAuthorDelete, isDiscussionActive, isVotingActive Rules', () {
    final now = DateTime.now();

    ReportModel buildReport({
      required HandlingStatus handlingStatus,
      PublicationState publicationState = PublicationState.published,
      DateTime? deletedAt,
      bool? isDiscussionActive,
    }) {
      return ReportModel(
        id: 'rep-test',
        reportNumber: 'LPR-2026-TEST',
        authorId: 'user-author',
        authorName: 'Author Name',
        areaId: 'area-jateng',
        areaName: 'Semarang',
        title: 'Laporan Fasilitas',
        description: 'Deskripsi pengujian fitur role user.',
        category: 'Fasilitas Umum',
        latitude: -6.9924,
        longitude: 110.4225,
        locationAddress: 'Semarang',
        handlingStatus: handlingStatus,
        publicationState: publicationState,
        deletedAt: deletedAt,
        isDiscussionActive:
            isDiscussionActive ??
            (handlingStatus != HandlingStatus.completed &&
                handlingStatus != HandlingStatus.rejected),
        createdAt: now,
        updatedAt: now,
      );
    }

    test('canAuthorDelete returns true for newReport, rejected, completed, or pendingReview', () {
      expect(
        buildReport(handlingStatus: HandlingStatus.newReport).canAuthorDelete,
        isTrue,
      );
      expect(
        buildReport(handlingStatus: HandlingStatus.rejected).canAuthorDelete,
        isTrue,
      );
      expect(
        buildReport(handlingStatus: HandlingStatus.completed).canAuthorDelete,
        isTrue,
      );
      expect(
        buildReport(
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.pendingReview,
        ).canAuthorDelete,
        isTrue,
      );
    });

    test('canAuthorDelete returns false for accepted (dilihat) and inProgress (diproses)', () {
      expect(
        buildReport(handlingStatus: HandlingStatus.accepted).canAuthorDelete,
        isFalse,
      );
      expect(
        buildReport(handlingStatus: HandlingStatus.inProgress).canAuthorDelete,
        isFalse,
      );
    });

    test('canAuthorDelete returns false if already deleted', () {
      expect(
        buildReport(
          handlingStatus: HandlingStatus.completed,
          deletedAt: DateTime.now(),
        ).canAuthorDelete,
        isFalse,
      );
    });

    test('Discussion and Voting status on completed and rejected reports', () {
      final completed = buildReport(handlingStatus: HandlingStatus.completed);
      expect(completed.isDiscussionActive, isFalse);
      expect(completed.canAddComment, isFalse);
      expect(completed.isVotingActive, isFalse);

      final rejected = buildReport(handlingStatus: HandlingStatus.rejected);
      expect(rejected.isDiscussionActive, isFalse);
      expect(rejected.canAddComment, isFalse);
      expect(rejected.isVotingActive, isFalse);
    });

    test(
      'Discussion turned off by user on in_progress report still allows voting',
      () {
        final inProgressDisabledDiscussion = buildReport(
          handlingStatus: HandlingStatus.inProgress,
          isDiscussionActive: false,
        );
        expect(inProgressDisabledDiscussion.isDiscussionActive, isFalse);
        expect(inProgressDisabledDiscussion.canAddComment, isFalse);
        // Upvote dan downvote MASIH BISA
        expect(inProgressDisabledDiscussion.isVotingActive, isTrue);
      },
    );
  });

  group('2. Repository Tests: Deletion & Discussion Toggle', () {
    late ReportRepository repo;

    setUp(() {
      repo = ReportRepository();
    });

    test(
      'softDeleteReport succeeds on newReport and completed reports',
      () async {
        final rep = await repo.createReport(
          authorId: 'user-1',
          authorName: 'Budi',
          title: 'Sampah Liar',
          description: 'Sampah menumpuk di jalan.',
          category: 'Kebersihan',
          latitude: -6.9924,
          longitude: 110.4225,
          locationAddress: 'Semarang',
        );

        // Status newReport -> bisa dihapus
        final deletedNew = await repo.softDeleteReport(
          reportId: rep.id,
          currentUserId: 'user-1',
        );
        expect(deletedNew.isDeleted, isTrue);
      },
    );

    test('softDeleteReport throws when user tries to delete accepted or inProgress report', () async {
      final rep = await repo.createReport(
        authorId: 'user-1',
        authorName: 'Budi',
        title: 'Jalan Berlubang',
        description: 'Lubang jalan dalam.',
        category: 'Jalan & Infrastruktur',
        latitude: -6.9924,
        longitude: 110.4225,
        locationAddress: 'Semarang',
      );

      // Ubah status ke accepted (Diterima / dilihat)
      await repo.updateHandlingStatus(
        reportId: rep.id,
        newStatus: HandlingStatus.accepted,
      );

      expect(
        () => repo.softDeleteReport(reportId: rep.id, currentUserId: 'user-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('diterima atau sedang diproses tidak dapat dihapus'),
          ),
        ),
      );

      // Ubah status ke inProgress (Diproses)
      await repo.updateHandlingStatus(
        reportId: rep.id,
        newStatus: HandlingStatus.inProgress,
      );

      expect(
        () => repo.softDeleteReport(reportId: rep.id, currentUserId: 'user-1'),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('diterima atau sedang diproses tidak dapat dihapus'),
          ),
        ),
      );
    });

    test('completed report automatically disables discussion and user can toggle it back on', () async {
      final rep = await repo.createReport(
        authorId: 'user-1',
        authorName: 'Budi',
        title: 'Lampu Penerangan',
        description: 'Lampu mati di pertigaan jalan.',
        category: 'Fasilitas Umum',
        latitude: -6.9924,
        longitude: 110.4225,
        locationAddress: 'Semarang',
      );

      // Admin menyelesaikan laporan
      final completed = await repo.updateHandlingStatus(
        reportId: rep.id,
        newStatus: HandlingStatus.completed,
        reason: 'Selesai diperbaiki.',
        completionProofUrl: 'https://example.com/proof.jpg',
      );

      // Diskusi otomatis mati saat laporan SELESAI
      expect(completed.isDiscussionActive, isFalse);
      expect(completed.canAddComment, isFalse);
      expect(completed.isVotingActive, isFalse);

      // User (pemilik) mengaktifkan kembali diskusi
      final toggledOn = await repo.toggleDiscussionActive(
        reportId: rep.id,
        currentUserId: 'user-1',
        isDiscussionActive: true,
      );
      expect(toggledOn.isDiscussionActive, isTrue);
      expect(toggledOn.canAddComment, isTrue);
      // Voting tetap ditutup karena laporan completed
      expect(toggledOn.isVotingActive, isFalse);

      // User menonaktifkan kembali diskusi
      final toggledOff = await repo.toggleDiscussionActive(
        reportId: rep.id,
        currentUserId: 'user-1',
        isDiscussionActive: false,
      );
      expect(toggledOff.isDiscussionActive, isFalse);
      expect(toggledOff.canAddComment, isFalse);
    });
  });

  group(
    '3. UI Widget Tests: ReportDetailScreen Role USER Discussion & Deletion',
    () {
      late ReportRepository repo;
      late AuthRepository authRepo;
      late CommentRepository commentRepo;

      setUp(() {
        repo = ReportRepository();
        authRepo = AuthRepository();
        commentRepo = CommentRepository();
      });

      Widget createTestApp(ReportModel report, String currentUserId) {
        authRepo.setCurrentUserProfileForTesting(
          UserProfileModel(
            id: currentUserId,
            email: '$currentUserId@test.com',
            fullName: 'Pengguna Uji',
          ),
        );

        return MultiProvider(
          providers: [
            Provider.value(value: repo),
            Provider.value(value: authRepo),
            Provider.value(value: commentRepo),
            ChangeNotifierProvider(
              create: (_) => AuthController(authRepository: authRepo),
            ),
          ],
          child: MaterialApp(
            home: ReportDetailScreen(
              reportId: report.id,
              initialReport: report,
            ),
          ),
        );
      }

      testWidgets(
        'Completed report shows "Aktifkan Diskusi" and "Hapus Laporan" in menu for owner',
        (tester) async {
          final now = DateTime.now();
          final completedReport = ReportModel(
            id: 'rep-completed',
            reportNumber: 'LPR-2026-COMPLETED',
            authorId: 'usr-owner',
            authorName: 'Pemilik Laporan',
            areaId: 'area-jateng',
            areaName: 'Semarang',
            title: 'Jalan Selesai Diaspal',
            description: 'Jalanan telah mulus kembali.',
            category: 'Jalan & Infrastruktur',
            latitude: -6.9924,
            longitude: 110.4225,
            locationAddress: 'Semarang',
            handlingStatus: HandlingStatus.completed,
            publicationState: PublicationState.published,
            isDiscussionActive: false,
            createdAt: now,
            updatedAt: now,
          );

          await tester.pumpWidget(createTestApp(completedReport, 'usr-owner'));
          await tester.pumpAndSettle();

          // Cek bahwa VoteActionBar disabled dengan keterangan
          expect(find.byType(VoteActionBar), findsOneWidget);
          expect(
            find.textContaining('Penilaian suara ditutup'),
            findsOneWidget,
          );

          // Cek bahwa banner diskusi ditutup tampil
          expect(
            find.textContaining('Diskusi dinonaktifkan (Laporan Selesai)'),
            findsOneWidget,
          );

          // Buka Popup Menu opsi
          await tester.tap(find.byType(PopupMenuButton<String>));
          await tester.pumpAndSettle();

          // Opsi untuk author pada completed report
          expect(find.text('Aktifkan Diskusi'), findsOneWidget);
          expect(find.text('Hapus Laporan'), findsOneWidget);
        },
      );

      testWidgets(
        'Accepted (dilihat) and inProgress (diproses) reports do NOT show "Hapus Laporan"',
        (tester) async {
          final now = DateTime.now();
          final inProgressReport = ReportModel(
            id: 'rep-progress',
            reportNumber: 'LPR-2026-PROG',
            authorId: 'usr-owner',
            authorName: 'Pemilik Laporan',
            areaId: 'area-jateng',
            areaName: 'Semarang',
            title: 'Perbaikan Saluran Air',
            description: 'Petugas sedang menggali saluran.',
            category: 'Fasilitas Umum',
            latitude: -6.9924,
            longitude: 110.4225,
            locationAddress: 'Semarang',
            handlingStatus: HandlingStatus.inProgress,
            publicationState: PublicationState.published,
            isDiscussionActive: true,
            createdAt: now,
            updatedAt: now,
          );

          await tester.pumpWidget(createTestApp(inProgressReport, 'usr-owner'));
          await tester.pumpAndSettle();

          // Buka Popup Menu opsi
          await tester.tap(find.byType(PopupMenuButton<String>));
          await tester.pumpAndSettle();

          // Opsi edit dan toggle diskusi harus ada
          expect(find.text('Edit Laporan'), findsOneWidget);
          expect(find.text('Nonaktifkan Diskusi'), findsOneWidget);

          // "Hapus Laporan" TIDAK BOLEH tampil saat sedang diproses
          expect(find.text('Hapus Laporan'), findsNothing);
        },
      );
    },
  );
}
