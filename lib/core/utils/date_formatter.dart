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
    final effectiveDate = isAfter(now) ? now : this;
    final difference = now.difference(effectiveDate);

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

  /// Format label waktu khusus laporan sesuai kebutuhan produk:
  /// - Bagi user biasa: laporan yang berumur < 1 jam berstatus "Baru saja",
  ///   dan setelah >= 1 jam menampilkan waktu relatif seperti "1 jam lalu", "2 jam lalu", atau tanggal.
  /// - Bagi admin: laporan yang berumur < 1 jam berstatus "Baru",
  ///   dan label "Baru" ini akan hilang (berubah menampilkan waktu relatif aktual)
  ///   segera setelah admin membuka detail laporan tersebut ([isViewedByAdmin] == true).
  String toReportTimeLabel({
    bool isAdmin = false,
    bool isViewedByAdmin = false,
  }) {
    final now = DateTime.now();
    // Cegah waktu di masa depan (akibat clock drift / timezone desync)
    final effectiveDate = isAfter(now) ? now : this;
    final difference = now.difference(effectiveDate);
    final isLessThanOneHour = difference.inHours < 1;

    if (isAdmin) {
      // Untuk admin: jika < 1 jam dan BELUM membuka detail -> 'Baru'
      if (isLessThanOneHour && !isViewedByAdmin) {
        return 'Baru';
      }
      // Jika sudah dibuka oleh admin atau sudah >= 1 jam: 'Baru' hilang, tampilkan waktu relatif aktual
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

    // Bagi user biasa: laporan < 1 jam adalah 'Baru saja'
    if (isLessThanOneHour) {
      return 'Baru saja';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return toDisplayDate();
    }
  }
}
