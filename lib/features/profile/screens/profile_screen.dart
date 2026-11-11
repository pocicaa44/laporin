import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/user_profile_model.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/services/network_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/set_username_screen.dart';
import '../../my_reports/screens/my_reports_screen.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../navigation/widgets/app_drawer.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/profile_photo_detail_dialog.dart';
import 'edit_profile_screen.dart';

/// Profile & Settings screen with role indicator, username display, and avatar preview detail
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showAvatarDetail(BuildContext context, UserProfileModel? user) {
    ProfilePhotoDetailDialog.show(context: context, avatarUrl: user?.avatarUrl);
  }

  Future<void> _handleLogout(BuildContext context, AuthController auth) async {
    if (auth.isLoading) return;

    final rootNav = Navigator.of(context, rootNavigator: true);
    var isDialogShowing = true;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;

    // Dialog loading non-dismissible langsung muncul saat tombol logout ditekan
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: dialogBg,
          shape: const RoundedRectangleBorder(borderRadius: AppRadius.dialog),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sedang logout',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).then((_) {
      isDialogShowing = false;
    });

    try {
      try {
        context.read<NavigationController>().resetToHome();
      } catch (_) {}
      await auth.signOut();
    } finally {
      final nav = rootNav.mounted
          ? rootNav
          : FcmService.navigatorKey.currentState;
      if (nav != null) {
        if (!auth.isAuthenticated) {
          nav.popUntil((route) => route.isFirst);
        } else if (isDialogShowing && nav.canPop()) {
          nav.pop();
          isDialogShowing = false;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isOnline = context.isOnline;
    final user = auth.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.border;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: const Text('Profil Saya'),
      ),
      body: RefreshIndicator(
        onRefresh: () => auth.refreshProfile(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: AppRadius.card,
                border: Border.all(color: cardBorder),
              ),
              child: Row(
                children: [
                  UserAvatar(
                    name: user?.fullName ?? 'Warga Laporin',
                    username: user?.username,
                    avatarUrl: user?.avatarUrl,
                    radius: 36,
                    showEditBadge: false,
                    isLoading: false,
                    onTap: () => _showAvatarDetail(context, user),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName.isNotEmpty == true
                              ? user!.fullName
                              : (auth.isAuthenticated
                                    ? 'Warga Laporin'
                                    : 'Tamu'),
                          style: AppTextStyles.sectionTitleOf(context),
                        ),
                        const SizedBox(height: 3),
                        // Username display with robust fallback handling
                        if (auth.isLoading)
                          Row(
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Memuat username...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: textSecondary,
                                ),
                              ),
                            ],
                          )
                        else if (user != null &&
                            user.username.trim().isNotEmpty)
                          Text(
                            '@${user.username.trim().replaceFirst('@', '')}',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: primaryColor,
                            ),
                          )
                        else if (auth.isAuthenticated)
                          Row(
                            children: [
                              Text(
                                '@belum_diset',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const SetUsernameScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Setel Sekarang',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: primaryColor,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            '@tamu',
                            style: TextStyle(
                              fontSize: 13,
                              color: textSecondary,
                            ),
                          ),
                        if (user?.email.isNotEmpty == true) ...[
                          const SizedBox(height: 3),
                          Text(
                            user!.email,
                            style: AppTextStyles.captionOf(context),
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: auth.isAdmin
                                    ? (isDark
                                        ? AppColors.darkWarningSubtle
                                        : const Color(0xFFFEF8E7))
                                    : (isDark
                                        ? AppColors.darkPrimarySoft
                                        : AppColors.primarySoft),
                                borderRadius: AppRadius.pill,
                              ),
                              child: Text(
                                auth.isAdmin
                                    ? 'Peran: Petugas / Admin'
                                    : 'Peran: Warga',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: auth.isAdmin
                                      ? (isDark
                                          ? AppColors.darkWarningText
                                          : const Color(0xFFD98205))
                                      : (isDark
                                          ? AppColors.darkPrimaryLight
                                          : AppColors.primaryStrong),
                                ),
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
            const SizedBox(height: 24),

            // Menu Options
            if (auth.isAuthenticated)
              _ProfileMenuItem(
                icon: FontAwesomeIcons.userPen,
                title: 'Edit Profil',
                subtitle: isOnline
                    ? 'Ubah foto profil dan username Anda'
                    : 'Edit profil dinonaktifkan saat offline',
                isEnabled: isOnline,
                onTap: isOnline
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const EditProfileScreen(),
                          ),
                        );
                      }
                    : null,
              ),

            if (!auth.isAdmin)
              _ProfileMenuItem(
                icon: FontAwesomeIcons.clipboardList,
                title: 'Laporan Saya',
                subtitle: 'Pantau laporan yang pernah Anda buat',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MyReportsScreen()),
                  );
                },
              ),

            _ProfileMenuItem(
              icon: FontAwesomeIcons.gear,
              title: 'Pengaturan',
              subtitle: 'Tema tampilan, notifikasi, dan tentang aplikasi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),

            const SizedBox(height: 12),
            _ProfileMenuItem(
              icon: FontAwesomeIcons.arrowRightFromBracket,
              title: 'Keluar',
              iconColor: AppColors.danger,
              textColor: AppColors.danger,
              onTap: auth.isLoading
                  ? () {}
                  : () => _handleLogout(context, auth),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.iconColor,
    this.textColor,
    this.isEnabled = true,
    required this.onTap,
  });

  final FaIconData icon;
  final String title;
  final String? subtitle;
  final Color? iconColor;
  final Color? textColor;
  final bool isEnabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultPrimary =
        isDark ? AppColors.darkPrimary : AppColors.primary;
    final defaultTextPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final defaultTextSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final defaultDisabled =
        isDark ? AppColors.darkDisabled : AppColors.disabled;
    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final cardBorder = isDark ? AppColors.darkBorder : AppColors.border;

    final effectiveIconColor = isEnabled
        ? (iconColor ?? defaultPrimary)
        : defaultDisabled;
    final effectiveTextColor = isEnabled
        ? (textColor ?? defaultTextPrimary)
        : defaultTextSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: AppRadius.button,
        border: Border.all(color: cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.button,
        child: ListTile(
          onTap: isEnabled ? onTap : null,
          leading: FaIcon(icon, color: effectiveIconColor, size: 18),
          title: Text(
            title,
            style: AppTextStyles.label.copyWith(color: effectiveTextColor),
          ),
          subtitle: subtitle != null
              ? Text(subtitle!, style: AppTextStyles.captionOf(context))
              : null,
          trailing: isEnabled
              ? FaIcon(
                  FontAwesomeIcons.chevronRight,
                  size: 14,
                  color: defaultTextSecondary,
                )
              : null,
        ),
      ),
    );
  }
}
