import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';

/// Modular widget for managing existing and new photo attachments during report edit (< 200 lines)
class EditReportMediaManager extends StatelessWidget {
  const EditReportMediaManager({
    super.key,
    required this.existingPhotos,
    required this.newPhotos,
    required this.onRemoveExistingPhoto,
    required this.onAddNewPhoto,
    required this.onRemoveNewPhoto,
  });

  final List<String> existingPhotos;
  final List<XFile> newPhotos;
  final ValueChanged<int> onRemoveExistingPhoto;
  final ValueChanged<XFile> onAddNewPhoto;
  final ValueChanged<int> onRemoveNewPhoto;

  int get totalCount => existingPhotos.length + newPhotos.length;

  Future<void> _showPickerBottomSheet(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.sheet),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Tambah Foto Bukti Baru',
                style: AppTextStyles.sectionTitle,
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.camera,
                  color: AppColors.primary,
                ),
                title: const Text('Ambil Foto dari Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
              ListTile(
                leading: const FaIcon(
                  FontAwesomeIcons.images,
                  color: AppColors.primary,
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
      if (file != null) {
        onAddNewPhoto(file);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Foto Bukti Masalah (Maks. 5)',
              style: AppTextStyles.label,
            ),
            Text('$totalCount/5 Foto', style: AppTextStyles.caption),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Anda dapat mempertahankan foto tersimpan, menghapusnya, atau menambah foto baru.',
          style: AppTextStyles.caption,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 104,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // 1. Existing photos
              ...List.generate(existingPhotos.length, (index) {
                return _buildExistingPhotoThumbnail(
                  existingPhotos[index],
                  index,
                );
              }),

              // 2. Newly picked photos
              ...List.generate(newPhotos.length, (index) {
                return _buildNewPhotoThumbnail(newPhotos[index], index);
              }),

              // 3. Add button if total < 5
              if (totalCount < 5) _buildAddButton(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildExistingPhotoThumbnail(String url, int index) {
    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          SizedBox(width: 90, height: 90, child: _buildImageFromUrl(url)),
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const BoxDecoration(
                color: Colors.black87,
                borderRadius: AppRadius.borderXs,
              ),
              child: const Text(
                'Tersimpan',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemoveExistingPhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewPhotoThumbnail(XFile file, int index) {
    return Container(
      width: 90,
      height: 90,
      margin: const EdgeInsets.only(right: 10),
      child: Stack(
        children: [
          AppImage(
            imageSource: file.path,
            width: 90,
            height: 90,
            fit: BoxFit.cover,
            memCacheWidth: 180,
            memCacheHeight: 180,
            borderRadius: AppRadius.input,
          ),
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: AppRadius.borderXs,
              ),
              child: const Text(
                'Foto Baru',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => onRemoveNewPhoto(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageFromUrl(String url) {
    return AppImage(
      imageSource: url,
      width: 90,
      height: 90,
      fit: BoxFit.cover,
      memCacheWidth: 180,
      memCacheHeight: 180,
      borderRadius: AppRadius.input,
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return InkWell(
      onTap: () => _showPickerBottomSheet(context),
      borderRadius: AppRadius.input,
      child: Container(
        width: 90,
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.primarySubtle,
          borderRadius: AppRadius.input,
          border: Border.all(color: AppColors.primary, width: 1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.primary,
              size: 26,
            ),
            SizedBox(height: 4),
            Text(
              'Tambah',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
