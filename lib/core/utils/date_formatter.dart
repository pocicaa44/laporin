import 'package:intl/intl.dart';

const List<String> _idMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'Mei',
  'Jun',
  'Jul',
  'Agu',
  'Sep',
  'Okt',
  'Nov',
  'Des',
];

/// Date formatting extension as specified in skills.md (Strict DRY rule)
extension DateTimeFormatX on DateTime {
  /// Format date as: 20 Okt 2026
  String toDisplayDate() {
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(this);
    } catch (_) {
      // Safe fallback if locale data is uninitialized or unavailable
      final d = day.toString().padLeft(2, '0');
      final m = _idMonths[month - 1];
      return '$d $m $year';
    }
  }

  /// Format date with time: 20 Okt 2026, 14:30
  String toDisplayDateTime() {
    try {
      return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(this);
    } catch (_) {
      // Safe fallback if locale data is uninitialized or unavailable
      final d = day.toString().padLeft(2, '0');
      final m = _idMonths[month - 1];
      final h = hour.toString().padLeft(2, '0');
      final min = minute.toString().padLeft(2, '0');
      return '$d $m $year, $h:$min';
    }
  }

  /// Human-friendly relative time: "2 jam lalu", "3 hari lalu", etc.
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return 'Baru saja';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return toDisplayDate();
    }
  }
}
