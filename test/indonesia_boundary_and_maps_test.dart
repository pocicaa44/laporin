import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/config/indonesia_regions.dart';
import 'package:laporin/core/config/map_config.dart';
import 'package:laporin/core/services/boundary_service.dart';
import 'package:laporin/core/services/network_service.dart';
import 'package:laporin/core/widgets/laporin_map_view.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/create_report/screens/map_location_picker_screen.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/feed/screens/feed_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Indonesia Nationwide Boundary Verification (NKRI)', () {
    final boundaryService = BoundaryService.instance;

    group('Positive Cases: Major Cities & Regions Across Indonesia', () {
      test('Banda Aceh, Aceh', () {
        expect(boundaryService.isInsideIndonesia(5.55, 95.32), isTrue);
      });

      test('Medan, Sumatera Utara', () {
        expect(boundaryService.isInsideIndonesia(3.5952, 98.6722), isTrue);
      });

      test('Padang, Sumatera Barat', () {
        expect(boundaryService.isInsideIndonesia(-0.95, 100.35), isTrue);
      });

      test('Palembang, Sumatera Selatan', () {
        expect(boundaryService.isInsideIndonesia(-2.99, 104.75), isTrue);
      });

      test('Batam, Kepulauan Riau', () {
        expect(boundaryService.isInsideIndonesia(1.12, 104.03), isTrue);
      });

      test('DKI Jakarta (Monas)', () {
        expect(boundaryService.isInsideIndonesia(-6.2088, 106.8456), isTrue);
      });

      test('Bandung, Jawa Barat', () {
        expect(boundaryService.isInsideIndonesia(-6.9175, 107.6191), isTrue);
      });

      test('Semarang, Jawa Tengah', () {
        expect(boundaryService.isInsideIndonesia(-6.9932, 110.4203), isTrue);
      });

      test('Surabaya, Jawa Timur', () {
        expect(boundaryService.isInsideIndonesia(-7.2575, 112.7521), isTrue);
      });

      test('Denpasar, Bali', () {
        expect(boundaryService.isInsideIndonesia(-8.6705, 115.2126), isTrue);
      });

      test('Mataram, Nusa Tenggara Barat', () {
        expect(boundaryService.isInsideIndonesia(-8.5833, 116.1167), isTrue);
      });

      test('Kupang, Nusa Tenggara Timur (West Timor)', () {
        expect(boundaryService.isInsideIndonesia(-10.1772, 123.6070), isTrue);
      });

      test('Pontianak, Kalimantan Barat', () {
        expect(boundaryService.isInsideIndonesia(-0.0263, 109.3425), isTrue);
      });

      test('Banjarmasin, Kalimantan Selatan', () {
        expect(boundaryService.isInsideIndonesia(-3.3194, 114.5908), isTrue);
      });

      test('Balikpapan, Kalimantan Timur', () {
        expect(boundaryService.isInsideIndonesia(-1.2654, 116.8312), isTrue);
      });

      test('Tarakan, Kalimantan Utara', () {
        expect(boundaryService.isInsideIndonesia(3.3270, 117.5956), isTrue);
      });

      test('Makassar, Sulawesi Selatan', () {
        expect(boundaryService.isInsideIndonesia(-5.1477, 119.4327), isTrue);
      });

      test('Manado, Sulawesi Utara', () {
        expect(boundaryService.isInsideIndonesia(1.4748, 124.8428), isTrue);
      });

      test('Ambon, Maluku', () {
        expect(boundaryService.isInsideIndonesia(-3.6954, 128.1814), isTrue);
      });

      test('Ternate, Maluku Utara', () {
        expect(boundaryService.isInsideIndonesia(0.7893, 127.3610), isTrue);
      });

      test('Jayapura, Papua', () {
        expect(boundaryService.isInsideIndonesia(-2.5337, 140.7181), isTrue);
      });

      test('Merauke, Papua Selatan', () {
        expect(boundaryService.isInsideIndonesia(-8.4991, 140.4011), isTrue);
      });

      test('Sorong, Papua Barat Daya', () {
        expect(boundaryService.isInsideIndonesia(-0.8762, 131.2562), isTrue);
      });
    });

    group('Negative Cases: International & Non-Indonesian Locations', () {
      test('Singapore must be rejected', () {
        expect(boundaryService.isInsideIndonesia(1.3521, 103.8198), isFalse);
      });

      test('Kuala Lumpur, Malaysia must be rejected', () {
        expect(boundaryService.isInsideIndonesia(3.1390, 101.6869), isFalse);
      });

      test('Kuching, Sarawak must be rejected', () {
        expect(boundaryService.isInsideIndonesia(1.5533, 110.3592), isFalse);
      });

      test('Kota Kinabalu, Sabah must be rejected', () {
        expect(boundaryService.isInsideIndonesia(5.9804, 116.0735), isFalse);
      });

      test('Bandar Seri Begawan, Brunei must be rejected', () {
        expect(boundaryService.isInsideIndonesia(4.9031, 114.9398), isFalse);
      });

      test('Dili, Timor-Leste must be rejected', () {
        expect(boundaryService.isInsideIndonesia(-8.5569, 125.5783), isFalse);
      });

      test('Port Moresby, Papua New Guinea must be rejected', () {
        expect(boundaryService.isInsideIndonesia(-9.4438, 147.1803), isFalse);
      });

      test('Tokyo, Japan must be rejected', () {
        expect(boundaryService.isInsideIndonesia(35.6762, 139.6503), isFalse);
      });

      test('Sydney, Australia must be rejected', () {
        expect(boundaryService.isInsideIndonesia(-33.8688, 151.2093), isFalse);
      });

      test('Null Island (0.0, 0.0) must be rejected', () {
        expect(boundaryService.isInsideIndonesia(0.0, 0.0), isFalse);
      });

      test('NaN coordinates must fail-closed', () {
        expect(boundaryService.isInsideIndonesia(double.nan, 110.0), isFalse);
        expect(boundaryService.isInsideIndonesia(-7.0, double.nan), isFalse);
      });

      test('Infinite coordinates must fail-closed', () {
        expect(
          boundaryService.isInsideIndonesia(double.infinity, 110.0),
          isFalse,
        );
        expect(
          boundaryService.isInsideIndonesia(-7.0, double.negativeInfinity),
          isFalse,
        );
      });
    });

    test('Standard error message is exact and actionable', () {
      expect(
        BoundaryService.outsideIndonesiaErrorMessage,
        equals('Lokasi laporan hanya tersedia di wilayah Indonesia.'),
      );
    });
  });

  group('2. OpenStreetMap & Tile Configuration Verification', () {
    test('MapConfig adheres to OSM tile usage policy', () {
      expect(
        MapConfig.osmTileUrl,
        equals('https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
      );
      expect(MapConfig.osmAttribution, contains('OpenStreetMap contributors'));
      expect(MapConfig.userAgentPackageName, equals('id.laporin.app'));
    });

    test('IndonesiaRegions contains all 38 provinces', () {
      expect(IndonesiaRegions.provinces.length, equals(38));
      final jateng = IndonesiaRegions.findByCode('33');
      expect(jateng, isNotNull);
      expect(jateng!.name, equals('Jawa Tengah'));

      final dki = IndonesiaRegions.findByCode('31');
      expect(dki, isNotNull);
      expect(dki!.name, equals('DKI Jakarta'));

      final papua = IndonesiaRegions.findByCode('91');
      expect(papua, isNotNull);
      expect(papua!.name, equals('Papua'));
    });
  });

  group('3. Dual Feed Architecture & Controller State', () {
    late ReportRepository repo;
    late FeedController controller;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      repo = ReportRepository();
      controller = FeedController(reportRepository: repo);
    });

    tearDown(() {
      controller.dispose();
    });

    test('Initial feed starts in National scope by default', () {
      expect(controller.isNational, isTrue);
      expect(controller.scope, equals(FeedScope.national));
      expect(controller.selectedProvinceId, isNull);
    });

    test(
      'Switching to Provincial scope updates state and clears previous feed',
      () {
        controller.setProvincialScope(
          'b0000000-0000-0000-0000-000000000033',
          'Jawa Tengah',
        );

        expect(controller.isNational, isFalse);
        expect(controller.scope, equals(FeedScope.provincial));
        expect(
          controller.selectedProvinceId,
          equals('b0000000-0000-0000-0000-000000000033'),
        );
        expect(controller.selectedProvinceName, equals('Jawa Tengah'));
      },
    );

    test('Switching back to National scope resets province', () {
      controller.setProvincialScope(
        'b0000000-0000-0000-0000-000000000031',
        'DKI Jakarta',
      );
      expect(controller.isNational, isFalse);

      controller.setNationalScope();
      expect(controller.isNational, isTrue);
      expect(controller.selectedProvinceId, isNull);
    });

    test('switchToAll() switches scope to National', () {
      controller.setProvincialScope(
        'b0000000-0000-0000-0000-000000000031',
        'DKI Jakarta',
      );
      expect(controller.isNational, isFalse);

      controller.switchToAll();
      expect(controller.isNational, isTrue);
      expect(controller.selectedProvinceId, isNull);
    });

    test('switchToDetectedProvince() switches scope to detected province', () {
      controller.setDetectedProvinceForTesting(
        'b0000000-0000-0000-0000-000000000033',
        'Jawa Tengah',
      );
      expect(controller.hasDetectedProvince, isTrue);
      expect(controller.detectedProvinceName, equals('Jawa Tengah'));
      expect(controller.isDetectedProvinceActive, isFalse);

      controller.switchToDetectedProvince();
      expect(controller.isNational, isFalse);
      expect(
        controller.selectedProvinceId,
        equals('b0000000-0000-0000-0000-000000000033'),
      );
      expect(controller.selectedProvinceName, equals('Jawa Tengah'));
      expect(controller.isDetectedProvinceActive, isTrue);

      controller.switchToAll();
      expect(controller.isNational, isTrue);
      expect(controller.isDetectedProvinceActive, isFalse);
    });

    test(
      'Loads cached detected location from SharedPreferences on init',
      () async {
        SharedPreferences.setMockInitialValues({
          'detected_province_id': 'b0000000-0000-0000-0000-000000000051',
          'detected_province_name': 'Bali',
        });
        final newController = FeedController(
          reportRepository: repo,
          autoDetectGps: false,
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(newController.hasDetectedProvince, isTrue);
        expect(
          newController.detectedProvinceId,
          equals('b0000000-0000-0000-0000-000000000051'),
        );
        expect(newController.detectedProvinceName, equals('Bali'));
        newController.dispose();
      },
    );

    test('switchToAll() switches scope to National', () {
      controller.setProvincialScope(
        'b0000000-0000-0000-0000-000000000031',
        'DKI Jakarta',
      );
      expect(controller.isNational, isFalse);

      controller.switchToAll();
      expect(controller.isNational, isTrue);
      expect(controller.selectedProvinceId, isNull);
    });

    test('switchToDetectedProvince() switches scope to detected province', () {
      controller.setDetectedProvinceForTesting(
        'b0000000-0000-0000-0000-000000000033',
        'Jawa Tengah',
      );
      expect(controller.hasDetectedProvince, isTrue);
      expect(controller.detectedProvinceName, equals('Jawa Tengah'));
      expect(controller.isDetectedProvinceActive, isFalse);

      controller.switchToDetectedProvince();
      expect(controller.isNational, isFalse);
      expect(
        controller.selectedProvinceId,
        equals('b0000000-0000-0000-0000-000000000033'),
      );
      expect(controller.selectedProvinceName, equals('Jawa Tengah'));
      expect(controller.isDetectedProvinceActive, isTrue);

      controller.switchToAll();
      expect(controller.isNational, isTrue);
      expect(controller.isDetectedProvinceActive, isFalse);
    });

    test(
      'Loads cached detected location from SharedPreferences on init',
      () async {
        SharedPreferences.setMockInitialValues({
          'detected_province_id': 'b0000000-0000-0000-0000-000000000051',
          'detected_province_name': 'Bali',
        });
        final newController = FeedController(
          reportRepository: repo,
          autoDetectGps: false,
        );
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(newController.hasDetectedProvince, isTrue);
        expect(
          newController.detectedProvinceId,
          equals('b0000000-0000-0000-0000-000000000051'),
        );
        expect(newController.detectedProvinceName, equals('Bali'));
        newController.dispose();
      },
    );
  });

  group(
    '4. FeedScreen Scope Selector Menu ("Semua" vs "{Provinsi Terdeteksi}")',
    () {
      late AuthRepository authRepo;
      late AuthController authController;
      late NetworkService networkService;
      late ReportRepository reportRepo;
      late FeedController feedController;

      setUp(() {
        SharedPreferences.setMockInitialValues({});
        authRepo = AuthRepository();
        authRepo.setCurrentUserProfileForTesting(
          const UserProfileModel(
            id: 'user-1',
            email: 'warga@laporin.id',
            fullName: 'Warga Indonesia',
            username: 'warga_id',
            role: UserRole.user,
          ),
        );
        authController = AuthController(authRepository: authRepo);
        networkService = NetworkService();
        reportRepo = ReportRepository();
        feedController = FeedController(
          reportRepository: reportRepo,
          autoDetectGps: false,
        );
      });

      tearDown(() {
        feedController.dispose();
      });

      testWidgets(
        'Renders only "Semua" and detected province in scope menu, with no 38 provinces picker',
        (tester) async {
          feedController.setDetectedProvinceForTesting(
            'b0000000-0000-0000-0000-000000000033',
            'Jawa Tengah',
          );

          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<NetworkService>.value(
                  value: networkService,
                ),
                Provider<AuthRepository>.value(value: authRepo),
                ChangeNotifierProvider<AuthController>.value(
                  value: authController,
                ),
                Provider<ReportRepository>.value(value: reportRepo),
                ChangeNotifierProvider<FeedController>.value(
                  value: feedController,
                ),
              ],
              child: const MaterialApp(home: FeedScreen()),
            ),
          );
          await tester.pumpAndSettle();

          // Verify "Semua" and "Jawa Tengah" are displayed
          expect(find.text('Semua'), findsWidgets);
          expect(find.text('Jawa Tengah'), findsOneWidget);

          // Verify 38-province picker ("Lainnya") is completely removed
          expect(find.text('Lainnya'), findsNothing);

          // Tap on "Jawa Tengah" to switch scope to detected province
          await tester.tap(find.text('Jawa Tengah'));
          await tester.pumpAndSettle();

          expect(feedController.isNational, isFalse);
          expect(feedController.selectedProvinceName, equals('Jawa Tengah'));
          expect(feedController.isDetectedProvinceActive, isTrue);

          // Tap on "Semua" in the Scope Selector Bar to switch back to national
          final semuaFinder = find.widgetWithText(InkWell, 'Semua');
          await tester.tap(semuaFinder.first);
          await tester.pumpAndSettle();

          expect(feedController.isNational, isTrue);
          expect(feedController.selectedProvinceId, isNull);
        },
      );
    },
  );

  group('5. Static Upright Marker Verification When Map Rotates', () {
    testWidgets(
      'MapLocationPickerScreen configures MarkerLayer and Marker with rotate: true and topCenter alignment',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: MapLocationPickerScreen(
              initialLat: -6.9932,
              initialLng: 110.4203,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        final markerLayerFinder = find.byType(MarkerLayer);
        expect(markerLayerFinder, findsOneWidget);

        final markerLayer = tester.widget<MarkerLayer>(markerLayerFinder);
        expect(markerLayer.rotate, isTrue);
        expect(markerLayer.alignment, equals(Alignment.topCenter));
        expect(markerLayer.markers.length, equals(1));

        final marker = markerLayer.markers.first;
        expect(marker.rotate, isTrue);
        expect(marker.alignment, equals(Alignment.topCenter));
        expect(marker.point.latitude, equals(-6.9932));
        expect(marker.point.longitude, equals(110.4203));
      },
    );

    testWidgets(
      'LaporinMapView defaults MarkerLayer to rotate: true and topCenter alignment',
      (tester) async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(
              body: LaporinMapView(
                initialCenter: LatLng(-6.2, 106.8),
                markers: [
                  Marker(
                    point: LatLng(-6.2, 106.8),
                    child: Icon(Icons.location_on),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final markerLayerFinder = find.byType(MarkerLayer);
        expect(markerLayerFinder, findsOneWidget);

        final markerLayer = tester.widget<MarkerLayer>(markerLayerFinder);
        expect(markerLayer.rotate, isTrue);
        expect(markerLayer.alignment, equals(Alignment.topCenter));
      },
    );
  });
}
