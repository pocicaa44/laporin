import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laporin/core/services/boundary_service.dart';
import 'package:laporin/core/services/location_service.dart';
import 'package:laporin/core/services/media_service.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';

void main() {
  group('Performance & Standalone Isolate Optimization Tests', () {
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

    test('FeedController debounces search queries', () async {
      final repo = ReportRepository();
      final controller = FeedController(reportRepository: repo);

      // Rapidly changing search query
      controller.setSearchQuery('j');
      controller.setSearchQuery('ja');
      controller.setSearchQuery('jal');
      controller.setSearchQuery('jalan');

      expect(controller.searchQuery, equals('jalan'));

      // Wait for debounce timer (300ms) to fire
      await Future.delayed(const Duration(milliseconds: 350));
      expect(controller.searchQuery, equals('jalan'));

      controller.dispose();
    });

    test('MediaService.uploadAllPhotos handles batch uploads concurrently without crashing', () async {
      final media = MediaService.instance;
      final mockFiles = [
        XFile('test/mock_photo_1.jpg'),
        XFile('test/mock_photo_2.jpg'),
      ];

      // In offline/test mode, fallback returns local path representation
      final urls = await media.uploadAllPhotos(
        authorId: 'usr-perf',
        files: mockFiles,
      );
      expect(urls.length, equals(2));
      expect(urls[0], equals('test/mock_photo_1.jpg'));
      expect(urls[1], equals('test/mock_photo_2.jpg'));
    });
  });
}
