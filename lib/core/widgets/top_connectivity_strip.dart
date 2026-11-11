import 'dart:async';

import 'package:flutter/material.dart';

import '../services/network_service.dart';
import '../theme/app_colors.dart';

/// Bottom connectivity status strip (banner) positioned right between the application layer
/// and the Android system navigation buttons.
/// - Offline: Grey background (abu-abu), persistent "Anda sedang offline" text.
/// - Back Online: Green background (hijau), "Kembali online" text for exactly 1 second, then dismisses.
class BottomConnectivityStrip extends StatefulWidget {
  const BottomConnectivityStrip({super.key, this.onVisibilityChanged});

  final ValueChanged<bool>? onVisibilityChanged;

  @override
  State<BottomConnectivityStrip> createState() => _BottomConnectivityStripState();
}

typedef TopConnectivityStrip = BottomConnectivityStrip;

class _BottomConnectivityStripState extends State<BottomConnectivityStrip> {
  bool? _wasOnline;
  bool _showOnlineSuccess = false;
  Timer? _onlineDismissTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isOnline = context.isOnline;

    if (_wasOnline != null) {
      if (!_wasOnline! && isOnline) {
        // Device came back online: show green strip for exactly 1 second
        _showOnlineSuccess = true;
        _onlineDismissTimer?.cancel();
        _onlineDismissTimer = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() {
              _showOnlineSuccess = false;
            });
            widget.onVisibilityChanged?.call(false);
          }
        });
        widget.onVisibilityChanged?.call(true);
      } else if (!isOnline) {
        // Device went offline: cancel dismiss timer and keep offline banner persistent
        _onlineDismissTimer?.cancel();
        _showOnlineSuccess = false;
        widget.onVisibilityChanged?.call(true);
      }
    } else {
      if (!isOnline) {
        widget.onVisibilityChanged?.call(true);
      }
    }
    _wasOnline = isOnline;
  }

  @override
  void dispose() {
    _onlineDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isOnline = context.isOnline;
    final isOffline = !isOnline;
    final isVisible = isOffline || _showOnlineSuccess;

    if (!isVisible) {
      return const SizedBox.shrink();
    }

    final Color backgroundColor = isOffline
        ? const Color(0xFF4B5563)
        : AppColors.success;
    final IconData icon = isOffline
        ? Icons.wifi_off_rounded
        : Icons.wifi_rounded;
    final String text = isOffline ? 'Anda sedang offline' : 'Kembali online';

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            alignment: Alignment.bottomCenter,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(isOffline ? 'offline_strip' : 'online_strip'),
        height: 26,
        width: double.infinity,
        color: backgroundColor,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
