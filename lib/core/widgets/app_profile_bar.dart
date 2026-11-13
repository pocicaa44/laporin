import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../features/auth/controllers/auth_controller.dart';
import '../../features/navigation/controllers/navigation_controller.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import 'user_avatar.dart';

/// Bar profil pengguna di bilah atas aplikasi (AppBar / Titlebar) pada tampilan desktop
class AppProfileBar extends StatelessWidget {
  const AppProfileBar({super.key, this.onTap});

  final VoidCallback? onTap;

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    try {
      context.read<NavigationController>().setIndex(4);
    } catch (_) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;

    final auth = context.watch<AuthController>();
    final user = auth.currentUser;
    final isAdmin = auth.isAdmin;

    final displayName = user?.fullName.isNotEmpty == true
        ? user!.fullName
        : (isAdmin ? 'Petugas Admin' : 'Warga Laporin');

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      child: Tooltip(
        message: 'Buka Profil ($displayName)',
        child: InkWell(
          onTap: () => _handleTap(context),
          borderRadius: AppRadius.pill,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: AppRadius.pill,
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                UserAvatar(
                  name: displayName,
                  username: user?.username,
                  avatarUrl: user?.avatarUrl,
                  radius: 14,
                  showEditBadge: false,
                ),
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 160),
                  child: Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
