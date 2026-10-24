import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';
import 'package:laporin/features/report_detail/widgets/photo_viewer_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  group('PhotoViewerDialog Unit & Widget Tests', () {
    testWidgets(
      'renders PhotoViewerDialog with PageView, counter, and InteractiveViewer',
      (tester) async {
        final photos = [
          'https://example.com/photo1.jpg',
          'https://example.com/photo2.jpg',
          'https://example.com/photo3.jpg',
        ];

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      PhotoViewerDialog.show(
                        context: context,
                        photoUrls: photos,
                        initialIndex: 0,
                        title: 'Foto Laporan',
                      );
                    },
                    child: const Text('Open Viewer'),
                  );
                },
              ),
            ),
          ),
        );

        // Open dialog
        await tester.tap(find.text('Open Viewer'));
        await tester.pumpAndSettle();

        // Check dialog content
        expect(find.byType(PhotoViewerDialog), findsOneWidget);
        expect(find.text('Foto Laporan'), findsOneWidget);
        expect(find.text('1 / 3'), findsOneWidget);
        expect(find.byType(PageView), findsOneWidget);
        expect(find.byType(InteractiveViewer), findsOneWidget);

        // Verify zoom hint
        expect(
          find.text('Cubit untuk zoom • Geser untuk foto lainnya'),
          findsOneWidget,
        );

        // Close button
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      },
    );

    testWidgets('navigates next and previous via chevron buttons and swipe', (
      tester,
    ) async {
      final photos = [
        'https://example.com/photo1.jpg',
        'https://example.com/photo2.jpg',
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    PhotoViewerDialog.show(
                      context: context,
                      photoUrls: photos,
                      initialIndex: 0,
                    );
                  },
                  child: const Text('Open Viewer'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Viewer'));
      await tester.pumpAndSettle();

      expect(find.text('1 / 2'), findsOneWidget);

      // Tap next arrow button
      final nextButton = find.byIcon(Icons.chevron_right_rounded);
      expect(nextButton, findsOneWidget);
      await tester.tap(nextButton);
      await tester.pumpAndSettle();

      // Counter should now be 2 / 2
      expect(find.text('2 / 2'), findsOneWidget);

      // Tap prev arrow button
      final prevButton = find.byIcon(Icons.chevron_left_rounded);
      expect(prevButton, findsOneWidget);
      await tester.tap(prevButton);
      await tester.pumpAndSettle();

      // Counter should now be 1 / 2
      expect(find.text('1 / 2'), findsOneWidget);
    });

    testWidgets('double tap zooms in and double tap again resets zoom', (
      tester,
    ) async {
      final photos = ['https://example.com/photo1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    PhotoViewerDialog.show(
                      context: context,
                      photoUrls: photos,
                      initialIndex: 0,
                    );
                  },
                  child: const Text('Open Viewer'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Viewer'));
      await tester.pumpAndSettle();

      final interactiveViewerFinder = find.byType(InteractiveViewer);
      expect(interactiveViewerFinder, findsOneWidget);

      InteractiveViewer viewer = tester.widget(interactiveViewerFinder);
      expect(
        viewer.transformationController?.value,
        equals(Matrix4.identity()),
      );

      // Double tap center
      await tester.tap(interactiveViewerFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(interactiveViewerFinder);
      await tester.pumpAndSettle();

      viewer = tester.widget(interactiveViewerFinder);
      // After double tap, matrix should not be identity (zoomed in to 2.5x)
      expect(
        viewer.transformationController?.value,
        isNot(equals(Matrix4.identity())),
      );

      // Double tap again to reset
      await tester.tap(interactiveViewerFinder);
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(interactiveViewerFinder);
      await tester.pumpAndSettle();

      viewer = tester.widget(interactiveViewerFinder);
      expect(
        viewer.transformationController?.value,
        equals(Matrix4.identity()),
      );
    });

    testWidgets('close button dismisses PhotoViewerDialog', (tester) async {
      final photos = ['https://example.com/photo1.jpg'];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    PhotoViewerDialog.show(
                      context: context,
                      photoUrls: photos,
                      initialIndex: 0,
                    );
                  },
                  child: const Text('Open Viewer'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Viewer'));
      await tester.pumpAndSettle();
      expect(find.byType(PhotoViewerDialog), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoViewerDialog), findsNothing);
    });

    testWidgets(
      'opens PhotoViewerDialog when tapping image gallery in ReportDetailScreen',
      (tester) async {
        final testReport = ReportModel(
          id: 'rep-img-test',
          reportNumber: 'LPR-2026-0077',
          authorId: 'usr-1',
          authorName: 'Budi',
          areaId: 'area-jateng',
          areaName: 'Kota Semarang',
          title: 'Tumpukan Sampah',
          description: 'Sampah menumpuk di pinggir jalan',
          category: 'Kebersihan',
          latitude: -6.99,
          longitude: 110.42,
          locationAddress: 'Jl. Pahlawan',
          handlingStatus: HandlingStatus.newReport,
          publicationState: PublicationState.published,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          photoUrls: [
            'https://example.com/trash1.jpg',
            'https://example.com/trash2.jpg',
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

        // Find the gallery subtitle text and zoom icon
        expect(
          find.text('2 foto lampiran (ketuk untuk perbesar & geser)'),
          findsOneWidget,
        );
        final zoomIcon = find.byIcon(Icons.zoom_in_rounded).first;
        expect(zoomIcon, findsOneWidget);

        // Tap on the image thumbnail
        await tester.tap(zoomIcon);
        await tester.pumpAndSettle();

        // PhotoViewerDialog should be open
        expect(find.byType(PhotoViewerDialog), findsOneWidget);
        expect(find.text('1 / 2'), findsOneWidget);
        expect(find.byType(InteractiveViewer), findsOneWidget);

        // Dismiss dialog
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();
        expect(find.byType(PhotoViewerDialog), findsNothing);
      },
    );
  });
}
