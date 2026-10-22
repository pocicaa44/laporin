import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_validators.dart';
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
  const CreateReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
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

    final report = await controller.submitReport(
      authorId: user.id,
      authorName: user.fullName.isNotEmpty ? user.fullName : 'Warga Laporin',
      authorUsername: user.username.isNotEmpty ? user.username : null,
      authorAvatarUrl: user.avatarUrl,
      title: _titleController.text,
      description: _descriptionController.text,
    );

    if (!mounted) return;

    if (report != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Laporan berhasil dikirim dan siap dipantau.'),
          backgroundColor: AppColors.success,
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
            controller.errorMessage ?? 'Gagal mengirim laporan. Coba lagi.',
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
