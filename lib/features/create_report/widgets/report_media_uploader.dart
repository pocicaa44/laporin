import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';

/// Modular widget for picking, previewing, and removing photo attachments (< 150 lines)
class ReportMediaUploader extends StatefulWidget {
  const ReportMediaUploader({
    super.key,
    required this.photos,
    required this.onAddPhoto,
    required this.onRemovePhoto,
  });

  final List<XFile> photos;
  final ValueChanged<XFile> onAddPhoto;
  final ValueChanged<int> onRemovePhoto;

  @override
  State<ReportMediaUploader> createState() => _ReportMediaUploaderState();
}

class _ReportMediaUploaderState extends State<ReportMediaUploader> {
  @override
  void initState() {
    super.initState();
    _checkLostMedia();
  }

  Future<void> _checkLostMedia() async {
    final lostFile = await MediaService.instance.retrieveLostData();
    if (lostFile != null && mounted) {
      widget.onAddPhoto(lostFile);
    }
  }

  Future<void> _showPickerBottomSheet(BuildContext context) async {
    final primaryColor = AppColors.primaryOf(context);
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pilih Sumber Foto Bukti',
                style: AppTextStyles.sectionTitleOf(context),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.camera,
                  color: primaryColor,
                ),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: FaIcon(
                  FontAwesomeIcons.images,
                  color: primaryColor,
                ),
                title: const Text('Pilih dari Galeri Perangkat'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    try {
      final file = await MediaService.instance.pickImage(source);
      if (file != null && mounted) {
        widget.onAddPhoto(file);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final photos = widget.photos;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Foto Bukti Masalah (Maks. 5)',
              style: AppTextStyles.labelOf(context),
            ),
            Text('${photos.length}/5 Foto', style: AppTextStyles.captionOf(context)),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 94,
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            scrollDirection: Axis.horizontal,
            itemCount: photos.length + (photos.length < 5 ? 1 : 0),
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == photos.length) {
                return _buildAddButton(context);
              }
              return _buildPhotoThumbnail(photos[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = AppColors.primaryOf(context);

    return InkWell(
      onTap: () => _showPickerBottomSheet(context),
      borderRadius: AppRadius.input,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkPrimarySoft : AppColors.primarySubtle,
          borderRadius: AppRadius.input,
          border: Border.all(color: primaryColor, width: 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.camera, color: primaryColor, size: 20),
            const SizedBox(height: 6),
            Text(
              'Tambah',
              style: TextStyle(
                fontSize: 11,
                color: primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoThumbnail(XFile photo, int index) {
    return Stack(
      children: [
        AppImage(
          imageSource: photo.path,
          width: 90,
          height: 90,
          fit: BoxFit.cover,
          memCacheWidth: 180,
          memCacheHeight: 180,
          borderRadius: AppRadius.input,
        ),
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: () => widget.onRemovePhoto(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const FaIcon(
                FontAwesomeIcons.xmark,
                size: 11,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
