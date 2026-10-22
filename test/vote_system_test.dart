import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/feed/widgets/report_card.dart';
import 'package:laporin/features/report_detail/controllers/report_detail_controller.dart';
import 'package:laporin/features/report_detail/widgets/vote_action_bar.dart';

/// Mock repository untuk mensimulasikan delay dan failure backend
class MockFailingReportRepository extends ReportRepository {
  bool shouldFail = false;
  Completer<ReportModel>? inFlightCompleter;

  @override
  Future<ReportModel> voteReport({
    required String reportId,
    required String userId,
    required String voteType,
  }) async {
    if (inFlightCompleter != null) {
      return await inFlightCompleter!.future;
    }
    if (shouldFail) {
      throw Exception('Koneksi jaringan terputus');
    }
    return super.voteReport(
      reportId: reportId,
      userId: userId,
      voteType: voteType,
    );
  }
}

void main() {
  ReportModel createDummyReport({
    String id = 'rep-1',
    int upvotes = 5,
    int downvotes = 2,
    String? currentUserVote,
    PublicationState pubState = PublicationState.published,
    HandlingStatus handling = HandlingStatus.inProgress,
  }) {
    final now = DateTime.now();
    return ReportModel(
      id: id,
      reportNumber: 'LPR-2026-0001',
      authorId: 'usr-1',
      authorName: 'Dewanto',
      areaId: 'area-jateng',
      areaName: 'Kota Semarang',
      title: 'Lampu Jalan Padam',
      description: 'Lampu PJU padam di sepanjang jalan utama',
      category: 'Fasilitas Umum',
      latitude: -6.9932,
      longitude: 110.4203,
      locationAddress: 'Jl. Pemuda No. 10, Semarang',
      handlingStatus: handling,
      publicationState: pubState,
      createdAt: now,
      updatedAt: now,
      upvotesCount: upvotes,
      downvotesCount: downvotes,
      currentUserVote: currentUserVote,
    );
  }

  group('1. ReportModel Deterministic Vote Calculation Tests', () {
    test('Beri Upvote saat belum vote (+1 upvote, currentUserVote = up)', () {
      final initial = createDummyReport(
        upvotes: 5,
        downvotes: 2,
        currentUserVote: null,
      );
      final updated = initial.calculateOptimisticVote('up');

      expect(updated.upvotesCount, equals(6));
      expect(updated.downvotesCount, equals(2));
      expect(updated.currentUserVote, equals('up'));
    });

    test(
      'Batalkan Upvote saat sudah Upvote (-1 upvote, currentUserVote = null)',
      () {
        final initial = createDummyReport(
          upvotes: 6,
          downvotes: 2,
          currentUserVote: 'up',
        );
        final updated = initial.calculateOptimisticVote('up');

        expect(updated.upvotesCount, equals(5));
        expect(updated.downvotesCount, equals(2));
        expect(updated.currentUserVote, isNull);
      },
    );

    test(
      'Beri Downvote saat belum vote (+1 downvote, currentUserVote = down)',
      () {
        final initial = createDummyReport(
          upvotes: 5,
          downvotes: 2,
          currentUserVote: null,
        );
        final updated = initial.calculateOptimisticVote('down');

        expect(updated.upvotesCount, equals(5));
        expect(updated.downvotesCount, equals(3));
        expect(updated.currentUserVote, equals('down'));
      },
    );

    test('Batalkan Downvote saat sudah Downvote (-1 downvote, currentUserVote = null)', () {
      final initial = createDummyReport(
        upvotes: 5,
        downvotes: 3,
        currentUserVote: 'down',
      );
      final updated = initial.calculateOptimisticVote('down');

      expect(updated.upvotesCount, equals(5));
      expect(updated.downvotesCount, equals(2));
      expect(updated.currentUserVote, isNull);
    });

    test('Switch Vote: dari Upvote ke Downvote (-1 upvote, +1 downvote)', () {
      final initial = createDummyReport(
        upvotes: 5,
        downvotes: 2,
        currentUserVote: 'up',
      );
      final updated = initial.calculateOptimisticVote('down');

      expect(updated.upvotesCount, equals(4));
      expect(updated.downvotesCount, equals(3));
      expect(updated.currentUserVote, equals('down'));
    });

    test('Switch Vote: dari Downvote ke Upvote (-1 downvote, +1 upvote)', () {
      final initial = createDummyReport(
        upvotes: 5,
        downvotes: 2,
        currentUserVote: 'down',
      );
      final updated = initial.calculateOptimisticVote('up');

      expect(updated.upvotesCount, equals(6));
      expect(updated.downvotesCount, equals(1));
      expect(updated.currentUserVote, equals('up'));
    });

    test('Counter tidak pernah negatif jika dibatalkan dari nilai 0', () {
      final initial = createDummyReport(
        upvotes: 0,
        downvotes: 0,
        currentUserVote: 'up',
      );
      final updated = initial.calculateOptimisticVote('up');

      expect(updated.upvotesCount, equals(0));
      expect(updated.downvotesCount, equals(0));
      expect(updated.currentUserVote, isNull);
    });

    test('Threshold downvote tercapai otomatis mengubah publicationState menjadi held', () {
      // 3 upvotes, 6 downvotes (total 9). Memberi 1 downvote -> total 10, down 7 -> 70%
      final initial = createDummyReport(
        upvotes: 3,
        downvotes: 6,
        currentUserVote: null,
      );
      final updated = initial.calculateOptimisticVote('down');

      expect(updated.upvotesCount, equals(3));
      expect(updated.downvotesCount, equals(7));
      expect(updated.publicationState, equals(PublicationState.held));
      expect(updated.isPubliclyVisible, isFalse);
      expect(updated.moderationReason, contains('Ambang batas downvote'));
    });
  });

  group('2. ReportRepository Vote Invariants Tests', () {
    test(
      'voteReport menolak voting pada laporan terminal (rejected / cancelled)',
      () async {
        final repo = ReportRepository();
        final report = await repo.createReport(
          authorId: 'u1',
          authorName: 'User',
          title: 'Laporan Test',
          description: 'Deskripsi fasilitas publik rusak',
          category: 'Fasilitas Umum',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Semarang',
        );

        // Ubah jadi rejected
        await repo.updateHandlingStatus(
          reportId: report.id,
          newStatus: HandlingStatus.rejected,
          reason: 'Laporan duplikat',
        );

        expect(
          () => repo.voteReport(
            reportId: report.id,
            userId: 'u2',
            voteType: 'up',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'voteReport menolak voting pada laporan yang ditahan (held)',
      () async {
        final repo = ReportRepository();
        final report = await repo.createReport(
          authorId: 'u1',
          authorName: 'User',
          title: 'Laporan Test',
          description: 'Deskripsi fasilitas publik rusak',
          category: 'Fasilitas Umum',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Semarang',
        );

        // Ubah jadi held
        await repo.updatePublicationState(
          reportId: report.id,
          newState: PublicationState.held,
          reason: 'Dalam moderasi',
        );

        expect(
          () => repo.voteReport(
            reportId: report.id,
            userId: 'u2',
            voteType: 'up',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );
  });

  group('3. FeedController Optimistic Vote & Race Condition Tests', () {
    test(
      'Optimistic UI update langsung terrefleksi sebelum backend selesai',
      () async {
        final mockRepo = MockFailingReportRepository();
        final report = await mockRepo.createReport(
          authorId: 'u1',
          authorName: 'User',
          title: 'Jalan Rusak',
          description: 'Jalan berlubang cukup besar',
          category: 'Jalan & Jembatan',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Semarang',
        );

        // Completer untuk menahan respons async backend
        mockRepo.inFlightCompleter = Completer<ReportModel>();

        final controller = FeedController(reportRepository: mockRepo);
        await controller.fetchFeed();

        expect(controller.reports.first.upvotesCount, equals(0));
        expect(controller.reports.first.currentUserVote, isNull);

        // Panggil vote 'up'
        final voteFuture = controller.vote(report.id, 'user-voter', 'up');

        // Seketika itu juga (optimistic), controller sudah memiliki data baru
        expect(controller.reports.first.upvotesCount, equals(1));
        expect(controller.reports.first.currentUserVote, equals('up'));
        expect(controller.isVoting(report.id), isTrue);

        // Selesaikan async completer
        final completedReport = controller.reports.first;
        mockRepo.inFlightCompleter!.complete(completedReport);
        await voteFuture;

        expect(controller.isVoting(report.id), isFalse);
        expect(controller.reports.first.upvotesCount, equals(1));
        expect(controller.reports.first.currentUserVote, equals('up'));

        controller.dispose();
      },
    );

    test(
      'In-flight request lock mencegah race condition klik berulang',
      () async {
        final mockRepo = MockFailingReportRepository();
        final report = await mockRepo.createReport(
          authorId: 'u1',
          authorName: 'User',
          title: 'Jalan Rusak',
          description: 'Jalan berlubang cukup besar',
          category: 'Jalan & Jembatan',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Semarang',
        );

        mockRepo.inFlightCompleter = Completer<ReportModel>();

        final controller = FeedController(reportRepository: mockRepo);
        await controller.fetchFeed();

        // Klik 1 (in-flight dimulai)
        final future1 = controller.vote(report.id, 'user-voter', 'up');
        expect(controller.reports.first.upvotesCount, equals(1));

        // Klik 2 dilakukan cepat saat request 1 masih in-flight
        final future2 = controller.vote(report.id, 'user-voter', 'up');

        // Klik 2 harus diabaikan (lock aktif), tidak boleh menggandakan suara
        expect(controller.reports.first.upvotesCount, equals(1));

        mockRepo.inFlightCompleter!.complete(controller.reports.first);
        await future1;
        await future2;

        expect(controller.reports.first.upvotesCount, equals(1));
        controller.dispose();
      },
    );

    test('Rollback state ke kondisi awal jika request backend gagal', () async {
      final mockRepo = MockFailingReportRepository();
      final report = await mockRepo.createReport(
        authorId: 'u1',
        authorName: 'User',
        title: 'Jalan Rusak',
        description: 'Jalan berlubang cukup besar',
        category: 'Jalan & Jembatan',
        latitude: -6.9932,
        longitude: 110.4203,
        locationAddress: 'Semarang',
      );

      final controller = FeedController(reportRepository: mockRepo);
      await controller.fetchFeed();

      expect(controller.reports.first.upvotesCount, equals(0));
      expect(controller.reports.first.currentUserVote, isNull);

      // Buat backend gagal
      mockRepo.shouldFail = true;

      // Panggil vote
      await controller.vote(report.id, 'user-voter', 'up');

      // Setelah gagal, state harus di-rollback ke kondisi semula
      expect(controller.reports.first.upvotesCount, equals(0));
      expect(controller.reports.first.currentUserVote, isNull);
      expect(controller.errorMessage, isNotNull);
      expect(controller.errorMessage, contains('Gagal memperbarui vote'));

      controller.dispose();
    });

    test(
      'Laporan seketika lenyap dari feed jika downvote mencapai ambang batas',
      () async {
        final repo = ReportRepository();
        // Buat laporan yang mendekati threshold (3 upvotes, 6 downvotes = total 9)
        final report = await repo.createReport(
          authorId: 'u1',
          authorName: 'User',
          title: 'Laporan Kontroversial',
          description: 'Deskripsi laporan yang banyak downvote',
          category: 'Fasilitas Umum',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Semarang',
        );

        // Simulasikan 3 upvotes dan 6 downvotes
        for (var i = 0; i < 3; i++) {
          await repo.voteReport(
            reportId: report.id,
            userId: 'up-user-$i',
            voteType: 'up',
          );
        }
        for (var i = 0; i < 6; i++) {
          await repo.voteReport(
            reportId: report.id,
            userId: 'down-user-$i',
            voteType: 'down',
          );
        }

        final controller = FeedController(reportRepository: repo);
        await controller.fetchFeed();
        expect(controller.reports.any((r) => r.id == report.id), isTrue);

        // Beri downvote ke-7 (total 10, down 7 -> 70% threshold!)
        await controller.vote(report.id, 'final-down-voter', 'down');

        // Laporan wajib lenyap dari public feed seketika!
        expect(controller.reports.any((r) => r.id == report.id), isFalse);

        controller.dispose();
      },
    );
  });

  group('4. ReportDetailController Optimistic Vote & Concurrency Tests', () {
    test('Optimistic update dan rollback saat backend gagal di ReportDetailController', () async {
      final mockRepo = MockFailingReportRepository();
      final commentRepo = CommentRepository();

      final initialReport = createDummyReport(
        upvotes: 4,
        downvotes: 1,
        currentUserVote: null,
      );

      final controller = ReportDetailController(
        reportId: initialReport.id,
        reportRepository: mockRepo,
        commentRepository: commentRepo,
        initialReport: initialReport,
      );

      expect(controller.report!.upvotesCount, equals(4));
      expect(controller.report!.currentUserVote, isNull);

      // Simulasikan kegagalan backend
      mockRepo.shouldFail = true;

      // Panggil vote
      await controller.vote('user-1', 'up');

      // State harus kembali ke kondisi awal (rollback)
      expect(controller.report!.upvotesCount, equals(4));
      expect(controller.report!.currentUserVote, isNull);
      expect(controller.errorMessage, isNotNull);

      controller.dispose();
    });
  });

  group('5. UI Rendering & Interaction Tests', () {
    testWidgets(
      'ReportCard renders active styling correctly for upvote and downvote',
      (tester) async {
        final reportUp = createDummyReport(
          upvotes: 10,
          downvotes: 2,
          currentUserVote: 'up',
        );
        bool upvoted = false;
        bool downvoted = false;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ReportCard(
                report: reportUp,
                onTap: () {},
                onUpvote: () => upvoted = true,
                onDownvote: () => downvoted = true,
              ),
            ),
          ),
        );

        // Cek icon thumbsUp dan teks count
        expect(find.text('10'), findsOneWidget);
        expect(find.text('2'), findsOneWidget);

        // Tap Upvote
        await tester.tap(find.text('10'));
        await tester.pump();
        expect(upvoted, isTrue);

        // Tap Downvote
        await tester.tap(find.text('2'));
        await tester.pump();
        expect(downvoted, isTrue);
      },
    );

    testWidgets(
      'VoteActionBar renders correct button labels and active states',
      (tester) async {
        final reportDown = createDummyReport(
          upvotes: 8,
          downvotes: 4,
          currentUserVote: 'down',
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: VoteActionBar(
                report: reportDown,
                onUpvote: () {},
                onDownvote: () {},
              ),
            ),
          ),
        );

        expect(find.text('Dukung (8)'), findsOneWidget);
        expect(find.text('Keberatan (4)'), findsOneWidget);
      },
    );
  });
}
