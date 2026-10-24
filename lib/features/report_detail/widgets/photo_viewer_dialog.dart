import 'dart:io' as io;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Modal dialog untuk melihat foto dalam resolusi penuh, mendukung swipe/geser antar foto dan pinch-to-zoom.
class PhotoViewerDialog extends StatefulWidget {
  const PhotoViewerDialog({
    super.key,
    required this.photoUrls,
    this.initialIndex = 0,
    this.title,
  });

  final List<String> photoUrls;
  final int initialIndex;
  final String? title;

  /// Helper statis untuk menampilkan dialog penampil foto secara mudah
  static Future<void> show({
    required BuildContext context,
    required List<String> photoUrls,
    int initialIndex = 0,
    String? title,
  }) {
    if (photoUrls.isEmpty) return Future.value();
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.92),
      builder: (_) => PhotoViewerDialog(
        photoUrls: photoUrls,
        initialIndex: initialIndex,
        title: title,
      ),
    );
  }

  @override
  State<PhotoViewerDialog> createState() => _PhotoViewerDialogState();
}

class _PhotoViewerDialogState extends State<PhotoViewerDialog> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.photoUrls.length - 1);
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentIndex < widget.photoUrls.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final count = widget.photoUrls.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // 1. Swipeable PageView of zoomable photos
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              itemCount: count,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                return _ZoomablePhotoView(url: widget.photoUrls[index]);
              },
            ),
          ),

          // 2. Navigasi panah kiri (Desktop / Web / Tablet / Aksesibilitas)
          if (count > 1 && _currentIndex > 0)
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.chevron_left_rounded, size: 36),
                  onPressed: _previousPage,
                  tooltip: 'Foto Sebelumnya',
                ),
              ),
            ),

          // 3. Navigasi panah kanan (Desktop / Web / Tablet / Aksesibilitas)
          if (count > 1 && _currentIndex < count - 1)
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black45,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.chevron_right_rounded, size: 36),
                  onPressed: _nextPage,
                  tooltip: 'Foto Selanjutnya',
                ),
              ),
            ),

          // 4. Header Bar: Tombol Tutup & Indikator Halaman
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                color: Colors.black26,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                      tooltip: 'Tutup',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.title != null)
                            Text(
                              widget.title!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (count > 1) ...[
                            if (widget.title != null) const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.white24,
                                  width: 0.5,
                                ),
                              ),
                              child: Text(
                                '${_currentIndex + 1} / $count',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(
                      width: 48,
                    ), // Spacer penyeimbang tombol close
                  ],
                ),
              ),
            ),
          ),

          // 5. Petunjuk kontrol di bagian bawah
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                alignment: Alignment.center,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black45,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    count > 1
                        ? 'Cubit untuk zoom • Geser untuk foto lainnya'
                        : 'Cubit untuk memperbesar foto',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomablePhotoView extends StatefulWidget {
  const _ZoomablePhotoView({required this.url});

  final String url;

  @override
  State<_ZoomablePhotoView> createState() => _ZoomablePhotoViewState();
}

class _ZoomablePhotoViewState extends State<_ZoomablePhotoView> {
  final TransformationController _transformationController =
      TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _handleDoubleTapDown(TapDownDetails details) {
    _doubleTapDetails = details;
  }

  void _handleDoubleTap() {
    if (_transformationController.value != Matrix4.identity()) {
      _transformationController.value = Matrix4.identity();
    } else {
      final position = _doubleTapDetails?.localPosition ?? Offset.zero;
      final tx = -position.dx * 1.5;
      final ty = -position.dy * 1.5;
      _transformationController.value = Matrix4.identity()
        ..setEntry(0, 0, 2.5)
        ..setEntry(1, 1, 2.5)
        ..setEntry(0, 3, tx)
        ..setEntry(1, 3, ty);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: _handleDoubleTapDown,
      onDoubleTap: _handleDoubleTap,
      child: Center(
        child: InteractiveViewer(
          transformationController: _transformationController,
          clipBehavior: Clip.none,
          minScale: 1.0,
          maxScale: 4.5,
          child: _buildImage(widget.url),
        ),
      ),
    );
  }

  Widget _buildImage(String url) {
    final isNetwork =
        url.startsWith('http://') ||
        url.startsWith('https://') ||
        url.startsWith('blob:') ||
        url.startsWith('data:');

    if (isNetwork) {
      return Image.network(
        url,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          final total = loadingProgress.expectedTotalBytes;
          final loaded = loadingProgress.cumulativeBytesLoaded;
          return Center(
            child: CircularProgressIndicator(
              value: total != null ? loaded / total : null,
              color: Colors.white,
            ),
          );
        },
        errorBuilder: (_, _, _) => _errorPlaceholder(),
      );
    }

    if (!kIsWeb) {
      return Image.file(
        io.File(url),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => _errorPlaceholder(),
      );
    }

    return _errorPlaceholder();
  }

  Widget _errorPlaceholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.broken_image_rounded, size: 48, color: Colors.white54),
          SizedBox(height: 8),
          Text(
            'Gagal memuat gambar',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
