import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laporin/data/models/comment_model.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/report_detail/controllers/report_detail_controller.dart';
import 'package:laporin/features/report_detail/widgets/comment_thread_tile.dart';
import 'package:laporin/features/report_detail/widgets/comment_tile.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('id_ID', null);
  });

  group('Comment Thread Model & Logic Tests', () {
    test('buildThreads correctly groups root comments and nested replies', () {
      final now = DateTime.now();
      final comments = [
        CommentModel(
          id: 'c1',
          reportId: 'rep-1',
          authorId: 'u1',
          authorName: '@asjdh213_',
          body: 'Laporan utama dari pembuat laporan',
          createdAt: now.subtract(const Duration(hours: 10)),
        ),
        CommentModel(
          id: 'c2',
          reportId: 'rep-1',
          authorId: 'u2',
          authorName: '@dljas44',
          body: 'Balasan pertama ke pembuat',
          createdAt: now.subtract(const Duration(hours: 2)),
          parentCommentId: 'c1',
        ),
        CommentModel(
          id: 'c3',
          reportId: 'rep-1',
          authorId: 'u3',
          authorName: '@wwaw777',
          body: 'Balasan kedua membalas balasan pertama',
          createdAt: now.subtract(const Duration(minutes: 5)),
          parentCommentId: 'c2',
        ),
        CommentModel(
          id: 'c4',
          reportId: 'rep-1',
          authorId: 'u4',
          authorName: '@aaaaaa000_',
          body: 'Komentar root kedua yang mandiri',
          createdAt: now.subtract(const Duration(hours: 6)),
        ),
      ];

      final threads = CommentThreadItem.buildThreads(comments);

      expect(threads.length, equals(2));

      // Thread 1
      expect(threads[0].root.id, equals('c1'));
      expect(threads[0].root.authorName, equals('@asjdh213_'));
      expect(threads[0].replies.length, equals(2));

      // Reply 1
      expect(threads[0].replies[0].comment.id, equals('c2'));
      expect(threads[0].replies[0].comment.authorName, equals('@dljas44'));
      expect(threads[0].replies[0].replyToAuthorName, equals('@asjdh213_'));

      // Reply 2 (nested reply to reply 1)
      expect(threads[0].replies[1].comment.id, equals('c3'));
      expect(threads[0].replies[1].comment.authorName, equals('@wwaw777'));
      expect(threads[0].replies[1].replyToAuthorName, equals('@dljas44'));

      // Thread 2
      expect(threads[1].root.id, equals('c4'));
      expect(threads[1].root.authorName, equals('@aaaaaa000_'));
      expect(threads[1].replies, isEmpty);
    });

    test(
      'findRootId finds the root comment across multiple nesting levels',
      () {
        final comments = [
          CommentModel(
            id: 'root-1',
            reportId: 'rep-1',
            authorId: 'u1',
            authorName: '@root',
            body: 'Root',
            createdAt: DateTime.now(),
          ),
          CommentModel(
            id: 'rep-1',
            reportId: 'rep-1',
            authorId: 'u2',
            authorName: '@rep1',
            body: 'Reply 1',
            createdAt: DateTime.now(),
            parentCommentId: 'root-1',
          ),
          CommentModel(
            id: 'rep-2',
            reportId: 'rep-1',
            authorId: 'u3',
            authorName: '@rep2',
            body: 'Reply 2',
            createdAt: DateTime.now(),
            parentCommentId: 'rep-1',
          ),
        ];

        expect(
          CommentThreadItem.findRootId(comments[0], comments),
          equals('root-1'),
        );
        expect(
          CommentThreadItem.findRootId(comments[1], comments),
          equals('root-1'),
        );
        expect(
          CommentThreadItem.findRootId(comments[2], comments),
          equals('root-1'),
        );
      },
    );
  });

  group('CommentTile UI Tests', () {
    testWidgets('renders Pencipta badge when comment author is report author', (
      tester,
    ) async {
      final comment = CommentModel(
        id: 'c1',
        reportId: 'rep-1',
        authorId: 'u1',
        authorName: '@asjdh213_',
        body: 'Komentar oleh pencipta laporan.',
        createdAt: DateTime.now().subtract(const Duration(hours: 10)),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentTile(
              comment: comment,
              isCreator: true,
              onReply: () {},
            ),
          ),
        ),
      );

      expect(find.text('@asjdh213_'), findsOneWidget);
      expect(find.text('Pencipta'), findsOneWidget);
      expect(find.text('Balas'), findsOneWidget);
      expect(find.text('Komentar oleh pencipta laporan.'), findsOneWidget);
    });

    testWidgets(
      'renders FontAwesome caretRight and @target_author for replies',
      (tester) async {
        final comment = CommentModel(
          id: 'c2',
          reportId: 'rep-1',
          authorId: 'u2',
          authorName: '@dljas44',
          body: 'Terima kasih atas infonya.',
          createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommentTile(
                comment: comment,
                replyToAuthor: '@asjdh213_',
                isReply: true,
                onReply: () {},
              ),
            ),
          ),
        );

        expect(find.text('@dljas44'), findsOneWidget);
        expect(find.byType(FaIcon), findsOneWidget);
        expect(find.text('@asjdh213_'), findsOneWidget);
        expect(find.text('Terima kasih atas infonya.'), findsOneWidget);
        expect(find.text('Balas'), findsOneWidget);
      },
    );

    testWidgets(
      'username font is grey and badges only appear for single/non-reply comments',
      (tester) async {
        final creatorStaffComment = CommentModel(
          id: 'c3',
          reportId: 'rep-1',
          authorId: 'u1',
          authorName: '@petugas_creator',
          authorRole: UserRole.admin,
          body: 'Komentar saya.',
          createdAt: DateTime.now(),
        );

        // 1. Single / non-reply comment (isReply: false) -> badges appear
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommentTile(
                comment: creatorStaffComment,
                isCreator: true,
                isReply: false,
              ),
            ),
          ),
        );

        final textWidget = tester.widget<Text>(find.text('@petugas_creator'));
        expect(textWidget.style?.color, equals(const Color(0xFF6B7280)));
        expect(find.text('Pencipta'), findsOneWidget);
        expect(find.text('Petugas'), findsOneWidget);

        // 2. Reply comment (isReply: true) -> badges do NOT appear, only username
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommentTile(
                comment: creatorStaffComment,
                isCreator: true,
                isReply: true,
                replyToAuthor: '@target_user',
              ),
            ),
          ),
        );

        final replyTextWidget = tester.widget<Text>(
          find.text('@petugas_creator'),
        );
        expect(replyTextWidget.style?.color, equals(const Color(0xFF6B7280)));
        final targetTextWidget = tester.widget<Text>(find.text('@target_user'));
        expect(targetTextWidget.style?.color, equals(const Color(0xFF6B7280)));
        expect(find.text('Pencipta'), findsNothing);
        expect(find.text('Petugas'), findsNothing);
      },
    );
  });

  group('CommentThreadTile Expand & Collapse Tests', () {
    testWidgets(
      'renders collapsed state with "Lihat X balasan" and toggles to expanded',
      (tester) async {
        final thread = CommentThreadItem(
          root: CommentModel(
            id: 'c1',
            reportId: 'rep-1',
            authorId: 'u1',
            authorName: '@asjdh213_',
            body: 'Komentar root',
            createdAt: DateTime.now(),
          ),
          replies: [
            CommentReplyItem(
              comment: CommentModel(
                id: 'c2',
                reportId: 'rep-1',
                authorId: 'u2',
                authorName: '@dljas44',
                body: 'Balasan 1',
                createdAt: DateTime.now(),
                parentCommentId: 'c1',
              ),
              replyToAuthorName: '@asjdh213_',
            ),
          ],
        );

        bool isExpanded = false;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                home: Scaffold(
                  body: CommentThreadTile(
                    thread: thread,
                    reportAuthorId: 'u1',
                    isExpanded: isExpanded,
                    onToggleExpanded: () {
                      setState(() {
                        isExpanded = !isExpanded;
                      });
                    },
                    onReply: (_) {},
                  ),
                ),
              );
            },
          ),
        );

        // Awalnya collapsed: Balasan tidak terlihat, tombol "Lihat 1 balasan" terlihat
        expect(find.text('Lihat 1 balasan'), findsOneWidget);
        expect(find.text('Balasan 1'), findsNothing);

        // Tap "Lihat 1 balasan"
        await tester.tap(find.text('Lihat 1 balasan'));
        await tester.pumpAndSettle();

        // Sekarang expanded: Balasan terlihat, tombol "Sembunyikan" terlihat
        expect(find.text('Balasan 1'), findsOneWidget);
        expect(find.text('Sembunyikan'), findsOneWidget);

        // Tap "Sembunyikan"
        await tester.tap(find.text('Sembunyikan'));
        await tester.pumpAndSettle();

        // Kembali collapsed
        expect(find.text('Lihat 1 balasan'), findsOneWidget);
        expect(find.text('Balasan 1'), findsNothing);
      },
    );
  });

  group('ReportDetailController Reply Support Tests', () {
    test(
      'submitting comment with parentCommentId saves reply relation',
      () async {
        final reportRepo = ReportRepository();
        final commentRepo = CommentRepository();

        final testReport = ReportModel(
          id: 'rep-reply-test',
          reportNumber: 'LPR-2026-7777',
          authorId: 'u1',
          authorName: 'Budi Santoso',
          areaId: 'area-jateng',
          areaName: 'Kota Semarang',
          title: 'Jalan Rusak',
          description: 'Jalan berlubang',
          category: 'Infrastruktur',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Semarang',
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final controller = ReportDetailController(
          reportId: testReport.id,
          reportRepository: reportRepo,
          commentRepository: commentRepo,
          initialReport: testReport,
        );

        // Tambahkan komentar utama
        final success1 = await controller.submitComment(
          authorId: 'u1',
          authorName: '@asjdh213_',
          authorRole: UserRole.user,
          body: 'Komentar root pertama',
        );
        expect(success1, isTrue);
        expect(controller.comments.length, equals(1));
        expect(controller.report?.commentsCount, equals(1));
        final rootCommentId = controller.comments.first.id;

        // Balas komentar utama dengan parentCommentId
        final success2 = await controller.submitComment(
          authorId: 'u2',
          authorName: '@dljas44',
          authorRole: UserRole.user,
          body: 'Ini adalah balasan saya untuk Anda',
          parentCommentId: rootCommentId,
        );
        expect(success2, isTrue);
        expect(controller.comments.length, equals(2));
        expect(controller.report?.commentsCount, equals(2));
        expect(controller.comments[1].parentCommentId, equals(rootCommentId));

        // Bangun thread dari komentar controller
        final threads = CommentThreadItem.buildThreads(controller.comments);
        expect(threads.length, equals(1));
        expect(threads[0].root.id, equals(rootCommentId));
        expect(threads[0].replies.length, equals(1));
        expect(threads[0].replies[0].comment.authorName, equals('@dljas44'));
        expect(threads[0].replies[0].replyToAuthorName, equals('@asjdh213_'));

        controller.dispose();
      },
    );

    test('isLoadingComments tracks comments fetching lifecycle', () async {
      final reportRepo = ReportRepository();
      final commentRepo = CommentRepository();

      final testReport = ReportModel(
        id: 'rep-loading-test',
        reportNumber: 'LPR-2026-8888',
        authorId: 'u1',
        authorName: 'Budi Santoso',
        areaId: 'area-jateng',
        areaName: 'Kota Semarang',
        title: 'Jalan Rusak',
        description: 'Jalan berlubang',
        category: 'Infrastruktur',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Semarang',
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final controller = ReportDetailController(
        reportId: testReport.id,
        reportRepository: reportRepo,
        commentRepository: commentRepo,
        initialReport: testReport,
      );

      // Awalnya isLoadingComments adalah true
      expect(controller.isLoadingComments, isTrue);

      // Tunggu hingga loadData selesai
      await Future.delayed(const Duration(milliseconds: 120));
      expect(controller.isLoadingComments, isFalse);

      // Trigger refreshComments
      final refreshFuture = controller.refreshComments();
      expect(controller.isLoadingComments, isTrue);
      await refreshFuture;
      expect(controller.isLoadingComments, isFalse);

      controller.dispose();
    });
  });

  group('Comments Loading Indicator Widget Tests', () {
    testWidgets(
      'renders spinning circular progress indicator when comments are loading',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  const isLoadingComments = true;
                  final comments = <CommentModel>[];
                  if (isLoadingComments && comments.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(),
                          ),
                          SizedBox(height: 12),
                          Text('Memuat komentar & diskusi...'),
                        ],
                      ),
                    );
                  }
                  return const Text('Loaded');
                },
              ),
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Memuat komentar & diskusi...'), findsOneWidget);
      },
    );
  });

  group('Delete Comment Feature Tests', () {
    test(
      'CommentRepository deleteComment removes comment from storage',
      () async {
        final commentRepo = CommentRepository();
        final c1 = await commentRepo.addComment(
          reportId: 'rep-del-test',
          authorId: 'user-1',
          authorName: 'User Satu',
          authorRole: UserRole.user,
          body: 'Komentar yang akan dihapus',
        );

        var comments = await commentRepo.getComments('rep-del-test');
        expect(comments.any((c) => c.id == c1.id), isTrue);

        await commentRepo.deleteComment(c1.id, userId: 'user-1');

        comments = await commentRepo.getComments('rep-del-test');
        expect(comments.any((c) => c.id == c1.id), isFalse);
      },
    );

    test(
      'ReportDetailController deleteComment removes comment and updates count',
      () async {
        final reportRepo = ReportRepository();
        final commentRepo = CommentRepository();

        final testReport = ReportModel(
          id: 'rep-ctrl-del-test',
          reportNumber: 'LPR-2026-9999',
          authorId: 'u-owner',
          authorName: 'Owner Laporan',
          areaId: 'area-1',
          areaName: 'Kota Semarang',
          title: 'Sampah Menumpuk',
          description: 'Deskripsi',
          category: 'Kebersihan',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Semarang',
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          commentsCount: 2,
        );

        final c1 = await commentRepo.addComment(
          reportId: testReport.id,
          authorId: 'user-1',
          authorName: 'User Satu',
          authorRole: UserRole.user,
          body: 'Komentar 1',
        );
        final c2 = await commentRepo.addComment(
          reportId: testReport.id,
          authorId: 'user-2',
          authorName: 'User Dua',
          authorRole: UserRole.user,
          body: 'Komentar 2',
        );

        final controller = ReportDetailController(
          reportId: testReport.id,
          reportRepository: reportRepo,
          commentRepository: commentRepo,
          initialReport: testReport,
          currentUserId: 'user-1',
        );

        await Future.delayed(const Duration(milliseconds: 100));
        expect(controller.comments.length, equals(2));

        final success = await controller.deleteComment(
          commentId: c1.id,
          userId: 'user-1',
        );

        expect(success, isTrue);
        expect(controller.comments.length, equals(1));
        expect(controller.comments.first.id, equals(c2.id));
        expect(controller.report?.commentsCount, equals(1));

        controller.dispose();
      },
    );

    testWidgets(
      'CommentTile shows "Hapus" only when currentUserId matches comment author',
      (tester) async {
        final comment = CommentModel(
          id: 'c-test-1',
          reportId: 'rep-1',
          authorId: 'user-current',
          authorName: '@akunsaya',
          body: 'Ini komentar milik saya sendiri.',
          createdAt: DateTime.now(),
        );

        // Kasus 1: Komentar milik akun yang sedang digunakan -> Tombol "Hapus" muncul di sebelah "Balas"
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommentTile(
                comment: comment,
                currentUserId: 'user-current',
                onReply: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.text('Balas'), findsOneWidget);
        expect(find.text('Hapus'), findsOneWidget);
        expect(
          find.byKey(const Key('delete_comment_c-test-1')),
          findsOneWidget,
        );

        // Kasus 2: Komentar milik akun lain -> Tombol "Hapus" TIDAK muncul
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommentTile(
                comment: comment,
                currentUserId: 'user-lain',
                onReply: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.text('Balas'), findsOneWidget);
        expect(find.text('Hapus'), findsNothing);
        expect(find.byKey(const Key('delete_comment_c-test-1')), findsNothing);

        // Kasus 3: Tidak ada pengguna yang login (guest) -> Tombol "Hapus" TIDAK muncul
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommentTile(
                comment: comment,
                currentUserId: null,
                onReply: () {},
                onDelete: () {},
              ),
            ),
          ),
        );

        expect(find.text('Balas'), findsOneWidget);
        expect(find.text('Hapus'), findsNothing);
      },
    );

    testWidgets('Tapping "Hapus" in CommentTile triggers onDelete callback', (
      tester,
    ) async {
      final comment = CommentModel(
        id: 'c-tap-1',
        reportId: 'rep-1',
        authorId: 'user-me',
        authorName: '@me',
        body: 'Komentar untuk tes tap hapus.',
        createdAt: DateTime.now(),
      );

      bool deleted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CommentTile(
              comment: comment,
              currentUserId: 'user-me',
              onReply: () {},
              onDelete: () {
                deleted = true;
              },
            ),
          ),
        ),
      );

      final balasTextWidget = tester.widget<Text>(find.text('Balas'));
      final hapusTextWidget = tester.widget<Text>(find.text('Hapus'));
      expect(hapusTextWidget.style?.color, equals(const Color(0xFF4B5563)));
      expect(
        hapusTextWidget.style?.color,
        equals(balasTextWidget.style?.color),
      );
      expect(
        hapusTextWidget.style?.fontSize,
        equals(balasTextWidget.style?.fontSize),
      );
      expect(
        hapusTextWidget.style?.fontWeight,
        equals(balasTextWidget.style?.fontWeight),
      );

      await tester.tap(find.text('Hapus'));
      await tester.pump();

      expect(deleted, isTrue);
    });

    testWidgets(
      'CommentThreadTile shows Hapus only for comments belonging to currentUserId',
      (tester) async {
        final thread = CommentThreadItem(
          root: CommentModel(
            id: 'root-c',
            reportId: 'rep-1',
            authorId: 'author-other',
            authorName: '@orang_lain',
            body: 'Komentar orang lain',
            createdAt: DateTime.now(),
          ),
          replies: [
            CommentReplyItem(
              comment: CommentModel(
                id: 'reply-c',
                reportId: 'rep-1',
                authorId: 'author-me',
                authorName: '@saya',
                body: 'Balasan dari saya',
                createdAt: DateTime.now(),
                parentCommentId: 'root-c',
              ),
              replyToAuthorName: '@orang_lain',
            ),
          ],
        );

        CommentModel? deletedTarget;

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CommentThreadTile(
                thread: thread,
                reportAuthorId: 'rep-author',
                isExpanded: true,
                onToggleExpanded: () {},
                onReply: (_) {},
                currentUserId: 'author-me',
                onDelete: (c) {
                  deletedTarget = c;
                },
              ),
            ),
          ),
        );

        // Root adalah akun lain -> tidak ada tombol Hapus
        expect(find.byKey(const Key('delete_comment_root-c')), findsNothing);

        // Reply adalah akun saya -> tombol Hapus muncul
        expect(find.byKey(const Key('delete_comment_reply-c')), findsOneWidget);

        // Hanya ada tepat 1 tombol Hapus di layar (milik reply)
        expect(find.text('Hapus'), findsOneWidget);

        // Tap tombol Hapus pada reply
        await tester.tap(find.text('Hapus'));
        await tester.pump();

        expect(deletedTarget, isNotNull);
        expect(deletedTarget!.id, equals('reply-c'));
      },
    );
  });
}
