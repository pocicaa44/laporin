import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/announcement_model.dart';
import '../controllers/admin_announcement_controller.dart';
import '../widgets/announcement_image_picker.dart';

/// Halaman penuh (screen) untuk mengedit pengumuman resmi oleh admin
class AdminEditAnnouncementScreen extends StatefulWidget {
  const AdminEditAnnouncementScreen({
    super.key,
    required this.announcement,
    required this.controller,
  });

  final AnnouncementModel announcement;
  final AdminAnnouncementController controller;

  @override
  State<AdminEditAnnouncementScreen> createState() =>
      _AdminEditAnnouncementScreenState();
}

class _AdminEditAnnouncementScreenState
    extends State<AdminEditAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _selectedCategory;
  late final List<String> _categories;
  XFile? _newImageFile;
  bool _removeExistingImage = false;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement.title);
    _contentController = TextEditingController(
      text: widget.announcement.content,
    );
    _selectedCategory = widget.announcement.category;
    const defaultCategories = [
      'Umum',
      'Darurat',
      'Layanan Publik',
      'Pemeliharaan',
    ];
    if (!defaultCategories.contains(_selectedCategory) &&
        _selectedCategory.isNotEmpty) {
      _categories = [_selectedCategory, ...defaultCategories];
    } else {
      _categories = defaultCategories;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdate() async {
    if (_isUpdating) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    final success = await widget.controller.updateAnnouncement(
      id: widget.announcement.id,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      category: _selectedCategory,
      currentImageUrl: _removeExistingImage
          ? null
          : widget.announcement.imageUrl,
      newImageFile: _newImageFile,
      removeImage: _removeExistingImage && _newImageFile == null,
      authorId: widget.announcement.authorId,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isUpdating = false;
        _errorMessage =
            widget.controller.errorMessage ??
            'Gagal memperbarui pengumuman. Silakan coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);
    final surfaceColor = AppColors.surfaceOf(context);
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: _isUpdating
              ? null
              : () => Navigator.of(context).pop(false),
        ),
        title: const Text('Edit Pengumuman'),
      ),
      body: Container(
        color: isDark ? AppColors.darkBackground : const Color(0xFFF0F2F5),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 720),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border.symmetric(
                vertical: BorderSide(color: borderColor, width: 1),
              ),
            ),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: surfaceColor,
                      borderRadius: AppRadius.card,
                      border: Border.all(color: borderColor),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Informasi Pengumuman',
                          style: AppTextStyles.sectionTitleOf(context),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Perbarui informasi pengumuman resmi agar warga mendapatkan data yang akurat.',
                          style: AppTextStyles.captionOf(context),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _titleController,
                          enabled: !_isUpdating,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'Judul Pengumuman *',
                            hintText:
                                'Contoh: Pemeliharaan Jalan Raya Solo-Semarang',
                          ),
                          validator: (v) {
                            final text = v?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Judul pengumuman wajib diisi';
                            }
                            if (text.length < 5) {
                              return 'Judul minimal 5 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Kategori Pengumuman',
                          style: AppTextStyles.labelOf(context),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _categories.map((cat) {
                              final isSelected = cat == _selectedCategory;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    cat,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : textPrimary,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: primaryColor,
                                  backgroundColor: surfaceColor,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: AppRadius.pill,
                                    side: BorderSide(
                                      color: isSelected
                                          ? primaryColor
                                          : borderColor,
                                    ),
                                  ),
                                  onSelected: _isUpdating
                                      ? null
                                      : (_) => setState(
                                          () => _selectedCategory = cat,
                                        ),
                                  showCheckmark: false,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contentController,
                          enabled: !_isUpdating,
                          maxLines: 6,
                          decoration: const InputDecoration(
                            labelText: 'Isi Pengumuman *',
                            hintText: 'Tuliskan informasi resmi yang ingin disampaikan secara lengkap...',
                            alignLabelWithHint: true,
                          ),
                          validator: (v) {
                            final text = v?.trim() ?? '';
                            if (text.isEmpty) {
                              return 'Isi pengumuman wajib diisi';
                            }
                            if (text.length < 10) {
                              return 'Isi pengumuman minimal 10 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        Text(
                          'Media Gambar (Opsional)',
                          style: AppTextStyles.labelOf(context),
                        ),
                        const SizedBox(height: 8),
                        AnnouncementImagePicker(
                          initialImageUrl: _removeExistingImage
                              ? null
                              : widget.announcement.imageUrl,
                          selectedFile: _newImageFile,
                          onImageSelected: (file) {
                            setState(() {
                              _newImageFile = file;
                              _removeExistingImage = false;
                            });
                          },
                          onImageRemoved: () {
                            setState(() {
                              _newImageFile = null;
                              _removeExistingImage = true;
                            });
                          },
                        ),
                        if (_errorMessage != null) ...[
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: 0.1),
                              borderRadius: AppRadius.input,
                              border: Border.all(
                                color: AppColors.danger.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  size: 18,
                                  color: AppColors.danger,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(
                                      color: AppColors.danger,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                text: 'Batal',
                                variant: AppButtonVariant.secondary,
                                onPressed: _isUpdating
                                    ? null
                                    : () => Navigator.of(context).pop(false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: AppButton(
                                text: 'Simpan Perubahan',
                                icon: Icons.check_circle_outline_rounded,
                                isLoading: _isUpdating,
                                onPressed: _isUpdating ? null : _handleUpdate,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
