import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
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
    final surfaceColor = AppColors.surfaceOf(context);
    final borderColor = AppColors.borderOf(context);
    final textSecondary = AppColors.textSecondaryOf(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori Masalah *', style: AppTextStyles.labelOf(context)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: AppRadius.input,
            border: Border.all(color: borderColor, width: 1),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: selectedCategory,
              isExpanded: true,
              dropdownColor: surfaceColor,
              icon: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: textSecondary,
              ),
              items: availableCategories.map((category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category, style: AppTextStyles.bodyOf(context)),
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
