import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'ReportDetailScreen renders successfully with initialReport and photos without crashing',
    (tester) async {
      final testReport = ReportModel(
        id: 'rep-test-1',
        reportNumber: 'LPR-2026-0001',
        authorId: 'user-1',
        authorName: 'Budi Santoso',
        areaId: 'area-jateng',
        areaName: 'Kota Semarang',
        title: 'Jalan Rusak dan Berlubang di Simpang Lima',
        description: 'Lubang cukup dalam di badan jalan lajur kiri membahayakan pengendara motor.',
        category: 'Infrastruktur',
        latitude: -6.9924,
        longitude: 110.4225,
        locationAddress: 'Jl. Simpang Lima, Semarang',
        handlingStatus: HandlingStatus.newReport,
        publicationState: PublicationState.published,
        createdAt: DateTime(2026, 10, 22, 10, 0),
        updatedAt: DateTime(2026, 10, 22, 10, 0),
        photoUrls: [
          '/data/user/0/com.dewanto.laporin/cache/image_picker_1.jpg',
        ],
      );

      final authRepository = AuthRepository();
      final reportRepository = ReportRepository();
      final commentRepository = CommentRepository();

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: authRepository),
            Provider.value(value: reportRepository),
            Provider.value(value: commentRepository),
            ChangeNotifierProvider(
              create: (_) => AuthController(authRepository: authRepository),
            ),
          ],
          child: MaterialApp(
            home: ReportDetailScreen(
              reportId: testReport.id,
              initialReport: testReport,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('LPR-2026-0001'), findsOneWidget);
      expect(
        find.text('Jalan Rusak dan Berlubang di Simpang Lima'),
        findsOneWidget,
      );
      expect(find.text('Jl. Simpang Lima, Semarang'), findsOneWidget);
      expect(find.text('Infrastruktur'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Deskripsi Masalah'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Deskripsi Masalah'), findsOneWidget);
      expect(find.byType(ReportDetailScreen), findsOneWidget);
    },
  );
}
