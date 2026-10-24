import 'package:flutter/foundation.dart';

import '../models/announcement_model.dart';
import '../services/supabase_service.dart';

/// Repository untuk pengelolaan pengumuman resmi per PRD.md FR-09
class AnnouncementRepository {
  AnnouncementRepository({SupabaseService? supabaseService})
    : _service = supabaseService ?? SupabaseService.instance;

  final SupabaseService _service;

  final List<AnnouncementModel> _announcements = [];
  bool _hasFetched = false;

  /// Daftar pengumuman yang tersimpan dalam memori
  List<AnnouncementModel> get cachedAnnouncements =>
      List.unmodifiable(_announcements);

  /// Helper pengujian untuk mengisi data mock
  void setAnnouncementsForTesting(List<AnnouncementModel> list) {
    _announcements.clear();
    _announcements.addAll(list);
    _hasFetched = true;
  }

  /// Mengambil daftar pengumuman dari Supabase atau memori lokal
  Future<List<AnnouncementModel>> getAnnouncements({
    bool forceRefresh = false,
  }) async {
    if (_hasFetched && !forceRefresh) {
      return List<AnnouncementModel>.from(_announcements);
    }

    final client = _service.client;
    if (client != null) {
      try {
        final response = await client
            .from('announcements')
            .select()
            .order('created_at', ascending: false);

        final rawList = response as List;
        final list = rawList
            .map(
              (item) =>
                  AnnouncementModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();

        _announcements.clear();
        _announcements.addAll(list);
        _hasFetched = true;
        return list;
      } catch (e) {
        debugPrint('Catatan fetch announcements Supabase: $e');
        // Jika tabel belum ada atau jaringan offline, gunakan data cache
      }
    }

    _hasFetched = true;
    return List<AnnouncementModel>.from(_announcements);
  }

  /// Membuat pengumuman baru oleh admin dan menyimpannya ke Supabase
  Future<AnnouncementModel> createAnnouncement({
    required String title,
    required String content,
    String category = 'Umum',
    required String authorId,
    required String authorName,
  }) async {
    final cleanTitle = title.trim();
    final cleanContent = content.trim();

    if (cleanTitle.length < 5) {
      throw Exception('Judul pengumuman minimal 5 karakter.');
    }
    if (cleanContent.length < 10) {
      throw Exception('Isi pengumuman minimal 10 karakter.');
    }

    final now = DateTime.now();
    final id = 'ann-${now.millisecondsSinceEpoch}';

    final newAnnouncement = AnnouncementModel(
      id: id,
      title: cleanTitle,
      content: cleanContent,
      category: category,
      authorId: authorId,
      authorName: authorName,
      isPublished: true,
      createdAt: now,
      updatedAt: now,
    );

    final client = _service.client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final payload = {
          'title': cleanTitle,
          'content': cleanContent,
          'category': category,
          'author_id': authorId,
          'author_name': authorName,
          'is_published': true,
          'created_at': now.toUtc().toIso8601String(),
          'updated_at': now.toUtc().toIso8601String(),
        };

        final response = await client
            .from('announcements')
            .insert(payload)
            .select()
            .maybeSingle();

        if (response != null) {
          final serverAnnouncement = AnnouncementModel.fromJson(response);
          _announcements.insert(0, serverAnnouncement);
          return serverAnnouncement;
        }
      } catch (e) {
        debugPrint('Catatan insert announcement Supabase: $e');
        // Lanjutkan dengan local model jika offline / error
      }
    }

    _announcements.insert(0, newAnnouncement);
    return newAnnouncement;
  }
}
