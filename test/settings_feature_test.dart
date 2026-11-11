import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:laporin/data/models/notification_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/profile/screens/profile_screen.dart';
import 'package:laporin/features/settings/controllers/settings_controller.dart';
import 'package:laporin/features/settings/screens/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. SettingsController Unit Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial settings default values', () {
      final controller = SettingsController();

      expect(controller.themeMode, equals(ThemeMode.system));
      expect(controller.notificationsEnabled, isTrue);
      expect(controller.notifyAnnouncements, isTrue);
      expect(controller.notifyStatusChanges, isTrue);
      expect(controller.notifySupports, isTrue);
      expect(controller.notifyComments, isTrue);
      expect(controller.notifyNewReports, isTrue);
      expect(controller.notifyReplies, isTrue);
    });

    test('ThemeMode switching and persistence', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = SettingsController();

      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, equals(ThemeMode.dark));

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(SettingsController.keyThemeMode), equals('dark'));

      await controller.setThemeMode(ThemeMode.light);
      expect(controller.themeMode, equals(ThemeMode.light));
      expect(prefs.getString(SettingsController.keyThemeMode), equals('light'));

      await controller.setThemeMode(ThemeMode.system);
      expect(controller.themeMode, equals(ThemeMode.system));
      expect(prefs.getString(SettingsController.keyThemeMode), equals('system'));
    });

    test('Notification preferences toggle and isNotificationAllowed helper', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = SettingsController();

      // All allowed initially
      expect(controller.isNotificationAllowed(NotificationType.announcement), isTrue);
      expect(controller.isNotificationAllowed(NotificationType.statusChanged), isTrue);
      expect(controller.isNotificationAllowed(NotificationType.upvoted), isTrue);
      expect(controller.isNotificationAllowed(NotificationType.newComment), isTrue);

      // Disable announcement
      await controller.setNotifyAnnouncements(false);
      expect(controller.notifyAnnouncements, isFalse);
      expect(controller.isNotificationAllowed(NotificationType.announcement), isFalse);
      expect(controller.isNotificationAllowed(NotificationType.statusChanged), isTrue);

      // Disable comments
      await controller.setNotifyComments(false);
      expect(controller.notifyComments, isFalse);
      expect(controller.isNotificationAllowed(NotificationType.newComment), isFalse);
      expect(controller.isNotificationAllowed(NotificationType.replyComment), isFalse);

      // Disable master toggle turns everything off
      await controller.setNotificationsEnabled(false);
      expect(controller.isNotificationAllowed(NotificationType.statusChanged), isFalse);
      expect(controller.isNotificationAllowed(NotificationType.upvoted), isFalse);

      // Re-enable master toggle
      await controller.setNotificationsEnabled(true);
      expect(controller.isNotificationAllowed(NotificationType.statusChanged), isTrue);
      expect(controller.isNotificationAllowed(NotificationType.upvoted), isTrue);
      expect(controller.isNotificationAllowed(NotificationType.announcement), isFalse); // remains false
    });

    test('Admin notification preferences toggle and isNotificationAllowed helper', () async {
      SharedPreferences.setMockInitialValues({});
      final controller = SettingsController();

      // Admin ecosystem allowed types
      expect(controller.isNotificationAllowed(NotificationType.newReport, isAdmin: true), isTrue);
      expect(controller.isNotificationAllowed(NotificationType.announcement, isAdmin: true), isTrue);
      expect(controller.isNotificationAllowed(NotificationType.replyComment, isAdmin: true), isTrue);

      // Disable new reports
      await controller.setNotifyNewReports(false);
      expect(controller.notifyNewReports, isFalse);
      expect(controller.isNotificationAllowed(NotificationType.newReport, isAdmin: true), isFalse);
      expect(controller.isNotificationAllowed(NotificationType.announcement, isAdmin: true), isTrue);

      // Disable replies
      await controller.setNotifyReplies(false);
      expect(controller.notifyReplies, isFalse);
      expect(controller.isNotificationAllowed(NotificationType.replyComment, isAdmin: true), isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(SettingsController.keyNotifyNewReports), isFalse);
      expect(prefs.getBool(SettingsController.keyNotifyReplies), isFalse);
    });
  });

  group('2. SettingsScreen Widget Tests', () {
    late SettingsController settingsController;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      settingsController = SettingsController();
    });

    testWidgets('Renders all required sections and controls', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SettingsController>.value(
            value: settingsController,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // AppBar title
      expect(find.text('Pengaturan'), findsOneWidget);

      // Section 1: Tema & Tampilan
      expect(find.text('Tema & Tampilan'), findsOneWidget);
      expect(find.text('Pilih Mode Tampilan'), findsOneWidget);
      expect(find.text('Sistem'), findsOneWidget);
      expect(find.text('Terang'), findsOneWidget);
      expect(find.text('Gelap'), findsOneWidget);

      // Section 2: Notifikasi
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Aktifkan Notifikasi'), findsOneWidget);
      expect(find.text('Pengumuman Masuk'), findsOneWidget);
      expect(find.text('Perubahan Status Laporan'), findsOneWidget);
      expect(find.text('Dukungan Warga'), findsOneWidget);
      expect(find.text('Komentar & Diskusi'), findsOneWidget);

      // Section 3: Tentang Aplikasi
      expect(find.text('Tentang Aplikasi'), findsOneWidget);
      expect(find.text('Laporin'), findsOneWidget);
      expect(find.text('Versi 1.0.0 (MVP Pelaporan Fasilitas Publik)'), findsOneWidget);
      expect(find.text('Lihat Informasi Lengkap & Lisensi'), findsOneWidget);
    });

    testWidgets('Tapping theme cards updates controller themeMode', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SettingsController>.value(
            value: settingsController,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap 'Gelap'
      await tester.tap(find.text('Gelap'));
      await tester.pumpAndSettle();
      expect(settingsController.themeMode, equals(ThemeMode.dark));

      // Tap 'Terang'
      await tester.tap(find.text('Terang'));
      await tester.pumpAndSettle();
      expect(settingsController.themeMode, equals(ThemeMode.light));

      // Tap 'Sistem'
      await tester.tap(find.text('Sistem'));
      await tester.pumpAndSettle();
      expect(settingsController.themeMode, equals(ThemeMode.system));
    });

    testWidgets('Tapping About App action opens AboutDialog', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<SettingsController>.value(
            value: settingsController,
            child: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final aboutAction = find.text('Lihat Informasi Lengkap & Lisensi');
      expect(aboutAction, findsOneWidget);

      await tester.tap(aboutAction);
      await tester.pumpAndSettle();

      // AboutDialog is displayed
      expect(find.byType(AboutDialog), findsOneWidget);
      expect(find.text('1.0.0 (MVP)'), findsWidgets);
    });

    testWidgets('Renders admin notification toggles when user is admin', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        UserProfileModel(
          id: 'admin-1',
          email: 'admin@laporin.id',
          fullName: 'Admin Diskominfo',
          username: 'admin_diskominfo',
          role: UserRole.admin,
          createdAt: DateTime.now(),
        ),
      );
      final authCtrl = AuthController(authRepository: authRepo);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: authCtrl),
            ChangeNotifierProvider<SettingsController>.value(value: settingsController),
          ],
          child: const MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Master switch exists
      expect(find.text('Aktifkan Notifikasi'), findsOneWidget);

      // Admin toggles: Laporan Masuk, Pengumuman, Balasan
      expect(find.text('Laporan Masuk'), findsOneWidget);
      expect(find.text('Pengumuman'), findsOneWidget);
      expect(find.text('Balasan'), findsOneWidget);

      // Citizen-specific toggles must NOT appear for admin
      expect(find.text('Pengumuman Masuk'), findsNothing);
      expect(find.text('Perubahan Status Laporan'), findsNothing);
      expect(find.text('Dukungan Warga'), findsNothing);
      expect(find.text('Komentar & Diskusi'), findsNothing);

      // Toggling switches
      await tester.tap(find.text('Laporan Masuk'));
      await tester.pumpAndSettle();
      expect(settingsController.notifyNewReports, isFalse);

      await tester.tap(find.text('Balasan'));
      await tester.pumpAndSettle();
      expect(settingsController.notifyReplies, isFalse);
    });
  });

  group('3. ProfileScreen Navigation to SettingsScreen', () {
    testWidgets('ProfileScreen renders Pengaturan menu item and navigates to SettingsScreen', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        UserProfileModel(
          id: 'user-1',
          email: 'warga@laporin.id',
          fullName: 'Budi Warga',
          username: 'budi_warga',
          role: UserRole.user,
          createdAt: DateTime.now(),
        ),
      );

      final authCtrl = AuthController(authRepository: authRepo);
      final settingsCtrl = SettingsController();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AuthController>.value(value: authCtrl),
            ChangeNotifierProvider<SettingsController>.value(value: settingsCtrl),
          ],
          child: const MaterialApp(
            home: ProfileScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Menu item 'Pengaturan' must exist
      expect(find.text('Pengaturan'), findsOneWidget);
      expect(find.text('Tema tampilan, notifikasi, dan tentang aplikasi'), findsOneWidget);

      // Tap 'Pengaturan'
      await tester.tap(find.text('Pengaturan'));
      await tester.pumpAndSettle();

      // SettingsScreen is displayed
      expect(find.byType(SettingsScreen), findsOneWidget);
    });
  });
}
