import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// Utility to show floating toast messages positioned at top center of the screen.
class AppToast {
  AppToast._();

  static OverlayEntry? _currentEntry;

  /// Shows a top-center toast message for the specified duration (default: 3 seconds).
  /// Features a slide-down animation when appearing and slide-up animation when disappearing.
  static void show(
    BuildContext context, {
    required String message,
    Duration duration = const Duration(seconds: 3),
    IconData? icon = Icons.check_circle_rounded,
  }) {
    if (!context.mounted) return;
    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    // Dismiss any currently active toast immediately
    dismiss();

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopToastWidget(
        message: message,
        icon: icon,
        duration: duration,
        onDismissed: () {
          if (entry.mounted) {
            entry.remove();
            if (_currentEntry == entry) {
              _currentEntry = null;
            }
          }
        },
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);
  }

  /// Cancels and removes any active toast immediately.
  static void dismiss() {
    if (_currentEntry != null && _currentEntry!.mounted) {
      _currentEntry!.remove();
      _currentEntry = null;
    }
  }
}

class _TopToastWidget extends StatefulWidget {
  const _TopToastWidget({
    required this.message,
    this.icon,
    this.duration = const Duration(seconds: 3),
    required this.onDismissed,
  });

  final String message;
  final IconData? icon;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_TopToastWidget> createState() => _TopToastWidgetState();
}

class _TopToastWidgetState extends State<_TopToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    // Animasi turun saat menampilkan (Offset(0, -1.2) -> Offset.zero)
    // dan animasi naik saat menghilang (Offset.zero -> Offset(0, -1.2))
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    ));

    // Mulai animasi turun saat menampilkan
    _controller.forward();

    // Tunggu selama durasi (3 detik), lalu jalankan animasi naik saat menghilang
    _dismissTimer = Timer(widget.duration, () {
      if (mounted) {
        _animateAndDismiss();
      }
    });
  }

  Future<void> _animateAndDismiss() async {
    if (!mounted) return;
    try {
      await _controller.reverse();
    } catch (_) {}
    if (mounted) {
      widget.onDismissed();
    }
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: topPadding + 16,
      left: 16,
      right: 16,
      child: Align(
        alignment: Alignment.topCenter,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Material(
              color: Colors.transparent,
              child: ClipRRect(
                borderRadius: AppRadius.pill,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      // Universal semi-transparent grey for both light and dark mode
                      color: const Color(0xB8374151),
                      borderRadius: AppRadius.pill,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.20),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.20),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: 16,
                            color: AppColors.success,
                          ),
                          const SizedBox(width: 8),
                        ],
                        Text(
                          widget.message,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                            decoration: TextDecoration.none,
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
      ),
    );
  }
}
