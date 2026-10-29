import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/services/fcm_service.dart';
import 'package:laporin/data/models/notification_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/features/announcements/screens/announcements_screen.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:laporin/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FcmService Unit & Navigation Tests', () {
    test(
      'FcmService singleton instance is preserved and has initial state',
      () {
        final instance1 = FcmService.instance;
        final instance2 = FcmService.instance;
        expect(identical(instance1, instance2), isTrue);
        expect(FcmService.navigatorKey, isNotNull);
      },
    );

    test('FcmService handlePayloadNavigation gracefully handles empty or invalid payload', () {
      final service = FcmService.instance;
      // Should not throw or crash even if empty or null keys
      expect(() => service.handlePayloadNavigation({}), returnsNormally);
      expect(
        () => service.handlePayloadNavigation({'invalid_key': 'random_value'}),
        returnsNormally,
      );
    });

    testWidgets(
      'handlePayloadNavigation pushes ReportDetailScreen on report_status_changed',
      (tester) async {
        final authRepo = AuthRepository();
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'user-123',
            email: 'budi@laporin.id',
            fullName: 'Budi Santoso',
            username: 'budi_santoso',
            role: UserRole.user,
          ),
        );

        await tester.pumpWidget(LaporinApp(authRepository: authRepo));
        await tester.pumpAndSettle();

        // Trigger notification payload for report_status_changed
        FcmService.instance.handlePayloadNavigation({
          'type': 'report_status_changed',
          'report_id': 'rep-test-12345',
          'handling_status': 'in_progress',
        });

        await tester.pumpAndSettle();

        // ReportDetailScreen should be pushed onto the navigator stack
        expect(find.byType(ReportDetailScreen), findsOneWidget);
      },
    );

    testWidgets(
      'handlePayloadNavigation pushes AnnouncementsScreen on announcement_published',
      (tester) async {
        final authRepo = AuthRepository();
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'user-123',
            email: 'budi@laporin.id',
            fullName: 'Budi Santoso',
            username: 'budi_santoso',
            role: UserRole.user,
          ),
        );

        await tester.pumpWidget(LaporinApp(authRepository: authRepo));
        await tester.pumpAndSettle();

        // Trigger notification payload for announcement_published
        FcmService.instance.handlePayloadNavigation({
          'type': 'announcement_published',
          'announcement_id': 'ann-test-999',
        });

        await tester.pumpAndSettle();

        // AnnouncementsScreen should be pushed onto the navigator stack
        expect(find.byType(AnnouncementsScreen), findsOneWidget);
      },
    );

    test('NotificationModel serialization and parsing for FCM events', () {
      final now = DateTime.now();

      final reportNotif = NotificationModel(
        id: 'notif-1',
        title: 'Status Laporan Diperbarui',
        message: 'Laporan Anda #LAP-001 kini berstatus: Diproses.',
        type: NotificationType.statusChanged,
        reportId: 'rep-1',
        createdAt: now,
      );

      final json = reportNotif.toJson();
      expect(json['type'], equals('status_changed'));
      expect(json['report_id'], equals('rep-1'));

      final parsed = NotificationModel.fromJson(json);
      expect(parsed.id, equals('notif-1'));
      expect(parsed.type, equals(NotificationType.statusChanged));
      expect(parsed.reportId, equals('rep-1'));

      final announcementNotif = NotificationModel(
        id: 'notif-2',
        title: 'Pengumuman Resmi',
        message: 'Kerja bakti serentak akhir pekan ini.',
        type: NotificationType.announcement,
        createdAt: now,
      );

      final annJson = announcementNotif.toJson();
      expect(annJson['type'], equals('announcement'));
      final annParsed = NotificationModel.fromJson(annJson);
      expect(annParsed.type, equals(NotificationType.announcement));

      final replyNotif = NotificationModel(
        id: 'notif-3',
        title: 'Seseorang Membalas Komentar Anda!',
        message: 'ketuk untuk melihat',
        type: NotificationType.replyComment,
        reportId: 'rep-1',
        createdAt: now,
      );
      expect(replyNotif.toJson()['type'], equals('reply_comment'));
      expect(
        NotificationModel.fromJson(replyNotif.toJson()).type,
        equals(NotificationType.replyComment),
      );

      final newReportNotif = NotificationModel(
        id: 'notif-4',
        title: 'Laporan Baru!',
        message: 'buka laporan sekarang.',
        type: NotificationType.newReport,
        reportId: 'rep-1',
        createdAt: now,
      );
      expect(newReportNotif.toJson()['type'], equals('new_report'));
      expect(
        NotificationModel.fromJson(newReportNotif.toJson()).type,
        equals(NotificationType.newReport),
      );
    });
  });
}
