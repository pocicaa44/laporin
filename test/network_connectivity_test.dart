import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:laporin/core/services/network_service.dart';
import 'package:laporin/core/widgets/app_button.dart';
import 'package:laporin/core/widgets/offline_fallback_view.dart';
import 'package:laporin/core/widgets/top_connectivity_strip.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/auth/screens/splash_screen.dart';
import 'package:laporin/features/create_report/screens/create_report_screen.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/feed/screens/feed_screen.dart';
import 'package:laporin/features/navigation/screens/main_navigation_screen.dart';
import 'package:laporin/features/profile/screens/profile_screen.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:laporin/features/report_detail/widgets/vote_action_bar.dart';
import 'package:laporin/main.dart';
import 'package:provider/provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. NetworkService Logic & Reachability Tests', () {
    test('isConnectedResults returns false for empty or none results', () {
      expect(NetworkService.isConnectedResults([]), isFalse);
      expect(
        NetworkService.isConnectedResults([ConnectivityResult.none]),
        isFalse,
      );
    });

    test('isConnectedResults returns true when wifi, mobile, or other valid connection exists', () {
      expect(
        NetworkService.isConnectedResults([ConnectivityResult.wifi]),
        isTrue,
      );
      expect(
        NetworkService.isConnectedResults([ConnectivityResult.mobile]),
        isTrue,
      );
      expect(
        NetworkService.isConnectedResults([ConnectivityResult.ethernet]),
        isTrue,
      );
      expect(
        NetworkService.isConnectedResults([ConnectivityResult.vpn]),
        isTrue,
      );
      expect(
        NetworkService.isConnectedResults([
          ConnectivityResult.none,
          ConnectivityResult.wifi,
        ]),
        isTrue,
      );
    });

    test(
      'updateStatusForTesting accurately updates isOnline and stream',
      () async {
        final service = NetworkService();
        expect(service.isOnline, isTrue);

        final events = <bool>[];
        final sub = service.onOnlineStatusChanged.listen(events.add);

        service.updateStatusForTesting(isOnline: false);
        expect(service.isOnline, isFalse);

        service.updateStatusForTesting(isOnline: true);
        expect(service.isOnline, isTrue);

        await Future.delayed(const Duration(milliseconds: 10));
        expect(events, equals([false, true]));
        await sub.cancel();
      },
    );

    test(
      'validates internet reachability using custom internetChecker',
      () async {
        var checkerCalled = false;
        final service = NetworkService(
          internetChecker: () async {
            checkerCalled = true;
            return false; // Interface active but no actual internet
          },
        );

        await service.handleConnectivityResults([ConnectivityResult.wifi]);
        expect(checkerCalled, isTrue);
        expect(service.isOnline, isFalse);
      },
    );
  });

  group('2. Top Connectivity Strip Tests', () {
    late NetworkService networkService;

    setUp(() {
      networkService = NetworkService();
    });

    testWidgets(
      'Top banner displays "Anda sedang offline" persistently when offline',
      (tester) async {
        networkService.updateStatusForTesting(isOnline: false);

        await tester.pumpWidget(
          ChangeNotifierProvider<NetworkService>.value(
            value: networkService,
            child: const MaterialApp(
              home: Scaffold(body: TopConnectivityStrip()),
            ),
          ),
        );
        await tester.pump();

        expect(find.text('Anda sedang offline'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);

        // Advance 5 seconds - should remain persistent
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Anda sedang offline'), findsOneWidget);
      },
    );

    testWidgets(
      'Transitions to "Kembali online" for exactly 1 second, then dismisses',
      (tester) async {
        networkService.updateStatusForTesting(isOnline: false);

        await tester.pumpWidget(
          ChangeNotifierProvider<NetworkService>.value(
            value: networkService,
            child: const MaterialApp(
              home: Scaffold(body: TopConnectivityStrip()),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('Anda sedang offline'), findsOneWidget);

        // Turn online
        networkService.updateStatusForTesting(isOnline: true);
        await tester.pump();

        expect(find.text('Kembali online'), findsOneWidget);
        expect(find.byIcon(Icons.wifi_rounded), findsOneWidget);

        // After 1 second, it should dismiss smoothly
        await tester.pump(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        expect(find.text('Kembali online'), findsNothing);
        expect(find.text('Anda sedang offline'), findsNothing);
      },
    );
  });

  group('3. Guest & Onboarding Offline Flow Tests', () {
    late AuthRepository authRepo;
    late NetworkService networkService;

    setUp(() {
      authRepo = AuthRepository();
      networkService = NetworkService();
    });

    testWidgets(
      'Button "Mulai Sekarang" is disabled when offline, and enables when online',
      (tester) async {
        networkService.updateStatusForTesting(isOnline: false);

        await tester.pumpWidget(
          LaporinApp(authRepository: authRepo, networkService: networkService),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.text('Anda sedang offline'), findsOneWidget);

        // Mulai Sekarang button is disabled
        final buttonWidget = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Mulai Sekarang'),
        );
        expect(buttonWidget.onPressed, isNull);

        // Tapping should not navigate to login
        await tester.tap(find.text('Mulai Sekarang'));
        await tester.pumpAndSettle();
        expect(find.byType(SplashScreen), findsOneWidget);

        // Bring online
        networkService.updateStatusForTesting(isOnline: true);
        await tester.pump();

        final buttonWidgetOnline = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Mulai Sekarang'),
        );
        expect(buttonWidgetOnline.onPressed, isNotNull);
      },
    );

    testWidgets(
      'Top connectivity banner is at top of screen on SplashScreen (without AppBar)',
      (tester) async {
        networkService.updateStatusForTesting(isOnline: false);

        await tester.pumpWidget(
          LaporinApp(authRepository: authRepo, networkService: networkService),
        );
        await tester.pumpAndSettle();

        expect(find.byType(SplashScreen), findsOneWidget);
        expect(find.byType(AppBar), findsNothing);

        final bannerFinder = find.byType(TopConnectivityStrip);
        expect(bannerFinder, findsOneWidget);
        final bannerRect = tester.getRect(bannerFinder);

        expect(bannerRect.top, lessThan(kToolbarHeight));
      },
    );
  });

  group('4. Authenticated Offline Awareness & Disabled Actions', () {
    late AuthRepository authRepo;
    late AuthController authController;
    late NetworkService networkService;
    late ReportRepository reportRepo;

    setUp(() {
      authRepo = AuthRepository();
      networkService = NetworkService();
      reportRepo = ReportRepository();

      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'user-offline-1',
          email: 'warga@laporin.id',
          fullName: 'Budi Santoso',
          username: 'budi_santoso',
          role: UserRole.user,
        ),
      );
      authController = AuthController(authRepository: authRepo);
    });

    testWidgets(
      'Center "+" button (Buat Laporan) on MainNavigationScreen is disabled when offline',
      (tester) async {
        networkService.updateStatusForTesting(isOnline: false);

        await tester.pumpWidget(
          LaporinApp(
            authRepository: authRepo,
            networkService: networkService,
            reportRepository: reportRepo,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(MainNavigationScreen), findsOneWidget);
        expect(find.text('Anda sedang offline'), findsOneWidget);

        // Center "+" icon
        final plusIconFinder = find.byWidgetPredicate(
          (w) =>
              w is FaIcon &&
              w.icon?.codePoint == FontAwesomeIcons.plus.codePoint,
        );
        expect(plusIconFinder, findsOneWidget);

        // Tapping "+" while offline must NOT open CreateReportScreen
        await tester.tap(plusIconFinder);
        await tester.pumpAndSettle();
        expect(find.byType(CreateReportScreen), findsNothing);

        // Restore online
        networkService.updateStatusForTesting(isOnline: true);
        await tester.pump();

        // Tapping "+" now navigates to CreateReportScreen
        await tester.tap(plusIconFinder);
        await tester.pumpAndSettle();
        expect(find.byType(CreateReportScreen), findsOneWidget);
      },
    );

    testWidgets(
      'Top connectivity banner is positioned below the AppBar on authenticated screens',
      (tester) async {
        networkService.updateStatusForTesting(isOnline: false);

        await tester.pumpWidget(
          LaporinApp(
            authRepository: authRepo,
            networkService: networkService,
            reportRepository: reportRepo,
          ),
        );
        await tester.pumpAndSettle();

        final appBarFinder = find.byType(AppBar);
        expect(appBarFinder, findsOneWidget);
        final appBarRect = tester.getRect(appBarFinder);

        final bannerFinder = find.byType(TopConnectivityStrip);
        expect(bannerFinder, findsOneWidget);
        final bannerRect = tester.getRect(bannerFinder);

        // Verify banner is positioned at the bottom edge of AppBar
        expect(bannerRect.top, greaterThanOrEqualTo(appBarRect.bottom - 1.0));
      },
    );

    testWidgets(
      'Submit button in CreateReportScreen is disabled when offline',
      (tester) async {
        networkService.updateStatusForTesting(isOnline: false);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<NetworkService>.value(
                value: networkService,
              ),
              Provider<AuthRepository>.value(value: authRepo),
              ChangeNotifierProvider<AuthController>.value(
                value: authController,
              ),
              Provider<ReportRepository>.value(value: reportRepo),
              Provider<CommentRepository>.value(value: CommentRepository()),
            ],
            child: const MaterialApp(home: CreateReportScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final submitButton = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Kirim Laporan'),
        );
        expect(submitButton.onPressed, isNull);

        // Bring online
        networkService.updateStatusForTesting(isOnline: true);
        await tester.pump();

        final submitButtonOnline = tester.widget<AppButton>(
          find.widgetWithText(AppButton, 'Kirim Laporan'),
        );
        expect(submitButtonOnline.onPressed, isNotNull);
      },
    );

    testWidgets(
      'Edit Profile option in ProfileScreen is disabled when offline',
      (tester) async {
        networkService.updateStatusForTesting(isOnline: false);

        await tester.pumpWidget(
          LaporinApp(
            authRepository: authRepo,
            networkService: networkService,
            reportRepository: reportRepo,
          ),
        );
        await tester.pumpAndSettle();

        // Navigate to Profile tab
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle();
        expect(find.byType(ProfileScreen), findsOneWidget);

        expect(
          find.text('Edit profil dinonaktifkan saat offline'),
          findsOneWidget,
        );

        // Tapping edit profile while offline does nothing
        await tester.tap(find.text('Edit Profil'));
        await tester.pumpAndSettle();
        expect(find.text('Simpan Perubahan'), findsNothing);
      },
    );

    testWidgets(
      'VoteActionBar and comments in ReportDetailScreen are disabled when offline',
      (tester) async {
        final dummyReport = ReportModel(
          id: 'rep-det-1',
          reportNumber: 'LPR-2026-0001',
          authorId: 'user-other',
          authorName: 'Siti Aminah',
          areaId: 'area-1',
          areaName: 'Kota Semarang',
          title: 'Lampu Jalan Padam',
          description: 'Lampu PJU padam di persimpangan jalan.',
          category: 'Penerangan Jalan',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Jl. Pemuda',
          handlingStatus: HandlingStatus.inProgress,
          publicationState: PublicationState.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        networkService.updateStatusForTesting(isOnline: false);

        await tester.pumpWidget(
          LaporinApp(
            authRepository: authRepo,
            networkService: networkService,
            reportRepository: reportRepo,
          ),
        );
        await tester.pumpAndSettle();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<NetworkService>.value(
                value: networkService,
              ),
              Provider<AuthRepository>.value(value: authRepo),
              ChangeNotifierProvider<AuthController>.value(
                value: authController,
              ),
              Provider<ReportRepository>.value(value: reportRepo),
              Provider<CommentRepository>.value(value: CommentRepository()),
            ],
            child: MaterialApp(
              home: ReportDetailScreen(
                reportId: dummyReport.id,
                initialReport: dummyReport,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // VoteActionBar disabled
        expect(find.byType(VoteActionBar), findsOneWidget);
        expect(find.text('Tidak tersedia dalam mode offline'), findsOneWidget);

        // Comment TextField disabled
        final commentField = tester.widget<TextField>(find.byType(TextField));
        expect(commentField.enabled, isFalse);
        expect(
          find.text('Komentar dinonaktifkan saat offline'),
          findsOneWidget,
        );
      },
    );
  });

  group('5. Offline Fallback View & Auto-Refetch Tests', () {
    late AuthRepository authRepo;
    late AuthController authController;
    late NetworkService networkService;
    late ReportRepository reportRepo;

    setUp(() {
      authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'user-offline-1',
          email: 'warga@laporin.id',
          fullName: 'Budi Santoso',
          username: 'budi_santoso',
          role: UserRole.user,
        ),
      );
      authController = AuthController(authRepository: authRepo);
      networkService = NetworkService();
      reportRepo = ReportRepository();
    });

    testWidgets(
      'FeedScreen displays OfflineFallbackView when empty and offline, and auto-refetches on online',
      (tester) async {
        networkService.updateStatusForTesting(isOnline: false);

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<NetworkService>.value(
                value: networkService,
              ),
              Provider<AuthRepository>.value(value: authRepo),
              ChangeNotifierProvider<AuthController>.value(
                value: authController,
              ),
              Provider<ReportRepository>.value(value: reportRepo),
              ChangeNotifierProvider(
                create: (_) => FeedController(reportRepository: reportRepo),
              ),
            ],
            child: const MaterialApp(home: FeedScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // Expect offline fallback view
        expect(find.byType(OfflineFallbackView), findsOneWidget);
        expect(
          find.text('Anda sedang offline, hubungkan ke jaringan dan coba lagi'),
          findsOneWidget,
        );
        expect(find.text('Coba Lagi'), findsOneWidget);

        // Add report to repository simulating network recovery
        await reportRepo.createReport(
          authorId: 'author-1',
          authorName: 'Warga 1',
          areaName: 'Semarang',
          title: 'Jalan Berlubang Semarang',
          description: 'Lubang jalan berdiameter 50cm di jalan protokol.',
          category: 'Jalan & Infrastruktur',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Jl. Pahlawan',
          photoUrls: [],
        );

        // Connection transitions to online -> should auto re-fetch!
        networkService.updateStatusForTesting(isOnline: true);
        await tester.pump();
        await tester.pumpAndSettle();

        // OfflineFallbackView disappears and report appears
        expect(find.byType(OfflineFallbackView), findsNothing);
        expect(find.text('Jalan Berlubang Semarang'), findsOneWidget);
      },
    );
  });
}
