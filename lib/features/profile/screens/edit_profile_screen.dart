import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/media_service.dart';
import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/widgets/username_text_field.dart';

/// Screen allowing users to edit their profile (avatar photo and username).
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _usernameController;

  XFile? _selectedAvatarFile;
  Uint8List? _selectedAvatarBytes;
  bool _resetToDefault = false;

  bool _isUsernameAvailable = true;
  bool _isCheckingUsername = false;
  bool _isSaving = false;
  bool _isProcessingAvatar = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthController>().currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
    final initialUsername = user?.username.trim().replaceFirst('@', '') ?? '';
    _usernameController = TextEditingController(text: initialUsername);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar(ImageSource source) async {
    if (_isProcessingAvatar || _isSaving) return;

    setState(() {
      _isProcessingAvatar = true;
    });

    try {
      final file = await MediaService.instance.pickAvatarImage(source);
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedAvatarFile = file;
        _selectedAvatarBytes = bytes;
        _resetToDefault = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingAvatar = false;
        });
      }
    }
  }

  void _showAvatarOptionsSheet() {
    if (!context.isOnline) return;
    final user = context.read<AuthController>().currentUser;
    final hasCustomAvatar =
        (user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty) ||
        _selectedAvatarFile != null;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ubah Foto Profil',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  leading: const FaIcon(
                    FontAwesomeIcons.images,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickAvatar(ImageSource.gallery);
                  },
                ),
                if (!kIsWeb)
                  ListTile(
                    leading: const FaIcon(
                      FontAwesomeIcons.camera,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    title: const Text('Ambil dari Kamera'),
                    onTap: () {
                      Navigator.pop(ctx);
                      _pickAvatar(ImageSource.camera);
                    },
                  ),
                if (hasCustomAvatar && !_resetToDefault)
                  ListTile(
                    leading: const FaIcon(
                      FontAwesomeIcons.trashCan,
                      color: AppColors.danger,
                      size: 20,
                    ),
                    title: const Text(
                      'Gunakan Avatar Standar (Hapus Foto)',
                      style: TextStyle(color: AppColors.danger),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _resetToDefault = true;
                        _selectedAvatarFile = null;
                        _selectedAvatarBytes = null;
                      });
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleSave() async {
    if (!context.isOnline) return;
    final auth = context.read<AuthController>();
    final user = auth.currentUser;
    if (user == null || _isSaving) return;

    if (_isCheckingUsername) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap tunggu, sedang memeriksa ketersediaan nama akun.',
          ),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    final currentCleanUsername = user.username
        .trim()
        .replaceFirst('@', '')
        .toLowerCase();
    final newCleanUsername = _usernameController.text
        .trim()
        .replaceFirst('@', '')
        .toLowerCase();
    final hasUsernameChange =
        newCleanUsername.isNotEmpty && newCleanUsername != currentCleanUsername;

    final currentFullName = user.fullName.trim();
    final newFullName = _nameController.text.trim();
    final hasNameChange =
        newFullName.isNotEmpty && newFullName != currentFullName;

    if (hasUsernameChange && !_isUsernameAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nama akun yang dipilih tidak tersedia atau tidak valid.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final hasAvatarChange =
        _selectedAvatarFile != null ||
        (_resetToDefault &&
            (user.avatarUrl != null && user.avatarUrl!.isNotEmpty));

    if (!hasUsernameChange && !hasNameChange && !hasAvatarChange) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak ada perubahan profil yang disimpan.'),
          backgroundColor: AppColors.textSecondary,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // 1. Tangani perubahan avatar terlebih dahulu jika ada
      if (_selectedAvatarFile != null) {
        final avatarSuccess = await auth.updateAvatar(_selectedAvatarFile!);
        if (!avatarSuccess) {
          throw Exception(auth.errorMessage ?? 'Gagal mengunggah foto profil.');
        }
      } else if (_resetToDefault &&
          (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)) {
        final removeSuccess = await auth.removeAvatar();
        if (!removeSuccess) {
          throw Exception(auth.errorMessage ?? 'Gagal mereset foto profil.');
        }
      }

      // 2. Tangani perubahan nama pengguna dan/atau nama akun (@)
      if (hasNameChange || hasUsernameChange) {
        final infoSuccess = await auth.updateProfileInfo(
          fullName: hasNameChange ? newFullName : null,
          username: hasUsernameChange ? newCleanUsername : null,
        );
        if (!infoSuccess) {
          throw Exception(
            auth.errorMessage ?? 'Gagal memperbarui informasi profil.',
          );
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui.'),
          backgroundColor: AppColors.success,
          duration: Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e
                .toString()
                .replaceFirst('Exception: ', '')
                .replaceFirst('AuthException: ', ''),
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Widget _buildAvatarPreview(String? currentAvatarUrl) {
    const double size = 100;

    Widget avatarImage;
    if (_selectedAvatarBytes != null) {
      avatarImage = ClipOval(
        child: Image.memory(
          _selectedAvatarBytes!,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (_resetToDefault) {
      avatarImage = ClipOval(
        child: Image.asset(
          UserAvatar.defaultAvatarAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    } else if (currentAvatarUrl != null && currentAvatarUrl.trim().isNotEmpty) {
      avatarImage = ClipOval(
        child: AppImage(
          imageSource: currentAvatarUrl.trim(),
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: Image.asset(
            UserAvatar.defaultAvatarAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
          errorWidget: Image.asset(
            UserAvatar.defaultAvatarAsset,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ),
      );
    } else {
      avatarImage = ClipOval(
        child: Image.asset(
          UserAvatar.defaultAvatarAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey.shade100,
              border: Border.all(color: AppColors.border, width: 2),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                avatarImage,
                if (_isProcessingAvatar)
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Material(
              color: (_isSaving || _isProcessingAvatar)
                  ? AppColors.border
                  : AppColors.primary,
              shape: const CircleBorder(),
              elevation: 2,
              child: InkWell(
                onTap: (_isSaving || _isProcessingAvatar)
                    ? null
                    : _showAvatarOptionsSheet,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: FaIcon(
                    FontAwesomeIcons.camera,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isOnline = context.isOnline;
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil'), centerTitle: false),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Avatar Header Section
                    _buildAvatarPreview(user?.avatarUrl),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton.icon(
                        onPressed: (_isSaving || _isProcessingAvatar)
                            ? null
                            : _showAvatarOptionsSheet,
                        icon: const FaIcon(FontAwesomeIcons.camera, size: 13),
                        label: const Text(
                          'Ubah Foto Profil',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (_resetToDefault) ...[
                      const SizedBox(height: 4),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primarySoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Akan menggunakan avatar standar',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.primaryStrong,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),

                    // Nama Pengguna (Display Name) Edit Section
                    const Text(
                      'Nama Pengguna',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isSaving,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Contoh: Budi Santoso',
                        prefixIcon: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 14),
                          child: FaIcon(
                            FontAwesomeIcons.user,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 44,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.danger),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.danger,
                            width: 1.5,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      validator: (val) {
                        final text = val?.trim() ?? '';
                        if (text.isEmpty) {
                          return 'Nama pengguna tidak boleh kosong';
                        }
                        if (text.length < 2) {
                          return 'Nama pengguna minimal 2 karakter';
                        }
                        if (text.length > 50) {
                          return 'Nama pengguna maksimal 50 karakter';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Nama publik atau panggilan Anda yang ditampilkan kepada warga lain dan petugas.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Nama Akun (Username dengan @) Edit Section
                    const Text(
                      'Nama Akun (@)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    UsernameTextField(
                      controller: _usernameController,
                      enabled: !_isSaving,
                      onAvailabilityChanged: (isAvailable, isChecking) {
                        setState(() {
                          _isUsernameAvailable = isAvailable;
                          _isCheckingUsername = isChecking;
                        });
                      },
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Nama akun unik diawali dengan @ untuk identitas profil Anda di thread publik dan laporan (3–30 karakter).',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Informational Readonly Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Akun',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textSecondary,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Divider(height: 20),
                          Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.envelope,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Email Terdaftar',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      user?.email.isNotEmpty == true
                                          ? user!.email
                                          : '-',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.shieldHalved,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Peran Akun',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      auth.isAdmin
                                          ? 'Petugas / Administrator'
                                          : 'Warga Masyarakat',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: auth.isAdmin
                                            ? const Color(0xFFD98205)
                                            : AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    AppButton(
                      text: 'Simpan Perubahan',
                      isLoading: _isSaving || auth.isLoading,
                      iconWidget: const Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Colors.white,
                      ),
                      onPressed: isOnline && !_isSaving ? _handleSave : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
