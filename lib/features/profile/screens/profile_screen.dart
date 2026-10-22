import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../admin/screens/admin_dashboard_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/screens/app_gate.dart';
import '../../my_reports/screens/my_reports_screen.dart';

/// Profile & Settings screen with role indicator and admin panel access
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil Saya')),
      body: ListView(
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
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.primarySoft,
                  child: Text(
                    (user?.fullName.isNotEmpty ?? false)
                        ? user!.fullName[0].toUpperCase()
                        : 'W',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName
                            : (auth.isAuthenticated ? 'Warga Laporin' : 'Tamu'),
                        style: AppTextStyles.sectionTitle,
                      ),
                      if (user?.email.isNotEmpty == true) ...[
                        const SizedBox(height: 2),
                        Text(user!.email, style: AppTextStyles.caption),
                      ],
                      const SizedBox(height: 8),
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
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu Options
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

          if (auth.isAdmin)
            _ProfileMenuItem(
              icon: FontAwesomeIcons.userShield,
              title: 'Panel Petugas / Admin',
              subtitle: 'Kelola review, moderasi, dan status penanganan',
              badge: 'Admin',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminDashboardScreen(),
                  ),
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
            onTap: () async {
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
    );
  }
}

class _ProfileMenuItem extends StatelessWidget {
  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    this.badge,
    this.iconColor = AppColors.primary,
    this.textColor = AppColors.textPrimary,
    required this.onTap,
  });

  final FaIconData icon;
  final String title;
  final String? subtitle;
  final String? badge;
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
          title: Row(
            children: [
              Text(
                title,
                style: AppTextStyles.label.copyWith(color: textColor),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
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
