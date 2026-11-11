import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';

/// Dialog konfirmasi penghapusan pengumuman resmi oleh admin
class AdminDeleteAnnouncementDialog extends StatefulWidget {
  const AdminDeleteAnnouncementDialog({
    super.key,
    required this.announcementTitle,
    required this.onConfirmDelete,
  });

  final String announcementTitle;
  final Future<bool> Function() onConfirmDelete;

  @override
  State<AdminDeleteAnnouncementDialog> createState() =>
      _AdminDeleteAnnouncementDialogState();
}

class _AdminDeleteAnnouncementDialogState
    extends State<AdminDeleteAnnouncementDialog> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleDelete() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final success = await widget.onConfirmDelete();
      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Gagal menghapus pengumuman. Silakan coba kembali.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dangerColor = isDark ? AppColors.darkDanger : AppColors.danger;
    final dangerSubtle = isDark ? AppColors.darkDangerSubtle : AppColors.danger.withValues(alpha: 0.1);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.border;
    final textSecondary = AppColors.textSecondaryOf(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.dialog,
        side: BorderSide(color: borderColor),
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: dangerSubtle,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.warning_amber_rounded,
              color: dangerColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text('Hapus Pengumuman?', style: AppTextStyles.sectionTitleOf(context)),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apakah Anda yakin ingin menghapus pengumuman "${widget.announcementTitle}"?',
            style: AppTextStyles.bodyOf(context),
          ),
          const SizedBox(height: 8),
          Text(
            'Pengumuman yang dihapus tidak akan lagi tampil pada layar warga. Tindakan ini tidak dapat dibatalkan.',
            style: AppTextStyles.captionOf(context),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: dangerSubtle,
                borderRadius: AppRadius.sm,
              ),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: dangerColor, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: Text(
            'Batal',
            style: TextStyle(color: textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: dangerColor,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.button),
          ),
          onPressed: _isLoading ? null : _handleDelete,
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Hapus'),
        ),
      ],
    );
  }
}
