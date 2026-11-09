import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/access_denied_screen.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/repositories/announcement_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../navigation/controllers/navigation_controller.dart';
import '../../navigation/widgets/app_drawer.dart';
import '../controllers/admin_announcement_controller.dart';
import '../screens/admin_create_announcement_screen.dart';
import '../screens/admin_edit_announcement_screen.dart';
import '../widgets/admin_delete_announcement_dialog.dart';

/// Screen manajemen pengumuman resmi bagi Admin (< 250 baris per skills.md)
class AdminAnnouncementsScreen extends StatelessWidget {
  const AdminAnnouncementsScreen({super.key, this.isEmbedded = false});

  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    // Route guard: hanya admin yang boleh mengakses layar ini
    if (!auth.isAdmin) {
      return AccessDeniedScreen(
        title: 'Akses Khusus Petugas',
        message: 'Menu Pengumuman hanya dapat diakses oleh akun dengan peran Petugas / Admin.',
        buttonText: 'Kembali ke Beranda',
        onButtonPressed: () => Navigator.of(context).pop(),
      );
    }

    return ChangeNotifierProvider(
      create: (context) => AdminAnnouncementController(
        repository: context.read<AnnouncementRepository>(),
      ),
      child: _AdminAnnouncementsView(isEmbedded: isEmbedded),
    );
  }
}

class _AdminAnnouncementsView extends StatefulWidget {
  const _AdminAnnouncementsView({required this.isEmbedded});

  final bool isEmbedded;

  @override
  State<_AdminAnnouncementsView> createState() =>
      _AdminAnnouncementsViewState();
}

class _AdminAnnouncementsViewState extends State<_AdminAnnouncementsView> {
  int? _lastNavChangeCount;

  @override
  void initState() {
    super.initState();
    if (!widget.isEmbedded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AdminAnnouncementController>().fetchAnnouncements(
            forceRefresh: true,
          );
        }
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.isEmbedded) {
      try {
        final nav = context.watch<NavigationController>();
        if (nav.currentIndex == 2 &&
            _lastNavChangeCount != nav.tabChangeCount) {
          _lastNavChangeCount = nav.tabChangeCount;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              context.read<AdminAnnouncementController>().fetchAnnouncements(
                forceRefresh: true,
              );
            }
          });
        } else {
          _lastNavChangeCount = nav.tabChangeCount;
        }
      } catch (_) {}
    }
  }

  Future<void> _handleCreate(
    BuildContext context,
    AdminAnnouncementController controller,
  ) async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminCreateAnnouncementScreen(controller: controller),
      ),
    );
    if (created == true && context.mounted) {
      await controller.fetchAnnouncements(forceRefresh: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengumuman resmi berhasil diterbitkan.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminAnnouncementController>();

    return Scaffold(
      drawer: const AppDrawer(),
      appBar: AppBar(
        leading: widget.isEmbedded ? const DrawerMenuButton() : null,
        automaticallyImplyLeading: !widget.isEmbedded,
        title: const Text('Pengumuman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Pengumuman',
            onPressed: () => controller.fetchAnnouncements(forceRefresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        key: const Key('admin_add_announcement_fab'),
        onPressed: () => _handleCreate(context, controller),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        elevation: 0,
        focusElevation: 0,
        hoverElevation: 0,
        highlightElevation: 0,
        tooltip: 'Tambah Pengumuman',
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchAnnouncements(forceRefresh: true),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            const Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.bullhorn,
                  size: 16,
                  color: AppColors.primary,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daftar Pengumuman Resmi',
                    style: AppTextStyles.sectionTitle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.isLoading && controller.announcements.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (controller.announcements.isEmpty)
              const EmptyState(
                title: 'Belum Ada Pengumuman',
                message: 'Pengumuman resmi yang Anda terbitkan akan tampil pada daftar ini.',
              )
            else
              ...controller.announcements.map(
                (announcement) => _AnnouncementCard(
                  key: ValueKey(
                    '${announcement.id}-${announcement.updatedAt.millisecondsSinceEpoch}',
                  ),
                  announcement: announcement,
                  controller: controller,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({
    super.key,
    required this.announcement,
    required this.controller,
  });

  final AnnouncementModel announcement;
  final AdminAnnouncementController controller;

  Future<void> _handleEdit(BuildContext context) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminEditAnnouncementScreen(
          announcement: announcement,
          controller: controller,
        ),
      ),
    );
    if (updated == true && context.mounted) {
      await controller.fetchAnnouncements(forceRefresh: true);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pengumuman berhasil diperbarui.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AdminDeleteAnnouncementDialog(
        announcementTitle: announcement.title,
        onConfirmDelete: () => controller.deleteAnnouncement(announcement.id),
      ),
    );
    if (confirmed == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengumuman berhasil dihapus.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmergency = announcement.category == 'Darurat';
    final hasImage =
        announcement.imageUrl != null && announcement.imageUrl!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(
          color: isEmergency ? AppColors.danger : AppColors.border,
          width: isEmergency ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.card,
        child: InkWell(
          onTap: () => _handleEdit(context),
          borderRadius: AppRadius.card,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isEmergency
                            ? const Color(0xFFFEECEB)
                            : AppColors.primarySoft,
                        borderRadius: AppRadius.pill,
                      ),
                      child: Text(
                        announcement.category,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isEmergency
                              ? AppColors.danger
                              : AppColors.primaryStrong,
                        ),
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      announcement.createdAt.toRelativeTime(),
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      tooltip: 'Opsi Pengumuman',
                      shape: const RoundedRectangleBorder(
                        borderRadius: AppRadius.button,
                      ),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          await _handleEdit(context);
                        } else if (value == 'delete') {
                          await _handleDelete(context);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.textPrimary,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Edit Pengumuman',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: AppColors.danger,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Hapus Pengumuman',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      child: const Icon(
                        Icons.more_vert_rounded,
                        size: 20,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(announcement.title, style: AppTextStyles.sectionTitle),
                const SizedBox(height: 6),
                Text(
                  announcement.content,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(height: 12),
                  AppImage(
                    imageSource: announcement.imageUrl!,
                    height: 180,
                    width: double.infinity,
                    borderRadius: AppRadius.button,
                    fit: BoxFit.cover,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.verified_user_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Diterbitkan oleh: ${announcement.authorName}',
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
