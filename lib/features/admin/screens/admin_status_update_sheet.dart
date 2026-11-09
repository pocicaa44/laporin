import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/app_validators.dart';
import '../../../core/widgets/app_button.dart';
import '../../../data/models/report_model.dart';

/// Modal bottom sheet for changing handling status with mandatory reasons per PRD.md Section 5.3
class AdminStatusUpdateSheet extends StatefulWidget {
  const AdminStatusUpdateSheet({super.key, required this.report});

  final ReportModel report;

  @override
  State<AdminStatusUpdateSheet> createState() => _AdminStatusUpdateSheetState();
}

class _AdminStatusUpdateSheetState extends State<AdminStatusUpdateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _reasonController = TextEditingController();
  late HandlingStatus _selectedStatus;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.report.handlingStatus;
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  bool get _requiresReason => _selectedStatus == HandlingStatus.rejected;

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
                  'Ubah Status Penanganan',
                  style: AppTextStyles.pageTitle,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${widget.report.reportNumber} - ${widget.report.title}',
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 16),

            // Status Options: baru, diterima, diproses, ditolak
            ...[
              HandlingStatus.newReport,
              HandlingStatus.accepted,
              HandlingStatus.inProgress,
              HandlingStatus.rejected,
            ].map((status) {
              final isSelected = status == _selectedStatus;
              final isDanger = status == HandlingStatus.rejected;
              return InkWell(
                onTap: () => setState(() => _selectedStatus = status),
                borderRadius: AppRadius.button,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        isSelected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: isSelected
                            ? (isDanger ? AppColors.danger : AppColors.primary)
                            : AppColors.textSecondary,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Text(status.label, style: AppTextStyles.label),
                    ],
                  ),
                ),
              );
            }),

            if (_requiresReason) ...[
              const SizedBox(height: 10),
              TextFormField(
                controller: _reasonController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Alasan Penolakan * (Wajib)',
                  hintText: 'Jelaskan alasan secara objektif dan sopan...',
                ),
                validator: (v) => AppValidators.validateReason(v, 'penolakan'),
              ),
              const SizedBox(height: 8),
              const Text(
                'Catatan: Laporan yang ditolak akan langsung hilang dari feed publik dan masuk jadwal arsip 24 jam.',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 20),

            AppButton(
              text: 'Simpan Perubahan',
              variant: _selectedStatus == HandlingStatus.rejected
                  ? AppButtonVariant.destructive
                  : AppButtonVariant.primary,
              onPressed: () {
                if (_requiresReason && !_formKey.currentState!.validate()) {
                  return;
                }
                Navigator.pop(context, {
                  'status': _selectedStatus,
                  'reason': _reasonController.text.trim(),
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
