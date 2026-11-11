import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_image.dart';
import '../../../data/models/report_model.dart';
import '../../auth/controllers/auth_controller.dart';

/// Modal bottom sheet for resolving report with mandatory proof per PRD FR-08 & DESIGN 5.9
class AdminResolveSheet extends StatefulWidget {
  const AdminResolveSheet({
    super.key,
    required this.report,
    this.initialProofUrl,
  });

  final ReportModel report;
  final String? initialProofUrl;

  @override
  State<AdminResolveSheet> createState() => _AdminResolveSheetState();
}

class _AdminResolveSheetState extends State<AdminResolveSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _notesController;

  XFile? _selectedImage;
  String? _proofUrl;
  String? _proofError;
  bool _isUploading = false;

  static const List<String> _resolutionTemplates = [
    'Pekerjaan perbaikan telah selesai',
    'Permasalahan telah berhasil ditangani',
    'Keluhan telah ditindaklanjuti dan diselesaikan',
    'Tindak lanjut atas laporan telah selesai dilakukan',
  ];

  @override
  void initState() {
    super.initState();
    _proofUrl = widget.initialProofUrl;
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await MediaService.instance.pickImage(source);
      if (file != null && mounted) {
        setState(() {
          _selectedImage = file;
          _proofError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  Future<void> _showImageSourcePicker(BuildContext context) async {
    final primaryColor = AppColors.primaryOf(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Foto Bukti',
                style: AppTextStyles.sectionTitleOf(context),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryColor),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: Icon(
                  Icons.photo_library,
                  color: primaryColor,
                ),
                title: const Text('Pilih dari Galeri Perangkat'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) {
      await _pickImage(source);
    }
  }

  void _applyTemplate(String template) {
    setState(() {
      _notesController.text = template;
      _notesController.selection = TextSelection.fromPosition(
        TextPosition(offset: _notesController.text.length),
      );
    });
  }

  Future<void> _submit() async {
    setState(() {
      _proofError = null;
    });

    final hasProof =
        _selectedImage != null || (_proofUrl != null && _proofUrl!.isNotEmpty);
    if (!hasProof) {
      setState(() {
        _proofError = 'Foto bukti penyelesaian wajib dilampirkan.';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
    });

    try {
      String finalProofUrl = _proofUrl ?? '';

      if (_selectedImage != null) {
        String authorId = widget.report.authorId;
        try {
          final auth = Provider.of<AuthController>(context, listen: false);
          if (auth.currentUser?.id != null) {
            authorId = auth.currentUser!.id;
          }
        } catch (_) {}

        finalProofUrl = await MediaService.instance.uploadPhoto(
          authorId: authorId,
          file: _selectedImage!,
          index: 0,
        );
      }

      if (!mounted) return;

      Navigator.pop(context, {
        'proofUrl': finalProofUrl,
        'notes': _notesController.text.trim(),
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunggah foto bukti: $e'),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasProof =
        _selectedImage != null || (_proofUrl != null && _proofUrl!.isNotEmpty);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final textPrimary = AppColors.textPrimaryOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;
    final dangerSubtle = isDark ? AppColors.darkDangerSubtle : const Color(0xFFFDECEE);

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Selesaikan Laporan',
                    style: AppTextStyles.pageTitleOf(context),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.report.reportNumber} - ${widget.report.title}',
                style: AppTextStyles.captionOf(context),
              ),
              const SizedBox(height: 16),

              // Mandatory Proof Image Header
              Row(
                children: [
                  Text(
                    'Foto Bukti Penyelesaian',
                    style: AppTextStyles.labelOf(context),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '* (Wajib)',
                    style: TextStyle(
                      color: dangerColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Proof Image Picker / Preview
              if (!hasProof)
                InkWell(
                  key: const Key('admin_proof_picker_button'),
                  onTap: () => _showImageSourcePicker(context),
                  borderRadius: AppRadius.card,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: 24,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: _proofError != null
                          ? dangerSubtle
                          : surfaceColor,
                      borderRadius: AppRadius.card,
                      border: Border.all(
                        color: _proofError != null
                            ? dangerColor
                            : borderColor,
                        width: _proofError != null ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo_outlined,
                          size: 36,
                          color: _proofError != null
                              ? dangerColor
                              : primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Pilih / Ambil Foto Bukti Penyelesaian',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _proofError != null
                                ? dangerColor
                                : textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wajib menyertakan foto hasil pekerjaan selesai (Kamera/Galeri)',
                          style: AppTextStyles.captionOf(context).copyWith(
                            color: _proofError != null
                                ? dangerColor
                                : textSecondary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              else
                ClipRRect(
                  borderRadius: AppRadius.card,
                  child: Stack(
                    children: [
                      AspectRatio(
                        aspectRatio: 16 / 9,
                        child: AppImage(
                          imageSource: _selectedImage?.path ?? _proofUrl ?? '',
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: IconButton(
                                key: const Key('admin_proof_replace_button'),
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                tooltip: 'Ganti Foto',
                                onPressed: () =>
                                    _showImageSourcePicker(context),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Material(
                              color: Colors.black54,
                              shape: const CircleBorder(),
                              child: IconButton(
                                key: const Key('admin_proof_delete_button'),
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                tooltip: 'Hapus Foto',
                                onPressed: () {
                                  setState(() {
                                    _selectedImage = null;
                                    _proofUrl = null;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: const BoxDecoration(
                            color: Color(0xBF000000),
                            borderRadius: AppRadius.pill,
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 14,
                                color: AppColors.success,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Bukti Foto Terlampir',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_proofError != null) ...[
                const SizedBox(height: 6),
                Text(
                  _proofError!,
                  key: const Key('admin_proof_error_text'),
                  style: TextStyle(
                    color: dangerColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // Template Catatan Penyelesaian
              Row(
                children: [
                  Icon(Icons.bolt, size: 16, color: primaryColor),
                  const SizedBox(width: 4),
                  Text(
                    'Pilih Template Catatan:',
                    style: AppTextStyles.labelOf(context).copyWith(fontSize: 13),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _resolutionTemplates.map((template) {
                  final isSelected = _notesController.text.trim() == template;
                  return InkWell(
                    key: Key('template_chip_$template'),
                    onTap: () => _applyTemplate(template),
                    borderRadius: AppRadius.pill,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor
                            : surfaceColor,
                        borderRadius: AppRadius.pill,
                        border: Border.all(
                          color: isSelected
                              ? primaryColor
                              : borderColor,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSelected
                                ? Icons.check
                                : Icons.format_quote_rounded,
                            size: 14,
                            color: isSelected
                                ? Colors.white
                                : primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              template,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.white
                                    : textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Message Box Catatan Penanganan
              TextFormField(
                key: const Key('admin_resolve_notes_field'),
                controller: _notesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan Penanganan *',
                  hintText: 'Uraikan hasil pekerjaan penyelesaian atau pilih template di atas...',
                  alignLabelWithHint: true,
                ),
                validator: (v) =>
                    AppValidators.validateRequired(v, 'Catatan penanganan'),
              ),
              const SizedBox(height: 24),

              AppButton(
                key: const Key('admin_confirm_resolve_button'),
                text: 'Konfirmasi Selesai',
                isLoading: _isUploading,
                onPressed: _isUploading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
