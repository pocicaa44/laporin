import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/supabase_service.dart';

/// Service handling image picking from Camera/Gallery and uploading to Supabase Storage
class MediaService {
  MediaService._();
  static final MediaService instance = MediaService._();

  final ImagePicker _picker = ImagePicker();

  /// Maximum photo size in bytes (10 MB per PRD specification)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Picks an image from Camera or Gallery with downscaling & compression
  Future<XFile?> pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (file == null) return null;

      // Inspect file size
      final length = await _getFileLength(file);
      if (length > maxFileSizeBytes) {
        throw Exception(
          'Ukuran foto melebihi batas maksimal 10 MB. Harap pilih foto lain.',
        );
      }

      return file;
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('camera_access_denied') ||
          msg.contains('camera permission')) {
        throw Exception(
          'Izin akses kamera ditolak. Harap izinkan akses kamera di Pengaturan aplikasi.',
        );
      }
      if (msg.contains('photo_access_denied') ||
          msg.contains('storage permission')) {
        throw Exception(
          'Izin akses galeri ditolak. Harap izinkan akses foto di Pengaturan aplikasi.',
        );
      }
      if (e is Exception) rethrow;
      throw Exception('Gagal mengambil foto: $e');
    }
  }

  /// Recovers lost photo data when Android kills MainActivity during camera capture.
  Future<XFile?> retrieveLostData() async {
    if (kIsWeb) return null;
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return null;
      if (response.file != null) {
        final file = response.file!;
        final length = await _getFileLength(file);
        if (length <= maxFileSizeBytes) {
          return file;
        }
      }
    } catch (e) {
      debugPrint('Catatan retrieve lost data: $e');
    }
    return null;
  }

  /// Uploads a single photo to Supabase Storage bucket 'report-attachments'.
  /// Returns the public accessible URL.
  Future<String> uploadPhoto({
    required String authorId,
    required XFile file,
    required int index,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      // Offline fallback: returns local path representation
      return file.path;
    }

    try {
      // Read bytes from disk on a standalone thread isolate to prevent UI frame drops
      final bytes = await _readFileBytesInIsolate(file);
      final ext = file.name.split('.').last;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'reports/$authorId/${timestamp}_$index.$ext';

      await client.storage
          .from('report-attachments')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(
              contentType: 'image/${ext == 'png' ? 'png' : 'jpeg'}',
              upsert: true,
            ),
          );

      final publicUrl = client.storage
          .from('report-attachments')
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Catatan upload lampiran Supabase: $e');
      return file.path;
    }
  }

  /// Batch uploads all selected photos concurrently in parallel.
  Future<List<String>> uploadAllPhotos({
    required String authorId,
    required List<XFile> files,
  }) async {
    if (files.isEmpty) return const [];
    // Concurrently upload photos in parallel using Future.wait
    return await Future.wait(
      List.generate(
        files.length,
        (i) => uploadPhoto(authorId: authorId, file: files[i], index: i),
      ),
    );
  }

  /// Reads raw bytes from disk on a dedicated isolate to avoid blocking the main UI thread.
  static Future<Uint8List> _readFileBytesInIsolate(XFile file) async {
    if (kIsWeb) {
      return await file.readAsBytes();
    }
    try {
      final path = file.path;
      return await Isolate.run<Uint8List>(() {
        final f = File(path);
        if (f.existsSync()) {
          return f.readAsBytesSync();
        }
        throw Exception('File does not exist on disk');
      });
    } catch (_) {
      // Fallback for mocked or virtual files in tests
      return await file.readAsBytes();
    }
  }

  /// Inspects file length safely across platforms and content URIs.
  static Future<int> _getFileLength(XFile file) async {
    try {
      return await file.length();
    } catch (_) {
      if (!kIsWeb) {
        try {
          final path = file.path;
          final f = File(path);
          if (f.existsSync()) {
            return f.lengthSync();
          }
        } catch (_) {}
      }
      return 0;
    }
  }
}
