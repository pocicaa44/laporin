import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../theme/app_colors.dart';
import 'app_image.dart';

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
    this.backgroundColor,
    this.foregroundColor,
  });

  final String name;
  final String? username;
  final String? avatarUrl;
  final double radius;
  final bool showEditBadge;
  final bool isLoading;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  String get _initials {
    if (username != null && username!.trim().isNotEmpty) {
      final clean = username!.trim().replaceFirst('@', '');
      if (clean.isNotEmpty) return clean[0].toUpperCase();
    }
    if (name.trim().isNotEmpty) {
      final clean = name.trim().replaceFirst('@', '');
      if (clean.isNotEmpty) return clean[0].toUpperCase();
    }
    return 'W';
  }

  /// Path asset untuk avatar default Laporin.
  /// Disimpan sebagai asset lokal agar tidak membebani server/database.
  static const String defaultAvatarAsset = 'assets/generic-avatar-profile.png';

  @override
  Widget build(BuildContext context) {
    final avatarWidget = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ?? Colors.grey.shade100,
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
      return ClipOval(
        child: AppImage(
          imageSource: url,
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          placeholder: _buildDefaultAssetAvatar(),
          errorWidget: _buildDefaultAssetAvatar(),
        ),
      );
    }

    return _buildDefaultAssetAvatar();
  }

  Widget _buildDefaultAssetAvatar() {
    return ClipOval(
      child: Image.asset(
        defaultAvatarAsset,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallbackText(),
      ),
    );
  }

  Widget _fallbackText() {
    return Center(
      child: Text(
        _initials,
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: foregroundColor ?? AppColors.primaryStrong,
        ),
      ),
    );
  }
}
