import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/widgets/app_image.dart';
import 'package:laporin/core/widgets/user_avatar.dart';
import 'package:laporin/data/models/comment_model.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/feed/widgets/report_card.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:laporin/features/report_detail/widgets/comment_tile.dart';
import 'package:provider/provider.dart';

class _FakeAuthRepository extends AuthRepository {
  _FakeAuthRepository(this._profile);
  final UserProfileModel _profile;

  @override
  UserProfileModel? get currentUserProfile => _profile;
}

void main() {
  const googleAvatarUrl =
      'https://lh3.googleusercontent.com/a/ACg8ocISsampleGoogleProfilePhotoUrl=s96-c';

  group('Google Profile Photo in Reports Tests', () {
    test('ReportModel parses author_avatar_url with Google photo URL', () {
      final json = {
        'id': 'rep-google-1',
        'report_number': 'LPR-2026-0099',
        'author_id': 'usr-google-1',
        'author_name': 'Dewanto Google',
        'author_username': 'dewanto_g',
        'author_avatar_url': googleAvatarUrl,
        'area_id': 'area-jateng',
        'area_name': 'Semarang',
        'title': 'Laporan dari User Google',
        'description': 'Deskripsi laporan dengan avatar akun Google',
        'category': 'Fasilitas Umum',
        'latitude': -6.9932,
        'longitude': 110.4203,
        'location_address': 'Jl. Pahlawan',
        'handling_status': 'new',
        'publication_state': 'published',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final report = ReportModel.fromJson(json);

      expect(report.authorAvatarUrl, equals(googleAvatarUrl));
      expect(report.authorName, equals('Dewanto Google'));
      expect(report.authorUsername, equals('dewanto_g'));
    });

    test('ReportModel parses joined profiles containing Google photo URL when author_avatar_url is null', () {
      final json = {
        'id': 'rep-google-2',
        'report_number': 'LPR-2026-0100',
        'author_id': 'usr-google-2',
        'author_name': 'Warga Google',
        'author_username': null,
        'author_avatar_url': null,
        'area_id': 'area-jateng',
        'area_name': 'Semarang',
        'title': 'Laporan Google kedua',
        'description': 'Laporan dengan profile join',
        'category': 'Jalan & Jembatan',
        'latitude': -6.9932,
        'longitude': 110.4203,
        'location_address': 'Jl. Pandanaran',
        'handling_status': 'new',
        'publication_state': 'published',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'profiles': {
          'username': 'google_user',
          'full_name': 'Pengguna Google Asli',
          'avatar_url': googleAvatarUrl,
        },
      };

      final report = ReportModel.fromJson(json);

      expect(report.authorAvatarUrl, equals(googleAvatarUrl));
      expect(report.authorName, equals('Pengguna Google Asli'));
      expect(report.authorUsername, equals('google_user'));
    });

    testWidgets(
      'UserAvatar renders network image with Google avatar URL correctly',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: UserAvatar(
                name: 'Dewanto Google',
                avatarUrl: googleAvatarUrl,
                radius: 20,
              ),
            ),
          ),
        );

        final appImageFinder = find.byType(AppImage);
        expect(appImageFinder, findsOneWidget);

        final appImage = tester.widget<AppImage>(appImageFinder);
        expect(appImage.imageSource, equals(googleAvatarUrl));
      },
    );

    testWidgets('ReportCard displays author Google avatar URL via UserAvatar', (
      tester,
    ) async {
      final report = ReportModel(
        id: 'rep-card-1',
        reportNumber: 'LPR-2026-0101',
        authorId: 'usr-google-1',
        authorName: 'Dewanto Google',
        authorUsername: 'dewanto_g',
        authorAvatarUrl: googleAvatarUrl,
        areaId: 'area-jateng',
        areaName: 'Semarang',
        title: 'Lampu Jalan Rusak',
        description: 'Lampu jalan mati di perempatan',
        category: 'Penerangan Jalan',
        latitude: -6.9932,
        longitude: 110.4203,
        locationAddress: 'Jl. Pemuda',
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

      final userAvatarFinder = find.byType(UserAvatar);
      expect(userAvatarFinder, findsOneWidget);

      final userAvatar = tester.widget<UserAvatar>(userAvatarFinder);
      expect(userAvatar.avatarUrl, equals(googleAvatarUrl));
      expect(userAvatar.name, equals('Dewanto Google'));
    });

    testWidgets(
      'ReportDetailScreen displays author Google avatar URL in report header',
      (tester) async {
        final googleUser = UserProfileModel(
          id: 'usr-google-1',
          email: 'dewanto@gmail.com',
          fullName: 'Dewanto Google',
          username: 'dewanto_g',
          avatarUrl: googleAvatarUrl,
        );

        final authRepo = _FakeAuthRepository(googleUser);
        final authController = AuthController(authRepository: authRepo);

        final report = ReportModel(
          id: 'rep-detail-1',
          reportNumber: 'LPR-2026-0102',
          authorId: 'usr-google-1',
          authorName: 'Dewanto Google',
          authorUsername: 'dewanto_g',
          authorAvatarUrl: googleAvatarUrl,
          areaId: 'area-jateng',
          areaName: 'Semarang',
          title: 'Pohon Tumbang',
          description: 'Pohon tumbang menghalangi jalan utama',
          category: 'Lingkungan Hidup',
          latitude: -6.9932,
          longitude: 110.4203,
          locationAddress: 'Jl. Ahmad Yani',
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider.value(value: authController),
              Provider<ReportRepository>(create: (_) => ReportRepository()),
              Provider<CommentRepository>(create: (_) => CommentRepository()),
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

        final userAvatarFinders = find.byType(UserAvatar);
        expect(userAvatarFinders, findsWidgets);

        // Cari avatar author di header laporan
        final authorAvatar = tester
            .widgetList<UserAvatar>(userAvatarFinders)
            .firstWhere((av) => av.avatarUrl == googleAvatarUrl);
        expect(authorAvatar.avatarUrl, equals(googleAvatarUrl));
        expect(authorAvatar.name, equals('Dewanto Google'));
      },
    );

    test('createReport stores Google avatar URL in ReportModel', () async {
      final reportRepo = ReportRepository();
      final report = await reportRepo.createReport(
        authorId: 'usr-google-test',
        authorName: 'Dewanto Google',
        authorUsername: 'dewanto_g',
        authorAvatarUrl: googleAvatarUrl,
        title: 'Laporan Test Google Avatar',
        description: 'Memastikan avatar google tersimpan di laporan',
        category: 'Fasilitas Umum',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Jl. Test',
      );

      expect(report.authorAvatarUrl, equals(googleAvatarUrl));
    });
  });

  group('Google Profile Photo in Comments Tests', () {
    test('CommentModel parses author_avatar_url with Google photo URL', () {
      final json = {
        'id': 'com-google-1',
        'report_id': 'rep-google-1',
        'author_id': 'usr-google-1',
        'author_name': 'Dewanto Google',
        'author_avatar_url': googleAvatarUrl,
        'author_role': 'user',
        'body': 'Komentar pengujian dengan foto profil akun Google',
        'created_at': DateTime.now().toIso8601String(),
      };

      final comment = CommentModel.fromJson(json);

      expect(comment.authorAvatarUrl, equals(googleAvatarUrl));
      expect(comment.authorName, equals('Dewanto Google'));
      expect(comment.body, contains('foto profil akun Google'));
    });

    test('CommentModel.copyWith updates authorAvatarUrl', () {
      final comment = CommentModel(
        id: 'com-1',
        reportId: 'rep-1',
        authorId: 'usr-1',
        authorName: 'Dewanto',
        authorAvatarUrl: null,
        body: 'Komentar tanpa avatar awal',
        createdAt: DateTime.now(),
      );

      final updated = comment.copyWith(authorAvatarUrl: googleAvatarUrl);

      expect(updated.authorAvatarUrl, equals(googleAvatarUrl));
      expect(updated.authorName, equals('Dewanto'));
    });

    testWidgets('CommentTile renders UserAvatar with Google photo URL', (
      tester,
    ) async {
      final comment = CommentModel(
        id: 'com-tile-1',
        reportId: 'rep-1',
        authorId: 'usr-google-1',
        authorName: '@dewanto_g',
        authorAvatarUrl: googleAvatarUrl,
        body: 'Saya melihat langsung kondisi di lokasi tersebut.',
        createdAt: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: CommentTile(comment: comment)),
        ),
      );

      final userAvatarFinder = find.byType(UserAvatar);
      expect(userAvatarFinder, findsOneWidget);

      final userAvatar = tester.widget<UserAvatar>(userAvatarFinder);
      expect(userAvatar.avatarUrl, equals(googleAvatarUrl));
      expect(userAvatar.name, equals('@dewanto_g'));
    });

    test(
      'CommentRepository.addComment stores Google avatar URL in CommentModel',
      () async {
        final commentRepo = CommentRepository();
        final comment = await commentRepo.addComment(
          reportId: 'rep-google-1',
          authorId: 'usr-google-1',
          authorName: 'Dewanto Google',
          authorAvatarUrl: googleAvatarUrl,
          authorRole: UserRole.user,
          body: 'Komentar baru dengan akun Google bawaan',
        );

        expect(comment.authorAvatarUrl, equals(googleAvatarUrl));
        expect(comment.authorName, equals('Dewanto Google'));
      },
    );
  });
}
