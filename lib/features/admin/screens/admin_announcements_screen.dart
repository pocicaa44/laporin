import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/access_denied_screen.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/repositories/announcement_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/admin_announcement_controller.dart';
import '../widgets/admin_announcement_form.dart';

/// Screen manajemen dan pembuatan pengumuman resmi bagi Admin
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

class _AdminAnnouncementsView extends StatelessWidget {
  const _AdminAnnouncementsView({required this.isEmbedded});

  final bool isEmbedded;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AdminAnnouncementController>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !isEmbedded,
        title: const Text('Pengumuman'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Segarkan Pengumuman',
            onPressed: () => controller.fetchAnnouncements(forceRefresh: true),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => controller.fetchAnnouncements(forceRefresh: true),
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          children: [
            const AdminAnnouncementForm(),
            const SizedBox(height: 20),
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.bullhorn,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Daftar Pengumuman Resmi',
                  style: AppTextStyles.sectionTitle,
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
                (announcement) => _AnnouncementCard(announcement: announcement),
              ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.announcement});

  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context) {
    final isEmergency = announcement.category == 'Darurat';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEmergency ? AppColors.danger : AppColors.border,
          width: isEmergency ? 1.5 : 1,
        ),
        boxShadow: const [AppColors.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isEmergency
                      ? const Color(0xFFFEECEB)
                      : AppColors.primarySoft,
                  borderRadius: BorderRadius.circular(6),
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
              Text(
                announcement.createdAt.toRelativeTime(),
                style: AppTextStyles.caption,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(announcement.title, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 6),
          Text(
            announcement.content,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.verified_user_rounded,
                size: 14,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
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
    );
  }
}
