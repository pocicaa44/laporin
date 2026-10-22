import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Modular widget for selecting report category per skills.md (< 100 lines)
class ReportCategoryPicker extends StatelessWidget {
  const ReportCategoryPicker({
    super.key,
    required this.selectedCategory,
    required this.onChanged,
  });

  final String selectedCategory;
  final ValueChanged<String> onChanged;

  static const List<String> availableCategories = [
    'Jalan & Infrastruktur',
    'Fasilitas Umum',
    'Kebersihan',
    'Taman & Lingkungan',
    'Keamanan & Ketertiban',
    'Lainnya',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Kategori Masalah *', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textSecondary,
              ),
              items: availableCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category, style: AppTextStyles.body),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) onChanged(val);
              },
            ),
          ),
        ),
      ],
    );
  }
}
