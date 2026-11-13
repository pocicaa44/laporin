import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/access_denied_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../feed/screens/feed_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../navigation/widgets/app_drawer.dart';
import '../widgets/admin_sidebar.dart';
import 'admin_announcements_screen.dart';
import 'admin_dashboard_screen.dart';
import 'admin_statistics_screen.dart';

/// Navigation shell khusus admin dengan tepat 4 menu utama per spesifikasi
class AdminNavigationScreen extends StatefulWidget {
  const AdminNavigationScreen({super.key});

  @override
  State<AdminNavigationScreen> createState() => _AdminNavigationScreenState();
}

class _AdminNavigationScreenState extends State<AdminNavigationScreen> {
  int _localIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    AdminDashboardScreen(isEmbedded: true),
    AdminAnnouncementsScreen(isEmbedded: true),
    AdminStatisticsScreen(isEmbedded: true),
    ProfileScreen(),
  ];

  void _onTabTapped(int index) {
    if (index == 0) {
      try {
        final auth = context.read<AuthController>();
        context.read<FeedController>().fetchFeed(auth.currentUser?.id, true);
      } catch (_) {}
    }
    try {
      context.read<NavigationController>().setIndex(index);
    } catch (_) {
      setState(() => _localIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    // Route guard: hanya akun admin yang berhak menggunakan shell navigasi ini
    if (!auth.isAdmin) {
      return AccessDeniedScreen(
        title: 'Akses Khusus Petugas',
        message: 'Navigasi khusus admin hanya dapat diakses oleh akun dengan peran Petugas / Admin.',
        buttonText: 'Kembali ke Beranda',
        onButtonPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
      );
    }

    int activeIndex = _localIndex;
    try {
      activeIndex = context.watch<NavigationController>().currentIndex;
    } catch (_) {}
    if (activeIndex < 0 || activeIndex >= _screens.length) {
      activeIndex = 0;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;

    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    // Layout Desktop: hilangkan navbar bawah, gunakan sidebar di kiri
    if (isDesktop) {
      return Container(
        color: bgColor,
        child: Scaffold(
          body: Row(
            children: [
              AdminSidebar(
                activeIndex: activeIndex,
                onTabTapped: _onTabTapped,
              ),
              Expanded(
                child: IndexedStack(index: activeIndex, children: _screens),
              ),
            ],
          ),
        ),
      );
    }

    // Layout Mobile: navbar di bawah dengan pembatas layar tengah
    return Container(
      color: bgColor,
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.symmetric(
              vertical: BorderSide(color: borderColor, width: 1),
            ),
          ),
          child: Scaffold(
            drawer: const AppDrawer(),
            body: IndexedStack(index: activeIndex, children: _screens),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                  top: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 64,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _AdminNavBarItem(
                          icon: FontAwesomeIcons.house,
                          label: 'Beranda',
                          isSelected: activeIndex == 0,
                          onTap: () => _onTabTapped(0),
                        ),
                      ),
                      Expanded(
                        child: _AdminNavBarItem(
                          icon: FontAwesomeIcons.tableColumns,
                          label: 'Panel',
                          isSelected: activeIndex == 1,
                          onTap: () => _onTabTapped(1),
                        ),
                      ),
                      Expanded(
                        child: _AdminNavBarItem(
                          icon: FontAwesomeIcons.bullhorn,
                          label: 'Pengumuman',
                          isSelected: activeIndex == 2,
                          onTap: () => _onTabTapped(2),
                        ),
                      ),
                      Expanded(
                        child: _AdminNavBarItem(
                          icon: FontAwesomeIcons.chartSimple,
                          label: 'Statistik',
                          isSelected: activeIndex == 3,
                          onTap: () => _onTabTapped(3),
                        ),
                      ),
                      Expanded(
                        child: _AdminNavBarItem(
                          icon: FontAwesomeIcons.user,
                          label: 'Profil',
                          isSelected: activeIndex == 4,
                          onTap: () => _onTabTapped(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminNavBarItem extends StatelessWidget {
  const _AdminNavBarItem({
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
    final color = isSelected
        ? (isDark ? AppColors.darkPrimary : AppColors.primary)
        : (isDark ? AppColors.darkTextSecondary : AppColors.textSecondary);

    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: AppRadius.button,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
