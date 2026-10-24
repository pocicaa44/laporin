import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
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
              backgroundColor: AppColors.danger,
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

  Future<String?> _showConfirmationDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primarySoft,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.send_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Kirim Laporan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Apakah Anda ingin menyimpan laporan ini sebagai draft atau langsung mempublikasikannya?',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            // Tombol Simpan Draft
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
                side: const BorderSide(color: AppColors.primary, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                foregroundColor: AppColors.primary,
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
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
              ),
              icon: const Icon(Icons.public_rounded, size: 20),
              label: const Text(
                'Publikasikan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              onPressed: () => Navigator.pop(ctx, 'publish'),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Batal / Lanjut Mengedit',
                  style: TextStyle(
                    color: AppColors.textSecondary,
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

    final action = await _showConfirmationDialog(context);
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
    );

    if (!mounted) return;

    if (report != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isDraft
                ? 'Laporan berhasil disimpan ke dalam Draft.'
                : 'Laporan berhasil dikirim dan siap dipantau.',
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

    return PopScope(
      canPop: !_isFormDirty(controller) || controller.isLoading,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldLeave = await _confirmLeave(context);
        if (shouldLeave && context.mounted) {
          Navigator.pop(context);
        }
      },
      child: Container(
        color: const Color(0xFFF0F2F5),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            decoration: const BoxDecoration(
              color: AppColors.background,
              border: Border.symmetric(
                vertical: BorderSide(color: AppColors.border, width: 1),
              ),
              boxShadow: [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 24,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Scaffold(
              appBar: AppBar(title: const Text('Buat Laporan Baru')),
              body: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        maxLength: 100,
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
                        maxLines: 4,
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
                      const SizedBox(height: 28),
                      AppButton(
                        text: 'Kirim Laporan',
                        isLoading: controller.isLoading,
                        onPressed: _submit,
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
}
