import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laporin/core/widgets/user_avatar.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/feed/widgets/report_card.dart';
import 'package:laporin/features/profile/screens/profile_screen.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('ReportModel Username & Profiles Join Tests', () {
    test('displayAuthorUsername formats with @ prefix when authorUsername is present', () {
      final report = ReportModel(
        id: 'rep-1',
        reportNumber: 'LPR-2026-0001',
        authorId: 'usr-1',
        authorName: 'Budi Santoso',
        authorUsername: 'budi_santoso',
        areaId: 'area-jateng',
        areaName: 'Semarang',
        title: 'Jalan Rusak',
        description: 'Jalan berlubang parah',
        category: 'Jalan & Infrastruktur',
        latitude: -6.9932,
        longitude: 110.4203,
        locationAddress: 'Jl. Pemuda, Semarang',
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(report.displayAuthorUsername, equals('@budi_santoso'));
    });

    test(
      'displayAuthorUsername cleans existing @ prefix in authorUsername',
      () {
        final report = ReportModel(
          id: 'rep-2',
          reportNumber: 'LPR-2026-0002',
          authorId: 'usr-2',
          authorName: 'Siti Aminah',
          authorUsername: '@siti_aminah',
          areaId: 'area-jateng',
          areaName: 'Solo',
          title: 'Lampu Padam',
          description: 'Lampu jalan mati sejak kemarin',
          category: 'Penerangan Jalan',
          latitude: -7.5666,
          longitude: 110.8228,
          locationAddress: 'Jl. Slamet Riyadi, Solo',
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(report.displayAuthorUsername, equals('@siti_aminah'));
      },
    );

    test('displayAuthorUsername falls back gracefully to authorName when authorUsername is absent', () {
      final report = ReportModel(
        id: 'rep-3',
        reportNumber: 'LPR-2026-0003',
        authorId: 'usr-3',
        authorName: 'Joko Widodo',
        authorUsername: null,
        areaId: 'area-jateng',
        areaName: 'Surakarta',
        title: 'Saluran Tersumbat',
        description: 'Drainase tersumbat sampah',
        category: 'Kebersihan & Lingkungan',
        latitude: -7.5666,
        longitude: 110.8228,
        locationAddress: 'Solo',
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(report.displayAuthorUsername, equals('@joko_widodo'));
    });

    test('displayAuthorUsername falls back to @warga_laporin when authorName is default', () {
      final report = ReportModel(
        id: 'rep-4',
        reportNumber: 'LPR-2026-0004',
        authorId: 'usr-4',
        authorName: 'Warga Laporin',
        authorUsername: null,
        areaId: 'area-jateng',
        areaName: 'Semarang',
        title: 'Taman Rusak',
        description: 'Fasilitas bermain anak rusak',
        category: 'Fasilitas Umum',
        latitude: -6.9932,
        longitude: 110.4203,
        locationAddress: 'Semarang',
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(report.displayAuthorUsername, equals('@warga_laporin'));
    });

    test('ReportModel.fromJson parses joined profiles table correctly', () {
      final rawJson = {
        'id': 'rep-join-1',
        'report_number': 'LPR-2026-0099',
        'author_id': 'usr-join-1',
        'author_name': 'Original Name',
        'area_id': 'area-jateng',
        'area_name': 'Semarang',
        'title': 'Pohon Tumbang',
        'description': 'Menghalangi jalan utama',
        'category': 'Keamanan & Ketertiban',
        'latitude': -6.9932,
        'longitude': 110.4203,
        'location_address': 'Jl. Pandanaran',
        'handling_status': 'new',
        'publication_state': 'published',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'profiles': {
          'username': 'andi_wijaya',
          'full_name': 'Andi Wijaya, S.T.',
          'avatar_url': 'https://example.com/avatar.jpg',
        },
      };

      final parsed = ReportModel.fromJson(rawJson);
      expect(parsed.authorUsername, equals('andi_wijaya'));
      expect(parsed.authorName, equals('Andi Wijaya, S.T.'));
      expect(parsed.authorAvatarUrl, equals('https://example.com/avatar.jpg'));
      expect(parsed.displayAuthorUsername, equals('@andi_wijaya'));
    });
  });

  group('Avatar Upload & Auth State Tests', () {
    test('AuthRepository updateAvatar updates profile avatar and currentUserProfile in-memory', () async {
      final authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'test-user-1',
          email: 'test@laporin.id',
          fullName: 'Test User',
          username: 'test_user',
          avatarUrl: null,
          role: UserRole.user,
        ),
      );

      final dummyImage = XFile('test/mock_avatar.jpg');
      final updatedProfile = await authRepo.updateAvatar(dummyImage);

      expect(updatedProfile.avatarUrl, isNotNull);
      expect(updatedProfile.avatarUrl, contains('mock_avatar.jpg'));
      expect(
        authRepo.currentUserProfile?.avatarUrl,
        equals(updatedProfile.avatarUrl),
      );
    });

    test(
      'AuthController updateAvatar manages isUploadingAvatar loading lifecycle',
      () async {
        final authRepo = AuthRepository();
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'test-user-2',
            email: 'test2@laporin.id',
            fullName: 'Test User Two',
            username: 'test_user_2',
            role: UserRole.user,
          ),
        );

        final controller = AuthController(authRepository: authRepo);
        expect(controller.isUploadingAvatar, isFalse);

        final dummyImage = XFile('test/mock_avatar_2.png');
        final updateFuture = controller.updateAvatar(dummyImage);
        expect(controller.isUploadingAvatar, isTrue);

        final result = await updateFuture;
        expect(result, isTrue);
        expect(controller.isUploadingAvatar, isFalse);
        expect(
          controller.currentUser?.avatarUrl,
          contains('mock_avatar_2.png'),
        );
      },
    );
  });

  group('UI Widget Tests for Username & Avatar Display', () {
    testWidgets('ReportCard renders author username visibly', (tester) async {
      final report = ReportModel(
        id: 'rep-card-1',
        reportNumber: 'LPR-2026-0005',
        authorId: 'usr-5',
        authorName: 'Rina Kusuma',
        authorUsername: 'rina_kusuma',
        areaId: 'area-jateng',
        areaName: 'Semarang',
        title: 'Jembatan Rusak',
        description: 'Jembatan retak dan berbahaya',
        category: 'Jalan & Infrastruktur',
        latitude: -6.9932,
        longitude: 110.4203,
        locationAddress: 'Jl. Gajah Mada',
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ReportCard(
              report: report,
              onTap: () {},
              onUpvote: () {},
              onDownvote: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the author's username is clearly rendered in ReportCard
      expect(find.text('@rina_kusuma'), findsOneWidget);
      expect(find.byType(UserAvatar), findsOneWidget);
    });

    testWidgets(
      'ReportDetailScreen renders author username and name in Header Card',
      (tester) async {
        final report = ReportModel(
          id: 'rep-detail-1',
          reportNumber: 'LPR-2026-0006',
          authorId: 'usr-6',
          authorName: 'Dewanto Santoso',
          authorUsername: 'dewanto_s',
          areaId: 'area-jateng',
          areaName: 'Semarang',
          title: 'Pagar Pembatas Rusak',
          description: 'Pagar pembatas jalan patah akibat tertabrak truk',
          category: 'Jalan & Infrastruktur',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Semarang Barat',
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime(2026, 10, 22, 14, 30),
          updatedAt: DateTime(2026, 10, 22, 14, 30),
        );

        final authRepo = AuthRepository();
        final reportRepo = ReportRepository();
        final commentRepo = CommentRepository();

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              Provider.value(value: authRepo),
              Provider.value(value: reportRepo),
              Provider.value(value: commentRepo),
              ChangeNotifierProvider(
                create: (_) => AuthController(authRepository: authRepo),
              ),
            ],
            child: MaterialApp(
              home: ReportDetailScreen(
                reportId: report.id,
                initialReport: report,
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Verify the author's username is displayed on ReportDetailScreen
        expect(find.text('@dewanto_s'), findsOneWidget);
        expect(find.textContaining('Dewanto Santoso'), findsOneWidget);
      },
    );

    testWidgets(
      'ProfileScreen renders username of logged-in user and UserAvatar',
      (tester) async {
        final authRepo = AuthRepository();
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'user-prof-1',
            email: 'budi@laporin.id',
            fullName: 'Budi Santoso',
            username: 'budi_santoso',
            role: UserRole.user,
          ),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider(
                create: (_) => AuthController(authRepository: authRepo),
              ),
            ],
            child: const MaterialApp(home: ProfileScreen()),
          ),
        );

        await tester.pumpAndSettle();

        // Verify full name and username display in ProfileScreen
        expect(find.text('Budi Santoso'), findsOneWidget);
        expect(find.text('@budi_santoso'), findsOneWidget);
        expect(find.text('budi@laporin.id'), findsOneWidget);
        expect(find.byType(UserAvatar), findsOneWidget);
      },
    );

    testWidgets('ProfileScreen shows fallback when username is not set', (
      tester,
    ) async {
      final authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        const UserProfileModel(
          id: 'user-prof-2',
          email: 'nousername@laporin.id',
          fullName: 'User Tanpa Username',
          username: '',
          role: UserRole.user,
        ),
      );

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AuthController(authRepository: authRepo),
            ),
          ],
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // Verify fallback indicators
      expect(find.text('@belum_diset'), findsOneWidget);
      expect(find.text('Setel Sekarang'), findsOneWidget);
    });

    test(
      'AuthController updateAvatar updates user avatarUrl successfully',
      () async {
        final authRepo = AuthRepository();
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'user-prof-3',
            email: 'avatar@laporin.id',
            fullName: 'Avatar User',
            username: 'avatar_user',
            role: UserRole.user,
          ),
        );

        final controller = AuthController(authRepository: authRepo);
        expect(controller.currentUser?.avatarUrl, isNull);

        final dummyFile = XFile('test/resources/avatar.jpg');
        final success = await controller.updateAvatar(dummyFile);

        expect(success, isTrue);
        expect(
          controller.currentUser?.avatarUrl,
          equals('test/resources/avatar.jpg'),
        );
        expect(controller.isUploadingAvatar, isFalse);
      },
    );
  });
}
