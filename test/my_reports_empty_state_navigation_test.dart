import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:laporin/core/services/network_service.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/announcement_repository.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/notification_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/create_report/screens/create_report_screen.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/my_reports/screens/my_reports_screen.dart';
import 'package:laporin/features/navigation/controllers/navigation_controller.dart';
import 'package:laporin/features/notifications/controllers/notification_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
    'Tapping "Buat Laporan Baru" from MyReports empty state directly navigates to CreateReportScreen',
    (tester) async {
      final authRepo = AuthRepository();
      final reportRepo = ReportRepository();
      final navigationController = NavigationController();

      const citizenUser = UserProfileModel(
        id: 'user-citizen-1',
        email: 'citizen@laporin.id',
        fullName: 'Budi Santoso',
        username: 'budi_11',
        role: UserRole.user,
      );

      authRepo.setCurrentUserProfileForTesting(citizenUser);
      reportRepo.setReportsForTesting([]);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<NetworkService>.value(
              value: NetworkService.instance,
            ),
            Provider<AuthRepository>.value(value: authRepo),
            Provider<ReportRepository>.value(value: reportRepo),
            Provider<CommentRepository>(create: (_) => CommentRepository()),
            Provider<NotificationRepository>(
              create: (_) => NotificationRepository(),
            ),
            Provider<AnnouncementRepository>(
              create: (_) => AnnouncementRepository(),
            ),
            ChangeNotifierProvider(
              create: (_) => AuthController(authRepository: authRepo),
            ),
            ChangeNotifierProvider<NavigationController>.value(
              value: navigationController,
            ),
            ChangeNotifierProvider(
              create: (_) => FeedController(reportRepository: reportRepo),
            ),
            ChangeNotifierProvider(
              create: (_) =>
                  NotificationController(repository: NotificationRepository()),
            ),
          ],
          child: const MaterialApp(
            home: MyReportsScreen(),
          ),
        ),
      );

      // Settle loading states and empty state display
      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('Belum Ada Laporan'), findsOneWidget);
      final buatLaporanButton = find.text('Buat Laporan Baru');
      expect(buatLaporanButton, findsOneWidget);

      // Tap "Buat Laporan Baru"
      await tester.tap(buatLaporanButton);
      await tester.pumpAndSettle();

      // Verify that CreateReportScreen is directly displayed!
      expect(find.byType(CreateReportScreen), findsOneWidget);
      expect(find.text('Kategori Masalah *'), findsOneWidget);
    },
  );
}
