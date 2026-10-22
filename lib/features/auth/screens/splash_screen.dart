import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import 'login_screen.dart';

/// Splash / Intro screen matching DESIGN.md Section 5.1 and official logo specification
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(height: 12),
                      // Logo & Illustration Centerpiece
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [AppColors.cardShadow],
                            ),
                            child: Image.asset(
                              'assets/logo_laporin.png',
                              fit: BoxFit.contain,
                              errorBuilder: (_, _, _) => const FaIcon(
                                FontAwesomeIcons.bullhorn,
                                size: 54,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          const Text(
                            'Laporin',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Suarakan Masalah Fasilitas Publik Bersama',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.pageTitle,
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'Laporkan kerusakan fasilitas umum, pantau progres penanganan transparan, dan bantu jadikan lingkungan kita lebih baik.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySecondary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Actions: Mulai & Masuk
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppButton(
                            text: 'Mulai Sekarang',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
