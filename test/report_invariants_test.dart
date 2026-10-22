import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/repositories/report_repository.dart';

void main() {
  group('Report Model & Invariants Tests (PRD & AGENTS.md)', () {
    test('Public visibility requires published state and non-terminal handling status', () {
      final now = DateTime.now();

      // Normal published report -> visible
      final report1 = ReportModel(
        id: '1',
        reportNumber: 'LPR-1',
        authorId: 'u1',
        authorName: 'User',
        areaId: 'a1',
        areaName: 'Jakarta',
        title: 'Title',
        description: 'Desc',
        category: 'Jalan',
        latitude: -6.2,
        longitude: 106.8,
        locationAddress: 'Loc',
        handlingStatus: HandlingStatus.inProgress,
        publicationState: PublicationState.published,
        createdAt: now,
        updatedAt: now,
      );
      expect(report1.isPubliclyVisible, isTrue);

      // Pending review -> NOT visible
      final report2 = report1.copyWith(
        publicationState: PublicationState.pendingReview,
      );
      expect(report2.isPubliclyVisible, isFalse);

      // Held by moderation -> NOT visible
      final report3 = report1.copyWith(publicationState: PublicationState.held);
      expect(report3.isPubliclyVisible, isFalse);

      // Rejected -> NOT visible even if state was published
      final report4 = report1.copyWith(handlingStatus: HandlingStatus.rejected);
      expect(report4.isPubliclyVisible, isFalse);

      // Cancelled -> NOT visible even if state was published
      final report5 = report1.copyWith(
        handlingStatus: HandlingStatus.cancelled,
      );
      expect(report5.isPubliclyVisible, isFalse);
    });

    test('Downvote threshold calculation correctly calculates percentage of active votes', () {
      final now = DateTime.now();
      final report = ReportModel(
        id: '1',
        reportNumber: 'LPR-1',
        authorId: 'u1',
        authorName: 'User',
        areaId: 'a1',
        areaName: 'Jakarta',
        title: 'Title',
        description: 'Desc',
        category: 'Jalan',
        latitude: -6.2,
        longitude: 106.8,
        locationAddress: 'Loc',
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
        createdAt: now,
        updatedAt: now,
        upvotesCount: 3,
        downvotesCount: 7, // 7 / 10 = 70%
      );

      expect(report.downvotePercentage, equals(70.0));
      expect(report.reachedDownvoteThreshold, isTrue);

      // Below total vote threshold (< 10 total)
      final reportBelowTotal = report.copyWith(
        upvotesCount: 1,
        downvotesCount: 3,
      ); // 75%, but total = 4
      expect(reportBelowTotal.reachedDownvoteThreshold, isFalse);

      // Below percentage threshold (< 70%)
      final reportBelowPct = report.copyWith(
        upvotesCount: 5,
        downvotesCount: 7,
      ); // 7/12 = 58.3%
      expect(reportBelowPct.reachedDownvoteThreshold, isFalse);
    });

    test(
      'ReportRepository rejects completed status without completion proof',
      () async {
        final repo = ReportRepository();
        final report = await repo.createReport(
          authorId: 'u1',
          authorName: 'User',
          title: 'Lubang Jalan',
          description: 'Deskripsi jalan berlubang',
          category: 'Jalan & Infrastruktur',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Jl. Pahlawan No. 1, Semarang',
        );

        expect(
          () => repo.updateHandlingStatus(
            reportId: report.id,
            newStatus: HandlingStatus.completed,
            completionProofUrl: null, // missing proof
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'ReportRepository rejects rejected status without rejection reason',
      () async {
        final repo = ReportRepository();
        final report = await repo.createReport(
          authorId: 'u1',
          authorName: 'User',
          title: 'Lubang Jalan',
          description: 'Deskripsi jalan berlubang',
          category: 'Jalan & Infrastruktur',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Jl. Pahlawan No. 1, Semarang',
        );

        expect(
          () => repo.updateHandlingStatus(
            reportId: report.id,
            newStatus: HandlingStatus.rejected,
            reason: '', // empty reason
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'ReportRepository sets 24h archive timer when rejected or cancelled',
      () async {
        final repo = ReportRepository();
        final report = await repo.createReport(
          authorId: 'u1',
          authorName: 'User',
          title: 'Lubang Jalan',
          description: 'Deskripsi jalan berlubang',
          category: 'Jalan & Infrastruktur',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Jl. Pahlawan No. 1, Semarang',
        );

        final updated = await repo.updateHandlingStatus(
          reportId: report.id,
          newStatus: HandlingStatus.rejected,
          reason: 'Lokasi tidak dapat ditemukan',
        );

        expect(updated.terminalAt, isNotNull);
        expect(updated.archiveAfter, isNotNull);
        final diff = updated.archiveAfter!.difference(updated.terminalAt!);
        expect(diff.inHours, equals(24));
        expect(updated.isPubliclyVisible, isFalse);
      },
    );

    test('ReportRepository rejects report creation when location is outside Central Java', () async {
      final repo = ReportRepository();
      expect(
        () => repo.createReport(
          authorId: 'u1',
          authorName: 'User',
          title: 'Lubang Jalan',
          description: 'Deskripsi jalan berlubang',
          category: 'Jalan & Infrastruktur',
          latitude: -6.2088,
          longitude: 106.8456,
          locationAddress: 'Jl. Sudirman, Jakarta',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('Jawa Tengah'),
          ),
        ),
      );
    });
  });
}
