import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:laporin/core/services/network_service.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/features/auth/screens/splash_screen.dart';
import 'package:laporin/features/auth/screens/login_screen.dart';
import 'package:laporin/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. NetworkService Logic Tests', () {
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
      'updateStatusForTesting accurately updates isOnline and isOverviewActive',
      () {
        final service = NetworkService();
        expect(service.isOnline, isTrue);

        service.updateStatusForTesting(isOnline: false, isOverviewActive: true);
        expect(service.isOnline, isFalse);
        expect(service.isOverviewActive, isTrue);

        service.updateStatusForTesting(isOnline: true, isOverviewActive: false);
        expect(service.isOnline, isTrue);
        expect(service.isOverviewActive, isFalse);
      },
    );
  });

  group('2. Offline / Online SnackBar UI Presentation Tests', () {
    late AuthRepository authRepo;

    setUp(() {
      authRepo = AuthRepository();
      NetworkService.instance.hideSnackBar();
      NetworkService.instance.updateStatusForTesting(
        isOnline: true,
        isOverviewActive: false,
      );
    });

    tearDown(() {
      NetworkService.instance.hideSnackBar();
    });

    testWidgets(
      'Does NOT display SnackBar when device goes offline while on overview/SplashScreen',
      (tester) async {
        await tester.pumpWidget(LaporinApp(authRepository: authRepo));
        await tester.pumpAndSettle();

        // Currently on SplashScreen (overview)
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(NetworkService.instance.isOverviewActive, isTrue);

        // Simulate device going offline
        NetworkService.instance.handleConnectivityResults([
          ConnectivityResult.none,
        ]);
        await tester.pump();

        // Must NOT display "Anda sedang offline" on overview screen
        expect(find.text('Anda sedang offline'), findsNothing);

        // Simulate device coming back online
        NetworkService.instance.handleConnectivityResults([
          ConnectivityResult.wifi,
        ]);
        await tester.pump();

        // Must NOT display "Kembali online" on overview screen
        expect(find.text('Kembali online'), findsNothing);
      },
    );

    testWidgets(
      'Displays "Anda sedang offline" and "Kembali online" when device is on LoginScreen',
      (tester) async {
        await tester.pumpWidget(LaporinApp(authRepository: authRepo));
        await tester.pumpAndSettle();

        // Tap "Mulai Sekarang" to navigate to LoginScreen
        await tester.tap(find.text('Mulai Sekarang'));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);
        expect(NetworkService.instance.isOverviewActive, isFalse);

        // Simulate device going offline
        NetworkService.instance.handleConnectivityResults([
          ConnectivityResult.none,
        ]);
        await tester.pump();

        // Should display "Anda sedang offline" SnackBar
        expect(find.text('Anda sedang offline'), findsOneWidget);

        // Simulate device reconnecting
        NetworkService.instance.handleConnectivityResults([
          ConnectivityResult.wifi,
        ]);
        await tester.pump();

        // Should display "Kembali online" SnackBar
        expect(find.text('Kembali online'), findsOneWidget);
      },
    );

    testWidgets(
      'Displays SnackBar on MainNavigationScreen for authenticated citizen',
      (tester) async {
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'citizen-1',
            email: 'warga@laporin.id',
            fullName: 'Warga Jateng',
            username: 'warga_jateng',
            role: UserRole.user,
          ),
        );

        await tester.pumpWidget(LaporinApp(authRepository: authRepo));
        await tester.pumpAndSettle();

        expect(NetworkService.instance.isOverviewActive, isFalse);

        // Device goes offline
        NetworkService.instance.handleConnectivityResults([
          ConnectivityResult.none,
        ]);
        await tester.pump();

        expect(find.text('Anda sedang offline'), findsOneWidget);

        // Device reconnects
        NetworkService.instance.handleConnectivityResults([
          ConnectivityResult.mobile,
        ]);
        await tester.pump();

        expect(find.text('Kembali online'), findsOneWidget);
      },
    );

    testWidgets(
      'Displays SnackBar on AdminNavigationScreen for authenticated admin',
      (tester) async {
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'admin-1',
            email: 'admin@laporin.id',
            fullName: 'Petugas Dinas',
            username: 'admin_dinas',
            role: UserRole.admin,
          ),
        );

        await tester.pumpWidget(LaporinApp(authRepository: authRepo));
        await tester.pumpAndSettle();

        expect(NetworkService.instance.isOverviewActive, isFalse);

        // Device goes offline
        NetworkService.instance.handleConnectivityResults([
          ConnectivityResult.none,
        ]);
        await tester.pump();

        expect(find.text('Anda sedang offline'), findsOneWidget);

        // Device reconnects
        NetworkService.instance.handleConnectivityResults([
          ConnectivityResult.wifi,
        ]);
        await tester.pump();

        expect(find.text('Kembali online'), findsOneWidget);
      },
    );

    testWidgets(
      'Hides offline SnackBar when popping back from LoginScreen to SplashScreen',
      (tester) async {
        await tester.pumpWidget(LaporinApp(authRepository: authRepo));
        await tester.pumpAndSettle();

        // Go to LoginScreen
        await tester.tap(find.text('Mulai Sekarang'));
        await tester.pumpAndSettle();

        expect(find.byType(LoginScreen), findsOneWidget);

        // Device goes offline on LoginScreen
        NetworkService.instance.handleConnectivityResults([
          ConnectivityResult.none,
        ]);
        await tester.pump();
        expect(find.text('Anda sedang offline'), findsOneWidget);

        // User pops back to SplashScreen
        final navigator = Navigator.of(
          tester.element(find.byType(LoginScreen)),
        );
        navigator.pop();
        await tester.pumpAndSettle();

        // Now back on SplashScreen (overview)
        expect(find.byType(SplashScreen), findsOneWidget);
        expect(NetworkService.instance.isOverviewActive, isTrue);

        // SnackBar must be dismissed on overview screen
        expect(find.text('Anda sedang offline'), findsNothing);
      },
    );
  });
}
