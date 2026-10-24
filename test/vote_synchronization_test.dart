import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:laporin/core/theme/app_colors.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/feed/widgets/report_card.dart';
import 'package:laporin/features/report_detail/controllers/report_detail_controller.dart';
import 'package:laporin/features/report_detail/widgets/vote_action_bar.dart';

void main() {
  group('Vote Synchronization Tests between ReportCard and DetailScreen', () {
    late ReportRepository repository;
    late CommentRepository commentRepository;
    late ReportModel baseReport;
    const testUserId = 'usr-sync-123';

    setUp(() async {
      repository = ReportRepository();
      commentRepository = CommentRepository();

      baseReport = await repository.createReport(
        authorId: 'author-1',
        authorName: 'Warga Peduli',
        title: 'Jalan Berlubang di Dekat Pasar',
        description:
            'Lubang berdiameter 1 meter membahayakan pengendara motor.',
        category: 'Infrastruktur Jalan',
        latitude: -6.9932,
        longitude: 110.4203,
        locationAddress: 'Jl. Pemuda No. 45, Semarang',
      );
    });

    test('Upvoting from Feed immediately synchronizes active state to ReportDetailController', () async {
      final feedController = FeedController(
        reportRepository: repository,
        currentUserId: testUserId,
      );
      await feedController.fetchFeed(testUserId);

      expect(feedController.reports.first.currentUserVote, isNull);
      expect(feedController.reports.first.upvotesCount, equals(0));

      // 1. User memberikan Upvote di Feed (Card)
      await feedController.vote(baseReport.id, testUserId, 'up');

      final updatedInFeed = feedController.reports.first;
      expect(updatedInFeed.currentUserVote, equals('up'));
      expect(updatedInFeed.upvotesCount, equals(1));

      // 2. Buka Halaman Detail dengan initialReport dari Feed
      final detailController = ReportDetailController(
        reportId: baseReport.id,
        reportRepository: repository,
        commentRepository: commentRepository,
        initialReport: updatedInFeed,
        currentUserId: testUserId,
      );

      // Langsung aktif sejak frame pertama tanpa lag
      expect(detailController.report?.currentUserVote, equals('up'));
      expect(detailController.report?.upvotesCount, equals(1));

      await detailController.loadData();

      // Tetap konsisten setelah asynchronous data load
      expect(detailController.report?.currentUserVote, equals('up'));
      expect(detailController.report?.upvotesCount, equals(1));

      feedController.dispose();
      detailController.dispose();
    });

    test('Voting from DetailScreen synchronizes active state back to FeedCard on return', () async {
      final feedController = FeedController(
        reportRepository: repository,
        currentUserId: testUserId,
      );
      await feedController.fetchFeed(testUserId);

      final initialReport = feedController.reports.first;

      // 1. Pengguna membuka DetailScreen saat belum vote
      final detailController = ReportDetailController(
        reportId: baseReport.id,
        reportRepository: repository,
        commentRepository: commentRepository,
        initialReport: initialReport,
        currentUserId: testUserId,
      );

      expect(detailController.report?.currentUserVote, isNull);

      // 2. Pengguna memberikan Downvote di DetailScreen
      await detailController.vote(testUserId, 'down');

      expect(detailController.report?.currentUserVote, equals('down'));
      expect(detailController.report?.downvotesCount, equals(1));

      // 3. Pengguna kembali ke Feed (syncReport dipanggil dengan report dari detail)
      feedController.syncReport(detailController.report!);

      final updatedInFeed = feedController.reports.first;
      expect(updatedInFeed.currentUserVote, equals('down'));
      expect(updatedInFeed.downvotesCount, equals(1));

      feedController.dispose();
      detailController.dispose();
    });

    test('Switching vote from Upvote to Downvote in Detail updates Feed immediately', () async {
      // Beri upvote awal
      await repository.voteReport(
        reportId: baseReport.id,
        userId: testUserId,
        voteType: 'up',
      );

      final feedController = FeedController(
        reportRepository: repository,
        currentUserId: testUserId,
      );
      await feedController.fetchFeed(testUserId);

      expect(feedController.reports.first.currentUserVote, equals('up'));
      expect(feedController.reports.first.upvotesCount, equals(1));
      expect(feedController.reports.first.downvotesCount, equals(0));

      // Buka detail dan ganti vote menjadi downvote
      final detailController = ReportDetailController(
        reportId: baseReport.id,
        reportRepository: repository,
        commentRepository: commentRepository,
        initialReport: feedController.reports.first,
        currentUserId: testUserId,
      );

      await detailController.vote(testUserId, 'down');

      expect(detailController.report?.currentUserVote, equals('down'));
      expect(detailController.report?.upvotesCount, equals(0));
      expect(detailController.report?.downvotesCount, equals(1));

      // Sync ke feed card
      feedController.syncReport(detailController.report!);

      final syncedCardReport = feedController.reports.first;
      expect(syncedCardReport.currentUserVote, equals('down'));
      expect(syncedCardReport.upvotesCount, equals(0));
      expect(syncedCardReport.downvotesCount, equals(1));

      feedController.dispose();
      detailController.dispose();
    });

    test('Cancelling (toggle off) vote in Feed synchronizes inactive state to Detail', () async {
      // Vote awal
      await repository.voteReport(
        reportId: baseReport.id,
        userId: testUserId,
        voteType: 'up',
      );

      final feedController = FeedController(
        reportRepository: repository,
        currentUserId: testUserId,
      );
      await feedController.fetchFeed(testUserId);

      // Toggle off di feed
      await feedController.vote(baseReport.id, testUserId, 'up');
      expect(feedController.reports.first.currentUserVote, isNull);
      expect(feedController.reports.first.upvotesCount, equals(0));

      // Detail screen dibuka
      final detailController = ReportDetailController(
        reportId: baseReport.id,
        reportRepository: repository,
        commentRepository: commentRepository,
        initialReport: feedController.reports.first,
        currentUserId: testUserId,
      );

      expect(detailController.report?.currentUserVote, isNull);
      expect(detailController.report?.upvotesCount, equals(0));

      feedController.dispose();
      detailController.dispose();
    });

    testWidgets(
      'Both ReportCard and VoteActionBar display active highlight styling when user has voted',
      (tester) async {
        final upvotedReport = baseReport.copyWith(
          currentUserVote: 'up',
          upvotesCount: 8,
          downvotesCount: 2,
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  ReportCard(
                    report: upvotedReport,
                    onTap: () {},
                    onUpvote: () {},
                    onDownvote: () {},
                  ),
                  VoteActionBar(
                    report: upvotedReport,
                    onUpvote: () {},
                    onDownvote: () {},
                  ),
                ],
              ),
            ),
          ),
        );

        // Periksa ReportCard menampilkan thumbs up aktif dengan teks '8'
        final upvoteTextFinder = find.text('8');
        expect(upvoteTextFinder, findsOneWidget);
        final upvoteText = tester.widget<Text>(upvoteTextFinder);
        expect(upvoteText.style?.color, equals(AppColors.primary));
        expect(upvoteText.style?.fontWeight, equals(FontWeight.w700));

        // Periksa icon thumbsUp aktif di ReportCard berwarna primary
        final faIcons = tester.widgetList<FaIcon>(find.byType(FaIcon));
        final activeThumbIcon = faIcons.firstWhere(
          (icon) => icon.color == AppColors.primary,
        );
        expect(activeThumbIcon.color, equals(AppColors.primary));

        // Periksa VoteActionBar menampilkan 'Dukung (8)' aktif dengan warna primary
        final actionBarTextFinder = find.text('Dukung (8)');
        expect(actionBarTextFinder, findsOneWidget);
        final actionText = tester.widget<Text>(actionBarTextFinder);
        expect(actionText.style?.color, equals(AppColors.primary));
        expect(actionText.style?.fontWeight, equals(FontWeight.bold));

        // Periksa icon thumb_up_alt_rounded aktif di VoteActionBar
        expect(find.byIcon(Icons.thumb_up_alt_rounded), findsOneWidget);
      },
    );
  });
}
