import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/media_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_image.dart';

/// Widget pemilih dan pratinjau media gambar pengumuman resmi (< 150 baris per skills.md)
class AnnouncementImagePicker extends StatefulWidget {
  const AnnouncementImagePicker({
    super.key,
    this.initialImageUrl,
    this.selectedFile,
    required this.onImageSelected,
    required this.onImageRemoved,
  });

  final String? initialImageUrl;
  final XFile? selectedFile;
  final ValueChanged<XFile> onImageSelected;
  final VoidCallback onImageRemoved;

  @override
  State<AnnouncementImagePicker> createState() =>
      _AnnouncementImagePickerState();
}

class _AnnouncementImagePickerState extends State<AnnouncementImagePicker> {
  Uint8List? _previewBytes;
  bool _isLoadingBytes = false;

  @override
  void initState() {
    super.initState();
    _loadBytesIfNeeded();
  }

  @override
  void didUpdateWidget(covariant AnnouncementImagePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedFile != widget.selectedFile) {
      _loadBytesIfNeeded();
    }
  }

  Future<void> _loadBytesIfNeeded() async {
    final file = widget.selectedFile;
    if (file == null) {
      if (_previewBytes != null && mounted) {
        setState(() => _previewBytes = null);
      }
      return;
    }

    setState(() => _isLoadingBytes = true);
    try {
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _previewBytes = bytes;
          _isLoadingBytes = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingBytes = false);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await MediaService.instance.pickImage(source);
      if (file != null && mounted) {
        widget.onImageSelected(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Pilih Sumber Gambar', style: AppTextStyles.label),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(
                  Icons.photo_library_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Pilih dari Galeri'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt_rounded,
                  color: AppColors.primary,
                ),
                title: const Text('Ambil dari Kamera'),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasFile = widget.selectedFile != null;
    final hasInitialUrl =
        widget.initialImageUrl != null && widget.initialImageUrl!.isNotEmpty;

    if (!hasFile && !hasInitialUrl) {
      return OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(
            color: AppColors.primary,
            style: BorderStyle.solid,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.add_photo_alternate_outlined),
        label: const Text(
          'Tambah Foto Pengumuman (Opsional)',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: _showSourcePicker,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 180,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (hasFile)
                  _isLoadingBytes
                      ? const Center(child: CircularProgressIndicator())
                      : (_previewBytes != null
                            ? Image.memory(_previewBytes!, fit: BoxFit.cover)
                            : const SizedBox.shrink())
                else if (hasInitialUrl)
                  AppImage(
                    imageSource: widget.initialImageUrl!,
                    fit: BoxFit.cover,
                  ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Hapus Foto',
                      onPressed: widget.onImageRemoved,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.image_outlined,
                  size: 16,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 6),
                const Text('Foto Pengumuman', style: AppTextStyles.caption),
                const Spacer(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.primary,
                  ),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Ganti Foto'),
                  onPressed: _showSourcePicker,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
