import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
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

  /// Maximum photo size in bytes (10 MB per PRD specification for reports)
  static const int maxFileSizeBytes = 10 * 1024 * 1024;

  /// Maximum avatar size in bytes (30 KB = 30,000 bytes per avatar optimization rule)
  static const int maxAvatarSizeBytes = 30000;

  /// Target dimension for square avatar photo (256x256 pixels)
  static const int targetAvatarDimension = 256;

  /// Step-down resolutions for adaptive avatar compression
  static const List<int> avatarResolutions = [256, 192, 128];

  /// Step-down qualities for adaptive avatar compression
  static const List<int> avatarQualities = [75, 65, 55, 45, 35, 25];

  /// Adaptively crops to 1:1, bakes EXIF orientation, resizes, and compresses
  /// an avatar image to <= 30,000 bytes (max 30 KB).
  ///
  /// Steps:
  /// 1. Decode raw bytes into an Image object.
  /// 2. Bake EXIF orientation to ensure upright display without distortion.
  /// 3. Center-crop to 1:1 square aspect ratio.
  /// 4. Adaptively attempt combinations of resolutions (256, 192, 128) and qualities (75 -> 25).
  /// 5. Return immediately when byte size is <= 30,000 bytes.
  /// 6. If even 128x128 at quality 25 exceeds 30,000 bytes, throw an informative exception.
  static Uint8List compressAvatarBytes(Uint8List rawBytes) {
    final original = img.decodeImage(rawBytes);
    if (original == null) {
      throw Exception('Format gambar tidak didukung atau file gambar rusak.');
    }

    // Bake EXIF orientation to keep correct rotation
    final baked = img.bakeOrientation(original);

    // Center crop to 1:1 square aspect ratio
    final side = math.min(baked.width, baked.height);
    final cropX = (baked.width - side) ~/ 2;
    final cropY = (baked.height - side) ~/ 2;
    final cropped = (baked.width == side && baked.height == side)
        ? baked
        : img.copyCrop(baked, x: cropX, y: cropY, width: side, height: side);

    // Adaptive compression loop across resolutions and qualities
    for (final dim in avatarResolutions) {
      final resized = (cropped.width == dim && cropped.height == dim)
          ? cropped
          : img.copyResize(
              cropped,
              width: dim,
              height: dim,
              interpolation: img.Interpolation.linear,
            );

      for (final quality in avatarQualities) {
        final compressed = Uint8List.fromList(
          img.encodeJpg(resized, quality: quality),
        );
        if (compressed.lengthInBytes <= maxAvatarSizeBytes) {
          return compressed;
        }
      }
    }

    throw Exception(
      'Foto profil tidak dapat dikompresi di bawah 30 KB. Harap pilih foto lain.',
    );
  }

  /// Compresses avatar bytes asynchronously without blocking the UI thread.
  Future<Uint8List> compressAvatar(Uint8List rawBytes) async {
    if (kIsWeb) {
      return compressAvatarBytes(rawBytes);
    }
    return await compute(compressAvatarBytes, rawBytes);
  }

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

  /// Picks an avatar image from Camera or Gallery, crops to 1:1, bakes orientation,
  /// and adaptively compresses it to target <= 30 KB (30,000 bytes).
  Future<XFile?> pickAvatarImage(ImageSource source) async {
    final picked = await pickImage(
      source,
      maxWidth: null,
      maxHeight: null,
      imageQuality: 100,
    );
    if (picked == null) return null;

    final rawBytes = await _readFileBytesInIsolate(picked);
    final compressedBytes = await compressAvatar(rawBytes);

    if (!kIsWeb) {
      try {
        final tempDir = Directory.systemTemp;
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final tempFile = File('${tempDir.path}/avatar_$timestamp.jpg');
        await tempFile.writeAsBytes(compressedBytes, flush: true);
        return XFile(
          tempFile.path,
          bytes: compressedBytes,
          name: 'avatar_$timestamp.jpg',
          mimeType: 'image/jpeg',
        );
      } catch (e) {
        debugPrint('Catatan simpan temp file avatar: $e');
        return XFile.fromData(
          compressedBytes,
          name: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
          mimeType: 'image/jpeg',
        );
      }
    } else {
      return XFile.fromData(
        compressedBytes,
        name: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
        mimeType: 'image/jpeg',
      );
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

  /// Uploads an announcement photo to Supabase Storage bucket 'report-attachments'.
  /// Returns the public accessible URL.
  Future<String> uploadAnnouncementPhoto({
    required String authorId,
    required XFile file,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      return file.path;
    }

    try {
      final bytes = await _readFileBytesInIsolate(file);
      final rawExt = file.name.split('.').last.toLowerCase();
      final ext = (rawExt == 'png' || rawExt == 'webp') ? rawExt : 'jpeg';
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = 'announcements/$authorId/$timestamp.$ext';

      await client.storage
          .from('report-attachments')
          .uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: 'image/$ext', upsert: true),
          );

      final publicUrl = client.storage
          .from('report-attachments')
          .getPublicUrl(filePath);
      return publicUrl;
    } catch (e) {
      debugPrint('Catatan upload foto pengumuman Supabase: $e');
      return file.path;
    }
  }

  /// Uploads an avatar image to Supabase Storage bucket 'avatars' (fallback 'report-attachments').
  /// Ensures file is processed and strictly <= 30,000 bytes before upload.
  /// Safe path format per user: '$userId/avatar_$timestamp.jpg'
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
      var bytes = await _readFileBytesInIsolate(file);

      // Pastikan bytes telah dikompresi ke <= 30.000 byte dan 1:1 rasio
      if (bytes.lengthInBytes > maxAvatarSizeBytes) {
        bytes = await compressAvatar(bytes);
      }

      // Validasi ketat sisi klien: ukuran final tidak boleh melebihi 30.000 byte
      if (bytes.lengthInBytes > maxAvatarSizeBytes) {
        throw Exception(
          'Ukuran foto profil (${bytes.lengthInBytes} byte) melebihi batas maksimal 30 KB.',
        );
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/avatar_$timestamp.jpg';

      try {
        await client.storage
            .from('avatars')
            .uploadBinary(
              filePath,
              bytes,
              fileOptions: const FileOptions(
                contentType: 'image/jpeg',
                upsert: true,
              ),
            );
        return client.storage.from('avatars').getPublicUrl(filePath);
      } catch (avatarError) {
        debugPrint(
          'Catatan upload bucket avatars: $avatarError. Mencoba fallback ke bucket report-attachments...',
        );
        try {
          final fallbackPath = 'avatars/$userId/avatar_$timestamp.jpg';
          await client.storage
              .from('report-attachments')
              .uploadBinary(
                fallbackPath,
                bytes,
                fileOptions: const FileOptions(
                  contentType: 'image/jpeg',
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
      if (e is Exception) rethrow;
      throw Exception('Gagal mengunggah foto profil ke penyimpanan server: $e');
    }
  }

  /// Parses Supabase Storage reference (bucket and path) from an avatar URL or path.
  ///
  /// CRITICAL SECURITY RULES:
  /// 1. Rejects external URLs (e.g., Google, Unsplash) and asset paths ('assets/...').
  /// 2. Prevents path traversal (e.g. contains '..').
  /// 3. Ensures the path strictly belongs to [userId] (starts with '$userId/' or 'avatars/$userId/').
  /// 4. Restricts deletion to valid avatar storage buckets ('avatars' or 'report-attachments').
  static ({String bucket, String path})? parseAvatarStoragePath({
    required String? avatarUrl,
    required String userId,
  }) {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) return null;
    final clean = avatarUrl.trim();

    // Abaikan jika merupakan asset lokal
    if (clean.startsWith('assets/') || clean.startsWith('asset/')) {
      return null;
    }

    final uri = Uri.tryParse(clean);
    if (uri == null) return null;

    // Jika merupakan URL lengkap (http/https)
    if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final segments = uri.pathSegments;
      // Format URL Supabase Storage: /storage/v1/object/(public|sign|authenticated)/<bucket>/<path...>
      final objectIdx = segments.indexOf('object');
      if (objectIdx != -1 && objectIdx + 2 < segments.length) {
        final bucket = segments[objectIdx + 2];
        final objectPath = segments.sublist(objectIdx + 3).join('/');

        // Cegah path traversal
        if (objectPath.contains('..')) return null;

        if (bucket == 'avatars') {
          // Harus diawali folder userId milik pengguna yang sedang login
          if (objectPath.startsWith('$userId/') ||
              objectPath.startsWith('avatars/$userId/')) {
            return (bucket: 'avatars', path: objectPath);
          }
        } else if (bucket == 'report-attachments') {
          // Pada fallback report-attachments, avatar wajib berada di avatars/{userId}/
          if (objectPath.startsWith('avatars/$userId/')) {
            return (bucket: 'report-attachments', path: objectPath);
          }
        }
        return null;
      }
      // Bukan URL Supabase Storage (misalnya avatar Google, OAuth, atau CDN pihak ketiga)
      return null;
    }

    // Jika merupakan relative path
    final normalized = clean.replaceAll(r'\', '/');
    if (normalized.contains('..')) return null;

    if (normalized.startsWith('avatars/$userId/')) {
      return (bucket: 'avatars', path: normalized);
    } else if (normalized.startsWith('$userId/')) {
      return (bucket: 'avatars', path: normalized);
    }

    return null;
  }

  /// Deletes an avatar file from Supabase Storage if and only if it belongs to [userId].
  /// Returns true if deletion succeeded, false otherwise.
  Future<bool> deleteAvatarFile({
    required String? avatarUrl,
    required String userId,
  }) async {
    if (avatarUrl == null || avatarUrl.trim().isEmpty) return false;

    final ref = parseAvatarStoragePath(avatarUrl: avatarUrl, userId: userId);
    if (ref == null) {
      debugPrint(
        'MediaService: Avatar URL bukan file storage milik pengguna aktif, melewati penghapusan: $avatarUrl',
      );
      return false;
    }

    final client = SupabaseService.instance.client;
    if (client == null) {
      debugPrint(
        'MediaService: Supabase client offline, tidak dapat menghapus avatar lama.',
      );
      return false;
    }

    try {
      debugPrint(
        'MediaService: Menghapus avatar lama di bucket "${ref.bucket}", path: "${ref.path}"',
      );
      await client.storage.from(ref.bucket).remove([ref.path]);
      return true;
    } catch (e) {
      debugPrint(
        'Catatan gagal menghapus avatar lama dari Supabase Storage: $e',
      );
      return false;
    }
  }

  /// Parses Supabase Storage reference (bucket and path) from any storage URL or relative path.
  static ({String bucket, String path})? parseStoragePath(String? url) {
    if (url == null || url.trim().isEmpty) return null;
    final clean = url.trim();

    // Abaikan jika merupakan asset lokal
    if (clean.startsWith('assets/') || clean.startsWith('asset/')) {
      return null;
    }

    final uri = Uri.tryParse(clean);
    if (uri == null) return null;

    if (uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https')) {
      final segments = uri.pathSegments;
      final objectIdx = segments.indexOf('object');
      if (objectIdx != -1 && objectIdx + 2 < segments.length) {
        final bucket = segments[objectIdx + 2];
        final objectPath = segments.sublist(objectIdx + 3).join('/');
        if (objectPath.contains('..')) return null;
        return (bucket: bucket, path: objectPath);
      }
      return null;
    }

    final normalized = clean
        .replaceAll(r'\', '/')
        .replaceFirst(RegExp(r'^/+'), '');
    if (normalized.contains('..')) return null;
    if (normalized.startsWith('reports/') ||
        normalized.startsWith('announcements/') ||
        normalized.startsWith('avatars/')) {
      return (bucket: 'report-attachments', path: normalized);
    }

    return null;
  }

  /// Menghapus file-file media laporan (foto lampiran & bukti penyelesaian)
  /// dari Supabase Storage secara tuntas agar tidak membebani penyimpanan server.
  Future<int> deleteReportMedia({
    required List<String> photoUrls,
    String? completionProofUrl,
  }) async {
    final client = SupabaseService.instance.client;
    if (client == null) {
      debugPrint(
        'MediaService: Supabase client offline, melewati penghapusan media storage.',
      );
      return 0;
    }

    final allUrls = <String>[...photoUrls];
    if (completionProofUrl != null && completionProofUrl.trim().isNotEmpty) {
      allUrls.add(completionProofUrl.trim());
    }

    if (allUrls.isEmpty) return 0;

    final bucketToPaths = <String, Set<String>>{};

    for (final url in allUrls) {
      final parsed = parseStoragePath(url);
      if (parsed != null) {
        bucketToPaths
            .putIfAbsent(parsed.bucket, () => <String>{})
            .add(parsed.path);
      }
    }

    int totalDeleted = 0;
    for (final entry in bucketToPaths.entries) {
      try {
        final paths = entry.value.toList();
        if (paths.isNotEmpty) {
          debugPrint(
            'MediaService: Menghapus ${paths.length} file media dari bucket "${entry.key}": $paths',
          );
          await client.storage.from(entry.key).remove(paths);
          totalDeleted += paths.length;
        }
      } catch (e) {
        debugPrint(
          'Catatan gagal membersihkan media dari storage bucket ${entry.key}: $e',
        );
      }
    }

    return totalDeleted;
  }

  /// Reads raw bytes from disk on a dedicated isolate to avoid blocking the main UI thread.
  static Future<Uint8List> _readFileBytesInIsolate(XFile file) async {
    if (kIsWeb) {
      return await file.readAsBytes();
    }
    if (file.path.isEmpty) {
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
