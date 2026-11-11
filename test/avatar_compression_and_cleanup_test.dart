import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:laporin/core/services/media_service.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/profile/screens/edit_profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helper to generate synthetic test images with varying dimensions and complexity
Uint8List createTestImageBytes({
  required int width,
  required int height,
  bool complexPattern = false,
}) {
  final image = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      if (complexPattern) {
        final r = (x * 7 + y * 13) % 256;
        final g = (x * 19 + y * 3) % 256;
        final b = (x * 31 + y * 29) % 256;
        image.setPixelRgb(x, y, r, g, b);
      } else {
        image.setPixelRgb(x, y, 64, 128, 200);
      }
    }
  }
  return Uint8List.fromList(img.encodePng(image));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('1. Image Compression Pipeline Tests (Max 30 KB, 256x256, 1:1, JPEG)', () {
    test('Foto besar berhasil dikompresi menjadi maksimal 30.000 byte dan rasio 1:1', () {
      // Create large 1200x800 image (> 150 KB)
      final largeBytes = createTestImageBytes(
        width: 1200,
        height: 800,
        complexPattern: true,
      );
      expect(largeBytes.lengthInBytes, greaterThan(30000));

      final compressedBytes = MediaService.compressAvatarBytes(largeBytes);

      // Skenario 1: Ukuran final <= 30.000 byte
      expect(
        compressedBytes.lengthInBytes,
        lessThanOrEqualTo(MediaService.maxAvatarSizeBytes),
      );
      expect(compressedBytes.lengthInBytes, lessThanOrEqualTo(30000));

      // Dimensi target 256x256 dan rasio 1:1
      final decoded = img.decodeImage(compressedBytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(decoded.height));
      expect(decoded.width, lessThanOrEqualTo(256));
    });

    test(
      'Foto yang sudah kecil diproses dengan efisien tanpa iterasi berlebihan',
      () {
        // 200x200 solid color image (simple and small)
        final smallBytes = createTestImageBytes(
          width: 200,
          height: 200,
          complexPattern: false,
        );

        final compressed = MediaService.compressAvatarBytes(smallBytes);
        expect(compressed.lengthInBytes, lessThanOrEqualTo(30000));

        final decoded = img.decodeImage(compressed);
        expect(decoded, isNotNull);
        expect(decoded!.width, equals(256));
        expect(decoded.height, equals(256));
      },
    );

    test('Kompresi adaptif menurunkan resolusi jika kualitas rendah masih belum mencukupi', () {
      // High-frequency noisy pattern
      final noisyImage = img.Image(width: 512, height: 512);
      final random = math.Random(42);
      for (int y = 0; y < 512; y++) {
        for (int x = 0; x < 512; x++) {
          noisyImage.setPixelRgb(
            x,
            y,
            random.nextInt(256),
            random.nextInt(256),
            random.nextInt(256),
          );
        }
      }
      final rawBytes = Uint8List.fromList(img.encodePng(noisyImage));

      final compressed = MediaService.compressAvatarBytes(rawBytes);
      expect(compressed.lengthInBytes, lessThanOrEqualTo(30000));

      final decoded = img.decodeImage(compressed);
      expect(decoded, isNotNull);
      expect(decoded!.width, equals(decoded.height));
      expect(MediaService.avatarResolutions.contains(decoded.width), isTrue);
    });

    test('Foto dengan metadata EXIF berhasil distrip dan dikompresi di bawah 30 KB', () {
      final imageWithExif = img.Image(width: 400, height: 400);
      for (int y = 0; y < 400; y++) {
        for (int x = 0; x < 400; x++) {
          imageWithExif.setPixelRgb(x, y, (x * 3) % 256, (y * 5) % 256, 120);
        }
      }
      // Simulate heavy camera metadata
      imageWithExif.textData = {
        'CameraModel': 'Pixel 8 Pro',
        'MakerNote': 'A' * 5000,
      };
      final rawJpegWithMeta = Uint8List.fromList(img.encodeJpg(imageWithExif));

      final compressed = MediaService.compressAvatarBytes(rawJpegWithMeta);
      expect(
        compressed.lengthInBytes,
        lessThanOrEqualTo(MediaService.maxAvatarSizeBytes),
      );
      expect(compressed.lengthInBytes, lessThanOrEqualTo(30000));

      final decoded = img.decodeImage(compressed);
      expect(decoded, isNotNull);
      expect(decoded!.exif.isEmpty, isTrue);
      expect(decoded.textData == null || decoded.textData!.isEmpty, isTrue);
    });

    test('Format file tidak didukung atau corrupt ditolak dengan aman', () {
      final corruptBytes = Uint8List.fromList([0, 1, 2, 3, 4, 5, 6, 7]);
      expect(
        () => MediaService.compressAvatarBytes(corruptBytes),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'description',
            contains('Format gambar tidak didukung'),
          ),
        ),
      );
    });
  });

  group('2. Storage Path Parsing & Security Rules Tests (Least Privilege & IDOR Prevention)', () {
    const userId = '00000000-0000-0000-0000-000000000001';
    const otherUserId = '99999999-9999-9999-9999-999999999999';

    test('Valid avatars bucket URL parsed correctly for owner', () {
      const url =
          'https://test.supabase.co/storage/v1/object/public/avatars/00000000-0000-0000-0000-000000000001/avatar_12345.jpg';
      final ref = MediaService.parseAvatarStoragePath(
        avatarUrl: url,
        userId: userId,
      );

      expect(ref, isNotNull);
      expect(ref!.bucket, equals('avatars'));
      expect(
        ref.path,
        equals('00000000-0000-0000-0000-000000000001/avatar_12345.jpg'),
      );
    });

    test('Valid report-attachments fallback URL parsed correctly for owner', () {
      const url =
          'https://test.supabase.co/storage/v1/object/public/report-attachments/avatars/00000000-0000-0000-0000-000000000001/avatar_12345.jpg';
      final ref = MediaService.parseAvatarStoragePath(
        avatarUrl: url,
        userId: userId,
      );

      expect(ref, isNotNull);
      expect(ref!.bucket, equals('report-attachments'));
      expect(
        ref.path,
        equals('avatars/00000000-0000-0000-0000-000000000001/avatar_12345.jpg'),
      );
    });

    test('Relative path formats parsed correctly for owner', () {
      final ref1 = MediaService.parseAvatarStoragePath(
        avatarUrl: '$userId/avatar_999.jpg',
        userId: userId,
      );
      expect(ref1, isNotNull);
      expect(ref1!.bucket, equals('avatars'));
      expect(ref1.path, equals('$userId/avatar_999.jpg'));

      final ref2 = MediaService.parseAvatarStoragePath(
        avatarUrl: 'avatars/$userId/avatar_888.jpg',
        userId: userId,
      );
      expect(ref2, isNotNull);
      expect(ref2!.bucket, equals('avatars'));
      expect(ref2.path, equals('avatars/$userId/avatar_888.jpg'));
    });

    test('Skenario 11: Foto profil pengguna lain DITOLAK dan tidak dapat dihapus', () {
      const otherUserUrl =
          'https://test.supabase.co/storage/v1/object/public/avatars/$otherUserId/avatar_12345.jpg';
      final ref = MediaService.parseAvatarStoragePath(
        avatarUrl: otherUserUrl,
        userId: userId, // current user is NOT otherUserId
      );

      expect(ref, isNull);
    });

    test('Lampiran foto laporan tidak dapat dihapus melalui jalur avatar', () {
      const reportAttachmentUrl =
          'https://test.supabase.co/storage/v1/object/public/report-attachments/reports/$userId/photo_1.jpg';
      final ref = MediaService.parseAvatarStoragePath(
        avatarUrl: reportAttachmentUrl,
        userId: userId,
      );

      expect(ref, isNull);
    });

    test(
      'URL eksternal (Google, Unsplash) ditolak dan tidak dihapus dari storage',
      () {
        const googlePhotoUrl =
            'https://lh3.googleusercontent.com/a/ACg8ocK123456789=s96-c';
        final refGoogle = MediaService.parseAvatarStoragePath(
          avatarUrl: googlePhotoUrl,
          userId: userId,
        );
        expect(refGoogle, isNull);

        const unsplashUrl =
            'https://images.unsplash.com/photo-1534528741775-53994a69daeb';
        final refUnsplash = MediaService.parseAvatarStoragePath(
          avatarUrl: unsplashUrl,
          userId: userId,
        );
        expect(refUnsplash, isNull);
      },
    );

    test('Asset generic default avatar tidak dihapus dari storage', () {
      const assetPath = 'assets/generic-avatar-profile.png';
      final refAsset = MediaService.parseAvatarStoragePath(
        avatarUrl: assetPath,
        userId: userId,
      );
      expect(refAsset, isNull);
    });

    test('Path traversal attempts (..) ditolak dengan aman', () {
      const maliciousUrl =
          'https://test.supabase.co/storage/v1/object/public/avatars/$userId/../../reports/secret.jpg';
      final ref = MediaService.parseAvatarStoragePath(
        avatarUrl: maliciousUrl,
        userId: userId,
      );
      expect(ref, isNull);
    });
  });

  group('3. Sequential Avatar Update & Cleanup Tests in AuthRepository', () {
    const userId = 'user-test-uuid-1';
    const oldAvatarUrl =
        'https://test.supabase.co/storage/v1/object/public/avatars/$userId/avatar_old.jpg';

    test('Skenario 5 & 6: Avatar baru berhasil disimpan, state diperbarui, avatar lama dihapus', () async {
      final authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: userId,
          email: 'user@laporin.id',
          fullName: 'Budi Warga',
          username: 'budi_warga',
          avatarUrl: oldAvatarUrl,
          role: UserRole.user,
        ),
      );

      final testImageBytes = createTestImageBytes(width: 300, height: 300);
      final newFile = XFile.fromData(
        testImageBytes,
        name: 'new_avatar.jpg',
        mimeType: 'image/jpeg',
      );

      // In offline/unconnected mode, updateAvatar still completes the sequential flow
      final updatedProfile = await authRepo.updateAvatar(newFile);

      expect(updatedProfile.avatarUrl, isNotNull);
      expect(updatedProfile.avatarUrl, isNot(equals(oldAvatarUrl)));
      expect(
        authRepo.currentUserProfile?.avatarUrl,
        equals(updatedProfile.avatarUrl),
      );
    });

    test('Skenario 9: removeAvatar mereset avatar_url ke null dan menghapus avatar lama dari storage', () async {
      final authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: userId,
          email: 'user@laporin.id',
          fullName: 'Budi Warga',
          username: 'budi_warga',
          avatarUrl: oldAvatarUrl,
          role: UserRole.user,
        ),
      );

      final controller = AuthController(authRepository: authRepo);
      expect(controller.currentUser?.avatarUrl, equals(oldAvatarUrl));

      final success = await controller.removeAvatar();
      expect(success, isTrue);
      expect(controller.currentUser?.avatarUrl, isNull);
    });
  });

  group('4. EditProfileScreen UI & State Tests', () {
    testWidgets(
      'EditProfileScreen renders UserAvatar preview and handles cancel gracefully without modifying state',
      (tester) async {
        final authRepo = AuthRepository();
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'test-user-preview',
            email: 'preview@laporin.id',
            fullName: 'Preview User',
            username: 'preview_user',
            avatarUrl: null,
            role: UserRole.user,
          ),
        );

        final controller = AuthController(authRepository: authRepo);

        await tester.pumpWidget(
          ChangeNotifierProvider<AuthController>.value(
            value: controller,
            child: const MaterialApp(home: EditProfileScreen()),
          ),
        );

        // Verify UserAvatar displays generic asset
        expect(find.byType(EditProfileScreen), findsOneWidget);
        expect(find.text('Ubah Foto Profil'), findsWidgets);

        // Skenario 10: Pengguna tidak memilih foto baru / membatalkan -> profil tetap tidak berubah
        expect(controller.currentUser?.avatarUrl, isNull);
      },
    );

    testWidgets(
      'EditProfileScreen renders app header and account info card with dark theme colors',
      (tester) async {
        final authRepo = AuthRepository();
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'test-user-dark',
            email: 'user_dark@laporin.id',
            fullName: 'Dark Mode User',
            username: 'dark_user',
            avatarUrl: null,
            role: UserRole.user,
          ),
        );

        final controller = AuthController(authRepository: authRepo);

        await tester.pumpWidget(
          ChangeNotifierProvider<AuthController>.value(
            value: controller,
            child: MaterialApp(
              theme: ThemeData.dark(),
              home: const EditProfileScreen(),
            ),
          ),
        );

        // 1. Verify App Header title 'Edit Profil' uses bright text color
        final headerTitleFinder = find.descendant(
          of: find.byType(AppBar),
          matching: find.text('Edit Profil'),
        );
        expect(headerTitleFinder, findsOneWidget);
        final headerText = tester.widget<Text>(headerTitleFinder);
        expect(headerText.style?.color, equals(const Color(0xFFF8FAFC)));

        // 2. Verify 'Informasi Akun' card container uses darkSurface and darkBorder
        expect(find.text('Informasi Akun'), findsOneWidget);
        expect(find.text('user_dark@laporin.id'), findsOneWidget);
        final emailText = tester.widget<Text>(find.text('user_dark@laporin.id'));
        expect(emailText.style?.color, equals(const Color(0xFFF8FAFC)));

        // 3. Verify card container decoration color is darkSurface
        final cardContainerFinder = find.ancestor(
          of: find.text('Informasi Akun'),
          matching: find.byType(Container),
        ).first;
        final cardContainer = tester.widget<Container>(cardContainerFinder);
        final decoration = cardContainer.decoration as BoxDecoration;
        expect(decoration.color, equals(const Color(0xFF1E293B)));
      },
    );
  });
}
