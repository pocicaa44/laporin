import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/services/fcm_service.dart';
import 'package:laporin/data/models/notification_model.dart';
import 'package:laporin/data/repositories/notification_repository.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';

void main() {
  group('NotificationController & Feature Tests', () {
    late NotificationRepository repository;
    late NotificationController controller;

    setUp(() {
      repository = NotificationRepository();
      controller = NotificationController(repository: repository);
    });

    tearDown(() {
      controller.dispose();
    });

    test('markAllAsRead successfully updates all items and unreadCount without unmodifiable list error', () async {
      final now = DateTime.now();
      final item1 = NotificationModel(
        id: 'n-1',
        title: 'Status Baru',
        message: 'Laporan diproses',
        type: NotificationType.statusChanged,
        createdAt: now,
        isRead: false,
      );
      final item2 = NotificationModel(
        id: 'n-2',
        title: 'Pengumuman Baru',
        message: 'Info penting',
        type: NotificationType.announcement,
        createdAt: now,
        isRead: false,
      );

      repository.setNotificationsForTesting([item1, item2]);
      await controller.fetchNotifications();

      expect(controller.notifications.length, equals(2));
      expect(controller.unreadCount, equals(2));

      // Harus berhasil tanpa UnsupportedError: Cannot modify an unmodifiable list
      await controller.markAllAsRead();

      expect(controller.unreadCount, equals(0));
      expect(controller.notifications.every((n) => n.isRead), isTrue);
    });

    test('markAsRead updates specific item and unreadCount', () async {
      final now = DateTime.now();
      final item1 = NotificationModel(
        id: 'n-1',
        title: 'Status Baru',
        message: 'Laporan diproses',
        type: NotificationType.statusChanged,
        createdAt: now,
        isRead: false,
      );
      final item2 = NotificationModel(
        id: 'n-2',
        title: 'Pengumuman Baru',
        message: 'Info penting',
        type: NotificationType.announcement,
        createdAt: now,
        isRead: false,
      );

      repository.setNotificationsForTesting([item1, item2]);
      await controller.fetchNotifications();

      expect(controller.unreadCount, equals(2));

      await controller.markAsRead('n-1');

      expect(controller.unreadCount, equals(1));
      expect(controller.notifications.firstWhere((n) => n.id == 'n-1').isRead, isTrue);
      expect(controller.notifications.firstWhere((n) => n.id == 'n-2').isRead, isFalse);
    });
  });

  group('Android Notification Channel Tests', () {
    test('androidNotificationChannel has Importance.max and sound enabled for popup heads-up', () {
      expect(FcmService.androidNotificationChannel.id, equals('laporin_channel'));
      expect(FcmService.androidNotificationChannel.importance, equals(Importance.max));
      expect(FcmService.androidNotificationChannel.playSound, isTrue);
      expect(FcmService.androidNotificationChannel.enableVibration, isTrue);
    });
  });
}
