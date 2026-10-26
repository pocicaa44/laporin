import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/announcement_repository.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/auth/screens/splash_screen.dart';
import 'package:laporin/features/navigation/controllers/navigation_controller.dart';
import 'package:laporin/features/navigation/screens/main_navigation_screen.dart';
import 'package:laporin/features/profile/screens/profile_screen.dart';
import 'package:laporin/main.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DelayedSignOutAuthRepository extends AuthRepository {
  Completer<void>? signOutCompleter;

  @override
  Future<void> signOut() async {
    if (signOutCompleter != null) {
      await signOutCompleter!.future;
    }
    setCurrentUserProfileForTesting(null);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget({
    required AuthController authController,
    required NavigationController navKey,
  }) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: authController),
        ChangeNotifierProvider<NavigationController>.value(value: navKey),
      ],
      child: const MaterialApp(home: ProfileScreen()),
    );
  }

  group('Logout Loading Dialog Tests', () {
    testWidgets(
      'Tapping Keluar immediately shows non-dismissible loading dialog with "Sedang logout" and spinner',
      (tester) async {
        final delayedRepo = DelayedSignOutAuthRepository();
        delayedRepo.signOutCompleter = Completer<void>();
        delayedRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'user-logout-test',
            email: 'user@laporin.id',
            fullName: 'Budi Santoso',
            username: 'budi_santoso',
            role: UserRole.user,
          ),
        );

        final authController = AuthController(authRepository: delayedRepo);
        final navKey = NavigationController();

        await tester.pumpWidget(
          createTestWidget(authController: authController, navKey: navKey),
        );
        await tester.pumpAndSettle();

        // Verify Keluar button exists
        final keluarButton = find.text('Keluar');
        expect(keluarButton, findsOneWidget);

        // Verify dialog is NOT shown before tapping
        expect(find.text('Sedang logout'), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);

        // Tap Keluar
        await tester.tap(keluarButton);
        await tester.pump(); // Pump frame right after tap

        // Verify loading dialog appears IMMEDIATELY
        final dialogFinder = find.byType(Dialog);
        expect(dialogFinder, findsOneWidget);
        expect(find.text('Sedang logout'), findsOneWidget);

        final dialogSpinner = find.descendant(
          of: dialogFinder,
          matching: find.byType(CircularProgressIndicator),
        );
        expect(dialogSpinner, findsOneWidget);

        // Verify spinner is placed below the text
        final textPos = tester.getCenter(find.text('Sedang logout'));
        final spinnerPos = tester.getCenter(dialogSpinner);
        expect(spinnerPos.dy, greaterThan(textPos.dy));

        // Verify PopScope with canPop: false prevents dismiss on back navigation
        final popScope = tester.widget<PopScope>(
          find
                  .descendant(
                    of: find.byType(Dialog),
                    matching: find.byType(PopScope),
                  )
                  .evaluate()
                  .isEmpty
              ? find.byType(PopScope).first
              : find.descendant(
                  of: find.byType(Dialog),
                  matching: find.byType(PopScope),
                ),
        );
        expect(popScope.canPop, isFalse);

        // Try tapping outside the dialog (barrier dismiss attempt)
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();

        // Dialog MUST still be visible (cannot be cancelled or dismissed)
        expect(find.text('Sedang logout'), findsOneWidget);
        expect(dialogSpinner, findsOneWidget);

        // Now complete the signOut process
        delayedRepo.signOutCompleter!.complete();
        await tester.pumpAndSettle();

        // Once signed out, loading dialog is dismissed
        expect(find.text('Sedang logout'), findsNothing);
      },
    );

    testWidgets(
      'Logout inside AppGate unmounts ProfileScreen but dialog is immediately dismissed upon completion',
      (tester) async {
        final delayedRepo = DelayedSignOutAuthRepository();
        delayedRepo.signOutCompleter = Completer<void>();
        delayedRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'user-appgate-test',
            email: 'appgate@laporin.id',
            fullName: 'Siti Aminah',
            username: 'siti_aminah',
            role: UserRole.user,
          ),
        );

        await tester.pumpWidget(
          LaporinApp(
            key: const ValueKey('app-logout-test'),
            authRepository: delayedRepo,
            reportRepository: ReportRepository(),
            announcementRepository: AnnouncementRepository(),
          ),
        );
        await tester.pumpAndSettle();

        // Should render MainNavigationScreen initially
        expect(find.byType(MainNavigationScreen), findsOneWidget);

        // Switch to Profil tab (index 4)
        await tester.tap(find.text('Profil'));
        await tester.pumpAndSettle();

        // Verify Keluar button exists
        final keluarButton = find.text('Keluar');
        expect(keluarButton, findsOneWidget);

        // Tap Keluar
        await tester.tap(keluarButton);
        await tester.pump();

        // Loading dialog appears immediately
        expect(find.text('Sedang logout'), findsOneWidget);

        // Complete signOut
        delayedRepo.signOutCompleter!.complete();
        await tester.pumpAndSettle();

        // Dialog MUST be dismissed immediately
        expect(find.text('Sedang logout'), findsNothing);

        // User is now on SplashScreen
        expect(find.byType(SplashScreen), findsOneWidget);
      },
    );
  });
}
