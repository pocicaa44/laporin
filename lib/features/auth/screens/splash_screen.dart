import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/services/network_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import 'login_screen.dart';

/// Splash / Intro screen matching DESIGN.md Section 5.1 and official logo specification
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with RouteAware {
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    NetworkService.instance.setOverviewActive(true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    try {
      context.networkService.setOverviewActive(true);
    } catch (_) {
      NetworkService.instance.setOverviewActive(true);
    }
    final modalRoute = ModalRoute.of(context);
    if (modalRoute != null) {
      NetworkService.routeObserver.subscribe(this, modalRoute);
    }
  }

  @override
  void dispose() {
    NetworkService.routeObserver.unsubscribe(this);
    try {
      context.networkService.setOverviewActive(false, notifyIfOffline: false);
    } catch (_) {
      NetworkService.instance.setOverviewActive(false, notifyIfOffline: false);
    }
    super.dispose();
  }

  @override
  void didPush() {
    try {
      context.networkService.setOverviewActive(true);
    } catch (_) {
      NetworkService.instance.setOverviewActive(true);
    }
  }

  @override
  void didPushNext() {
    try {
      context.networkService.setOverviewActive(false);
    } catch (_) {
      NetworkService.instance.setOverviewActive(false);
    }
  }

  @override
  void didPopNext() {
    try {
      context.networkService.setOverviewActive(true);
    } catch (_) {
      NetworkService.instance.setOverviewActive(true);
    }
  }

  Future<void> _handleStart() async {
    if (_isNavigating) return;
    setState(() => _isNavigating = true);

    try {
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } finally {
      if (mounted) {
        setState(() => _isNavigating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.isOnline;

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
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
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/logo_laporin.png',
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: AppColors.surfaceOf(context),
                                  alignment: Alignment.center,
                                  child: FaIcon(
                                    FontAwesomeIcons.bullhorn,
                                    size: 54,
                                    color: AppColors.primaryOf(context),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),
                          Text(
                            'Laporin',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryOf(context),
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Suarakan Masalah Fasilitas Publik Bersama',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.pageTitleOf(context),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Laporkan kerusakan fasilitas umum, pantau progres penanganan transparan, dan bantu jadikan lingkungan kita lebih baik.',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.bodySecondaryOf(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      // Actions: Mulai & Masuk with immediate loading feedback & double-tap lock
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppButton(
                            text: 'Mulai Sekarang',
                            isLoading: _isNavigating,
                            onPressed: isOnline ? _handleStart : null,
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
