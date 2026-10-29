import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../create_report/widgets/report_category_picker.dart';
import '../../create_report/widgets/report_location_picker.dart';
import '../controllers/edit_report_controller.dart';
import '../widgets/edit_report_media_manager.dart';

/// Screen for editing an existing citizen report (< 200 lines per skills.md)
class EditReportScreen extends StatelessWidget {
  const EditReportScreen({super.key, required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => EditReportController(
        report: report,
        reportRepository: context.read<ReportRepository>(),
      ),
      child: _EditReportForm(originalReport: report),
    );
  }
}

class _EditReportForm extends StatefulWidget {
  const _EditReportForm({required this.originalReport});

  final ReportModel originalReport;

  @override
  State<_EditReportForm> createState() => _EditReportFormState();
}

class _EditReportFormState extends State<_EditReportForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.originalReport.title);
    _descriptionController = TextEditingController(
      text: widget.originalReport.description,
    );
    _titleController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool _isFormDirty(EditReportController controller) {
    return _titleController.text.trim() != widget.originalReport.title ||
        _descriptionController.text.trim() !=
            widget.originalReport.description ||
        controller.category != widget.originalReport.category ||
        controller.locationAddress != widget.originalReport.locationAddress ||
        controller.newPhotos.isNotEmpty ||
        controller.existingPhotos.length !=
            widget.originalReport.photoUrls.length;
  }

  Future<bool> _confirmLeave(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Batalkan Perubahan?'),
        content: const Text(
          'Perubahan yang belum Anda simpan pada laporan ini akan hilang jika keluar sekarang.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Tetap Mengedit'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Batalkan Perubahan'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  void _submit() async {
    if (!context.isOnline) return;
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final controller = context.read<EditReportController>();
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

    final updated = await controller.submitUpdate(
      currentUserId: user.id,
      title: _titleController.text,
      description: _descriptionController.text,
    );

    if (!mounted) return;

    if (updated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perubahan laporan berhasil disimpan.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Gagal menyimpan perubahan laporan.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<EditReportController>();
    final isOnline = context.isOnline;

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
        appBar: AppBar(title: const Text('Edit Laporan')),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Judul Laporan
                TextFormField(
                  controller: _titleController,
                  validator: AppValidators.validateTitle,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Judul Laporan *',
                    hintText: 'Contoh: Jalan Berlubang di Simpang Lima',
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Kategori Masalah
                ReportCategoryPicker(
                  selectedCategory: controller.category,
                  onChanged: controller.setCategory,
                ),
                const SizedBox(height: 16),

                // 3. Lokasi Kejadian (Jawa Tengah)
                ReportLocationPicker(
                  address: controller.locationAddress,
                  latitude: controller.latitude,
                  longitude: controller.longitude,
                  areaName: controller.areaName,
                  onLocationChanged: (address, lat, lng, areaName) {
                    controller.setLocation(
                      address: address,
                      lat: lat,
                      lng: lng,
                      areaName: areaName,
                    );
                  },
                ),
                const SizedBox(height: 16),

                // 4. Pengelolaan Foto (Tersimpan & Baru)
                EditReportMediaManager(
                  existingPhotos: controller.existingPhotos,
                  newPhotos: controller.newPhotos,
                  onRemoveExistingPhoto: controller.removeExistingPhoto,
                  onAddNewPhoto: controller.addNewPhoto,
                  onRemoveNewPhoto: controller.removeNewPhoto,
                ),
                const SizedBox(height: 16),

                // 5. Deskripsi Masalah
                TextFormField(
                  controller: _descriptionController,
                  validator: AppValidators.validateDescription,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi Masalah *',
                    hintText:
                        'Jelaskan rincian dan kronologi masalah fasilitas...',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),

                // 6. Tombol Simpan
                AppButton(
                  text: 'Simpan Perubahan',
                  isLoading: controller.isLoading,
                  onPressed: isOnline && !controller.isLoading ? _submit : null,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
