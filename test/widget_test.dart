import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/main.dart';

void main() {
  testWidgets('LaporinApp unauthenticated renders Splash Screen and Logo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const LaporinApp());
    await tester.pumpAndSettle();

    // Verify Laporin title and intro actions
    expect(find.text('Laporin'), findsOneWidget);
    expect(find.text('Mulai Sekarang'), findsOneWidget);

    // Tap Mulai Sekarang -> Navigates to Login Screen
    await tester.tap(find.text('Mulai Sekarang'));
    await tester.pumpAndSettle();

    expect(find.text('Selamat Datang Kembali'), findsOneWidget);
    expect(find.text('Masuk Sekarang'), findsOneWidget);
  });

  testWidgets(
    'LaporinApp authenticated with username directly enters MainNavigationScreen (session persisted)',
    (WidgetTester tester) async {
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

      // Does not show splash or login screen
      expect(find.text('Mulai Sekarang'), findsNothing);
      expect(find.text('Selamat Datang Kembali'), findsNothing);

      // Directly shows MainNavigationScreen bottom navigation destinations
      expect(find.text('Beranda'), findsOneWidget);
      expect(find.text('Laporan'), findsOneWidget);
      expect(find.text('Notifikasi'), findsOneWidget);
      expect(find.text('Profil'), findsOneWidget);
    },
  );

  testWidgets(
    'LaporinApp authenticated without username enters SetUsernameScreen',
    (WidgetTester tester) async {
      final authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'user-new',
          email: 'newuser@laporin.id',
          fullName: 'New User',
          username: '',
          role: UserRole.user,
        ),
      );

      await tester.pumpWidget(LaporinApp(authRepository: authRepo));
      await tester.pumpAndSettle();

      // Does not show splash
      expect(find.text('Mulai Sekarang'), findsNothing);

      // Shows SetUsernameScreen prompts
      expect(find.text('Buat Username'), findsOneWidget);
      expect(find.text('Simpan & Lanjutkan'), findsOneWidget);
    },
  );
}
