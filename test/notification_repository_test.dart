import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/notification_model.dart';
import 'package:laporin/data/repositories/notification_repository.dart';

void main() {
  group('NotificationRepository Tests', () {
    late NotificationRepository repository;

    setUp(() {
      repository = NotificationRepository();
    });

    test('getNotifications returns empty list initially', () async {
      final list = await repository.getNotifications();
      expect(list, isEmpty);
    });

    test('setNotificationsForTesting populates notifications and sorts by createdAt desc', () async {
      final now = DateTime.now();
      final item1 = NotificationModel(
        id: 'notif-1',
        title: 'Status Baru',
        message: 'Laporan #LAP-1 diterima',
        type: NotificationType.statusChanged,
        createdAt: now.subtract(const Duration(minutes: 10)),
      );
      final item2 = NotificationModel(
        id: 'notif-2',
        title: 'Pengumuman Baru',
        message: 'Pengumuman kerja bakti',
        type: NotificationType.announcement,
        createdAt: now,
      );

      repository.setNotificationsForTesting([item1, item2]);

      final list = await repository.getNotifications();
      expect(list.length, equals(2));
      // Sesuai sorting b.createdAt.compareTo(a.createdAt), item2 yang lebih baru harus di awal
      expect(list.first.id, equals('notif-2'));
      expect(list.last.id, equals('notif-1'));
    });

    test(
      'markAsRead updates isRead to true for matching notification',
      () async {
        final item = NotificationModel(
          id: 'notif-100',
          title: 'Status Baru',
          message: 'Laporan diproses',
          type: NotificationType.statusChanged,
          createdAt: DateTime.now(),
          isRead: false,
        );

        repository.setNotificationsForTesting([item]);

        await repository.markAsRead('notif-100');

        final list = await repository.getNotifications();
        expect(list.first.isRead, isTrue);
      },
    );

    test('markAllAsRead marks all notifications as read', () async {
      final item1 = NotificationModel(
        id: 'notif-1',
        title: 'Notif 1',
        message: 'Pesan 1',
        type: NotificationType.statusChanged,
        createdAt: DateTime.now(),
        isRead: false,
      );
      final item2 = NotificationModel(
        id: 'notif-2',
        title: 'Notif 2',
        message: 'Pesan 2',
        type: NotificationType.announcement,
        createdAt: DateTime.now(),
        isRead: false,
      );

      repository.setNotificationsForTesting([item1, item2]);

      await repository.markAllAsRead();

      final list = await repository.getNotifications();
      expect(list.every((n) => n.isRead), isTrue);
    });
  });
}
