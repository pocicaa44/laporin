import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/auth/screens/otp_verification_screen.dart';
import 'package:laporin/features/auth/widgets/otp_input_row.dart';
import 'package:laporin/features/report_detail/widgets/delete_report_dialog.dart';
import 'package:provider/provider.dart';

void main() {
  group('DeleteReportDialog UI Verification', () {
    testWidgets(
      'Renders exact delete confirmation dialog message and buttons',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: DeleteReportDialog(
                reportNumber: 'LAP-2026-001',
                onConfirmDelete: () async => true,
              ),
            ),
          ),
        );

        // Verify exact message specified by user
        expect(find.text('Hapus Laporan?'), findsOneWidget);
        expect(
          find.text('apakah anda yakin ingin menghapus laporan LAP-2026-001?'),
          findsOneWidget,
        );
        expect(
          find.text('catatan: Tindakan ini tidak dapat dibatalkan'),
          findsOneWidget,
        );
        expect(find.text('Batal'), findsOneWidget);
        expect(find.text('Hapus Laporan'), findsOneWidget);
      },
    );
  });

  group('OtpInputRow Character Limiting', () {
    testWidgets('Prevents entering more than 1 character per digit box', (
      WidgetTester tester,
    ) async {
      final controllers = List.generate(6, (_) => TextEditingController());
      final focusNodes = List.generate(6, (_) => FocusNode());
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OtpInputRow(
              controllers: controllers,
              focusNodes: focusNodes,
              onChanged: (_) {},
            ),
          ),
        ),
      );

      // Enter multi-character in box 0
      final firstField = find.byType(TextFormField).first;
      await tester.enterText(firstField, '999');
      await tester.pump();

      // Controller 0 must have at most 1 character
      expect(controllers[0].text.length, lessThanOrEqualTo(1));
    });
  });

  group('OtpVerificationScreen Timers', () {
    testWidgets(
      'Shows 5-minute expiration countdown and 1-minute resend countdown',
      (WidgetTester tester) async {
        final authRepo = AuthRepository();
        final authController = AuthController(authRepository: authRepo);

        await tester.pumpWidget(
          ChangeNotifierProvider.value(
            value: authController,
            child: const MaterialApp(
              home: OtpVerificationScreen(email: 'test@laporin.id'),
            ),
          ),
        );

        // Initial expiration countdown starts at 05:00
        expect(find.text('Waktu tersisa: 05:00'), findsOneWidget);

        // Initial resend countdown starts at 01:00
        expect(find.text('Kirim ulang dalam 01:00'), findsOneWidget);

        // Advance 1 second
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Waktu tersisa: 04:59'), findsOneWidget);
        expect(find.text('Kirim ulang dalam 00:59'), findsOneWidget);
      },
    );
  });
}
