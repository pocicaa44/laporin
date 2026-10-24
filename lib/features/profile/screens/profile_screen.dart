import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/user_avatar.dart';
import '../../../data/models/user_profile_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/app_gate.dart';
import '../../auth/screens/set_username_screen.dart';
import '../../my_reports/screens/my_reports_screen.dart';
import '../../navigation/widgets/app_drawer.dart';
import 'edit_profile_screen.dart';

/// Profile & Settings screen with role indicator, username display, and avatar preview detail
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showAvatarDetail(BuildContext context, UserProfileModel? user) {
    final avatarUrl = user?.avatarUrl?.trim();
    final hasCustomAvatar = avatarUrl != null && avatarUrl.isNotEmpty;

    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (ctx) {
        final screenWidth = MediaQuery.of(ctx).size.width;
        final size = (screenWidth * 0.8).clamp(220.0, 320.0);

        return Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(24),
          child: Center(
            child: GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: ClipRRect(
                child: Container(
                  width: size,
                  height: size,
                  color: Colors.white,
                  child: hasCustomAvatar
                      ? AppImage(
                          imageSource: avatarUrl,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                          placeholder: Image.asset(
                            UserAvatar.defaultAvatarAsset,
                            width: size,
                            height: size,
                            fit: BoxFit.cover,
                          ),
                          errorWidget: Image.asset(
                            UserAvatar.defaultAvatarAsset,
                            width: size,
                            height: size,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          UserAvatar.defaultAvatarAsset,
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: const Text('Profil Saya'),
      ),
      body: RefreshIndicator(
        onRefresh: () => auth.refreshProfile(),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          children: [
            // User Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
                boxShadow: const [AppColors.cardShadow],
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
                          style: AppTextStyles.sectionTitle,
                        ),
                        const SizedBox(height: 3),
                        // Username display with robust fallback handling
                        if (auth.isLoading)
                          const Row(
                            children: [
                              SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Memuat username...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          )
                        else if (user != null &&
                            user.username.trim().isNotEmpty)
                          Text(
                            '@${user.username.trim().replaceFirst('@', '')}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          )
                        else if (auth.isAuthenticated)
                          Row(
                            children: [
                              const Text(
                                '@belum_diset',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textSecondary,
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
                                child: const Text(
                                  'Setel Sekarang',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          const Text(
                            '@tamu',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        if (user?.email.isNotEmpty == true) ...[
                          const SizedBox(height: 3),
                          Text(user!.email, style: AppTextStyles.caption),
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
                                    ? const Color(0xFFFEF8E7)
                                    : AppColors.primarySoft,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                auth.isAdmin
                                    ? 'Peran: Petugas / Admin'
                                    : 'Peran: Warga',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: auth.isAdmin
                                      ? const Color(0xFFD98205)
                                      : AppColors.primaryStrong,
                                ),
                              ),
                            ),
                            if (auth.isAuthenticated)
                              OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const EditProfileScreen(),
                                    ),
                                  );
                                },
                                icon: const FaIcon(
                                  FontAwesomeIcons.penToSquare,
                                  size: 11,
                                ),
                                label: const Text(
                                  'Edit Profil',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  side: const BorderSide(
                                    color: AppColors.primary,
                                    width: 1.2,
                                  ),
                                  foregroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
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
                subtitle: 'Ubah foto profil dan username Anda',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const EditProfileScreen(),
                    ),
                  );
                },
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
              icon: FontAwesomeIcons.circleInfo,
              title: 'Tentang Aplikasi Laporin',
              subtitle: 'Versi 1.0.0 (MVP Pelaporan Fasilitas Publik)',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'Laporin',
                  applicationVersion: '1.0.0 (MVP)',
                  applicationIcon: Image.asset(
                    'assets/logo_laporin.png',
                    width: 48,
                    height: 48,
                  ),
                  children: const [
                    Text(
                      'Aplikasi pelaporan masalah publik transparan berbasis geospasial, moderasi komunitas, dan akuntabilitas penanganan instansi.',
                    ),
                  ],
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
                  : () async {
                      await auth.signOut();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (_) => const AppGate()),
                          (route) => false,
                        );
                      }
                    },
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
    this.iconColor = AppColors.primary,
    this.textColor = AppColors.textPrimary,
    required this.onTap,
  });

  final FaIconData icon;
  final String title;
  final String? subtitle;
  final Color iconColor;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          onTap: onTap,
          leading: FaIcon(icon, color: iconColor, size: 18),
          title: Text(
            title,
            style: AppTextStyles.label.copyWith(color: textColor),
          ),
          subtitle: subtitle != null
              ? Text(subtitle!, style: AppTextStyles.caption)
              : null,
          trailing: const FaIcon(
            FontAwesomeIcons.chevronRight,
            size: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
