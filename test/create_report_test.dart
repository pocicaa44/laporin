import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:laporin/core/utils/app_validators.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/create_report/controllers/create_report_controller.dart';
import 'package:laporin/features/create_report/screens/create_report_screen.dart';
import 'package:provider/provider.dart';

void main() {
  group('CreateReportController Tests', () {
    late ReportRepository reportRepository;
    late CreateReportController controller;

    setUp(() {
      reportRepository = ReportRepository();
      controller = CreateReportController(reportRepository: reportRepository);
    });

    test('Initial controller state has expected defaults', () {
      expect(controller.category, equals('Jalan & Infrastruktur'));
      expect(controller.locationAddress, isEmpty);
      expect(controller.selectedPhotos, isEmpty);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);
    });

    test('Updating category updates controller state', () {
      controller.setCategory('Kebersihan');
      expect(controller.category, equals('Kebersihan'));
    });

    test('Updating location updates address, coordinates, and areaName', () {
      controller.setLocation(
        address: 'Jl. Pahlawan No. 1, Semarang',
        lat: -6.9932,
        lng: 110.4203,
        areaName: 'Jawa Tengah',
      );
      expect(
        controller.locationAddress,
        equals('Jl. Pahlawan No. 1, Semarang'),
      );
      expect(controller.latitude, equals(-6.9932));
      expect(controller.longitude, equals(110.4203));
      expect(controller.areaName, equals('Jawa Tengah'));
    });

    test(
      'addPhoto enforces max 5 photos limit and removePhoto removes item',
      () {
        for (int i = 0; i < 6; i++) {
          controller.addPhoto(XFile('path/to/photo_$i.jpg'));
        }
        expect(controller.selectedPhotos.length, equals(5));

        controller.removePhoto(0);
        expect(controller.selectedPhotos.length, equals(4));
      },
    );

    test(
      'submitReport without location returns null and sets error message',
      () async {
        final result = await controller.submitReport(
          authorId: 'usr-1',
          authorName: 'Budi Santoso',
          title: 'Jalan Rusak Parah',
          description:
              'Jalan berlubang cukup dalam dan membahayakan pengendara motor.',
        );

        expect(result, isNull);
        expect(controller.errorMessage, contains('lokasi kejadian'));
      },
    );

    test('submitReport with location outside Indonesia returns null and sets outsideIndonesia error', () async {
      controller.setLocation(
        address: 'Orchard Road, Singapore',
        lat: 1.3521,
        lng: 103.8198,
        areaName: 'Singapore',
      );

      final result = await controller.submitReport(
        authorId: 'usr-1',
        authorName: 'Budi Santoso',
        title: 'Lampu Jalan Mati',
        description: 'Lampu penerangan jalan padam sejak kemarin malam.',
      );

      expect(result, isNull);
      expect(controller.errorMessage, contains('Indonesia'));
    });

    test('submitReport with valid Indonesia location successfully creates ReportModel', () async {
      controller.setLocation(
        address: 'Jl. Pahlawan No. 1, Semarang',
        lat: -6.9932,
        lng: 110.4203,
        areaName: 'Jawa Tengah',
      );

      final result = await controller.submitReport(
        authorId: 'usr-1',
        authorName: 'Budi Santoso',
        title: 'Lampu Jalan Mati',
        description: 'Lampu penerangan jalan padam sejak kemarin malam.',
      );

      expect(result, isNotNull);
      expect(result!.title, equals('Lampu Jalan Mati'));
      expect(result.handlingStatus, equals(HandlingStatus.newReport));
      expect(result.publicationState, equals(PublicationState.published));
      expect(result.areaName, equals('Jawa Tengah'));
    });
  });

  group('Validation Tests for Create Report', () {
    test('AppValidators.validateTitle enforces length rules', () {
      expect(AppValidators.validateTitle(''), isNotNull);
      expect(AppValidators.validateTitle('abc'), isNotNull); // < 5 chars
      expect(AppValidators.validateTitle('Jalan Rusak'), isNull); // Valid
      expect(AppValidators.validateTitle('a' * 101), isNotNull); // > 100 chars
    });

    test('AppValidators.validateDescription enforces min 10 chars', () {
      expect(AppValidators.validateDescription(''), isNotNull);
      expect(
        AppValidators.validateDescription('rusak'),
        isNotNull,
      ); // < 10 chars
      expect(
        AppValidators.validateDescription('Jalanan berlubang cukup dalam'),
        isNull,
      ); // >= 10 chars
    });
  });

  group('CreateReportScreen Widget Tests', () {
    testWidgets('Renders all required form fields and labels', (tester) async {
      final authRepo = AuthRepository();
      final reportRepo = ReportRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AuthController(authRepository: authRepo),
            ),
            Provider<ReportRepository>.value(value: reportRepo),
          ],
          child: const MaterialApp(home: CreateReportScreen()),
        ),
      );

      expect(find.text('Buat Laporan Baru'), findsOneWidget);
      expect(find.text('Judul Laporan *'), findsOneWidget);
      expect(find.text('Kategori Masalah *'), findsOneWidget);
      expect(find.text('Titik Lokasi Kejadian *'), findsOneWidget);
      expect(find.text('Deskripsi Masalah *'), findsOneWidget);
      expect(find.text('Foto Bukti Masalah (Maks. 5)'), findsOneWidget);
      expect(find.text('Kirim Laporan'), findsOneWidget);
    });

    testWidgets('Triggers validation errors when submitting empty form', (
      tester,
    ) async {
      final authRepo = AuthRepository();
      final reportRepo = ReportRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => AuthController(authRepository: authRepo),
            ),
            Provider<ReportRepository>.value(value: reportRepo),
          ],
          child: const MaterialApp(home: CreateReportScreen()),
        ),
      );

      final submitBtn = find.text('Kirim Laporan');
      await tester.ensureVisible(submitBtn);
      await tester.tap(submitBtn);
      await tester.pumpAndSettle();

      expect(find.text('Judul laporan wajib diisi.'), findsOneWidget);
      expect(find.text('Deskripsi laporan wajib diisi.'), findsOneWidget);
    });
  });
}
