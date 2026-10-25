import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';
import 'package:laporin/features/auth/screens/forgot_password_screen.dart';
import 'package:laporin/features/auth/screens/login_screen.dart';
import 'package:laporin/features/auth/screens/otp_verification_screen.dart';
import 'package:laporin/features/auth/screens/reset_password_screen.dart';
import 'package:laporin/features/auth/widgets/otp_input_row.dart';
import 'package:provider/provider.dart';

class MockSuccessAuthRepository extends AuthRepository {
  bool sendOtpCalled = false;
  bool verifyOtpCalled = false;
  bool updatePasswordCalled = false;
  bool shouldOtpFail = false;

  @override
  Future<void> sendResetPasswordOtp(String email) async {
    sendOtpCalled = true;
  }

  @override
  Future<void> verifyRecoveryOtp({
    required String email,
    required String otp,
  }) async {
    verifyOtpCalled = true;
    if (shouldOtpFail) {
      throw Exception('Kode OTP tidak valid atau sudah kedaluwarsa.');
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    updatePasswordCalled = true;
  }

  @override
  Future<void> signOut() async {}
}

Widget createTestApp({
  required Widget child,
  required AuthController authController,
}) {
  return ChangeNotifierProvider<AuthController>.value(
    value: authController,
    child: MaterialApp(home: child),
  );
}

void main() {
  group('AuthRepository and AuthController Password Reset Tests', () {
    test(
      'AuthRepository throws Exception when Supabase is disconnected',
      () async {
        final repo = AuthRepository();
        expect(
          () => repo.sendResetPasswordOtp('user@test.com'),
          throwsA(isA<Exception>()),
        );
        expect(
          () => repo.verifyRecoveryOtp(email: 'user@test.com', otp: '123456'),
          throwsA(isA<Exception>()),
        );
        expect(
          () => repo.updatePassword('newPassword123'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'AuthController password reset flows propagate success and error',
      () async {
        final repo = MockSuccessAuthRepository();
        final controller = AuthController(authRepository: repo);

        // 1. sendResetPasswordOtp success
        final sendSuccess = await controller.sendResetPasswordOtp(
          'user@test.com',
        );
        expect(sendSuccess, isTrue);
        expect(repo.sendOtpCalled, isTrue);
        expect(controller.errorMessage, isNull);

        // 2. verifyRecoveryOtp success
        final verifySuccess = await controller.verifyRecoveryOtp(
          email: 'user@test.com',
          otp: '123456',
        );
        expect(verifySuccess, isTrue);
        expect(repo.verifyOtpCalled, isTrue);
        expect(controller.errorMessage, isNull);

        // 3. updatePassword success
        final updateSuccess = await controller.updatePassword('newPassword123');
        expect(updateSuccess, isTrue);
        expect(repo.updatePasswordCalled, isTrue);
        expect(controller.errorMessage, isNull);

        // 4. verifyRecoveryOtp failure
        repo.shouldOtpFail = true;
        final failSuccess = await controller.verifyRecoveryOtp(
          email: 'user@test.com',
          otp: '999999',
        );
        expect(failSuccess, isFalse);
        expect(controller.errorMessage, contains('tidak valid'));

        // 5. clearErrorMessage
        controller.clearErrorMessage();
        expect(controller.errorMessage, isNull);
      },
    );
  });

  group('Password Reset UI Widget Tests', () {
    late MockSuccessAuthRepository mockRepo;
    late AuthController authController;

    setUp(() {
      mockRepo = MockSuccessAuthRepository();
      authController = AuthController(authRepository: mockRepo);
    });

    testWidgets(
      'LoginScreen renders Lupa password? button and opens ForgotPasswordScreen',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const LoginScreen(),
            authController: authController,
          ),
        );

        expect(find.text('Lupa password?'), findsOneWidget);

        // Tap Lupa password?
        await tester.tap(find.text('Lupa password?'));
        await tester.pumpAndSettle();

        expect(find.byType(ForgotPasswordScreen), findsOneWidget);
        expect(find.text('Kirim OTP'), findsOneWidget);
      },
    );

    testWidgets(
      'ForgotPasswordScreen validates email and triggers sending OTP',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ForgotPasswordScreen(),
            authController: authController,
          ),
        );

        // Try submit without entering email
        await tester.tap(find.text('Kirim OTP'));
        await tester.pumpAndSettle();
        expect(find.text('Email wajib diisi.'), findsOneWidget);

        // Enter invalid email
        await tester.enterText(find.byType(TextFormField), 'invalid-email');
        await tester.tap(find.text('Kirim OTP'));
        await tester.pumpAndSettle();
        expect(find.text('Format email tidak valid.'), findsOneWidget);

        // Enter valid email and submit
        await tester.enterText(find.byType(TextFormField), 'warga@laporin.id');
        await tester.tap(find.text('Kirim OTP'));
        await tester.pumpAndSettle();

        expect(mockRepo.sendOtpCalled, isTrue);
        // Should navigate to OtpVerificationScreen
        expect(find.byType(OtpVerificationScreen), findsOneWidget);
      },
    );

    testWidgets(
      'OtpVerificationScreen displays required notification text, 6 digit boxes, timer, and error handling',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const OtpVerificationScreen(email: 'warga@laporin.id'),
            authController: authController,
          ),
        );

        // 1. Text required by user prompt: "kode OTP terkirim. silahkan buka email anda"
        expect(
          find.text('kode OTP terkirim. silahkan buka email anda'),
          findsOneWidget,
        );
        expect(find.text('warga@laporin.id'), findsOneWidget);

        // 2. 6-digit OTP input row
        expect(find.byType(OtpInputRow), findsOneWidget);

        // 3. Expiration timer
        expect(find.textContaining('Waktu tersisa:'), findsOneWidget);

        // 4. Konfirmasi button
        expect(find.text('Konfirmasi'), findsOneWidget);

        // Tap Konfirmasi when OTP is not full -> shows error beneath OTP row and boxes turn red
        await tester.tap(find.text('Konfirmasi'));
        await tester.pumpAndSettle();

        expect(
          find.text('Harap masukkan 6 digit kode OTP secara lengkap.'),
          findsOneWidget,
        );

        // Set mock to fail OTP verification
        mockRepo.shouldOtpFail = true;

        // Enter 6 digits
        final textFields = find.descendant(
          of: find.byType(OtpInputRow),
          matching: find.byType(TextFormField),
        );
        expect(textFields, findsNWidgets(6));

        for (int i = 0; i < 6; i++) {
          await tester.enterText(textFields.at(i), '1');
        }
        await tester.pumpAndSettle();

        // Tap Konfirmasi with invalid OTP
        await tester.tap(find.text('Konfirmasi'));
        await tester.pumpAndSettle();

        // Error message appears below OTP row and boxes have error state
        expect(
          find.textContaining('tidak valid atau sudah kedaluwarsa'),
          findsOneWidget,
        );
        final otpRowWidget = tester.widget<OtpInputRow>(
          find.byType(OtpInputRow),
        );
        expect(otpRowWidget.hasError, isTrue);

        // Now test successful OTP verification
        mockRepo.shouldOtpFail = false;
        await tester.tap(find.text('Konfirmasi'));
        await tester.pumpAndSettle();

        // Navigates to ResetPasswordScreen
        expect(find.byType(ResetPasswordScreen), findsOneWidget);
      },
    );

    testWidgets(
      'ResetPasswordScreen validates inputs and updates password then redirects',
      (tester) async {
        await tester.pumpWidget(
          createTestApp(
            child: const ResetPasswordScreen(email: 'warga@laporin.id'),
            authController: authController,
          ),
        );

        expect(find.text('masukkan password baru'), findsOneWidget);
        expect(find.text('konfirmasi password'), findsOneWidget);
        expect(find.text('Perbarui password'), findsOneWidget);

        // Try submit empty
        await tester.tap(find.text('Perbarui password'));
        await tester.pumpAndSettle();
        expect(find.text('Kata sandi wajib diisi.'), findsOneWidget);

        // Fill passwords mismatch
        final textFields = find.byType(TextFormField);
        await tester.enterText(textFields.at(0), 'passwordBaru123');
        await tester.enterText(textFields.at(1), 'mismatchPassword');
        await tester.tap(find.text('Perbarui password'));
        await tester.pumpAndSettle();
        expect(find.text('Konfirmasi kata sandi tidak cocok.'), findsOneWidget);

        // Fill matching passwords and submit
        await tester.enterText(textFields.at(1), 'passwordBaru123');
        await tester.tap(find.text('Perbarui password'));
        await tester.pumpAndSettle();

        expect(mockRepo.updatePasswordCalled, isTrue);
        // Redirects to LoginScreen
        expect(find.byType(LoginScreen), findsOneWidget);
      },
    );
  });
}
