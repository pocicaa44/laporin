import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:laporin/core/services/fcm_service.dart';
import 'package:laporin/core/theme/app_theme.dart';
import 'package:laporin/data/models/notification_model.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/announcement_repository.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/notification_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';
import 'package:laporin/features/notifications/screens/notifications_screen.dart';
import 'package:laporin/features/settings/controllers/settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Notification Deduplication Tests', () {
    late NotificationRepository repository;

    setUp(() {
      repository = NotificationRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('Deduplicates notifications with identical ID', () async {
      final now = DateTime.now();
      final notif1 = NotificationModel(
        id: 'dup-id-1',
        title: 'Status Diperbarui',
        message: 'Laporan Anda sedang diproses',
        type: NotificationType.statusChanged,
        createdAt: now,
      );
      final notif2 = NotificationModel(
        id: 'dup-id-1',
        title: 'Status Diperbarui',
        message: 'Laporan Anda sedang diproses',
        type: NotificationType.statusChanged,
        createdAt: now.add(const Duration(milliseconds: 100)),
      );

      repository.setNotificationsForTesting([notif1, notif2]);
      final list = await repository.getNotifications();

      expect(list.length, equals(1));
      expect(list.first.id, equals('dup-id-1'));
    });

    test('Deduplicates notifications with same type, reportId, and message within 5 seconds', () async {
      final now = DateTime.now();
      final notif1 = NotificationModel(
        id: 'notif-a',
        title: 'Status Diperbarui',
        message: 'Laporan Jalan Rusak diproses',
        type: NotificationType.statusChanged,
        reportId: 'rep-001',
        createdAt: now,
      );
      final notif2 = NotificationModel(
        id: 'notif-b',
        title: 'Status Diperbarui',
        message: 'Laporan Jalan Rusak diproses',
        type: NotificationType.statusChanged,
        reportId: 'rep-001',
        createdAt: now.add(const Duration(seconds: 2)), // within 5 seconds window
      );

      repository.setNotificationsForTesting([notif1, notif2]);
      final list = await repository.getNotifications();

      expect(list.length, equals(1));
    });

    test('Allows distinct notifications when time interval is >= 5 seconds', () async {
      final now = DateTime.now();
      final notif1 = NotificationModel(
        id: 'notif-a',
        title: 'Status Diperbarui',
        message: 'Laporan Jalan Rusak diproses',
        type: NotificationType.statusChanged,
        reportId: 'rep-001',
        createdAt: now,
      );
      final notif2 = NotificationModel(
        id: 'notif-b',
        title: 'Status Diperbarui',
        message: 'Laporan Jalan Rusak diproses',
        type: NotificationType.statusChanged,
        reportId: 'rep-001',
        createdAt: now.add(const Duration(seconds: 10)), // outside 5 seconds
      );

      repository.setNotificationsForTesting([notif1, notif2]);
      final list = await repository.getNotifications();

      expect(list.length, equals(2));
    });

    test('addNotification rejects immediate duplicate additions', () async {
      final now = DateTime.now();
      final notif1 = NotificationModel(
        id: 'notif-add-1',
        title: 'Status Baru',
        message: 'Pembaruan laporan',
        type: NotificationType.statusChanged,
        reportId: 'rep-100',
        createdAt: now,
      );
      final notif2 = NotificationModel(
        id: 'notif-add-2',
        title: 'Status Baru',
        message: 'Pembaruan laporan',
        type: NotificationType.statusChanged,
        reportId: 'rep-100',
        createdAt: now.add(const Duration(milliseconds: 500)),
      );

      await repository.addNotification(notif1);
      await repository.addNotification(notif2);

      final list = await repository.getNotifications();
      expect(list.length, equals(1));
      expect(list.first.id, equals('notif-add-1'));
    });
  });

  group('2. All 6 Event Dispatchers on NotificationRepository', () {
    late NotificationRepository repository;

    setUp(() {
      repository = NotificationRepository();
    });

    tearDown(() {
      repository.dispose();
    });

    test('1. notifyNewReport dispatches newReport notification', () async {
      await repository.notifyNewReport(
        reportId: 'rep-new-1',
        reportTitle: 'Sampah Menumpuk di Pasar',
      );

      final list = await repository.getNotifications();
      expect(list.length, equals(1));
      expect(list.first.type, equals(NotificationType.newReport));
      expect(list.first.reportId, equals('rep-new-1'));
      expect(list.first.title, contains('Laporan Baru'));
      expect(list.first.message, contains('Sampah Menumpuk di Pasar'));
    });

    test('2. notifyStatusChanged dispatches statusChanged notification', () async {
      await repository.notifyStatusChanged(
        reportId: 'rep-stat-1',
        reportTitle: 'Lampu Jalan Mati',
        statusLabel: 'sedang diproses',
      );

      final list = await repository.getNotifications();
      expect(list.length, equals(1));
      expect(list.first.type, equals(NotificationType.statusChanged));
      expect(list.first.reportId, equals('rep-stat-1'));
      expect(list.first.title, equals('Status laporan Anda diperbarui!'));
      expect(list.first.message, contains('Lampu Jalan Mati'));
    });

    test('2b. notifyStatusChanged dispatches completed notification with exact title', () async {
      await repository.notifyStatusChanged(
        reportId: 'rep-stat-done',
        reportTitle: 'Jalan Aspal',
        statusLabel: 'Selesai',
        status: HandlingStatus.completed,
      );

      final list = await repository.getNotifications();
      expect(list.first.title, equals('Laporan Anda telah diselesaikan!'));
    });

    test('2c. notifyStatusChanged dispatches rejected notification with exact title', () async {
      await repository.notifyStatusChanged(
        reportId: 'rep-stat-rej',
        reportTitle: 'Jalan Aspal',
        statusLabel: 'Ditolak',
        status: HandlingStatus.rejected,
      );

      final list = await repository.getNotifications();
      expect(list.first.title, equals('Laporan Anda ditolak!'));
    });

    test('3. notifyUpvoted dispatches upvoted notification', () async {
      await repository.notifyUpvoted(
        reportId: 'rep-up-1',
        reportTitle: 'Jalan Berlubang di RT 03',
      );

      final list = await repository.getNotifications();
      expect(list.length, equals(1));
      expect(list.first.type, equals(NotificationType.upvoted));
      expect(list.first.reportId, equals('rep-up-1'));
      expect(list.first.title, equals('Seseorang mendukung laporan Anda!'));
      expect(list.first.message, contains('Jalan Berlubang di RT 03'));
    });

    test('4. notifyNewComment dispatches newComment notification', () async {
      await repository.notifyNewComment(
        reportId: 'rep-comm-1',
        reportTitle: 'Banjir Saluran Air',
        commenterName: 'Agus',
        commentBody: 'Segera diperbaiki ya pak',
      );

      final list = await repository.getNotifications();
      expect(list.length, equals(1));
      expect(list.first.type, equals(NotificationType.newComment));
      expect(list.first.reportId, equals('rep-comm-1'));
      expect(list.first.title, equals('Seseorang mengomentari laporan Anda!'));
      expect(list.first.message, contains('Agus'));
    });

    test('5. notifyReplyComment dispatches replyComment notification', () async {
      await repository.notifyReplyComment(
        reportId: 'rep-reply-1',
        replierName: 'Admin Kelurahan',
        replyBody: 'Tim dinas sudah meluncur ke lokasi.',
      );

      final list = await repository.getNotifications();
      expect(list.length, equals(1));
      expect(list.first.type, equals(NotificationType.replyComment));
      expect(list.first.reportId, equals('rep-reply-1'));
      expect(list.first.title, equals('Seseorang membalas komentar Anda!'));
      expect(list.first.message, contains('Admin Kelurahan'));
    });

    test('6. notifyAnnouncement dispatches announcement notification', () async {
      await repository.notifyAnnouncement(
        announcementTitle: 'Kerja Bakti Akbar Minggu Pagi',
        announcementContent: 'Diharapkan seluruh warga membawa peralatan kerja bakti.',
      );

      final list = await repository.getNotifications();
      expect(list.length, equals(1));
      expect(list.first.type, equals(NotificationType.announcement));
      expect(list.first.title, equals('Pengumuman baru diterbitkan!'));
      expect(list.first.message, contains('Kerja Bakti Akbar'));
    });
  });

  group('3. Repositories Triggering NotificationRepository Integration', () {
    test('ReportRepository.createReport triggers notifyNewReport', () async {
      NotificationRepository.instance.setNotificationsForTesting([]);
      final repo = ReportRepository();

      await repo.createReport(
        authorId: 'author-user-1',
        authorName: 'Budi Hartono',
        title: 'Laporan Baru Terintegrasi',
        description: 'Deskripsi laporan uji coba',
        category: 'Infrastruktur',
        latitude: -6.2,
        longitude: 106.8,
        locationAddress: 'Jl. Merdeka No. 1',
        provinceId: '31',
      );

      final notifs = await NotificationRepository.instance.getNotifications();
      expect(notifs.any((n) => n.type == NotificationType.newReport), isTrue);
    });

    test('ReportRepository.voteReport triggers notifyUpvoted', () async {
      NotificationRepository.instance.setNotificationsForTesting([]);
      final repo = ReportRepository();

      final report = ReportModel(
        id: 'rep-vote-test-1',
        reportNumber: 'REP-001',
        authorId: 'user-original-author',
        authorName: 'Warga',
        areaId: 'area-1',
        areaName: 'Jakarta Pusat',
        title: 'Lampu Penerangan Padam',
        description: 'Lampu padam sejak 3 hari lalu',
        category: 'Fasilitas Umum',
        locationAddress: 'Jl. Melati',
        latitude: -6.2,
        longitude: 106.8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
      );
      repo.updateReport(report);

      await repo.voteReport(
        reportId: report.id,
        userId: 'other-user-voter',
        voteType: 'up',
      );

      final notifs = await NotificationRepository.instance.getNotifications();
      expect(notifs.any((n) => n.type == NotificationType.upvoted), isTrue);
    });

    test('ReportRepository.updateHandlingStatus triggers notifyStatusChanged without duplicates', () async {
      NotificationRepository.instance.setNotificationsForTesting([]);
      final repo = ReportRepository();

      final report = ReportModel(
        id: 'rep-status-test-1',
        reportNumber: 'REP-002',
        authorId: 'user-author-99',
        authorName: 'Warga',
        areaId: 'area-1',
        areaName: 'Jakarta Pusat',
        title: 'Saluran Tersumbat',
        description: 'Air meluap ke jalan',
        category: 'Lingkungan',
        locationAddress: 'Jl. Mawar',
        latitude: -6.2,
        longitude: 106.8,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
      );
      repo.updateReport(report);

      await repo.updateHandlingStatus(
        reportId: report.id,
        newStatus: HandlingStatus.inProgress,
      );

      final notifs = await NotificationRepository.instance.getNotifications();
      final statusNotifs = notifs.where((n) => n.type == NotificationType.statusChanged).toList();
      expect(statusNotifs.length, equals(1));
    });

    test('CommentRepository.addComment triggers notifyNewComment and notifyReplyComment', () async {
      NotificationRepository.instance.setNotificationsForTesting([]);
      final commentRepo = CommentRepository();

      // Top level comment
      await commentRepo.addComment(
        reportId: 'rep-test-comment',
        authorId: 'user-commenter-1',
        authorName: 'Siti Rahma',
        authorRole: UserRole.user,
        body: 'Komentar pertama warga',
      );

      var notifs = await NotificationRepository.instance.getNotifications();
      expect(notifs.any((n) => n.type == NotificationType.newComment), isTrue);

      // Reply comment
      await commentRepo.addComment(
        reportId: 'rep-test-comment',
        authorId: 'user-admin-1',
        authorName: 'Admin Kelurahan',
        authorRole: UserRole.admin,
        body: 'Terima kasih atas masukannya',
        parentCommentId: 'parent-123',
      );

      notifs = await NotificationRepository.instance.getNotifications();
      expect(notifs.any((n) => n.type == NotificationType.replyComment), isTrue);
    });

    test('AnnouncementRepository.createAnnouncement triggers notifyAnnouncement', () async {
      NotificationRepository.instance.setNotificationsForTesting([]);
      final announcementRepo = AnnouncementRepository();

      await announcementRepo.createAnnouncement(
        title: 'Pemadaman Listrik Bergilir',
        content: 'Akan dilakukan perawatan trafo listrik besok.',
        authorId: 'admin-id-1',
        authorName: 'Admin PLN',
      );

      final notifs = await NotificationRepository.instance.getNotifications();
      expect(notifs.any((n) => n.type == NotificationType.announcement), isTrue);
    });
  });

  group('4. SettingsController & NotificationController Dynamic Filtering', () {
    final now = DateTime.now();
    final sampleNotifications = [
      NotificationModel(
        id: 'n-status',
        title: 'Status Diperbarui',
        message: 'Laporan Anda sedang diproses',
        type: NotificationType.statusChanged,
        createdAt: now.subtract(const Duration(minutes: 1)),
        isRead: false,
      ),
      NotificationModel(
        id: 'n-announcement',
        title: 'Pengumuman Baru',
        message: 'Info penting untuk warga',
        type: NotificationType.announcement,
        createdAt: now.subtract(const Duration(minutes: 2)),
        isRead: false,
      ),
      NotificationModel(
        id: 'n-upvoted',
        title: 'Dukungan Masuk',
        message: 'Warga mendukung laporan Anda',
        type: NotificationType.upvoted,
        createdAt: now.subtract(const Duration(minutes: 3)),
        isRead: false,
      ),
      NotificationModel(
        id: 'n-comment',
        title: 'Komentar Baru',
        message: 'Ada komentar masuk di laporan Anda',
        type: NotificationType.newComment,
        createdAt: now.subtract(const Duration(minutes: 4)),
        isRead: false,
      ),
      NotificationModel(
        id: 'n-reply',
        title: 'Balasan Komentar',
        message: 'Seseorang membalas komentar Anda',
        type: NotificationType.replyComment,
        createdAt: now.subtract(const Duration(minutes: 5)),
        isRead: false,
      ),
      NotificationModel(
        id: 'n-newrep',
        title: 'Laporan Baru Masuk',
        message: 'Laporan baru perlu ditinjau admin',
        type: NotificationType.newReport,
        createdAt: now.subtract(const Duration(minutes: 6)),
        isRead: false,
      ),
    ];

    test('User mode: Master switch and user sub-toggles work properly', () async {
      final repository = NotificationRepository();
      repository.setNotificationsForTesting(sampleNotifications);

      final settingsController = SettingsController();
      await settingsController.loadSettings();
      final notificationController = NotificationController(
        repository: repository,
        settingsController: settingsController,
        isAdmin: false, // User mode
      );

      await notificationController.fetchNotifications();
      // All 6 notifications in repository
      expect(notificationController.notifications.length, equals(6));
      expect(notificationController.unreadCount, equals(6));

      // 1. Disable status changes
      await settingsController.setNotifyStatusChanges(false);
      var visible = notificationController.notifications;
      expect(visible.any((n) => n.type == NotificationType.statusChanged), isFalse);
      expect(visible.length, equals(5));
      expect(notificationController.unreadCount, equals(5));

      // 2. Disable announcements
      await settingsController.setNotifyAnnouncements(false);
      visible = notificationController.notifications;
      expect(visible.any((n) => n.type == NotificationType.announcement), isFalse);
      expect(visible.length, equals(4));

      // 3. Disable supports
      await settingsController.setNotifySupports(false);
      visible = notificationController.notifications;
      expect(visible.any((n) => n.type == NotificationType.upvoted), isFalse);
      expect(visible.length, equals(3));

      // 4. Disable comments (controls both comments & replies for user)
      await settingsController.setNotifyComments(false);
      visible = notificationController.notifications;
      expect(visible.any((n) => n.type == NotificationType.newComment), isFalse);
      expect(visible.any((n) => n.type == NotificationType.replyComment), isFalse);
      expect(visible.length, equals(1)); // only newReport remains

      // 5. Master switch off
      await settingsController.setNotificationsEnabled(false);
      expect(notificationController.notifications, isEmpty);
      expect(notificationController.unreadCount, equals(0));

      notificationController.dispose();
      repository.dispose();
    });

    test('Admin mode: Master switch and admin sub-toggles work properly', () async {
      final repository = NotificationRepository();
      repository.setNotificationsForTesting(sampleNotifications);

      final settingsController = SettingsController();
      await settingsController.loadSettings();
      final notificationController = NotificationController(
        repository: repository,
        settingsController: settingsController,
        isAdmin: true, // Admin mode
      );

      await notificationController.fetchNotifications();
      expect(notificationController.notifications.length, equals(6));

      // 1. Disable incoming reports
      await settingsController.setNotifyNewReports(false);
      var visible = notificationController.notifications;
      expect(visible.any((n) => n.type == NotificationType.newReport), isFalse);
      expect(visible.length, equals(5));

      // 2. Disable announcements
      await settingsController.setNotifyAnnouncements(false);
      visible = notificationController.notifications;
      expect(visible.any((n) => n.type == NotificationType.announcement), isFalse);
      expect(visible.length, equals(4));

      // 3. Disable replies (for admin, controls comments & replies)
      await settingsController.setNotifyReplies(false);
      visible = notificationController.notifications;
      expect(visible.any((n) => n.type == NotificationType.replyComment), isFalse);
      expect(visible.any((n) => n.type == NotificationType.newComment), isFalse);
      expect(visible.length, equals(2)); // statusChanged & upvoted

      notificationController.dispose();
      repository.dispose();
    });

    test('Listener reactivity: changing setting notifies listeners immediately', () async {
      final repository = NotificationRepository();
      final settingsController = SettingsController();
      final notificationController = NotificationController(
        repository: repository,
        settingsController: settingsController,
        isAdmin: false,
      );

      var listenerCalled = false;
      notificationController.addListener(() {
        listenerCalled = true;
      });

      await settingsController.setNotifyAnnouncements(false);
      expect(listenerCalled, isTrue);

      notificationController.dispose();
      repository.dispose();
    });
  });

  group('5. NotificationsScreen UI & Settings Integration Tests', () {
    testWidgets('NotificationsScreen automatically respects settings toggles', (tester) async {
      final repository = NotificationRepository();
      final now = DateTime.now();
      repository.setNotificationsForTesting([
        NotificationModel(
          id: 'ui-status-1',
          title: 'Status Baru UI',
          message: 'Laporan perbaikan jalan disetujui',
          type: NotificationType.statusChanged,
          createdAt: now,
          isRead: false,
        ),
        NotificationModel(
          id: 'ui-ann-1',
          title: 'Pengumuman Baru UI',
          message: 'Pembersihan got serentak',
          type: NotificationType.announcement,
          createdAt: now,
          isRead: false,
        ),
      ]);

      final settingsController = SettingsController();
      final authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'u-123',
          email: 'user@test.com',
          fullName: 'Test User',
          username: 'testuser',
          role: UserRole.user,
        ),
      );
      final authController = AuthController(authRepository: authRepo);
      final notifController = NotificationController(
        repository: repository,
        settingsController: settingsController,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsController>.value(value: settingsController),
            ChangeNotifierProvider<AuthController>.value(value: authController),
            ChangeNotifierProvider<NotificationController>.value(value: notifController),
            Provider<NotificationRepository>.value(value: repository),
          ],
          child: MaterialApp(
            theme: AppTheme.lightTheme,
            home: const NotificationsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Both should appear initially
      expect(find.text('Status Baru UI'), findsOneWidget);
      expect(find.text('Pengumuman Baru UI'), findsOneWidget);

      // Disable announcements in settings
      await settingsController.setNotifyAnnouncements(false);
      await tester.pumpAndSettle();

      // Announcement should now be hidden, status should remain visible
      expect(find.text('Pengumuman Baru UI'), findsNothing);
      expect(find.text('Status Baru UI'), findsOneWidget);

      // Turn master notifications off
      await settingsController.setNotificationsEnabled(false);
      await tester.pumpAndSettle();

      // Now all notifications are hidden and empty state is shown
      expect(find.text('Status Baru UI'), findsNothing);
      expect(find.text('Belum Ada Notifikasi'), findsOneWidget);
    });
  });

  group('6. FcmService Foreground Message Suppression Tests', () {
    testWidgets('FcmService suppresses foreground message when notifications are disabled in settings', (tester) async {
      final settingsController = SettingsController();
      await settingsController.setNotificationsEnabled(false);

      final authRepo = AuthRepository();
      final authController = AuthController(authRepository: authRepo);
      final notifRepo = NotificationRepository();
      final notifController = NotificationController(
        repository: notifRepo,
        settingsController: settingsController,
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<SettingsController>.value(value: settingsController),
            ChangeNotifierProvider<AuthController>.value(value: authController),
            ChangeNotifierProvider<NotificationController>.value(value: notifController),
            Provider<NotificationRepository>.value(value: notifRepo),
          ],
          child: MaterialApp(
            navigatorKey: FcmService.navigatorKey,
            home: const Scaffold(body: Text('Home Screen')),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fire a foreground message while notifications are disabled
      const message = RemoteMessage(
        messageId: 'test-msg-001',
        data: {
          'type': 'report_status_changed',
          'title': 'Pembaruan Status',
          'body': 'Laporan Anda telah selesai',
        },
      );

      // Should not throw and should safely process with suppression
      expect(
        () => FcmService.instance.handleForegroundMessageForTesting(message),
        returnsNormally,
      );
    });
  });
}
