import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/services/supabase_service.dart';

/// Service handling image picking from Camera/Gallery and uploading to Supabase Storage
class MediaService {
  MediaService._();
  static final MediaService instance = MediaService._();

  final ImagePicker _picker = ImagePicker();

  /// Flag to prevent concurrent image picker invocations that cause PlatformException(already_active)
  bool _isPicking = false;
  bool get isPicking => _isPicking;

  /// Maximum photo size in bytes (10 MB per PRD specification)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Picks an image from Camera or Gallery with downscaling & compression for reports
  Future<XFile?> pickImage(
    ImageSource source, {
    double? maxWidth = 1920,
    double? maxHeight = 1080,
    int imageQuality = 85,
  }) async {
    if (_isPicking) {
      debugPrint(
        'MediaService: Image picker already active, ignoring request.',
      );
      return null;
    }
    _isPicking = true;

    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        imageQuality: imageQuality,
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
    } on PlatformException catch (e) {
      if (e.code == 'already_active') {
        debugPrint('MediaService: Handled PlatformException already_active.');
        return null;
      }
      final msg = e.message?.toLowerCase() ?? '';
      if (e.code == 'camera_access_denied' ||
          msg.contains('camera permission')) {
        throw Exception(
          'Izin akses kamera ditolak. Harap izinkan akses kamera di Pengaturan aplikasi.',
        );
      }
      if (e.code == 'photo_access_denied' ||
          msg.contains('storage permission')) {
        throw Exception(
          'Izin akses galeri ditolak. Harap izinkan akses foto di Pengaturan aplikasi.',
        );
      }
      throw Exception('Gagal mengambil foto: ${e.message ?? e.code}');
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('already_active') || msg.contains('already active')) {
        return null;
      }
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
    } finally {
      _isPicking = false;
    }
  }

  /// Picks an avatar image preserving original scale and orientation,
  /// applying JPEG compression (imageQuality: 80) to reduce server load without distortion.
  Future<XFile?> pickAvatarImage(ImageSource source) async {
    return pickImage(source, maxWidth: null, maxHeight: null, imageQuality: 80);
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

  /// Uploads all selected photos with bounded concurrency (batches of 2)
  /// to protect cellular socket and network memory on low-end devices.
  Future<List<String>> uploadAllPhotos({
    required String authorId,
    required List<XFile> files,
  }) async {
    if (files.isEmpty) return const [];
    final results = List<String>.filled(files.length, '');
    for (int i = 0; i < files.length; i += 2) {
      final end = (i + 2 < files.length) ? i + 2 : files.length;
      final chunkFutures = <Future<void>>[];
      for (int j = i; j < end; j++) {
        final index = j;
        chunkFutures.add(
          uploadPhoto(
            authorId: authorId,
            file: files[index],
            index: index,
          ).then((url) => results[index] = url),
        );
      }
      await Future.wait(chunkFutures);
    }
    return results;
  }

  /// Uploads an avatar image to Supabase Storage bucket 'avatars' (fallback 'profiles').
  /// Safe path format per user: 'avatars/$userId/avatar_$timestamp.$ext'
  Future<String> uploadAvatar({
    required String userId,
    required XFile file,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      // Offline / test fallback
      return file.path;
    }

    try {
      final bytes = await _readFileBytesInIsolate(file);
      final rawExt = file.name.split('.').last.toLowerCase();
      final ext =
          (rawExt == 'png' ||
              rawExt == 'jpg' ||
              rawExt == 'jpeg' ||
              rawExt == 'webp')
          ? rawExt
          : 'jpg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/avatar_$timestamp.$ext';

      try {
        await client.storage
            .from('avatars')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
            );
        return client.storage.from('avatars').getPublicUrl(filePath);
      } catch (avatarError) {
        debugPrint(
          'Catatan upload bucket avatars: $avatarError. Mencoba bucket report-attachments...',
        );
        try {
          final fallbackPath = 'avatars/$userId/avatar_$timestamp.$ext';
          await client.storage
              .from('report-attachments')
              .uploadBinary(
                fallbackPath,
                bytes,
                fileOptions: FileOptions(
                  contentType: 'image/$ext',
                  upsert: true,
                ),
              );
          return client.storage
              .from('report-attachments')
              .getPublicUrl(fallbackPath);
        } catch (fallbackError) {
          debugPrint('Catatan fallback upload avatar: $fallbackError');
          throw avatarError;
        }
      }
    } catch (e) {
      debugPrint('Catatan upload avatar Supabase: $e');
      throw Exception('Gagal mengunggah foto profil ke penyimpanan server: $e');
    }
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
