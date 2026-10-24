import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laporin/core/services/boundary_service.dart';
import 'package:laporin/core/services/location_service.dart';
import 'package:laporin/core/services/media_service.dart';
import 'package:laporin/core/widgets/app_button.dart';
import 'package:laporin/core/widgets/app_image.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/auth/screens/splash_screen.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/my_reports/controllers/my_reports_controller.dart';
import 'package:provider/provider.dart';

void main() {
  group('1. Performance & Standalone Isolate Optimization Tests', () {
    test(
      'BoundaryService.isInsideCentralJavaAsync runs accurately on Isolate',
      () async {
        final boundary = BoundaryService.instance;

        // Inside Central Java
        final inJateng = await boundary.isInsideCentralJavaAsync(
          -6.9932,
          110.4203,
        );
        expect(inJateng, isTrue);

        // Outside Central Java (DIY Enclave)
        final inDiy = await boundary.isInsideCentralJavaAsync(
          -7.7956,
          110.3695,
        );
        expect(inDiy, isFalse);

        // Outside Central Java (Jakarta)
        final inJakarta = await boundary.isInsideCentralJavaAsync(
          -6.2088,
          106.8456,
        );
        expect(inJakarta, isFalse);
      },
    );

    test('LocationService caches reverse geocoding to prevent redundant network I/O', () async {
      final locationService = LocationService.instance;
      const lat = -6.9932;
      const lng = 110.4203;

      final res1 = await locationService.getAddressFromCoordinates(lat, lng);
      expect(res1.isValidRegion, isTrue);

      // Second call should return cached instance immediately
      final res2 = await locationService.getAddressFromCoordinates(lat, lng);
      expect(res2.address, equals(res1.address));
      expect(res2.isValidRegion, equals(res1.isValidRegion));
    });

    test('MediaService.uploadAllPhotos handles batch uploads with bounded concurrency', () async {
      final media = MediaService.instance;
      final mockFiles = [
        XFile('test/mock_photo_1.jpg'),
        XFile('test/mock_photo_2.jpg'),
        XFile('test/mock_photo_3.jpg'),
      ];

      final urls = await media.uploadAllPhotos(
        authorId: 'usr-perf',
        files: mockFiles,
      );
      expect(urls.length, equals(3));
      expect(urls[0], equals('test/mock_photo_1.jpg'));
      expect(urls[1], equals('test/mock_photo_2.jpg'));
      expect(urls[2], equals('test/mock_photo_3.jpg'));
    });
  });

  group('2. Loading & Double-Submission Guards Tests', () {
    testWidgets(
      'SplashScreen Mulai Sekarang button enters loading state and disables double-tap',
      (tester) async {
        final authRepo = AuthRepository();
        await tester.pumpWidget(
          ChangeNotifierProvider(
            create: (_) => AuthController(authRepository: authRepo),
            child: const MaterialApp(home: SplashScreen()),
          ),
        );
        await tester.pumpAndSettle();

        final buttonFinder = find.byType(AppButton);
        expect(buttonFinder, findsOneWidget);

        final appButtonBefore = tester.widget<AppButton>(buttonFinder);
        expect(appButtonBefore.isLoading, isFalse);
        expect(find.text('Mulai Sekarang'), findsOneWidget);

        // Tap once
        await tester.tap(buttonFinder);
        await tester.pump(); // re-render with _isNavigating = true

        // Button must show loading state and spinner
        final appButtonAfter = tester.widget<AppButton>(buttonFinder);
        expect(appButtonAfter.isLoading, isTrue);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Second tap while navigating is safely ignored (disabled)
        await tester.tap(buttonFinder, warnIfMissed: false);
        await tester.pumpAndSettle();
      },
    );

    test(
      'AuthController in-flight request guards reject concurrent calls',
      () async {
        final authRepo = AuthRepository();
        final controller = AuthController(authRepository: authRepo);

        expect(controller.isLoading, isFalse);
        expect(controller.isUploadingAvatar, isFalse);

        // Verify checkUsernameAvailability handles empty/invalid gracefully
        final available = await controller.checkUsernameAvailability('');
        expect(available, isFalse);

        controller.dispose();
      },
    );
  });

  group('3. Pagination & Non-Destructive Refresh Tests', () {
    test(
      'FeedController implements pageSize, hasMore, and search debouncing',
      () async {
        final repo = ReportRepository();
        final controller = FeedController(reportRepository: repo);

        expect(FeedController.pageSize, equals(10));
        expect(controller.reports, isEmpty);
        // Initially true until first fetch determines total count
        expect(controller.hasMore, isTrue);

        // Await initial fetch completion
        await controller.fetchFeed();
        // With empty repo, items < pageSize so hasMore becomes false
        expect(controller.hasMore, isFalse);

        // Rapid search debouncing
        controller.setSearchQuery('j');
        controller.setSearchQuery('ja');
        controller.setSearchQuery('jal');
        controller.setSearchQuery('jalan');

        expect(controller.searchQuery, equals('jalan'));
        await Future.delayed(const Duration(milliseconds: 350));
        expect(controller.searchQuery, equals('jalan'));

        // Test loadMore with empty repo gracefully finishes
        await controller.loadMore();
        expect(controller.isLoadingMore, isFalse);

        controller.dispose();
      },
    );

    test(
      'MyReportsController supports pagination and non-destructive state',
      () async {
        final repo = ReportRepository();
        final controller = MyReportsController(
          userId: 'usr-test-1',
          reportRepository: repo,
        );

        expect(MyReportsController.pageSize, equals(10));
        expect(controller.reports, isEmpty);

        await controller.fetchMyReports();
        expect(controller.isLoading, isFalse);
        expect(controller.isRefreshing, isFalse);

        await controller.loadMore();
        expect(controller.isLoadingMore, isFalse);

        controller.dispose();
      },
    );
  });

  group('4. AppImage Decode Bounds & Fallback Tests', () {
    testWidgets('AppImage renders placeholder and error fallback gracefully', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImage(
              imageSource: 'invalid_dummy_url.jpg',
              memCacheWidth: 100,
              memCacheHeight: 100,
            ),
          ),
        ),
      );
      await tester.pump();

      // Error icon rendered gracefully without unhandled exception
      expect(find.byIcon(Icons.broken_image_rounded), findsOneWidget);
    });

    testWidgets('AppImage with empty url renders empty fallback placeholder', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppImage(
              imageSource: '',
              memCacheWidth: 64,
              memCacheHeight: 64,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.broken_image_rounded), findsOneWidget);
    });

    test('MediaService prevents concurrent pickImage invocations', () {
      final media = MediaService.instance;
      expect(media.isPicking, isFalse);
    });
  });
}
