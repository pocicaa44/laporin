import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_colors.dart';

/// Reusable avatar widget supporting image network/file loading, initials fallback,
/// loading progress overlay, and an optional camera badge for photo editing.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.name,
    this.username,
    this.avatarUrl,
    this.radius = 20,
    this.showEditBadge = false,
    this.isLoading = false,
    this.onTap,
  });

  final String name;
  final String? username;
  final String? avatarUrl;
  final double radius;
  final bool showEditBadge;
  final bool isLoading;
  final VoidCallback? onTap;

  String get _initials {
    if (username != null && username!.trim().isNotEmpty) {
      final clean = username!.trim().replaceFirst('@', '');
      if (clean.isNotEmpty) return clean[0].toUpperCase();
    }
    if (name.trim().isNotEmpty) {
      return name.trim()[0].toUpperCase();
    }
    return 'W';
  }

  @override
  Widget build(BuildContext context) {
    final avatarWidget = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primarySoft,
          child: _buildAvatarContent(),
        ),
        if (isLoading)
          Container(
            width: radius * 2,
            height: radius * 2,
            decoration: const BoxDecoration(
              color: Colors.black45,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        if (showEditBadge)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: const FaIcon(
                FontAwesomeIcons.camera,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: isLoading ? null : onTap,
        customBorder: const CircleBorder(),
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  Widget _buildAvatarContent() {
    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      final isNetwork =
          url.startsWith('http://') ||
          url.startsWith('https://') ||
          url.startsWith('blob:') ||
          url.startsWith('data:');

      if (isNetwork) {
        return ClipOval(
          child: Image.network(
            url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _fallbackText(),
          ),
        );
      }

      if (!kIsWeb) {
        try {
          final file = io.File(url);
          if (file.existsSync()) {
            return ClipOval(
              child: Image.file(
                file,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _fallbackText(),
              ),
            );
          }
        } catch (_) {}
      }
    }

    return _fallbackText();
  }

  Widget _fallbackText() {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: AppColors.primaryStrong,
        ),
      ),
    );
  }
}
