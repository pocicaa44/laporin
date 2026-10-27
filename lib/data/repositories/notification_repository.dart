import 'package:flutter/foundation.dart';

import '../models/notification_model.dart';
import '../services/supabase_service.dart';

/// Repository untuk mengelola riwayat notifikasi in-app per PRD.md Bagian 10.1 & DESIGN.md 5.12
class NotificationRepository {
  NotificationRepository({SupabaseService? supabaseService})
    : _service = supabaseService ?? SupabaseService.instance;

  final SupabaseService _service;
  final List<NotificationModel> _notifications = [];

  /// Helper untuk keperluan pengujian / unit test
  @visibleForTesting
  void setNotificationsForTesting(List<NotificationModel> items) {
    _notifications
      ..clear()
      ..addAll(items);
  }

  /// Mengambil daftar notifikasi pengguna dari Supabase (atau fallback in-memory)
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

        _notifications
          ..clear()
          ..addAll(items);
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
  }
}
