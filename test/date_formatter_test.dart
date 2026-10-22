import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:laporin/core/utils/date_formatter.dart';

void main() {
  group('DateTimeFormatX Unit Tests', () {
    test('toDisplayDate formats date properly with or without locale init', () {
      final testDate = DateTime(2026, 10, 22, 14, 30);
      final formatted = testDate.toDisplayDate();

      // Should format day, month, and year (e.g., 22 Okt 2026)
      expect(formatted, contains('22'));
      expect(formatted, contains('2026'));
      expect(formatted, anyOf(contains('Okt'), contains('Oct')));
    });

    test(
      'toDisplayDateTime formats date and time properly without throwing',
      () {
        final testDate = DateTime(2026, 10, 22, 14, 30);
        final formatted = testDate.toDisplayDateTime();

        expect(formatted, contains('22'));
        expect(formatted, contains('2026'));
        expect(formatted, contains('14:30'));
      },
    );

    test(
      'toDisplayDateTime formats properly after initializeDateFormatting',
      () async {
        await initializeDateFormatting('id_ID', null);
        final testDate = DateTime(2026, 5, 17, 9, 15);
        final formatted = testDate.toDisplayDateTime();

        expect(formatted, equals('17 Mei 2026, 09:15'));
      },
    );

    test('toRelativeTime handles various time intervals', () {
      final now = DateTime.now();

      final justNow = now.subtract(const Duration(seconds: 20));
      expect(justNow.toRelativeTime(), equals('Baru saja'));

      final minutesAgo = now.subtract(const Duration(minutes: 5));
      expect(minutesAgo.toRelativeTime(), equals('5 menit lalu'));

      final hoursAgo = now.subtract(const Duration(hours: 3));
      expect(hoursAgo.toRelativeTime(), equals('3 jam lalu'));

      final daysAgo = now.subtract(const Duration(days: 4));
      expect(daysAgo.toRelativeTime(), equals('4 hari lalu'));

      final weekAgo = now.subtract(const Duration(days: 10));
      expect(weekAgo.toRelativeTime(), contains('20'));
    });
  });
}
