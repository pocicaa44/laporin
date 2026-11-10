import 'package:flutter/material.dart';

import '../../../core/config/indonesia_regions.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../controllers/admin_report_controller.dart';

/// Komponen Dropdown Filter Wilayah Provinsi untuk Panel Feed Admin (< 150 baris per skills.md)
class AdminProvinceFilterDropdown extends StatelessWidget {
  const AdminProvinceFilterDropdown({
    super.key,
    required this.controller,
  });

  final AdminReportController controller;

  @override
  Widget build(BuildContext context) {
    final selectedId = controller.selectedProvinceId;
    final isFiltered = selectedId != null && selectedId.isNotEmpty && selectedId != 'all';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isFiltered ? AppColors.primary : AppColors.border,
          width: isFiltered ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.location_on_outlined,
            size: 20,
            color: isFiltered ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Text(
            'Wilayah:',
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String?>(
                key: const Key('admin_province_filter_dropdown'),
                isExpanded: true,
                value: selectedId,
                icon: const Icon(
                  Icons.arrow_drop_down_rounded,
                  color: AppColors.textSecondary,
                ),
                style: AppTextStyles.bodyRegular.copyWith(
                  fontWeight: isFiltered ? FontWeight.w600 : FontWeight.normal,
                  color: isFiltered ? AppColors.primary : AppColors.textPrimary,
                  fontSize: 13,
                ),
                hint: const Text(
                  'Semua Provinsi (Nasional)',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'Semua Provinsi (Nasional)',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...IndonesiaRegions.provinces.map((prov) {
                    return DropdownMenuItem<String?>(
                      value: prov.id,
                      child: Text(
                        prov.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }),
                ],
                onChanged: (newId) {
                  controller.setProvinceFilter(newId);
                },
              ),
            ),
          ),
          if (isFiltered)
            IconButton(
              icon: const Icon(Icons.close_rounded, size: 18),
              tooltip: 'Reset Filter Provinsi',
              color: AppColors.textSecondary,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              onPressed: () => controller.setProvinceFilter(null),
            ),
        ],
      ),
    );
  }
}
