import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:laporin/core/services/fcm_service.dart';
import 'package:laporin/core/theme/app_theme.dart';
import 'package:laporin/data/models/notification_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/notification_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';
import 'package:laporin/features/notifications/screens/notifications_screen.dart';

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
      expect(
        controller.notifications.firstWhere((n) => n.id == 'n-1').isRead,
        isTrue,
      );
      expect(
        controller.notifications.firstWhere((n) => n.id == 'n-2').isRead,
        isFalse,
      );
    });

    test(
      'deleteNotifications removes selected items from controller',
      () async {
        final now = DateTime.now();
        final item1 = NotificationModel(
          id: 'n-1',
          title: 'Status Baru',
          message: 'Laporan diproses',
          type: NotificationType.statusChanged,
          createdAt: now,
        );
        final item2 = NotificationModel(
          id: 'n-2',
          title: 'Pengumuman Baru',
          message: 'Info penting',
          type: NotificationType.announcement,
          createdAt: now,
        );

        repository.setNotificationsForTesting([item1, item2]);
        await controller.fetchNotifications();

        expect(controller.notifications.length, equals(2));

        await controller.deleteNotifications(['n-1']);

        expect(controller.notifications.length, equals(1));
        expect(controller.notifications.first.id, equals('n-2'));
      },
    );
  });

  group('NotificationsScreen Delete Feature UI Tests', () {
    late NotificationRepository repository;
    late NotificationController controller;
    late AuthRepository authRepository;
    late AuthController authController;

    setUp(() {
      repository = NotificationRepository();
      controller = NotificationController(repository: repository);
      authRepository = AuthRepository();
      authController = AuthController(authRepository: authRepository);
    });

    tearDown(() {
      controller.dispose();
      authController.dispose();
    });

    Widget createTestWidget() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthController>.value(value: authController),
          ChangeNotifierProvider<NotificationController>.value(
            value: controller,
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NotificationsScreen(),
        ),
      );
    }

    testWidgets('Enters selection mode when clicking trash icon in AppBar', (
      tester,
    ) async {
      final now = DateTime.now();
      final item1 = NotificationModel(
        id: 'n-1',
        title: 'Notif 1',
        message: 'Pesan 1',
        type: NotificationType.statusChanged,
        createdAt: now,
      );
      final item2 = NotificationModel(
        id: 'n-2',
        title: 'Notif 2',
        message: 'Pesan 2',
        type: NotificationType.announcement,
        createdAt: now,
      );

      repository.setNotificationsForTesting([item1, item2]);
      await controller.fetchNotifications();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Verifikasi icon tong sampah di pojok kanan atas
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.text('Pilih Semua'), findsNothing);
      expect(find.text('Hapus'), findsNothing);

      // Klik icon tong sampah untuk masuk ke mode seleksi
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      // Sekarang di mode seleksi:
      // - "Pilih Semua" di kiri bawah
      expect(find.text('Pilih Semua'), findsOneWidget);
      // - Tombol "Hapus" di kanan bawah
      expect(find.text('Hapus'), findsOneWidget);
      // - Checkbox tersedia untuk setiap notifikasi + 1 untuk pilih semua
      expect(find.byType(Checkbox), findsNWidgets(3));
    });

    testWidgets(
      'Can select single notification and delete permanently without confirmation dialog',
      (tester) async {
        final now = DateTime.now();
        final item1 = NotificationModel(
          id: 'n-1',
          title: 'Notif Pertama',
          message: 'Pesan Pertama',
          type: NotificationType.statusChanged,
          createdAt: now,
        );
        final item2 = NotificationModel(
          id: 'n-2',
          title: 'Notif Kedua',
          message: 'Pesan Kedua',
          type: NotificationType.announcement,
          createdAt: now,
        );

        repository.setNotificationsForTesting([item1, item2]);
        await controller.fetchNotifications();

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Masuk mode seleksi
        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();

        // Pilih notif pertama dengan mengetuk itemnya
        await tester.tap(find.text('Notif Pertama'));
        await tester.pumpAndSettle();

        expect(find.text('1 Dipilih'), findsOneWidget);

        // Klik tombol "Hapus" di kanan bawah
        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();

        // Tidak ada confirmation dialog, langsung terhapus
        expect(find.byType(AlertDialog), findsNothing);
        expect(find.text('Notif Pertama'), findsNothing);
        expect(find.text('Notif Kedua'), findsOneWidget);
        expect(controller.notifications.length, equals(1));
        expect(controller.notifications.first.id, equals('n-2'));
      },
    );

    testWidgets(
      'Can click "Pilih Semua" in bottom left and delete all notifications',
      (tester) async {
        final now = DateTime.now();
        final item1 = NotificationModel(
          id: 'n-1',
          title: 'Notif 1',
          message: 'Pesan 1',
          type: NotificationType.statusChanged,
          createdAt: now,
        );
        final item2 = NotificationModel(
          id: 'n-2',
          title: 'Notif 2',
          message: 'Pesan 2',
          type: NotificationType.announcement,
          createdAt: now,
        );

        repository.setNotificationsForTesting([item1, item2]);
        await controller.fetchNotifications();

        await tester.pumpWidget(createTestWidget());
        await tester.pumpAndSettle();

        // Masuk mode seleksi
        await tester.tap(find.byIcon(Icons.delete_outline_rounded));
        await tester.pumpAndSettle();

        // Klik "Pilih Semua" di kiri bawah
        await tester.tap(find.text('Pilih Semua'));
        await tester.pumpAndSettle();

        expect(find.text('2 Dipilih'), findsOneWidget);

        // Klik "Hapus"
        await tester.tap(find.text('Hapus'));
        await tester.pumpAndSettle();

        // Semua terhapus, menampilkan empty state
        expect(find.text('Belum Ada Notifikasi'), findsOneWidget);
        expect(controller.notifications, isEmpty);
      },
    );

    testWidgets('Can exit selection mode by clicking close icon', (
      tester,
    ) async {
      final now = DateTime.now();
      final item = NotificationModel(
        id: 'n-1',
        title: 'Notif 1',
        message: 'Pesan 1',
        type: NotificationType.statusChanged,
        createdAt: now,
      );

      repository.setNotificationsForTesting([item]);
      await controller.fetchNotifications();

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Masuk mode seleksi
      await tester.tap(find.byIcon(Icons.delete_outline_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Pilih Semua'), findsOneWidget);

      // Klik Batal / Close icon
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Keluar dari mode seleksi
      expect(find.text('Pilih Semua'), findsNothing);
      expect(find.text('Hapus'), findsNothing);
      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
    });
  });

  group('Android Notification Channel Tests', () {
    test('androidNotificationChannel has Importance.max and sound enabled for popup heads-up', () {
      expect(
        FcmService.androidNotificationChannel.id,
        equals('laporin_channel'),
      );
      expect(
        FcmService.androidNotificationChannel.importance,
        equals(Importance.max),
      );
      expect(FcmService.androidNotificationChannel.playSound, isTrue);
      expect(FcmService.androidNotificationChannel.enableVibration, isTrue);
    });
  });
}
