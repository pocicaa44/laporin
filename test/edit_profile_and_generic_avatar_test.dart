import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/widgets/app_button.dart';
import 'package:laporin/core/widgets/app_image.dart';
import 'package:laporin/core/widgets/user_avatar.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/profile/screens/edit_profile_screen.dart';
import 'package:laporin/features/profile/screens/profile_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('1. Default Generic Avatar & Optimization Tests', () {
    testWidgets(
      'UserAvatar renders Image.asset with generic-avatar.png when avatarUrl is null',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UserAvatar(
                name: 'Warga Satu',
                username: 'wargasatu',
                avatarUrl: null,
              ),
            ),
          ),
        );

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);

        final imageWidget = tester.widget<Image>(imageFinder);
        expect(imageWidget.image, isA<AssetImage>());
        final assetImage = imageWidget.image as AssetImage;
        expect(assetImage.assetName, equals('assets/generic-avatar.png'));
      },
    );

    testWidgets(
      'UserAvatar renders Image.asset with generic-avatar.png when avatarUrl is empty',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UserAvatar(
                name: 'Warga Dua',
                username: 'wargadua',
                avatarUrl: '   ',
              ),
            ),
          ),
        );

        final imageFinder = find.byType(Image);
        expect(imageFinder, findsOneWidget);

        final imageWidget = tester.widget<Image>(imageFinder);
        expect(imageWidget.image, isA<AssetImage>());
        final assetImage = imageWidget.image as AssetImage;
        expect(assetImage.assetName, equals('assets/generic-avatar.png'));
      },
    );

    testWidgets('UserAvatar renders AppImage when avatarUrl is non-empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              name: 'Warga Tiga',
              username: 'wargatiga',
              avatarUrl: 'https://example.com/avatar.jpg',
            ),
          ),
        ),
      );

      expect(find.byType(AppImage), findsOneWidget);
    });

    test('removeAvatar resets avatarUrl to null in UserProfileModel without server upload', () async {
      final authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'user-reset-1',
          email: 'reset@laporin.id',
          fullName: 'Reset User',
          username: 'reset_user',
          avatarUrl: 'https://example.com/old_avatar.jpg',
          role: UserRole.user,
        ),
      );

      final controller = AuthController(authRepository: authRepo);
      expect(controller.currentUser?.avatarUrl, isNotNull);

      final success = await controller.removeAvatar();
      expect(success, isTrue);
      expect(controller.currentUser?.avatarUrl, isNull);
    });
  });

  group('2. ProfileScreen Avatar & Navigation Tests', () {
    late AuthRepository authRepo;

    setUp(() {
      authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'user-prof-test',
          email: 'andi@laporin.id',
          fullName: 'Andi Wijaya',
          username: 'andiwijaya',
          avatarUrl: 'https://example.com/andi.jpg',
          role: UserRole.user,
        ),
      );
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthController(authRepository: authRepo),
          ),
        ],
        child: const MaterialApp(home: ProfileScreen()),
      );
    }

    testWidgets('ProfileScreen avatar does not display camera edit badge', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      final userAvatarFinder = find.byType(UserAvatar);
      expect(userAvatarFinder, findsOneWidget);

      final userAvatar = tester.widget<UserAvatar>(userAvatarFinder);
      expect(userAvatar.showEditBadge, isFalse);
    });

    testWidgets(
      'Clicking avatar on ProfileScreen opens avatar dialog containing ONLY photo without zoom or other widgets',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap on avatar in ProfileScreen
        await tester.tap(find.byType(UserAvatar));
        await tester.pumpAndSettle();

        // Dialog should appear
        final dialogFinder = find.byType(Dialog);
        expect(dialogFinder, findsOneWidget);

        // Verify ONLY the photo is displayed (no text, no buttons, no extra widgets)
        expect(
          find.descendant(of: dialogFinder, matching: find.byType(Text)),
          findsNothing,
        );
        expect(
          find.descendant(of: dialogFinder, matching: find.byType(IconButton)),
          findsNothing,
        );
        expect(
          find.descendant(
            of: dialogFinder,
            matching: find.byType(OutlinedButton),
          ),
          findsNothing,
        );
        expect(
          find.descendant(of: dialogFinder, matching: find.byType(AppImage)),
          findsOneWidget,
        );

        // Verify cannot be zoomed in/out (no InteractiveViewer)
        expect(
          find.descendant(
            of: dialogFinder,
            matching: find.byType(InteractiveViewer),
          ),
          findsNothing,
        );

        // Tapping the dialog photo closes the dialog
        await tester.tap(dialogFinder);
        await tester.pumpAndSettle();

        // Dialog closed
        expect(find.byType(Dialog), findsNothing);
      },
    );

    testWidgets(
      'ProfileScreen has Edit Profil button in card and menu option',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Edit Profil in user card and menu item
        expect(find.text('Edit Profil'), findsNWidgets(2));
        expect(find.text('Ubah foto profil dan username Anda'), findsOneWidget);

        // Tapping Edit Profil opens EditProfileScreen
        await tester.tap(find.text('Ubah foto profil dan username Anda'));
        await tester.pumpAndSettle();

        expect(find.byType(EditProfileScreen), findsOneWidget);
      },
    );
  });

  group('3. EditProfileScreen Tests', () {
    late AuthRepository authRepo;

    setUp(() {
      authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'user-edit-test',
          email: 'ratna@laporin.id',
          fullName: 'Ratna Sari',
          username: 'ratnasari',
          avatarUrl: 'https://example.com/ratna.jpg',
          role: UserRole.user,
        ),
      );
    });

    Widget createTestApp() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) => AuthController(authRepository: authRepo),
          ),
        ],
        child: const MaterialApp(home: EditProfileScreen()),
      );
    }

    testWidgets('EditProfileScreen renders initial values and account info', (
      tester,
    ) async {
      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Edit Profil'), findsOneWidget);
      expect(find.text('Ubah Foto Profil'), findsOneWidget);
      expect(find.text('Nama Pengguna'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Ratna Sari'), findsOneWidget);
      expect(find.text('Nama Akun (@)'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'ratnasari'), findsOneWidget);
      expect(find.text('ratna@laporin.id'), findsOneWidget);
      expect(find.text('Warga Masyarakat'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets(
      'Updating Nama Pengguna and Nama Akun in EditProfileScreen updates AuthController and repository',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Enter new Nama Pengguna
        final nameField = find.widgetWithText(TextFormField, 'Ratna Sari');
        await tester.enterText(nameField, 'Ratna Sari Dewi');
        await tester.pumpAndSettle();

        // Enter new Nama Akun
        final usernameField = find.widgetWithText(TextFormField, 'ratnasari');
        await tester.enterText(usernameField, 'ratna_dewi');
        await tester.pumpAndSettle(const Duration(milliseconds: 600));

        // Click Simpan Perubahan
        final saveBtn = find.text('Simpan Perubahan');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verify fullName and username updated in repository
        expect(
          authRepo.currentUserProfile?.fullName,
          equals('Ratna Sari Dewi'),
        );
        expect(authRepo.currentUserProfile?.username, equals('ratna_dewi'));
      },
    );

    testWidgets(
      'Resetting avatar to default in EditProfileScreen removes custom avatar',
      (tester) async {
        await tester.pumpWidget(createTestApp());
        await tester.pumpAndSettle();

        // Tap Ubah Foto Profil
        await tester.tap(find.text('Ubah Foto Profil'));
        await tester.pumpAndSettle();

        // Tap Gunakan Avatar Standar (Hapus Foto)
        final resetOption = find.text('Gunakan Avatar Standar (Hapus Foto)');
        expect(resetOption, findsOneWidget);
        await tester.tap(resetOption);
        await tester.pumpAndSettle();

        // Indikator "Akan menggunakan avatar standar" muncul
        expect(find.text('Akan menggunakan avatar standar'), findsOneWidget);

        // Click Simpan Perubahan
        final saveBtn = find.text('Simpan Perubahan');
        await tester.ensureVisible(saveBtn);
        await tester.tap(saveBtn);
        await tester.pumpAndSettle();

        // Verify avatarUrl is now null
        expect(authRepo.currentUserProfile?.avatarUrl, isNull);
      },
    );
  });
}
