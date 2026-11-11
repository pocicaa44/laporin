import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:laporin/core/config/indonesia_regions.dart';
import 'package:laporin/core/config/map_config.dart';
import 'package:laporin/core/services/location_service.dart';
import 'package:laporin/core/widgets/laporin_map_view.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/feed/controllers/feed_controller.dart';
import 'package:laporin/features/feed/screens/feed_map_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyReportLatest = ReportModel(
    id: 'rep-latest',
    reportNumber: 'LPR-2026-0999',
    authorId: 'user-aceh',
    authorName: 'Teuku Umar',
    areaId: 'b0000000-0000-0000-0000-000000000011',
    areaName: 'Banda Aceh',
    title: 'Laporan Terbaru di Banda Aceh',
    description: 'Deskripsi laporan di ujung barat Indonesia.',
    category: 'Jalan & Infrastruktur',
    latitude: 5.5500,
    longitude: 95.3200,
    locationAddress: 'Jl. Cut Nyak Dien, Banda Aceh',
    handlingStatus: HandlingStatus.newReport,
    publicationState: PublicationState.published,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final dummyReportUserCity = ReportModel(
    id: 'rep-jakarta',
    reportNumber: 'LPR-2026-0001',
    authorId: 'user-jkt',
    authorName: 'Siti Rahma',
    areaId: 'b0000000-0000-0000-0000-000000000031',
    areaName: 'Jakarta Pusat',
    title: 'Laporan Dekat Pengguna',
    description: 'Deskripsi laporan di Jakarta.',
    category: 'Kebersihan & Sampah',
    latitude: -6.2088,
    longitude: 106.8456,
    locationAddress: 'Jl. Merdeka Barat, Jakarta',
    handlingStatus: HandlingStatus.newReport,
    publicationState: PublicationState.published,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
  );

  group('Peta Sebaran Laporan (FeedMapScreen) Centering & User Location Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
      LocationService.mockPositionForTesting = null;
      LocationService.instance.setLastFetchedPositionForTesting(null);
    });

    tearDown(() {
      LocationService.mockPositionForTesting = null;
      LocationService.instance.setLastFetchedPositionForTesting(null);
    });

    test('LocationService remembers lastFetchedPosition and exposes lastKnownLatLng', () {
      expect(LocationService.instance.lastKnownLatLng, isNull);

      final mockPos = Position(
        latitude: -6.2088,
        longitude: 106.8456,
        timestamp: DateTime.now(),
        accuracy: 5.0,
        altitude: 10.0,
        altitudeAccuracy: 1.0,
        heading: 0.0,
        headingAccuracy: 1.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      LocationService.mockPositionForTesting = mockPos;
      expect(LocationService.instance.lastKnownLatLng, equals(const LatLng(-6.2088, 106.8456)));

      LocationService.mockPositionForTesting = null;
      LocationService.instance.setLastFetchedPositionForTesting(mockPos);
      expect(LocationService.instance.lastKnownLatLng, equals(const LatLng(-6.2088, 106.8456)));
    });

    test('FeedController stores userLocation when autoDetectLocation succeeds', () async {
      final repo = ReportRepository();
      final controller = FeedController(reportRepository: repo, autoDetectGps: false);

      expect(controller.userLocation, isNull);

      controller.setUserLocationForTesting(const LatLng(-6.9932, 110.4203));
      expect(controller.userLocation, equals(const LatLng(-6.9932, 110.4203)));

      controller.dispose();
    });

    testWidgets(
      'FeedMapScreen DOES NOT center on the latest created report when initialUserLocation is provided',
      (tester) async {
        const userLoc = LatLng(-6.2088, 106.8456); // Jakarta
        final reports = [dummyReportLatest, dummyReportUserCity];

        await tester.pumpWidget(
          MaterialApp(
            home: Provider<ReportRepository>(
              create: (_) => ReportRepository(),
              child: FeedMapScreen(
                initialReports: reports,
                initialUserLocation: userLoc,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final mapFinder = find.byType(LaporinMapView);
        expect(mapFinder, findsOneWidget);

        final laporinMap = tester.widget<LaporinMapView>(mapFinder);

        // Center must be the user location, NOT the latest report in Aceh (5.5500, 95.3200)
        expect(laporinMap.initialCenter, equals(userLoc));
        expect(laporinMap.initialCenter.latitude, isNot(equals(dummyReportLatest.latitude)));
        expect(laporinMap.initialCenter.longitude, isNot(equals(dummyReportLatest.longitude)));
        expect(laporinMap.initialZoom, equals(13.0));
      },
    );

    testWidgets(
      'FeedMapScreen falls back to province center when initialUserLocation is null but province is set',
      (tester) async {
        final reports = [dummyReportLatest];
        final jateng = IndonesiaRegions.findByName('Jawa Tengah')!;

        await tester.pumpWidget(
          MaterialApp(
            home: Provider<ReportRepository>(
              create: (_) => ReportRepository(),
              child: FeedMapScreen(
                initialReports: reports,
                initialProvinceId: jateng.id,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final mapFinder = find.byType(LaporinMapView);
        expect(mapFinder, findsOneWidget);

        final laporinMap = tester.widget<LaporinMapView>(mapFinder);

        // Map must center on province center, NOT on Aceh report
        expect(laporinMap.initialCenter.latitude, equals(jateng.centerLat));
        expect(laporinMap.initialCenter.longitude, equals(jateng.centerLng));
        expect(laporinMap.initialCenter.latitude, isNot(equals(dummyReportLatest.latitude)));
        expect(laporinMap.initialZoom, equals(MapConfig.provinceOverviewZoom));
      },
    );

    testWidgets(
      'FeedMapScreen falls back to Indonesia center when no user location or province is available, never latest report',
      (tester) async {
        final reports = [dummyReportLatest];

        await tester.pumpWidget(
          MaterialApp(
            home: Provider<ReportRepository>(
              create: (_) => ReportRepository(),
              child: FeedMapScreen(
                initialReports: reports,
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));

        final mapFinder = find.byType(LaporinMapView);
        expect(mapFinder, findsOneWidget);

        final laporinMap = tester.widget<LaporinMapView>(mapFinder);

        // Map must center on Indonesia center, NOT on latest report
        expect(laporinMap.initialCenter, equals(MapConfig.indonesiaCenter));
        expect(laporinMap.initialCenter.latitude, isNot(equals(dummyReportLatest.latitude)));
        expect(laporinMap.initialZoom, equals(MapConfig.nationalOverviewZoom));
      },
    );

    testWidgets(
      'FeedMapScreen GPS Floating Action Button triggers relocation to user location',
      (tester) async {
        const userLoc = LatLng(-7.2575, 112.7521); // Surabaya

        await tester.pumpWidget(
          MaterialApp(
            home: Provider<ReportRepository>(
              create: (_) => ReportRepository(),
              child: FeedMapScreen(
                initialReports: [dummyReportLatest],
                initialUserLocation: userLoc,
              ),
            ),
          ),
        );
        await tester.pump();

        final fabFinder = find.byWidgetPredicate(
          (w) => w is FloatingActionButton && w.heroTag == 'btn-feed-map-gps',
        );
        expect(fabFinder, findsOneWidget);

        await tester.tap(fabFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
      },
    );
  });
}
