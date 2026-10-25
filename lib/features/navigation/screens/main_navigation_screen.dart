import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
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
    final auth = context.watch<AuthController>();
    if (auth.isAdmin) {
      return const AdminNavigationScreen();
    }

    final unreadNotif = context.watch<NotificationController>().unreadCount;

    int activeIndex = _localIndex;
    try {
      activeIndex = context.watch<NavigationController>().currentIndex;
    } catch (_) {}

    return Container(
      color: const Color(0xFFF0F2F5),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          decoration: const BoxDecoration(
            color: AppColors.background,
            border: Border.symmetric(
              vertical: BorderSide(color: AppColors.border, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 24,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Scaffold(
            drawer: const AppDrawer(),
            body: IndexedStack(
              index: activeIndex == 2 ? 0 : activeIndex,
              children: _screens,
            ),
            bottomNavigationBar: Container(
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 1),
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

                      // Center prominent "+" action button
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => _onTabTapped(2),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color.fromRGBO(89, 108, 255, 0.35),
                                  offset: Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Center(
                              child: FaIcon(
                                FontAwesomeIcons.plus,
                                size: 20,
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
    final color = isSelected ? AppColors.primary : AppColors.textSecondary;

    return InkWell(
      onTap: onTap,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(12),
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
