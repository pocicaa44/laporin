import 'package:flutter/material.dart';

import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';

/// Controller for managing in-app notifications
class NotificationController extends ChangeNotifier {
  NotificationController({required this.repository}) {
    fetchNotifications();
  }

  final NotificationRepository repository;

  List<NotificationModel> _notifications = [];
  List<NotificationModel> get notifications => _notifications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final list = await repository.getNotifications();
      if (_isDisposed) return;
      _notifications = List<NotificationModel>.from(list);
    } catch (_) {
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> markAsRead(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      final updated = List<NotificationModel>.from(_notifications);
      updated[index] = updated[index].copyWith(isRead: true);
      _notifications = updated;
      notifyListeners();
    }

    try {
      await repository.markAsRead(id);
    } catch (e) {
      debugPrint('NotificationController markAsRead notice: $e');
    }
  }

  Future<void> markAllAsRead() async {
    if (_notifications.isEmpty || unreadCount == 0) return;

    // 1. Optimistic update: langsung jadikan semua isRead = true agar UI merespons instan
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    notifyListeners();

    // 2. Simpan perubahan ke repository dan database
    try {
      await repository.markAllAsRead();
    } catch (e) {
      debugPrint('NotificationController markAllAsRead notice: $e');
    }
  }

  /// Menghapus daftar notifikasi berdasarkan ID secara permanen
  Future<void> deleteNotifications(List<String> ids) async {
    if (ids.isEmpty) return;

    // Optimistic update: langsung hapus dari daftar state
    final idsSet = ids.toSet();
    _notifications = _notifications
        .where((n) => !idsSet.contains(n.id))
        .toList();
    notifyListeners();

    try {
      await repository.deleteNotifications(ids);
    } catch (e) {
      debugPrint('NotificationController deleteNotifications notice: $e');
    }
  }
}
