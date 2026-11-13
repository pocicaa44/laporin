import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/announcement_model.dart';
import '../services/supabase_service.dart';
import 'notification_repository.dart';

/// Repository untuk pengelolaan pengumuman resmi per PRD.md FR-09
class AnnouncementRepository {
  AnnouncementRepository({SupabaseService? supabaseService})
    : _service = supabaseService ?? SupabaseService.instance {
    _initRealtimeSubscription();
    _loadPreferences();
  }

  static const String _prefReadIdsKey = 'laporin_announcements_read_ids';

  final SupabaseService _service;
  RealtimeChannel? _realtimeChannel;
  StreamSubscription<List<Map<String, dynamic>>>? _streamSubscription;

  final List<AnnouncementModel> _announcements = [];
  final Set<String> _readAnnouncementIds = {};
  bool _isViewingAnnouncements = false;
  bool _markFetchedAsReadOnNextFetch = false;
  bool _hasFetched = false;

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void notifyListeners() {
    for (final listener in List.of(_listeners)) {
      listener();
    }
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedReadIds = prefs.getStringList(_prefReadIdsKey);
      if (savedReadIds != null) {
        _readAnnouncementIds.addAll(savedReadIds);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Catatan load SharedPreferences announcements: $e');
    }
  }

  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefReadIdsKey, _readAnnouncementIds.toList());
    } catch (e) {
      debugPrint('Catatan save SharedPreferences announcements: $e');
    }
  }

  void _initRealtimeSubscription() {
    final client = _service.client;
    if (client == null) return;

    try {
      _streamSubscription?.cancel();
      _streamSubscription = client
          .from('announcements')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false)
          .listen(
            (data) {
              final list = data
                  .map((item) => AnnouncementModel.fromJson(item))
                  .toList();
              _announcements.clear();
              _announcements.addAll(list);
              _hasFetched = true;
              if (_isViewingAnnouncements || _markFetchedAsReadOnNextFetch) {
                _readAnnouncementIds.addAll(_announcements.map((a) => a.id));
                _markFetchedAsReadOnNextFetch = false;
                _savePreferences();
              }
              notifyListeners();
            },
            onError: (e) {
              debugPrint('Announcements realtime stream notice: $e');
            },
          );
    } catch (e) {
      debugPrint('Realtime announcements subscription notice: $e');
    }
  }

  /// Memperbarui atau menyambung ulang stream realtime
  void reconnectRealtime() {
    _initRealtimeSubscription();
  }

  void dispose() {
    _streamSubscription?.cancel();
    _realtimeChannel?.unsubscribe();
    _listeners.clear();
  }

  /// Daftar pengumuman yang tersimpan dalam memori
  List<AnnouncementModel> get cachedAnnouncements =>
      List.unmodifiable(_announcements);

  /// ID pengumuman yang sudah dibaca / dibuka oleh pengguna
  Set<String> get readAnnouncementIds => Set.unmodifiable(_readAnnouncementIds);

  /// Status apakah user sedang aktif membuka layar pengumuman
  bool get isViewingAnnouncements => _isViewingAnnouncements;

  /// Mengatur status aktif melihat layar pengumuman
  void setViewingAnnouncements(bool isViewing) {
    _isViewingAnnouncements = isViewing;
    if (isViewing) {
      markAllAsRead();
    }
  }

  /// Jumlah pengumuman baru yang belum dibuka pengguna
  int get unreadCount {
    if (_isViewingAnnouncements) {
      return 0;
    }
    return _announcements
        .where((a) => !_readAnnouncementIds.contains(a.id))
        .length;
  }

  /// Cek apakah pengumuman tertentu sudah dibaca
  bool isRead(String id) => _readAnnouncementIds.contains(id);

  /// Menandai semua pengumuman yang ada sebagai sudah dibaca (badge hilang)
  void markAllAsRead() {
    if (_announcements.isEmpty) {
      _markFetchedAsReadOnNextFetch = true;
    } else {
      _readAnnouncementIds.addAll(_announcements.map((a) => a.id));
      _markFetchedAsReadOnNextFetch = false;
      _savePreferences();
    }
    notifyListeners();
  }

  /// Menandai satu pengumuman sebagai sudah dibaca
  void markAsRead(String id) {
    _readAnnouncementIds.add(id);
    _savePreferences();
    notifyListeners();
  }

  /// Helper pengujian untuk mengisi data mock
  void setAnnouncementsForTesting(
    List<AnnouncementModel> list, {
    Set<String>? readIds,
  }) {
    _announcements.clear();
    _announcements.addAll(list);
    _readAnnouncementIds.clear();
    if (readIds != null) {
      _readAnnouncementIds.addAll(readIds);
    }
    _isViewingAnnouncements = false;
    _markFetchedAsReadOnNextFetch = false;
    _hasFetched = true;
    notifyListeners();
  }

  /// Menambahkan pengumuman baru untuk simulasi realtime (testing/development)
  void addAnnouncementForTesting(AnnouncementModel announcement) {
    _announcements.insert(0, announcement);
    if (_isViewingAnnouncements) {
      _readAnnouncementIds.add(announcement.id);
    }
    notifyListeners();
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
        if (_isViewingAnnouncements || _markFetchedAsReadOnNextFetch) {
          _readAnnouncementIds.addAll(_announcements.map((a) => a.id));
          _markFetchedAsReadOnNextFetch = false;
          _savePreferences();
        }
        notifyListeners();
        return list;
      } catch (e) {
        debugPrint('Catatan fetch announcements Supabase: $e');
        // Jika tabel belum ada atau jaringan offline, gunakan data cache
      }
    }

    _hasFetched = true;
    notifyListeners();
    return List<AnnouncementModel>.from(_announcements);
  }

  /// Membuat pengumuman baru oleh admin dan menyimpannya ke Supabase
  Future<AnnouncementModel> createAnnouncement({
    required String title,
    required String content,
    String category = 'Umum',
    String? imageUrl,
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
      imageUrl: imageUrl,
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
          'image_url': ?imageUrl,
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
          notifyListeners();
          try {
            NotificationRepository.instance.notifyAnnouncement(
              announcementTitle: cleanTitle,
              announcementContent: cleanContent,
            );
          } catch (_) {}
          return serverAnnouncement;
        }
      } catch (e) {
        debugPrint('Catatan insert announcement Supabase: $e');
        // Lanjutkan dengan local model jika offline / error
      }
    }

    _announcements.insert(0, newAnnouncement);
    notifyListeners();
    try {
      NotificationRepository.instance.notifyAnnouncement(
        announcementTitle: cleanTitle,
        announcementContent: cleanContent,
      );
    } catch (_) {}
    return newAnnouncement;
  }

  /// Memperbarui pengumuman resmi oleh admin
  Future<AnnouncementModel> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    String category = 'Umum',
    String? imageUrl,
    bool clearImageUrl = false,
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
    final client = _service.client;
    if (client != null && client.auth.currentUser != null) {
      try {
        final payload = <String, dynamic>{
          'title': cleanTitle,
          'content': cleanContent,
          'category': category,
          'updated_at': now.toUtc().toIso8601String(),
        };
        if (clearImageUrl) {
          payload['image_url'] = null;
        } else if (imageUrl != null) {
          payload['image_url'] = imageUrl;
        }

        final response = await client
            .from('announcements')
            .update(payload)
            .eq('id', id)
            .select()
            .maybeSingle();

        if (response != null) {
          final serverAnnouncement = AnnouncementModel.fromJson(response);
          final index = _announcements.indexWhere((a) => a.id == id);
          if (index != -1) {
            _announcements[index] = serverAnnouncement;
          } else {
            _announcements.insert(0, serverAnnouncement);
          }
          notifyListeners();
          return serverAnnouncement;
        } else {
          throw Exception(
            'Pengumuman tidak ditemukan di database atau akses ditolak.',
          );
        }
      } catch (e) {
        debugPrint('Error update announcement Supabase: $e');
        rethrow;
      }
    }

    final index = _announcements.indexWhere((a) => a.id == id);
    if (index != -1) {
      final existing = _announcements[index];
      final updated = existing.copyWith(
        title: cleanTitle,
        content: cleanContent,
        category: category,
        imageUrl: imageUrl,
        clearImageUrl: clearImageUrl,
        updatedAt: now,
      );
      _announcements[index] = updated;
      notifyListeners();
      return updated;
    }

    throw Exception('Pengumuman tidak ditemukan.');
  }

  /// Menghapus pengumuman resmi oleh admin
  Future<bool> deleteAnnouncement(String id) async {
    final client = _service.client;
    if (client != null && client.auth.currentUser != null) {
      try {
        await client.from('announcements').delete().eq('id', id);
      } catch (e) {
        debugPrint('Catatan delete announcement Supabase: $e');
      }
    }

    _announcements.removeWhere((a) => a.id == id);
    _readAnnouncementIds.remove(id);
    notifyListeners();
    return true;
  }
}
