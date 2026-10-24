import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Reusable, memory-optimized image loader for network, local file, and web assets.
///
/// Features:
/// - Supports [memCacheWidth] & [memCacheHeight] to constrain bitmap decoding in RAM.
/// - Progressive loading with subtle placeholder (avoids white flashes).
/// - Safe error fallback widget.
/// - Works consistently across Android, iOS, and Web.
class AppImage extends StatelessWidget {
  const AppImage({
    super.key,
    required this.imageSource,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.memCacheWidth,
    this.memCacheHeight,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  final String imageSource;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final trimmed = imageSource.trim();
    if (trimmed.isEmpty) {
      return _buildError();
    }

    Widget content;
    final isNetwork =
        trimmed.startsWith('http://') ||
        trimmed.startsWith('https://') ||
        trimmed.startsWith('blob:') ||
        trimmed.startsWith('data:');

    final resolvedCacheWidth = kIsWeb ? null : memCacheWidth;
    final resolvedCacheHeight = kIsWeb
        ? null
        : (memCacheWidth != null ? null : memCacheHeight);

    if (isNetwork) {
      content = Image.network(
        trimmed,
        width: width,
        height: height,
        fit: fit,
        cacheWidth: resolvedCacheWidth,
        cacheHeight: resolvedCacheHeight,
        frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
          if (wasSynchronouslyLoaded || frame != null) {
            return child;
          }
          return _buildPlaceholder();
        },
        errorBuilder: (_, _, _) => _buildError(),
      );
    } else if (!kIsWeb) {
      try {
        final file = io.File(trimmed);
        if (file.existsSync()) {
          content = Image.file(
            file,
            width: width,
            height: height,
            fit: fit,
            cacheWidth: resolvedCacheWidth,
            cacheHeight: resolvedCacheHeight,
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded || frame != null) {
                return child;
              }
              return _buildPlaceholder();
            },
            errorBuilder: (_, _, _) => _buildError(),
          );
        } else {
          content = _buildError();
        }
      } catch (_) {
        content = _buildError();
      }
    } else {
      content = _buildError();
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: content);
    }
    return content;
  }

  Widget _buildPlaceholder() {
    if (placeholder != null) return placeholder!;
    return Container(
      width: width,
      height: height,
      color: AppColors.primarySoft,
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    if (errorWidget != null) return errorWidget!;
    return Container(
      width: width,
      height: height,
      color: AppColors.primarySoft,
      child: const Center(
        child: Icon(
          Icons.broken_image_rounded,
          color: AppColors.textSecondary,
          size: 24,
        ),
      ),
    );
  }
}
