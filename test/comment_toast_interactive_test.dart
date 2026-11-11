import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:laporin/core/widgets/app_toast.dart';
import 'package:laporin/data/models/report_model.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/data/repositories/comment_repository.dart';
import 'package:laporin/data/repositories/report_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/report_detail/screens/report_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppToast Unit & Widget Tests', () {
    testWidgets('AppToast displays message at top center for 3 seconds with slide animations then disappears', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Center(
                  child: ElevatedButton(
                    onPressed: () {
                      AppToast.show(
                        context,
                        message: 'komentar diposting',
                        duration: const Duration(seconds: 3),
                      );
                    },
                    child: const Text('Show Toast'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Toast is not shown initially
      expect(find.text('komentar diposting'), findsNothing);

      // Trigger toast
      await tester.tap(find.text('Show Toast'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Toast appears
      final toastFinder = find.text('komentar diposting');
      expect(toastFinder, findsOneWidget);

      // Verify animations: SlideTransition and FadeTransition exist
      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(FadeTransition), findsWidgets);

      // Verify position: top center of the screen
      final toastRect = tester.getRect(toastFinder);
      final screenWidth = tester.view.physicalSize.width / tester.view.devicePixelRatio;
      expect(toastRect.center.dx, closeTo(screenWidth / 2, 20.0));
      expect(toastRect.top, lessThan(100.0)); // positioned near top

      // Verify universal semi-transparent grey container
      final containerFinder = find.ancestor(
        of: toastFinder,
        matching: find.byType(Container),
      ).first;
      final container = tester.widget<Container>(containerFinder);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
      expect(decoration!.color, isNotNull);
      // Semi-transparent grey (alpha < 1.0 and > 0.5)
      expect(decoration.color!.a, lessThan(1.0));
      expect(decoration.color!.a, greaterThan(0.5));

      // At 2 seconds, toast is still visible
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('komentar diposting'), findsOneWidget);

      // At 3 seconds, slide-up dismissal animation starts
      await tester.pump(const Duration(seconds: 1));

      // After dismissal animation finishes (300ms), toast is removed
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('komentar diposting'), findsNothing);
    });

    testWidgets('AppToast.dismiss cancels and removes active toast immediately', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return Column(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        AppToast.show(
                          context,
                          message: 'komentar diposting',
                          duration: const Duration(seconds: 3),
                        );
                      },
                      child: const Text('Show'),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        AppToast.dismiss();
                      },
                      child: const Text('Dismiss'),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('komentar diposting'), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      await tester.pump();
      expect(find.text('komentar diposting'), findsNothing);
    });
  });

  group('ReportDetailScreen Comment Submission Toast Tests', () {
    late AuthRepository authRepo;
    late AuthController authController;
    late ReportRepository reportRepo;
    late CommentRepository commentRepo;
    late ReportModel testReport;

    setUp(() {
      authRepo = AuthRepository();
      authRepo.setCurrentUserProfileForTesting(
        UserProfileModel(
          id: 'user-poster',
          email: 'poster@laporin.id',
          fullName: 'Budi Santoso',
          username: 'budisantoso',
          role: UserRole.user,
          createdAt: DateTime.now(),
        ),
      );
      authController = AuthController(authRepository: authRepo);
      reportRepo = ReportRepository();
      commentRepo = CommentRepository();

      testReport = ReportModel(
        id: 'rep-toast-1',
        reportNumber: 'LAP-TST-001',
        authorId: 'user-other',
        authorName: 'Penulis Laporan',
        areaId: 'area-1',
        areaName: 'Kota Semarang',
        title: 'Laporan Uji Toast Komentar',
        description: 'Uji kirim komentar menampilkan toast',
        category: 'Infrastruktur',
        latitude: -6.99,
        longitude: 110.42,
        locationAddress: 'Jl. Pemuda No. 1',
        handlingStatus: HandlingStatus.inProgress,
        publicationState: PublicationState.published,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        commentsCount: 0,
        isDiscussionActive: true,
      );
    });

    tearDown(() {
      AppToast.dismiss();
    });

    testWidgets('shows top center toast "komentar diposting" for 3 seconds upon successful comment submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            Provider.value(value: authRepo),
            Provider.value(value: reportRepo),
            Provider.value(value: commentRepo),
            ChangeNotifierProvider.value(value: authController),
          ],
          child: MaterialApp(
            home: ReportDetailScreen(
              reportId: testReport.id,
              initialReport: testReport,
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Comment input field
      final inputFinder = find.byType(TextField);
      expect(inputFinder, findsOneWidget);

      // Enter comment
      await tester.enterText(inputFinder, 'Semoga cepat diperbaiki petugas');
      await tester.pump();

      // Send button
      final sendButton = find.byIcon(Icons.send_rounded);
      expect(sendButton, findsOneWidget);

      // Tap send button
      await tester.tap(sendButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Toast "komentar diposting" appears at top center
      final toastFinder = find.text('komentar diposting');
      expect(toastFinder, findsOneWidget);

      // Verify position: top center
      final toastRect = tester.getRect(toastFinder);
      expect(toastRect.center.dx, closeTo(400.0, 25.0)); // centered horizontally in 800px screen
      expect(toastRect.top, lessThan(120.0)); // top positioned

      // At 2 seconds, toast is still visible
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('komentar diposting'), findsOneWidget);

      // At 3 seconds total + animation, toast disappears
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('komentar diposting'), findsNothing);
    });
  });
}
