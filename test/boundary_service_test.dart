import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/services/boundary_service.dart';

void main() {
  group('BoundaryService — Central Java Boundary Verification', () {
    final boundaryService = BoundaryService.instance;

    group('Positive Cases: Locations inside Provinsi Jawa Tengah', () {
      test('Semarang (Ibu Kota Jawa Tengah)', () {
        expect(boundaryService.isInsideCentralJava(-6.9932, 110.4203), isTrue);
      });

      test('Surakarta / Solo', () {
        expect(boundaryService.isInsideCentralJava(-7.5755, 110.8243), isTrue);
      });

      test('Magelang', () {
        expect(boundaryService.isInsideCentralJava(-7.4706, 110.2178), isTrue);
      });

      test('Purwokerto (Banyumas)', () {
        expect(boundaryService.isInsideCentralJava(-7.4243, 109.2303), isTrue);
      });

      test('Cilacap', () {
        expect(boundaryService.isInsideCentralJava(-7.7279, 109.0059), isTrue);
      });

      test('Tegal', () {
        expect(boundaryService.isInsideCentralJava(-6.8694, 109.1402), isTrue);
      });

      test('Kudus', () {
        expect(boundaryService.isInsideCentralJava(-6.8048, 110.8405), isTrue);
      });

      test('Rembang', () {
        expect(boundaryService.isInsideCentralJava(-6.7063, 111.3385), isTrue);
      });

      test('Kepulauan Karimunjawa (Jepara)', () {
        expect(boundaryService.isInsideCentralJava(-5.8450, 110.4350), isTrue);
      });

      test('Nusakambangan (Cilacap)', () {
        expect(boundaryService.isInsideCentralJava(-7.7100, 108.8500), isTrue);
      });
    });

    group('Negative Cases: Neighboring enclaves and other provinces', () {
      test('Daerah Istimewa Yogyakarta (Yogyakarta City) must be rejected', () {
        // Enclave test: surrounded by Central Java but administratively DIY
        expect(boundaryService.isInsideCentralJava(-7.7956, 110.3695), isFalse);
      });

      test('Sleman (DIY) must be rejected', () {
        expect(boundaryService.isInsideCentralJava(-7.7156, 110.3556), isFalse);
      });

      test('Bantul (DIY) must be rejected', () {
        expect(boundaryService.isInsideCentralJava(-7.8938, 110.3306), isFalse);
      });

      test('Cirebon (Jawa Barat) must be rejected', () {
        expect(boundaryService.isInsideCentralJava(-6.7320, 108.5523), isFalse);
      });

      test('Bandung (Jawa Barat) must be rejected', () {
        expect(boundaryService.isInsideCentralJava(-6.9175, 107.6191), isFalse);
      });

      test('Surabaya (Jawa Timur) must be rejected', () {
        expect(boundaryService.isInsideCentralJava(-7.2575, 112.7521), isFalse);
      });

      test('Ngawi (Jawa Timur) must be rejected', () {
        expect(boundaryService.isInsideCentralJava(-7.4038, 111.4449), isFalse);
      });

      test('DKI Jakarta must be rejected', () {
        expect(boundaryService.isInsideCentralJava(-6.2088, 106.8456), isFalse);
      });

      test('Denpasar (Bali) must be rejected', () {
        expect(boundaryService.isInsideCentralJava(-8.6705, 115.2126), isFalse);
      });

      test('Tokyo (International) must be rejected', () {
        expect(boundaryService.isInsideCentralJava(35.6762, 139.6503), isFalse);
      });
    });

    group('Edge Cases and Fail-Closed Robustness', () {
      test('NaN latitude or longitude returns false', () {
        expect(
          boundaryService.isInsideCentralJava(double.nan, 110.4203),
          isFalse,
        );
        expect(
          boundaryService.isInsideCentralJava(-6.9932, double.nan),
          isFalse,
        );
        expect(
          boundaryService.isInsideCentralJava(double.nan, double.nan),
          isFalse,
        );
      });

      test('Infinite latitude or longitude returns false', () {
        expect(
          boundaryService.isInsideCentralJava(double.infinity, 110.4203),
          isFalse,
        );
        expect(
          boundaryService.isInsideCentralJava(-6.9932, double.negativeInfinity),
          isFalse,
        );
      });

      test('Out of geographic range latitude or longitude returns false', () {
        expect(boundaryService.isInsideCentralJava(95.0, 110.4203), isFalse);
        expect(boundaryService.isInsideCentralJava(-95.0, 110.4203), isFalse);
        expect(boundaryService.isInsideCentralJava(-6.9932, 190.0), isFalse);
        expect(boundaryService.isInsideCentralJava(-6.9932, -190.0), isFalse);
      });

      test('Default constants represent Central Java correctly', () {
        expect(BoundaryService.provinceName, equals('Jawa Tengah'));
        expect(BoundaryService.defaultLat, equals(-6.9932));
        expect(BoundaryService.defaultLng, equals(110.4203));
        expect(
          boundaryService.isInsideCentralJava(
            BoundaryService.defaultLat,
            BoundaryService.defaultLng,
          ),
          isTrue,
        );
        expect(
          BoundaryService.outsideAreaErrorMessage,
          contains('Jawa Tengah'),
        );
        expect(BoundaryService.gpsOutsideAreaMessage, contains('Jawa Tengah'));
      });
    });
  });
}
