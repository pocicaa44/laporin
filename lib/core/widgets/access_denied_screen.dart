import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Reusable Access Denied / 403 Forbidden screen matching DESIGN.md flat guidelines
class AccessDeniedScreen extends StatelessWidget {
  const AccessDeniedScreen({
    super.key,
    this.title = 'Akses Ditolak',
    this.message =
        'Anda tidak memiliki izin yang cukup untuk mengakses halaman ini.',
    this.buttonText = 'Kembali',
    required this.onButtonPressed,
  });

  final String title;
  final String message;
  final String buttonText;
  final VoidCallback onButtonPressed;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      color: AppColors.backgroundOf(context),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 720),
          decoration: BoxDecoration(
            color: AppColors.backgroundOf(context),
            border: Border.symmetric(
              vertical: BorderSide(color: AppColors.borderOf(context), width: 1),
            ),
          ),
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Otorisasi Akses'),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: onButtonPressed,
              ),
            ),
            body: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceOf(context),
                    borderRadius: AppRadius.card,
                    border: Border.all(color: AppColors.borderOf(context), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkDanger.withValues(alpha: 0.15)
                              : AppColors.dangerSubtle,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? AppColors.darkDanger.withValues(alpha: 0.4)
                                : const Color(0xFFFECACA),
                            width: 1,
                          ),
                        ),
                        child: Center(
                          child: FaIcon(
                            FontAwesomeIcons.shieldHalved,
                            size: 28,
                            color: AppColors.dangerOf(context),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.pageTitleOf(context),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySecondaryOf(context).copyWith(
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: AppButton(
                          text: buttonText,
                          onPressed: onButtonPressed,
                        ),
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
