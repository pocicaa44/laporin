import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/admin_announcement_controller.dart';

/// Form pembuatan pengumuman resmi oleh admin (< 150 baris per skills.md)
class AdminAnnouncementForm extends StatefulWidget {
  const AdminAnnouncementForm({super.key});

  @override
  State<AdminAnnouncementForm> createState() => _AdminAnnouncementFormState();
}

class _AdminAnnouncementFormState extends State<AdminAnnouncementForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedCategory = 'Umum';

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

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthController>();
    final controller = context.read<AdminAnnouncementController>();
    final user = auth.currentUser;

    if (user == null || !auth.isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Hanya Petugas / Admin yang dapat menerbitkan pengumuman.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }

    final success = await controller.createAnnouncement(
      title: _titleController.text,
      content: _contentController.text,
      category: _selectedCategory,
      authorId: user.id,
      authorName: user.fullName.isNotEmpty ? user.fullName : 'Petugas Laporin',
    );

    if (!mounted) return;

    if (success) {
      _titleController.clear();
      _contentController.clear();
      setState(() => _selectedCategory = 'Umum');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengumuman resmi berhasil diterbitkan.'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            controller.errorMessage ?? 'Gagal menerbitkan pengumuman.',
          ),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminAnnouncementController>();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Buat Pengumuman Baru',
              style: AppTextStyles.sectionTitle,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
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
            const Text('Kategori Pengumuman', style: AppTextStyles.label),
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
                              : AppColors.textPrimary,
                        ),
                      ),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedCategory = cat),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contentController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Isi Pengumuman *',
                hintText: 'Tuliskan informasi resmi yang ingin disampaikan...',
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
            const SizedBox(height: 16),
            AppButton(
              text: 'Terbitkan Pengumuman',
              isLoading: controller.isSubmitting,
              onPressed: controller.isSubmitting ? () {} : _handleSubmit,
            ),
          ],
        ),
      ),
    );
  }
}
