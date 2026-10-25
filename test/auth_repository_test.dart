import 'package:flutter_test/flutter_test.dart';
import 'package:laporin/core/utils/app_validators.dart';
import 'package:laporin/data/models/user_profile_model.dart';
import 'package:laporin/data/repositories/auth_repository.dart';
import 'package:laporin/features/auth/controllers/auth_controller.dart';

void main() {
  group('AuthRepository and AuthController Tests (Non-demo & Native Auth)', () {
    test(
      'AuthRepository defaults to unauthenticated and null user profile',
      () {
        final repo = AuthRepository();
        expect(repo.isAuthenticated, isFalse);
        expect(repo.currentUserProfile, isNull);
      },
    );

    test('signInWithEmail throws when Supabase client is not connected (no demo fallback)', () async {
      final repo = AuthRepository();
      expect(
        () => repo.signInWithEmail('test@laporin.id', 'password123'),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'signUpWithEmail throws when Supabase client is not connected',
      () async {
        final repo = AuthRepository();
        expect(
          () => repo.signUpWithEmail(
            username: 'budi_laporin',
            email: 'budi@laporin.id',
            password: 'password123',
          ),
          throwsA(isA<Exception>()),
        );
      },
    );

    test(
      'checkUsernameAvailability throws when Supabase client is not connected',
      () async {
        final repo = AuthRepository();
        expect(
          () => repo.checkUsernameAvailability('budi_laporin'),
          throwsA(isA<Exception>()),
        );
      },
    );

    test('signInWithGoogle throws when Supabase client is not connected (no demo fallback)', () async {
      final repo = AuthRepository();
      expect(() => repo.signInWithGoogle(), throwsA(isA<Exception>()));
    });

    test('AuthController reflects loading state and propagates errors on login failure', () async {
      final repo = AuthRepository();
      final controller = AuthController(authRepository: repo);

      expect(controller.isAuthenticated, isFalse);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNull);

      final success = await controller.signInWithEmail(
        'test@laporin.id',
        'wrongpassword',
      );
      expect(success, isFalse);
      expect(controller.isAuthenticated, isFalse);
      expect(controller.isLoading, isFalse);
      expect(controller.errorMessage, isNotNull);
    });

    test(
      'UserRole parsing defaults to regular user and preserves admin strictly',
      () {
        expect(UserRole.fromString('admin'), equals(UserRole.admin));
        expect(UserRole.fromString('user'), equals(UserRole.user));
        expect(UserRole.fromString(null), equals(UserRole.user));
        expect(UserRole.fromString('other'), equals(UserRole.user));
      },
    );

    test('AppValidators.validateUsername validates length and format', () {
      expect(AppValidators.validateUsername(null), isNotNull);
      expect(AppValidators.validateUsername(''), isNotNull);
      expect(AppValidators.validateUsername('ab'), isNotNull); // too short
      expect(
        AppValidators.validateUsername('user name with spaces'),
        isNotNull,
      );
      expect(AppValidators.validateUsername('user@invalid!'), isNotNull);
      expect(AppValidators.validateUsername('budi_123'), isNull); // valid
      expect(AppValidators.validateUsername('admin_laporin'), isNull); // valid
    });

    test('AppValidators.validatePassword enforces minimum 8 characters', () {
      expect(AppValidators.validatePassword(null), isNotNull);
      expect(AppValidators.validatePassword(''), isNotNull);
      expect(AppValidators.validatePassword('12345'), isNotNull);
      expect(AppValidators.validatePassword('1234567'), isNotNull);
      expect(
        AppValidators.validatePassword('1234567'),
        equals('Kata sandi minimal 8 karakter.'),
      );
      expect(AppValidators.validatePassword('12345678'), isNull);
      expect(AppValidators.validatePassword('strongPassword123'), isNull);
    });

    test('AppValidators.validateConfirmPassword checks equality', () {
      expect(
        AppValidators.validateConfirmPassword(null, 'secret123'),
        isNotNull,
      );
      expect(AppValidators.validateConfirmPassword('', 'secret123'), isNotNull);
      expect(
        AppValidators.validateConfirmPassword('wrong', 'secret123'),
        isNotNull,
      );
      expect(
        AppValidators.validateConfirmPassword('secret123', 'secret123'),
        isNull,
      );
    });
  });
}
