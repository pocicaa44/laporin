import 'package:flutter/material.dart';

import '../services/network_service.dart';
import '../theme/app_text_styles.dart';
import 'app_button.dart';

/// Reusable offline fallback view matching DRY & Modular standards per skills.md
class OfflineFallbackView extends StatefulWidget {
  const OfflineFallbackView({
    super.key,
    required this.onRetry,
    this.title = 'Koneksi Terputus',
    this.message = 'Anda sedang offline, hubungkan ke jaringan dan coba lagi',
  });

  final Future<void> Function() onRetry;
  final String title;
  final String message;

  @override
  State<OfflineFallbackView> createState() => _OfflineFallbackViewState();
}

class _OfflineFallbackViewState extends State<OfflineFallbackView> {
  bool _isRetrying = false;
  bool _wasOffline = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isOnline = context.isOnline;
    if (_wasOffline && isOnline) {
      _wasOffline = false;
      // Auto re-fetch when connectivity transitions back to online
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _handleRetry();
        }
      });
    } else if (!isOnline) {
      _wasOffline = true;
    }
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      await context.networkService.checkConnection();
      await widget.onRetry();
    } catch (_) {
    } finally {
      if (mounted) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF23272F).withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: Color(0xFF23272F),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: AppTextStyles.sectionTitle.copyWith(fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySecondary,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 180,
              child: AppButton(
                text: 'Coba Lagi',
                isLoading: _isRetrying,
                onPressed: _handleRetry,
                height: 44,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
