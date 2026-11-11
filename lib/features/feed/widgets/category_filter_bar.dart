import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Category filter chip bar matching DESIGN.md Section 4.4
class CategoryFilterBar extends StatelessWidget {
  const CategoryFilterBar({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  static const List<String> categories = [
    'Semua',
    'Jalan & Infrastruktur',
    'Fasilitas Umum',
    'Kebersihan',
    'Lainnya',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activePrimary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final inactiveBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final inactiveBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final inactiveText =
        isDark ? AppColors.darkTextSecondary : AppColors.textPrimary;

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat == selectedCategory;

          return ChoiceChip(
            label: Text(
              cat,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? Colors.white : inactiveText,
              ),
            ),
            selected: isSelected,
            selectedColor: activePrimary,
            backgroundColor: inactiveBg,
            side: BorderSide(
              color: isSelected ? activePrimary : inactiveBorder,
              width: isSelected ? 1.5 : 1.0,
            ),
            shape: const StadiumBorder(),
            showCheckmark: false,
            onSelected: (_) => onCategorySelected(cat),
          );
        },
      ),
    );
  }
}
