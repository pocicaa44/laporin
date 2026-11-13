import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../models/report_model.dart';
import '../services/supabase_service.dart';

/// Repository untuk mengelola riwayat notifikasi in-app per PRD.md Bagian 10.1 & DESIGN.md 5.12
/// Dilengkapi sistem deduplikasi ketat (anti-double) dan sinkronisasi real-time.
class NotificationRepository {
  NotificationRepository({SupabaseService? supabaseService})
    : _service = supabaseService ?? SupabaseService.instance {
    initRealtimeSubscription();
  }

  static NotificationRepository? _instance;
  static NotificationRepository get instance =>
      _instance ??= NotificationRepository();

  @visibleForTesting
  static void setInstanceForTesting(NotificationRepository? repo) {
    _instance = repo;
  }

  final SupabaseService _service;
  final List<NotificationModel> _notifications = [];
  StreamSubscription<List<Map<String, dynamic>>>? _streamSubscription;

  final List<VoidCallback> _listeners = [];
  void addListener(VoidCallback listener) => _listeners.add(listener);
  void removeListener(VoidCallback listener) => _listeners.remove(listener);
  void notifyListeners() {
    for (final listener in List.of(_listeners)) {
      try {
        listener();
      } catch (_) {}
    }
  }

  /// Helper untuk keperluan pengujian / unit test
  @visibleForTesting
  void setNotificationsForTesting(List<NotificationModel> items) {
    _setDeduplicatedNotifications(items);
    notifyListeners();
  }

  /// Inisialisasi subscription Supabase Realtime agar notifikasi baru masuk seketika
  void initRealtimeSubscription() {
    final client = _service.client;
    final currentUser = _service.currentUser;
    if (client == null || currentUser == null) return;

    try {
      _streamSubscription?.cancel();
      _streamSubscription = client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', currentUser.id)
          .order('created_at', ascending: false)
          .listen(
            (data) {
              final items = data
                  .map(
                    (item) => NotificationModel.fromJson(
                      Map<String, dynamic>.from(item),
                    ),
                  )
                  .toList();
              _setDeduplicatedNotifications(items);
              notifyListeners();
            },
            onError: (e) {
              debugPrint('Notifications realtime stream notice: $e');
            },
          );
    } catch (e) {
      debugPrint('Realtime notifications subscription notice: $e');
    }
  }

  /// Memperbarui stream realtime saat terjadi perubahan login user
  void reconnectRealtime() {
    initRealtimeSubscription();
  }

  /// Logika deduplikasi ketat: menyaring id identik dan event yang berulang dalam 5 detik
  void _setDeduplicatedNotifications(List<NotificationModel> items) {
    final seenIds = <String>{};
    final unique = <NotificationModel>[];

    for (final item in items) {
      if (!seenIds.add(item.id)) continue;

      final isDuplicate = unique.any((existing) =>
          existing.type == item.type &&
          existing.reportId == item.reportId &&
          existing.title == item.title &&
          existing.message == item.message &&
          existing.createdAt.difference(item.createdAt).abs().inSeconds < 5);

      if (!isDuplicate) {
        unique.add(item);
      }
    }

    unique.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _notifications
      ..clear()
      ..addAll(unique);
  }

  /// Mengambil daftar notifikasi pengguna dari Supabase (atau fallback in-memory)
  /// dengan jaminan deduplikasi (tidak akan pernah memuat notifikasi dobel).
  Future<List<NotificationModel>> getNotifications() async {
    final client = _service.client;
    final currentUser = _service.currentUser;

    if (client != null && currentUser != null) {
      try {
        final response = await client
            .from('notifications')
            .select()
            .eq('user_id', currentUser.id)
            .order('created_at', ascending: false)
            .limit(50);

        final items = (response as List<dynamic>)
            .map(
              (item) => NotificationModel.fromJson(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();

        _setDeduplicatedNotifications(items);
        return List.unmodifiable(_notifications);
      } catch (e) {
        debugPrint('Catatan getNotifications Supabase: $e');
      }
    }

    // Fallback in-memory list (untuk offline mode atau saat testing)
    final list = List<NotificationModel>.from(_notifications);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  static String _generateUuid() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant RFC 4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// Menambahkan notifikasi baru dengan proteksi duplikasi instan
  Future<void> addNotification(NotificationModel notification) async {
    // 1. Cek duplikasi di state lokal
    final isDuplicate = _notifications.any((existing) =>
        existing.id == notification.id ||
        (existing.type == notification.type &&
            existing.reportId == notification.reportId &&
            existing.title == notification.title &&
            existing.message == notification.message &&
            existing.createdAt
                    .difference(notification.createdAt)
                    .abs()
                    .inSeconds <
                5));

    if (isDuplicate) return;

    _notifications.insert(0, notification);
    notifyListeners();

    // 2. Jika koneksi Supabase tersedia dan user login, simpan ke database dengan valid UUID
    final client = _service.client;
    final currentUser = _service.currentUser;
    if (client != null && currentUser != null) {
      try {
        final validUuidRegex = RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          caseSensitive: false,
        );
        final effectiveId = validUuidRegex.hasMatch(notification.id)
            ? notification.id
            : _generateUuid();

        await client.from('notifications').insert({
          'id': effectiveId,
          'user_id': currentUser.id,
          'title': notification.title,
          'message': notification.message,
          'type': notification.type.value,
          if (notification.reportId != null) 'report_id': notification.reportId,
          'is_read': notification.isRead,
          'created_at': notification.createdAt.toUtc().toIso8601String(),
        });
      } catch (e) {
        debugPrint('Catatan insert notification Supabase: $e');
      }
    }
  }

  /// Helper untuk memicu notifikasi perubahan status laporan (User)
  Future<void> notifyStatusChanged({
    required String reportId,
    required String reportTitle,
    required String statusLabel,
    HandlingStatus? status,
    String? customMessage,
    String? customTitle,
  }) async {
    final now = DateTime.now();
    String title;
    if (customTitle != null && customTitle.isNotEmpty) {
      title = customTitle;
    } else if (status == HandlingStatus.completed ||
        statusLabel.toLowerCase().contains('selesai')) {
      title = 'Laporan Anda telah diselesaikan!';
    } else if (status == HandlingStatus.rejected ||
        statusLabel.toLowerCase().contains('tolak') ||
        statusLabel.toLowerCase().contains('ditolak')) {
      title = 'Laporan Anda ditolak!';
    } else {
      title = 'Status laporan Anda diperbarui!';
    }

    final notif = NotificationModel(
      id: _generateUuid(),
      title: title,
      message: customMessage ?? 'Laporan $reportTitle $statusLabel',
      type: NotificationType.statusChanged,
      reportId: reportId,
      createdAt: now,
    );
    await addNotification(notif);
  }

  /// Helper untuk memicu notifikasi laporan baru masuk (Admin)
  Future<void> notifyNewReport({
    required String reportId,
    required String reportTitle,
  }) async {
    final now = DateTime.now();
    final notif = NotificationModel(
      id: _generateUuid(),
      title: 'Laporan Baru!',
      message: 'Laporan "$reportTitle" baru saja dikirim warga.',
      type: NotificationType.newReport,
      reportId: reportId,
      createdAt: now,
    );
    await addNotification(notif);
  }

  /// Helper untuk memicu notifikasi dukungan/upvote warga (User)
  Future<void> notifyUpvoted({
    required String reportId,
    required String reportTitle,
  }) async {
    final now = DateTime.now();
    final notif = NotificationModel(
      id: _generateUuid(),
      title: 'Seseorang mendukung laporan Anda!',
      message: 'Laporan "$reportTitle" mendapat dukungan warga.',
      type: NotificationType.upvoted,
      reportId: reportId,
      createdAt: now,
    );
    await addNotification(notif);
  }

  /// Helper untuk memicu notifikasi komentar masuk (User)
  Future<void> notifyNewComment({
    required String reportId,
    required String reportTitle,
    required String commenterName,
    required String commentBody,
  }) async {
    final now = DateTime.now();
    final preview = commentBody.length > 60
        ? '${commentBody.substring(0, 60)}...'
        : commentBody;
    final notif = NotificationModel(
      id: _generateUuid(),
      title: 'Seseorang mengomentari laporan Anda!',
      message: '$commenterName mengomentari laporan $reportTitle: "$preview"',
      type: NotificationType.newComment,
      reportId: reportId,
      createdAt: now,
    );
    await addNotification(notif);
  }

  /// Helper untuk memicu notifikasi balasan komentar (Admin & User)
  Future<void> notifyReplyComment({
    required String reportId,
    required String replierName,
    required String replyBody,
  }) async {
    final now = DateTime.now();
    final preview = replyBody.length > 60
        ? '${replyBody.substring(0, 60)}...'
        : replyBody;
    final notif = NotificationModel(
      id: _generateUuid(),
      title: 'Seseorang membalas komentar Anda!',
      message: '$replierName membalas komentar Anda: "$preview"',
      type: NotificationType.replyComment,
      reportId: reportId,
      createdAt: now,
    );
    await addNotification(notif);
  }

  /// Helper untuk memicu notifikasi pengumuman baru (Admin & User)
  Future<void> notifyAnnouncement({
    required String announcementTitle,
    String? announcementContent,
  }) async {
    final now = DateTime.now();
    final notif = NotificationModel(
      id: _generateUuid(),
      title: 'Pengumuman baru diterbitkan!',
      message: announcementTitle,
      type: NotificationType.announcement,
      createdAt: now,
    );
    await addNotification(notif);
  }

  /// Menandai sebuah notifikasi telah dibaca
  Future<void> markAsRead(String id) async {
    final client = _service.client;
    final currentUser = _service.currentUser;

    if (client != null && currentUser != null) {
      try {
        await client
            .from('notifications')
            .update({'is_read': true})
            .eq('id', id)
            .eq('user_id', currentUser.id);
      } catch (e) {
        debugPrint('Catatan markAsRead Supabase: $e');
      }
    }

    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();
    }
  }

  /// Menandai seluruh notifikasi yang belum dibaca menjadi sudah dibaca
  Future<void> markAllAsRead() async {
    final client = _service.client;
    final currentUser = _service.currentUser;

    if (client != null && currentUser != null) {
      try {
        await client.rpc('mark_all_notifications_read');
      } catch (_) {
        try {
          await client
              .from('notifications')
              .update({'is_read': true})
              .eq('user_id', currentUser.id)
              .eq('is_read', false);
        } catch (e) {
          debugPrint('Catatan markAllAsRead Supabase: $e');
        }
      }
    }

    for (int i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
  }

  /// Menghapus daftar notifikasi berdasarkan ID secara permanen
  Future<void> deleteNotifications(List<String> ids) async {
    if (ids.isEmpty) return;

    final client = _service.client;
    final currentUser = _service.currentUser;

    if (client != null && currentUser != null) {
      try {
        await client
            .from('notifications')
            .delete()
            .inFilter('id', ids)
            .eq('user_id', currentUser.id);
      } catch (e) {
        debugPrint('Catatan deleteNotifications Supabase: $e');
      }
    }

    _notifications.removeWhere((n) => ids.contains(n.id));
    notifyListeners();
  }

  void dispose() {
    _streamSubscription?.cancel();
    _listeners.clear();
  }
}
