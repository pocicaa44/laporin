import 'dart:async';

import 'package:flutter/material.dart';

import '../services/network_service.dart';
import '../theme/app_colors.dart';

/// Top connectivity status strip (banner) per PRD & DESIGN specs.
/// - Offline: Dark Grey background, persistent "Anda sedang offline" text.
/// - Back Online: Success green background, "Kembali online" text for exactly 1 second, then dismisses.
class TopConnectivityStrip extends StatefulWidget {
  const TopConnectivityStrip({super.key, this.onVisibilityChanged});

  final ValueChanged<bool>? onVisibilityChanged;

  @override
  State<TopConnectivityStrip> createState() => _TopConnectivityStripState();
}

class _TopConnectivityStripState extends State<TopConnectivityStrip> {
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
        ? const Color(0xFF23272F)
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
            alignment: Alignment.topCenter,
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(isOffline ? 'offline_strip' : 'online_strip'),
        height: 28,
        width: double.infinity,
        color: backgroundColor,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 8),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
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
