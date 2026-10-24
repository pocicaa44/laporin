import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/notification_model.dart';
import '../../navigation/widgets/app_drawer.dart';
import '../../report_detail/screens/report_detail_screen.dart';
import '../controllers/notification_controller.dart';

/// Notifications list screen per DESIGN.md Section 5.12
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: const DrawerMenuButton(),
        title: const Text('Notifikasi'),
        actions: [
          if (controller.unreadCount > 0)
            TextButton(
              onPressed: () => controller.markAllAsRead(),
              child: const Text(
                'Tandai Dibaca',
                style: TextStyle(color: AppColors.primary, fontSize: 13),
              ),
            ),
        ],
      ),
      body: controller.isLoading
          ? const Center(child: CircularProgressIndicator())
          : controller.notifications.isEmpty
          ? const EmptyState(
              title: 'Belum Ada Notifikasi',
              message: 'Pembaruan tentang laporan dan pengumuman akan muncul di sini.',
              icon: Icons.notifications_none_rounded,
            )
          : RefreshIndicator(
              onRefresh: () => controller.fetchNotifications(),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                itemCount: controller.notifications.length,
                separatorBuilder: (_, _) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = controller.notifications[index];
                  return _NotificationItem(
                    item: item,
                    onTap: () {
                      controller.markAsRead(item.id);
                      if (item.reportId != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ReportDetailScreen(reportId: item.reportId!),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({required this.item, required this.onTap});

  final NotificationModel item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color iconColor;

    switch (item.type) {
      case NotificationType.statusChanged:
        icon = Icons.autorenew_rounded;
        iconColor = AppColors.primary;
        break;
      case NotificationType.newComment:
        icon = Icons.chat_bubble_outline_rounded;
        iconColor = AppColors.info;
        break;
      case NotificationType.upvoted:
        icon = Icons.thumb_up_alt_outlined;
        iconColor = AppColors.success;
        break;
      case NotificationType.moderation:
        icon = Icons.flag_outlined;
        iconColor = AppColors.danger;
        break;
      case NotificationType.announcement:
        icon = Icons.campaign_outlined;
        iconColor = const Color(0xFFD98205);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: item.isRead ? AppColors.surface : const Color(0xFFF7F8FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: item.isRead
              ? AppColors.border
              : AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          item.title,
          style: AppTextStyles.label.copyWith(
            fontWeight: item.isRead ? FontWeight.w500 : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              item.message,
              style: AppTextStyles.bodySecondary.copyWith(fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(item.createdAt.toRelativeTime(), style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
