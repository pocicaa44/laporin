import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/widgets/app_image.dart';
import '../../../core/widgets/user_avatar.dart';

/// Overlay minimalis untuk menampilkan foto profil pengguna dengan latar belakang transparan gelap,
/// tanpa tombol, tanpa teks, dan tanpa border. Mengetuk area mana pun akan menutup overlay.
class ProfilePhotoDetailDialog extends StatelessWidget {
  const ProfilePhotoDetailDialog({super.key, this.avatarUrl, this.avatarBytes});

  final String? avatarUrl;
  final Uint8List? avatarBytes;

  /// Helper statis untuk menampilkan dialog overlay foto profil
  static Future<void> show({
    required BuildContext context,
    String? avatarUrl,
    Uint8List? avatarBytes,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => ProfilePhotoDetailDialog(
        avatarUrl: avatarUrl,
        avatarBytes: avatarBytes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final size = (screenWidth * 0.85).clamp(240.0, 360.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.pop(context),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        shadowColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(
          side: BorderSide.none,
          borderRadius: BorderRadius.zero,
        ),
        child: Center(
          child: ClipRRect(
            borderRadius: AppRadius.card,
            child: SizedBox(
              width: size,
              height: size,
              child: _buildAvatarImage(size),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarImage(double size) {
    if (avatarBytes != null) {
      return Image.memory(
        avatarBytes!,
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    }

    final url = avatarUrl?.trim();
    if (url != null && url.isNotEmpty) {
      return AppImage(
        imageSource: url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: Image.asset(
          UserAvatar.defaultAvatarAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
        errorWidget: Image.asset(
          UserAvatar.defaultAvatarAsset,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      UserAvatar.defaultAvatarAsset,
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
