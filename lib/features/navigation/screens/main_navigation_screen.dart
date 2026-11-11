import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../admin/screens/admin_navigation_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../create_report/screens/create_report_screen.dart';
import '../../feed/controllers/feed_controller.dart';
import '../../feed/screens/feed_screen.dart';
import '../../my_reports/screens/my_reports_screen.dart';
import '../../notifications/controllers/notification_controller.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../profile/screens/profile_screen.dart';
import '../controllers/navigation_controller.dart';
import '../widgets/app_drawer.dart';

/// Main navigation shell with 5-item bottom bar per DESIGN.md Section 2.2
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _localIndex = 0;

  final List<Widget> _screens = const [
    FeedScreen(),
    MyReportsScreen(),
    SizedBox.shrink(), // Placeholder for the middle "+" action
    NotificationsScreen(),
    ProfileScreen(),
  ];

  bool _isOpeningCreate = false;

  void _onTabTapped(int index) {
    if (index == 2) {
      if (!context.isOnline) return;
      if (_isOpeningCreate) return;
      _isOpeningCreate = true;
      // Floating "+" Action: Open Create Report
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateReportScreen()),
      ).then((_) {
        _isOpeningCreate = false;
        // Refresh feed upon return
        if (mounted) {
          context.read<FeedController>().fetchFeed();
        }
      });
      return;
    }
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
    final isOnline = context.isOnline;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final auth = context.watch<AuthController>();
    if (auth.isAdmin) {
      return const AdminNavigationScreen();
    }

    final unreadNotif = context.watch<NotificationController>().unreadCount;

    int activeIndex = _localIndex;
    try {
      activeIndex = context.watch<NavigationController>().currentIndex;
    } catch (_) {}

    final bgColor = isDark ? AppColors.darkBackground : AppColors.background;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final surfaceColor = isDark ? AppColors.darkSurface : AppColors.surface;
    final primaryColor = isDark ? AppColors.darkPrimary : AppColors.primary;
    final disabledColor = isDark ? AppColors.darkDisabled : AppColors.disabled;

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
            body: IndexedStack(
              index: activeIndex == 2 ? 0 : activeIndex,
              children: _screens,
            ),
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
                      _NavBarItem(
                        icon: FontAwesomeIcons.house,
                        label: 'Beranda',
                        isSelected: activeIndex == 0,
                        onTap: () => _onTabTapped(0),
                      ),
                      _NavBarItem(
                        icon: FontAwesomeIcons.clipboardList,
                        label: 'Laporan',
                        isSelected: activeIndex == 1,
                        onTap: () => _onTabTapped(1),
                      ),

                      // Center prominent "+" action button (Buat Laporan) - Rounded modern per DESIGN.md
                      MouseRegion(
                        cursor: isOnline
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.forbidden,
                        child: GestureDetector(
                          onTap: isOnline ? () => _onTabTapped(2) : null,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? primaryColor
                                  : disabledColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.plus,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),

                      _NavBarItem(
                        icon: FontAwesomeIcons.bell,
                        label: 'Notifikasi',
                        isSelected: activeIndex == 3,
                        badgeCount: unreadNotif,
                        onTap: () => _onTabTapped(3),
                      ),
                      _NavBarItem(
                        icon: FontAwesomeIcons.user,
                        label: 'Profil',
                        isSelected: activeIndex == 4,
                        onTap: () => _onTabTapped(4),
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

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    this.badgeCount = 0,
    required this.onTap,
  });

  final FaIconData icon;
  final String label;
  final bool isSelected;
  final int badgeCount;
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              isLabelVisible: badgeCount > 0,
              label: Text('$badgeCount', style: const TextStyle(fontSize: 10)),
              child: FaIcon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 2),
            Text(
              label,
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
