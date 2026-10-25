/// Reusable input validators ensuring consistency across all forms (Strict DRY)
class AppValidators {
  AppValidators._();

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName wajib diisi.';
    }
    return null;
  }

  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Judul laporan wajib diisi.';
    }
    if (value.trim().length < 5) {
      return 'Judul laporan minimal 5 karakter.';
    }
    if (value.trim().length > 100) {
      return 'Judul laporan maksimal 100 karakter.';
    }
    return null;
  }

  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Deskripsi laporan wajib diisi.';
    }
    if (value.trim().length < 10) {
      return 'Deskripsi laporan minimal 10 karakter agar dapat ditindaklanjuti.';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email wajib diisi.';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Format email tidak valid.';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kata sandi wajib diisi.';
    }
    if (value.length < 8) {
      return 'Kata sandi minimal 8 karakter.';
    }
    return null;
  }

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Username wajib diisi.';
    }
    final trimmed = value.trim();
    if (trimmed.length < 3) {
      return 'Username minimal 3 karakter.';
    }
    if (trimmed.length > 30) {
      return 'Username maksimal 30 karakter.';
    }
    final regex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!regex.hasMatch(trimmed)) {
      return 'Username hanya boleh huruf, angka, dan garis bawah (_).';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Konfirmasi kata sandi wajib diisi.';
    }
    if (value != password) {
      return 'Konfirmasi kata sandi tidak cocok.';
    }
    return null;
  }

  static String? validateReason(String? value, String actionName) {
    if (value == null || value.trim().isEmpty) {
      return 'Alasan $actionName wajib diisi.';
    }
    if (value.trim().length < 5) {
      return 'Alasan minimal 5 karakter.';
    }
    return null;
  }
}
