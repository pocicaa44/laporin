import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/access_denied_screen.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../report_detail/screens/report_detail_screen.dart';
import '../controllers/create_report_controller.dart';
import '../widgets/report_category_picker.dart';
import '../widgets/report_location_picker.dart';
import '../widgets/report_media_uploader.dart';

/// Screen for citizens creating a new report (< 180 lines per skills.md)
class CreateReportScreen extends StatelessWidget {
  const CreateReportScreen({super.key, this.controller});

  final CreateReportController? controller;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    // Route guard: Petugas / Admin tidak dapat membuat laporan
    if (auth.isAdmin) {
      return AccessDeniedScreen(
        title: 'Akses Ditolak',
        message: 'Petugas / Admin tidak dapat membuat laporan baru. Silakan gunakan Panel untuk memantau, memverifikasi, dan memperbarui status laporan masyarakat.',
        buttonText: 'Kembali',
        onButtonPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      );
    }

    if (controller != null) {
      return ChangeNotifierProvider<CreateReportController>.value(
        value: controller!,
        child: const _CreateReportForm(),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => CreateReportController(
        reportRepository: context.read<ReportRepository>(),
      ),
      child: const _CreateReportForm(),
    );
  }
}

class _CreateReportForm extends StatefulWidget {
  const _CreateReportForm();

  @override
  State<_CreateReportForm> createState() => _CreateReportFormState();
}

class _CreateReportFormState extends State<_CreateReportForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isFormDirty(CreateReportController controller) {
    return _titleController.text.trim().isNotEmpty ||
        _descriptionController.text.trim().isNotEmpty ||
        controller.selectedPhotos.isNotEmpty ||
        controller.locationAddress.isNotEmpty;
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;

    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Pembuatan Laporan?'),
        content: const Text(
          'Data yang sudah Anda isi pada formulir ini akan hilang jika keluar sekarang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tetap di Sini'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: dangerColor,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<String?> _showConfirmationDialog(BuildContext context, {required bool isPrivate}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);
    final borderColor = AppColors.borderOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.dialog,
          side: BorderSide(color: borderColor, width: 1),
        ),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isPrivate ? Icons.lock_outline_rounded : Icons.send_rounded,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isPrivate ? 'Kirim Laporan Privat' : 'Kirim Laporan',
                style: AppTextStyles.sectionTitleOf(context).copyWith(fontSize: 18),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isPrivate
                  ? 'Simpan dan kirim laporan ini secara privat?'
                  : 'Simpan laporan sebagai draft atau langsung mempublikasikannya?',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            // Tombol Simpan Draft
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                side: BorderSide(color: primaryColor, width: 1.5),
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
                foregroundColor: primaryColor,
              ),
              icon: const Icon(Icons.drafts_outlined, size: 20),
              label: const Text(
                'Simpan Draft',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.pop(ctx, 'draft'),
            ),
            const SizedBox(height: 10),
            // Tombol Publikasikan
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: const RoundedRectangleBorder(
                  borderRadius: AppRadius.button,
                ),
                elevation: 0,
              ),
              icon: Icon(
                isPrivate ? Icons.lock_rounded : Icons.public_rounded,
                size: 20,
              ),
              label: Text(
                isPrivate ? 'Kirim Laporan' : 'Publikasikan',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.pop(ctx, 'publish'),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'Batal / Lanjut Mengedit',
                  style: TextStyle(
                    color: textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (!context.isOnline) return;
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final controller = context.read<CreateReportController>();
    final user = auth.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sesi telah berakhir. Silakan masuk kembali.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (auth.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Petugas / Admin tidak dapat membuat laporan baru.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    if (controller.locationAddress.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap tentukan titik lokasi kejadian terlebih dahulu.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final action = await _showConfirmationDialog(
      context,
      isPrivate: controller.isPrivate,
    );
    if (action == null || !mounted) return;

    final isDraft = action == 'draft';

    final report = await controller.submitReport(
      authorId: user.id,
      authorName: user.fullName.isNotEmpty ? user.fullName : 'Warga Laporin',
      authorUsername: user.username.isNotEmpty ? user.username : null,
      authorAvatarUrl: user.avatarUrl,
      title: _titleController.text,
      description: _descriptionController.text,
      isCallerAdmin: auth.isAdmin,
      isDraft: isDraft,
      isPrivate: controller.isPrivate,
    );

    if (!mounted) return;

    if (report != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDraft
                ? 'Laporan berhasil disimpan ke dalam Draft.'
                : (controller.isPrivate
                    ? 'Laporan privat berhasil dikirim.'
                    : 'Laporan berhasil dikirim.'),
          ),
          backgroundColor: isDraft
              ? const Color(0xFFD98205)
              : AppColors.success,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              ReportDetailScreen(reportId: report.id, initialReport: report),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Gagal memproses laporan. Coba lagi.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<CreateReportController>();
    final isOnline = context.isOnline;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;

    return PopScope(
      canPop: !_isFormDirty(controller) || controller.isLoading,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmLeave(context);
        if (shouldLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Buat Laporan Baru')),
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 720),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border.symmetric(
                  vertical: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 48),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        maxLength: 100,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'Judul Laporan *',
                          hintText: 'Contoh: Jalan Berlubang di Dekat Pasar',
                          counterText: '${_titleController.text.length}/100',
                        ),
                        validator: AppValidators.validateTitle,
                      ),
                      const SizedBox(height: 16),
                      ReportCategoryPicker(
                        selectedCategory: controller.category,
                        onChanged: controller.setCategory,
                      ),
                      const SizedBox(height: 16),
                      ReportLocationPicker(
                        address: controller.locationAddress,
                        latitude: controller.latitude,
                        longitude: controller.longitude,
                        areaName: controller.areaName,
                        onLocationChanged: (addr, lat, lng, area) =>
                            controller.setLocation(
                              address: addr,
                              lat: lat,
                              lng: lng,
                              areaName: area,
                            ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        minLines: 4,
                        maxLines: null,
                        scrollPhysics: const NeverScrollableScrollPhysics(),
                        textInputAction: TextInputAction.newline,
                        decoration: InputDecoration(
                          labelText: 'Deskripsi Masalah *',
                          hintText: 'Jelaskan kondisi kerusakan secara rinci (kronologi, dampak, patokan terdekat)...',
                          alignLabelWithHint: true,
                          helperText: 'Minimal 10 karakter',
                          counterText:
                              '${_descriptionController.text.length} karakter',
                        ),
                        validator: AppValidators.validateDescription,
                      ),
                      const SizedBox(height: 16),
                      ReportMediaUploader(
                        photos: controller.selectedPhotos,
                        onAddPhoto: controller.addPhoto,
                        onRemovePhoto: controller.removePhoto,
                      ),
                      const SizedBox(height: 20),
                      // Visibilitas Laporan (Publik atau Privat)
                      _buildVisibilitySelector(context, controller),
                      const SizedBox(height: 28),
                      AppButton(
                        text: 'Kirim Laporan',
                        isLoading: controller.isLoading,
                        onPressed: isOnline && !controller.isLoading
                            ? _submit
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVisibilitySelector(
    BuildContext context,
    CreateReportController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Visibilitas Laporan *',
              style: AppTextStyles.labelOf(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Opsi 1: Publik
            Expanded(
              child: _VisibilityCard(
                title: 'Publik',
                icon: Icons.public_rounded,
                isSelected: !controller.isPrivate,
                onTap: () => controller.setIsPrivate(false),
                isDark: isDark,
                primaryColor: primaryColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            // Opsi 2: Privat
            Expanded(
              child: _VisibilityCard(
                title: 'Privat',
                icon: Icons.lock_outline_rounded,
                isSelected: controller.isPrivate,
                onTap: () => controller.setIsPrivate(true),
                isDark: isDark,
                primaryColor: primaryColor,
                surfaceColor: surfaceColor,
                borderColor: borderColor,
                textPrimary: textPrimary,
                textSecondary: textSecondary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _VisibilityCard extends StatelessWidget {
  const _VisibilityCard({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
    required this.primaryColor,
    required this.surfaceColor,
    required this.borderColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  final Color primaryColor;
  final Color surfaceColor;
  final Color borderColor;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final activeBg = isDark
        ? AppColors.darkPrimarySoft
        : const Color(0xFFEFF6FF);
    final activeBorder = primaryColor;

    return Material(
      color: isSelected ? activeBg : surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.card,
        side: BorderSide(
          color: isSelected ? activeBorder : borderColor,
          width: isSelected ? 1.6 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.card,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? primaryColor : textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? primaryColor : textPrimary,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 6),
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: primaryColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
