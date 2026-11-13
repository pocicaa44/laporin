import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';

/// Screen for managing user preferences including theme mode, notification settings,
/// and displaying information about the Laporin application.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final settings = context.watch<SettingsController>();
    final auth = Provider.of<AuthController?>(context);
    final isAdmin = auth?.isAdmin ?? false;

    final cardBg = isDark ? AppColors.darkSurface : AppColors.surface;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final titleColor = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final bodyColor = isDark ? AppColors.darkTextBody : AppColors.textBody;
    final mutedColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(maxWidth: isDesktop ? 760 : double.infinity),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
          // ==========================================
          // SECTION 1: TEMA TAMPILAN
          // ==========================================
          _buildSectionHeader(
            icon: FaIcon(FontAwesomeIcons.palette, size: 14, color: titleColor),
            title: 'Tema & Tampilan',
            titleColor: titleColor,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: AppRadius.card,
              border: Border.all(color: borderColor),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pilih Mode Tampilan',
                  style: AppTextStyles.h3.copyWith(
                    color: titleColor,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sesuaikan pencahayaan aplikasi agar nyaman di mata saat siang maupun malam hari.',
                  style: AppTextStyles.caption.copyWith(color: mutedColor),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ThemeOptionCard(
                        icon: Icons.brightness_auto,
                        label: 'Sistem',
                        isSelected: settings.themeMode == ThemeMode.system,
                        onTap: () => settings.setThemeMode(ThemeMode.system),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeOptionCard(
                        icon: Icons.light_mode,
                        label: 'Terang',
                        isSelected: settings.themeMode == ThemeMode.light,
                        onTap: () => settings.setThemeMode(ThemeMode.light),
                        isDark: isDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ThemeOptionCard(
                        icon: Icons.dark_mode,
                        label: 'Gelap',
                        isSelected: settings.themeMode == ThemeMode.dark,
                        onTap: () => settings.setThemeMode(ThemeMode.dark),
                        isDark: isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================
          // SECTION 2: NOTIFIKASI
          // ==========================================
          _buildSectionHeader(
            icon: FaIcon(FontAwesomeIcons.bell, size: 14, color: titleColor),
            title: 'Notifikasi',
            titleColor: titleColor,
          ),
          const SizedBox(height: 10),
          Material(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.card,
              side: BorderSide(color: borderColor),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Master Notification Switch
                SwitchListTile.adaptive(
                  value: settings.notificationsEnabled,
                  onChanged: (val) => settings.setNotificationsEnabled(val),
                  title: Text(
                    'Aktifkan Notifikasi',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: titleColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Terima pemberitahuan langsung pada perangkat ini.',
                    style: AppTextStyles.caption.copyWith(color: mutedColor),
                  ),
                  activeThumbColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                ),
                Divider(color: borderColor, height: 1),

                if (isAdmin) ...[
                  // 1. Notif Laporan Masuk
                  _NotificationToggleTile(
                    icon: FontAwesomeIcons.fileLines,
                    iconColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                    title: 'Laporan Masuk',
                    subtitle: 'Pemberitahuan saat warga mengirimkan laporan baru untuk ditinjau.',
                    value: settings.notifyNewReports,
                    isEnabled: settings.notificationsEnabled,
                    onChanged: (val) => settings.setNotifyNewReports(val),
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                  Divider(color: borderColor, height: 1),

                  // 2. Notif Pengumuman
                  _NotificationToggleTile(
                    icon: FontAwesomeIcons.bullhorn,
                    iconColor: isDark ? AppColors.darkInfo : AppColors.info,
                    title: 'Pengumuman',
                    subtitle: 'Pemberitahuan siaran pengumuman resmi dan informasi publik.',
                    value: settings.notifyAnnouncements,
                    isEnabled: settings.notificationsEnabled,
                    onChanged: (val) => settings.setNotifyAnnouncements(val),
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                  Divider(color: borderColor, height: 1),

                  // 3. Notif Balasan
                  _NotificationToggleTile(
                    icon: FontAwesomeIcons.reply,
                    iconColor: isDark ? AppColors.darkSuccess : AppColors.success,
                    title: 'Balasan',
                    subtitle: 'Pemberitahuan saat ada balasan tanggapan baru dari warga.',
                    value: settings.notifyReplies,
                    isEnabled: settings.notificationsEnabled,
                    onChanged: (val) => settings.setNotifyReplies(val),
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                ] else ...[
                  // Sub-toggle: Pengumuman Masuk
                  _NotificationToggleTile(
                    icon: FontAwesomeIcons.bullhorn,
                    iconColor: isDark ? AppColors.darkInfo : AppColors.info,
                    title: 'Pengumuman Masuk',
                    subtitle: 'Siaran berita resmi dari administrator dan instansi pemerintah.',
                    value: settings.notifyAnnouncements,
                    isEnabled: settings.notificationsEnabled,
                    onChanged: (val) => settings.setNotifyAnnouncements(val),
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                  Divider(color: borderColor, height: 1),

                  // Sub-toggle: Perubahan Status
                  _NotificationToggleTile(
                    icon: FontAwesomeIcons.arrowsRotate,
                    iconColor: isDark ? AppColors.darkWarning : AppColors.warning,
                    title: 'Perubahan Status Laporan',
                    subtitle: 'Update saat laporan Anda diterima, diproses, selesai, atau ditolak.',
                    value: settings.notifyStatusChanges,
                    isEnabled: settings.notificationsEnabled,
                    onChanged: (val) => settings.setNotifyStatusChanges(val),
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                  Divider(color: borderColor, height: 1),

                  // Sub-toggle: Dukungan Warga (Upvote)
                  _NotificationToggleTile(
                    icon: FontAwesomeIcons.thumbsUp,
                    iconColor: isDark ? AppColors.darkSuccess : AppColors.success,
                    title: 'Dukungan Warga',
                    subtitle: 'Pemberitahuan saat warga lain mendukung (upvote) laporan Anda.',
                    value: settings.notifySupports,
                    isEnabled: settings.notificationsEnabled,
                    onChanged: (val) => settings.setNotifySupports(val),
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                  Divider(color: borderColor, height: 1),

                  // Sub-toggle: Komentar & Diskusi
                  _NotificationToggleTile(
                    icon: FontAwesomeIcons.comments,
                    iconColor: isDark ? AppColors.darkPrimary : AppColors.primary,
                    title: 'Komentar & Diskusi',
                    subtitle: 'Tanggapan baru warga atau tanggapan petugas di thread laporan.',
                    value: settings.notifyComments,
                    isEnabled: settings.notificationsEnabled,
                    onChanged: (val) => settings.setNotifyComments(val),
                    titleColor: titleColor,
                    mutedColor: mutedColor,
                    isDark: isDark,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ==========================================
          // SECTION 3: TENTANG APLIKASI
          // ==========================================
          _buildSectionHeader(
            icon: FaIcon(FontAwesomeIcons.circleInfo, size: 14, color: titleColor),
            title: 'Tentang Aplikasi',
            titleColor: titleColor,
          ),
          const SizedBox(height: 10),
          Material(
            color: cardBg,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.card,
              side: BorderSide(color: borderColor),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurfaceElevated : AppColors.primarySoft,
                        borderRadius: AppRadius.card,
                        border: Border.all(color: borderColor),
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadius.card,
                        child: Image.asset(
                          'assets/logo_laporin.png',
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Icon(
                              Icons.location_city_rounded,
                              size: 28,
                              color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Laporin',
                            style: AppTextStyles.h2.copyWith(
                              color: titleColor,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Versi 1.0.0 (MVP Pelaporan Fasilitas Publik)',
                            style: AppTextStyles.caption.copyWith(color: mutedColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Aplikasi pelaporan masalah fasilitas publik dan lingkungan transparan berbasis geospasial di seluruh wilayah Indonesia, akuntabilitas penanganan instansi pemerintah, dan partisipasi aktif komunitas warga.',
                  style: AppTextStyles.bodyRegular.copyWith(
                    color: bodyColor,
                    height: 1.45,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 16),
                Divider(color: borderColor, height: 1),
                const SizedBox(height: 12),
                InkWell(
                  borderRadius: AppRadius.button,
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Laporin',
                      applicationVersion: '1.0.0 (MVP)',
                      applicationIcon: ClipOval(
                        child: Image.asset(
                          'assets/logo_laporin.png',
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.location_city_rounded,
                            size: 40,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      children: const [
                        Text(
                          'Aplikasi pelaporan masalah publik transparan berbasis geospasial, moderasi komunitas, dan akuntabilitas penanganan instansi di 38 provinsi Indonesia.',
                        ),
                      ],
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: isDark ? AppColors.darkPrimary : AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Lihat Informasi Lengkap & Lisensi',
                          style: AppTextStyles.caption.copyWith(
                            color: isDark ? AppColors.darkPrimary : AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

          const SizedBox(height: 32),
        ],
      ),
    ),
  ),
);
  }

  Widget _buildSectionHeader({
    required Widget icon,
    required String title,
    required Color titleColor,
  }) {
    return Row(
      children: [
        icon,
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.h3.copyWith(
            color: titleColor,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _ThemeOptionCard extends StatelessWidget {
  const _ThemeOptionCard({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final activePrimary = isDark ? AppColors.darkPrimary : AppColors.primary;
    final activeBg = isDark
        ? const Color(0xFF1E3A8A).withValues(alpha: 0.3)
        : AppColors.primarySoft;
    final inactiveBg = isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF8FAFC);
    final borderColor = isSelected
        ? activePrimary
        : (isDark ? AppColors.darkBorder : AppColors.border);

    return Material(
      color: isSelected ? activeBg : inactiveBg,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.button,
        side: BorderSide(
          color: borderColor,
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.button,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          child: Column(
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected
                    ? activePrimary
                    : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.caption.copyWith(
                  color: isSelected
                      ? activePrimary
                      : (isDark ? AppColors.darkTextPrimary : AppColors.textPrimary),
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationToggleTile extends StatelessWidget {
  const _NotificationToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isEnabled,
    required this.onChanged,
    required this.titleColor,
    required this.mutedColor,
    required this.isDark,
  });

  final dynamic icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;
  final Color titleColor;
  final Color mutedColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = isEnabled ? titleColor : mutedColor.withValues(alpha: 0.6);
    final effectiveIconColor = isEnabled ? iconColor : mutedColor.withValues(alpha: 0.4);

    return SwitchListTile.adaptive(
      value: isEnabled && value,
      onChanged: isEnabled ? onChanged : null,
      activeThumbColor: isDark ? AppColors.darkPrimary : AppColors.primary,
      secondary: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurfaceElevated : const Color(0xFFF1F5F9),
          borderRadius: AppRadius.sm,
        ),
        child: icon is IconData
            ? Icon(
                icon as IconData,
                size: 16,
                color: effectiveIconColor,
              )
            : FaIcon(
                icon as dynamic,
                size: 15,
                color: effectiveIconColor,
              ),
      ),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: effectiveTitleColor,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: AppTextStyles.caption.copyWith(
          color: mutedColor.withValues(alpha: isEnabled ? 1.0 : 0.6),
          fontSize: 11.5,
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}
