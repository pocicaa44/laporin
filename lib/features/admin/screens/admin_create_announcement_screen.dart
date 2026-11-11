import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/admin_announcement_controller.dart';
import '../widgets/announcement_image_picker.dart';

/// Halaman penuh untuk membuat dan menerbitkan pengumuman resmi baru oleh admin
class AdminCreateAnnouncementScreen extends StatefulWidget {
  const AdminCreateAnnouncementScreen({super.key, required this.controller});

  final AdminAnnouncementController controller;

  @override
  State<AdminCreateAnnouncementScreen> createState() =>
      _AdminCreateAnnouncementScreenState();
}

class _AdminCreateAnnouncementScreenState
    extends State<AdminCreateAnnouncementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'Umum';
  XFile? _selectedImage;
  bool _isPublishing = false;
  String? _errorMessage;

  final List<String> _categories = const [
    'Umum',
    'Darurat',
    'Layanan Publik',
    'Pemeliharaan',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handlePublish() async {
    if (_isPublishing) return;
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final user = auth.currentUser;

    if (user == null || !auth.isAdmin) {
      setState(() {
        _errorMessage =
            'Hanya Petugas / Admin yang memiliki akses menerbitkan pengumuman.';
      });
      return;
    }

    setState(() {
      _isPublishing = true;
      _errorMessage = null;
    });

    final success = await widget.controller.createAnnouncement(
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      category: _selectedCategory,
      authorId: user.id,
      authorName: user.fullName.isNotEmpty ? user.fullName : 'Petugas Laporin',
      imageFile: _selectedImage,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isPublishing = false;
        _errorMessage =
            widget.controller.errorMessage ??
            'Gagal menerbitkan pengumuman. Periksa kembali jaringan Anda.';
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
          onPressed: _isPublishing
              ? null
              : () => Navigator.of(context).pop(false),
        ),
        title: const Text('Tambah Pengumuman'),
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
                          'Sampaikan informasi resmi kepada seluruh warga dalam jangkauan aplikasi.',
                          style: AppTextStyles.captionOf(context),
                        ),
                        const SizedBox(height: 18),
                        TextFormField(
                          controller: _titleController,
                          enabled: !_isPublishing,
                          maxLength: 100,
                          decoration: const InputDecoration(
                            labelText: 'Judul Pengumuman *',
                            hintText: 'Contoh: Pemadaman Listrik Sementara',
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
                                  onSelected: _isPublishing
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
                          enabled: !_isPublishing,
                          maxLines: 5,
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
                          selectedFile: _selectedImage,
                          onImageSelected: (file) =>
                              setState(() => _selectedImage = file),
                          onImageRemoved: () =>
                              setState(() => _selectedImage = null),
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
                                onPressed: _isPublishing
                                    ? null
                                    : () => Navigator.of(context).pop(false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 2,
                              child: AppButton(
                                text: 'Terbitkan Pengumuman',
                                icon: Icons.campaign_rounded,
                                isLoading: _isPublishing,
                                onPressed: _isPublishing
                                    ? null
                                    : _handlePublish,
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
