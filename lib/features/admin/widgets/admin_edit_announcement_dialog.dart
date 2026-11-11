import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/announcement_model.dart';
import '../controllers/admin_announcement_controller.dart';

/// Dialog untuk mengedit judul, kategori, dan isi pengumuman resmi oleh admin
class AdminEditAnnouncementDialog extends StatefulWidget {
  const AdminEditAnnouncementDialog({
    super.key,
    required this.announcement,
    required this.controller,
  });

  final AnnouncementModel announcement;
  final AdminAnnouncementController controller;

  @override
  State<AdminEditAnnouncementDialog> createState() =>
      _AdminEditAnnouncementDialogState();
}

class _AdminEditAnnouncementDialogState
    extends State<AdminEditAnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _selectedCategory;
  late final List<String> _categories;
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
    return Dialog(
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 540,
        constraints: const BoxConstraints(maxWidth: 540),
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Pengumuman',
                      style: AppTextStyles.sectionTitle,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: _isUpdating
                          ? null
                          : () => Navigator.of(context).pop(false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  enabled: !_isUpdating,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Judul Pengumuman *',
                    hintText: 'Contoh: Pemeliharaan Jalan Raya Solo-Semarang',
                  ),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return 'Judul pengumuman wajib diisi';
                    if (text.length < 5) return 'Judul minimal 5 karakter';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Kategori Pengumuman',
                  style: AppTextStyles.labelOf(context),
                ),
                const SizedBox(height: 6),
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
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimaryOf(context),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: AppColors.primaryOf(context),
                          backgroundColor: AppColors.surfaceOf(context),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.pill,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryOf(context)
                                  : AppColors.borderOf(context),
                            ),
                          ),
                          onSelected: _isUpdating
                              ? null
                              : (_) => setState(() => _selectedCategory = cat),
                          showCheckmark: false,
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _contentController,
                  enabled: !_isUpdating,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Isi Pengumuman *',
                    hintText:
                        'Tuliskan informasi resmi yang ingin disampaikan...',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) {
                    final text = v?.trim() ?? '';
                    if (text.isEmpty) return 'Isi pengumuman wajib diisi';
                    if (text.length < 10) {
                      return 'Isi pengumuman minimal 10 karakter';
                    }
                    return null;
                  },
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: AppRadius.sm,
                      border: Border.all(
                        color: AppColors.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: AppColors.danger,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(
                              color: AppColors.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isUpdating
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text(
                        'Batal',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadius.button,
                        ),
                      ),
                      onPressed: _isUpdating ? null : _handleUpdate,
                      child: _isUpdating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Simpan Perubahan'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
