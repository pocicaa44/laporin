import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Dialog konfirmasi soft-delete laporan per DESIGN.md & PRD Bagian 7 (< 120 lines)
class DeleteReportDialog extends StatefulWidget {
  const DeleteReportDialog({
    super.key,
    required this.reportNumber,
    required this.onConfirmDelete,
    this.isOtherPartyDeleted = false,
  });

  final String reportNumber;
  final Future<bool> Function() onConfirmDelete;
  final bool isOtherPartyDeleted;

  @override
  State<DeleteReportDialog> createState() => _DeleteReportDialogState();
}

class _DeleteReportDialogState extends State<DeleteReportDialog> {
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
          _errorMessage = 'Gagal menghapus laporan. Silakan coba kembali.';
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
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.danger,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.isOtherPartyDeleted ? 'Hapus Permanen?' : 'Hapus Laporan?',
              style: AppTextStyles.sectionTitle,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.isOtherPartyDeleted
                ? 'Pelapor telah menghapus laporan ${widget.reportNumber}. Konfirmasi ini akan menghapus laporan secara permanen dari database dan seluruh media foto lampiran akan dibersihkan dari server.'
                : 'Apakah Anda yakin ingin menghapus laporan ${widget.reportNumber}? Laporan akan dihapus dari daftar aktif publik.',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 8),
          Text(
            widget.isOtherPartyDeleted
                ? 'Perhatian: Tindakan ini permanen dan tidak dapat dipulihkan kembali.'
                : 'Catatan: Laporan akan dihapus permanen dari database dan seluruh media foto akan dibersihkan dari server apabila kedua belah pihak (warga & admin) telah menghapus laporan ini.',
            style: AppTextStyles.caption,
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12),
              ),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text(
            'Batal',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
              : Text(
                  widget.isOtherPartyDeleted
                      ? 'Hapus Permanen'
                      : 'Hapus Laporan',
                ),
        ),
      ],
    );
  }
}
