import 'package:flutter/material.dart';

import '../../../data/models/notification_model.dart';
import '../../../data/repositories/notification_repository.dart';
import '../../settings/controllers/settings_controller.dart';

/// Controller for managing in-app notifications
class NotificationController extends ChangeNotifier {
  NotificationController({
    required this.repository,
    this.settingsController,
    bool isAdmin = false,
  }) {
    _isAdmin = isAdmin;
    _settingsListener = () {
      notifyListeners();
    };
    settingsController?.addListener(_settingsListener!);

    _repositoryListener = () {
      fetchNotifications(silent: true);
    };
    repository.addListener(_repositoryListener!);

    fetchNotifications();
  }

  final NotificationRepository repository;
  final SettingsController? settingsController;
  bool _isAdmin = false;
  bool get isAdmin => _isAdmin;

  set isAdmin(bool value) {
    if (_isAdmin != value) {
      _isAdmin = value;
      notifyListeners();
    }
  }

  VoidCallback? _settingsListener;
  VoidCallback? _repositoryListener;

  List<NotificationModel> _notifications = [];

  /// Daftar seluruh notifikasi mentah (unfiltered)
  List<NotificationModel> get allNotifications => _notifications;

  /// Daftar notifikasi aktif yang disaring sesuai pengaturan pengguna di Halaman Pengaturan
  List<NotificationModel> get notifications {
    if (settingsController != null) {
      return _notifications.where((n) {
        return settingsController!.isNotificationAllowed(
          n.type,
          isAdmin: _isAdmin,
        );
      }).toList();
    }
    return _notifications;
  }

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isDisposed = false;

  @override
  void dispose() {
    if (_settingsListener != null) {
      settingsController?.removeListener(_settingsListener!);
    }
    if (_repositoryListener != null) {
      repository.removeListener(_repositoryListener!);
    }
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Menghitung jumlah notifikasi belum dibaca HANYA untuk jenis notifikasi yang diizinkan aktif
  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

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

    // 1. Optimistic update: tandai semua notifikasi aktif sebagai sudah dibaca
    final activeIds = notifications.map((n) => n.id).toSet();
    _notifications = _notifications.map((n) {
      if (activeIds.contains(n.id)) {
        return n.copyWith(isRead: true);
      }
      return n;
    }).toList();
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
