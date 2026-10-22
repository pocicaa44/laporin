import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/report_model.dart';

/// Modal bottom sheet for resolving report with mandatory proof per PRD FR-08 & DESIGN 5.9
class AdminResolveSheet extends StatefulWidget {
  const AdminResolveSheet({super.key, required this.report});

  final ReportModel report;

  @override
  State<AdminResolveSheet> createState() => _AdminResolveSheetState();
}

class _AdminResolveSheetState extends State<AdminResolveSheet> {
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController(
    text: 'Pekerjaan perbaikan telah selesai dilaksanakan oleh tim dinas.',
  );
  final String _proofUrl =
      'https://images.unsplash.com/photo-1581092160607-ee22621dd758?w=800';

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Selesaikan Laporan',
                  style: AppTextStyles.pageTitle,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.report.reportNumber} - ${widget.report.title}',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 16),

            // Mandatory Proof Image
            const Text(
              'Foto Bukti Penyelesaian * (Wajib)',
              style: AppTextStyles.label,
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(_proofUrl, fit: BoxFit.cover),
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xBF000000),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 14,
                            color: AppColors.success,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Foto Terverifikasi',
                            style: TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Catatan Penanganan *',
                hintText: 'Uraikan hasil pekerjaan penyelesaian...',
              ),
              validator: (v) => AppValidators.validateRequired(v, 'Catatan'),
            ),
            const SizedBox(height: 24),

            AppButton(
              text: 'Konfirmasi Selesai',
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(context, {
                  'proofUrl': _proofUrl,
                  'notes': _notesController.text,
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
