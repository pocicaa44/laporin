import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/offline_fallback_view.dart';
import '../../../data/models/notification_model.dart';
import '../../announcements/screens/announcements_screen.dart';
import '../../navigation/widgets/app_drawer.dart';
import '../../report_detail/screens/report_detail_screen.dart';
import '../controllers/notification_controller.dart';

/// Notifications list screen per DESIGN.md Section 5.12
class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};
  bool _isDeleting = false;
  bool _wasOffline = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      final isOnline = context.isOnline;
      if (_wasOffline && isOnline) {
        _wasOffline = false;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.read<NotificationController>().fetchNotifications();
          }
        });
      } else if (!isOnline) {
        _wasOffline = true;
      }
    } catch (_) {}
  }

  void _enterSelectionMode() {
    setState(() {
      _isSelectionMode = true;
      _selectedIds.clear();
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _toggleSelectAll(List<NotificationModel> notifications) {
    setState(() {
      if (_selectedIds.length == notifications.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(notifications.map((n) => n.id));
      }
    });
  }

  Future<void> _handleDeleteSelected(NotificationController controller) async {
    if (!context.isOnline) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hapus notifikasi tidak dapat dilakukan saat offline.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (_selectedIds.isEmpty || _isDeleting) return;
    setState(() => _isDeleting = true);

    final idsToDelete = _selectedIds.toList();
    await controller.deleteNotifications(idsToDelete);

    if (mounted) {
      setState(() {
        _isSelectionMode = false;
        _selectedIds.clear();
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${idsToDelete.length} notifikasi berhasil dihapus'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<NotificationController>();
    final isOnline = context.isOnline;

    // Jika notifikasi kosong saat mode seleksi, otomatis keluar dari mode seleksi
    if (controller.notifications.isEmpty && _isSelectionMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isSelectionMode) {
          _exitSelectionMode();
        }
      });
    }

    final isAllSelected =
        controller.notifications.isNotEmpty &&
        _selectedIds.length == controller.notifications.length;

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
        drawer: _isSelectionMode ? null : const AppDrawer(),
        appBar: AppBar(
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Batal',
                  onPressed: _exitSelectionMode,
                )
              : const DrawerMenuButton(),
          title: Text(
            _isSelectionMode
                ? (_selectedIds.isEmpty
                      ? 'Pilih Notifikasi'
                      : '${_selectedIds.length} Dipilih')
                : 'Notifikasi',
          ),
          actions: [
            if (!_isSelectionMode) ...[
              if (controller.unreadCount > 0)
                TextButton(
                  onPressed: () => controller.markAllAsRead(),
                  child: const Text(
                    'Tandai Dibaca',
                    style: TextStyle(color: AppColors.primary, fontSize: 13),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                tooltip: 'Hapus Notifikasi',
                onPressed: controller.notifications.isEmpty
                    ? null
                    : _enterSelectionMode,
              ),
            ] else ...[
              TextButton(
                onPressed: _exitSelectionMode,
                child: const Text(
                  'Batal',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ],
        ),
        body: RefreshIndicator(
          onRefresh: () => controller.fetchNotifications(),
          child: controller.isLoading
              ? const Center(child: CircularProgressIndicator())
              : controller.notifications.isEmpty
              ? (!isOnline
                    ? OfflineFallbackView(
                        onRetry: () => controller.fetchNotifications(),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) =>
                            SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: const Center(
                                  child: EmptyState(
                                    title: 'Belum Ada Notifikasi',
                                    message: 'Pembaruan tentang laporan dan pengumuman akan muncul di sini.',
                                    icon: Icons.notifications_none_rounded,
                                  ),
                                ),
                              ),
                            ),
                      ))
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: controller.notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = controller.notifications[index];
                    final isSelected = _selectedIds.contains(item.id);

                    return _NotificationItem(
                      item: item,
                      isSelectionMode: _isSelectionMode,
                      isSelected: isSelected,
                      onToggleSelect: () => _toggleSelection(item.id),
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(item.id);
                          return;
                        }

                        controller.markAsRead(item.id);
                        if (item.reportId != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  ReportDetailScreen(reportId: item.reportId!),
                            ),
                          );
                        } else if (item.type == NotificationType.announcement) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AnnouncementsScreen(),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
        ),
        bottomNavigationBar:
            _isSelectionMode && controller.notifications.isNotEmpty
            ? SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Kiri bawah: "Pilih Semua"
                      InkWell(
                        borderRadius: AppRadius.button,
                        onTap: () => _toggleSelectAll(controller.notifications),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 4,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: isAllSelected,
                                onChanged: (_) =>
                                    _toggleSelectAll(controller.notifications),
                                activeColor: AppColors.primary,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'Pilih Semua',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Kanan bawah: Tombol "Hapus"
                      ElevatedButton(
                        onPressed: _selectedIds.isEmpty || _isDeleting
                            ? null
                            : () => _handleDeleteSelected(controller),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.danger,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: AppColors.border,
                          disabledForegroundColor: AppColors.disabled,
                          elevation: 0,
                          minimumSize: const Size(88, 40),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          shape: const RoundedRectangleBorder(
                            borderRadius: AppRadius.button,
                          ),
                        ),
                        child: _isDeleting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                            : const Text(
                                'Hapus',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              )
            : null,
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.item,
    required this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onToggleSelect,
  });

  final NotificationModel item;
  final VoidCallback onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onToggleSelect;

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
      case NotificationType.replyComment:
        icon = Icons.reply_rounded;
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
      case NotificationType.newReport:
        icon = Icons.assignment_outlined;
        iconColor = AppColors.primary;
        break;
    }

    return Material(
      color: isSelected
          ? AppColors.danger.withValues(alpha: 0.05)
          : (item.isRead ? AppColors.surface : const Color(0xFFF7F8FF)),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.button,
        side: BorderSide(
          color: isSelected
              ? AppColors.danger
              : (item.isRead
                    ? AppColors.border
                    : AppColors.primary.withValues(alpha: 0.3)),
          width: isSelected ? 1.5 : 1.0,
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
        trailing: isSelectionMode
            ? Checkbox(
                value: isSelected,
                onChanged: (_) => onToggleSelect?.call(),
                activeColor: AppColors.danger,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              )
            : (!item.isRead
                  ? Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    )
                  : null),
      ),
    );
  }
}
