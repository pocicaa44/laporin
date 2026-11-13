import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';

/// Sidebar navigasi desktop untuk admin per DESIGN.md Section 2.3
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.activeIndex,
    required this.onTabTapped,
  });

  final int activeIndex;
  final ValueChanged<int> onTabTapped;

  static const double width = 260.0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final borderSubtle = isDark ? AppColors.darkBorderSubtle : AppColors.borderSubtle;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textMuted = isDark ? AppColors.darkTextMuted : AppColors.textMuted;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: surfaceColor,
        border: Border(
          right: BorderSide(color: borderColor, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header & Brand Logo
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo_laporin.png',
                      width: 36,
                      height: 36,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.campaign_rounded,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Laporin',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                                letterSpacing: -0.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.darkPrimarySubtle
                                  : AppColors.primarySubtle,
                              borderRadius: AppRadius.pill,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.darkPrimary.withValues(alpha: 0.3)
                                    : AppColors.primary.withValues(alpha: 0.25),
                              ),
                            ),
                            child: Text(
                              'ADMIN',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                color: primaryColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Portal Petugas',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                          color: textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Divider(height: 1, thickness: 1, color: borderSubtle),

          // 2. Navigation Section Title
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Text(
              'MENU UTAMA',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: textMuted,
                letterSpacing: 0.8,
              ),
            ),
          ),

          // 3. Navigation Items (Beranda, Panel, Pengumuman, Profil)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Column(
              children: [
                _AdminSidebarItem(
                  icon: FontAwesomeIcons.house,
                  label: 'Beranda',
                  isSelected: activeIndex == 0,
                  onTap: () => onTabTapped(0),
                ),
                const SizedBox(height: 4),
                _AdminSidebarItem(
                  icon: FontAwesomeIcons.tableColumns,
                  label: 'Panel',
                  isSelected: activeIndex == 1,
                  onTap: () => onTabTapped(1),
                ),
                const SizedBox(height: 4),
                _AdminSidebarItem(
                  icon: FontAwesomeIcons.bullhorn,
                  label: 'Pengumuman',
                  isSelected: activeIndex == 2,
                  onTap: () => onTabTapped(2),
                ),
                const SizedBox(height: 4),
                _AdminSidebarItem(
                  icon: FontAwesomeIcons.chartSimple,
                  label: 'Statistik',
                  isSelected: activeIndex == 3,
                  onTap: () => onTabTapped(3),
                ),
                const SizedBox(height: 4),
                _AdminSidebarItem(
                  icon: FontAwesomeIcons.user,
                  label: 'Profil',
                  isSelected: activeIndex == 4,
                  onTap: () => onTabTapped(4),
                ),
              ],
            ),
          ),

          const Spacer(),
        ],
      ),
    );
  }
}

class _AdminSidebarItem extends StatelessWidget {
  const _AdminSidebarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final FaIconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final bgColor = isSelected
        ? (isDark
            ? AppColors.darkPrimarySubtle
            : AppColors.primarySubtle)
        : Colors.transparent;

    final itemColor = isSelected ? primaryColor : textSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? (isDark
                      ? AppColors.darkPrimary.withValues(alpha: 0.3)
                      : AppColors.primary.withValues(alpha: 0.25))
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 22,
                child: Center(
                  child: FaIcon(
                    icon,
                    size: 16,
                    color: itemColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: itemColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
