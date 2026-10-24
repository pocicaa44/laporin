import 'package:flutter/material.dart';

import '../../../data/models/announcement_model.dart';
import '../../../data/repositories/announcement_repository.dart';

/// Controller untuk menampilkan dan mengelola status pembacaan pengumuman resmi bagi pengguna warga
class AnnouncementController extends ChangeNotifier {
  AnnouncementController({required this.repository}) {
    repository.addListener(_onRepositoryChanged);
    fetchAnnouncements();
  }

  final AnnouncementRepository repository;

  List<AnnouncementModel> _announcements = [];
  List<AnnouncementModel> get announcements => _announcements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  int get unreadCount => repository.unreadCount;

  bool isRead(String id) => repository.isRead(id);

  bool get isViewingAnnouncements => repository.isViewingAnnouncements;

  void setViewingAnnouncements(bool isViewing) {
    repository.setViewingAnnouncements(isViewing);
  }

  bool _isDisposed = false;

  void _onRepositoryChanged() {
    if (_isDisposed) return;
    _announcements = repository.cachedAnnouncements;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  /// Mengambil daftar pengumuman dari repository
  Future<void> fetchAnnouncements({bool forceRefresh = false}) async {
    if (_announcements.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final list = await repository.getAnnouncements(
        forceRefresh: forceRefresh,
      );
      if (_isDisposed) return;
      _announcements = list;
      _errorMessage = null;

      if (repository.isViewingAnnouncements) {
        repository.markAllAsRead();
      }
    } catch (e) {
      if (_isDisposed) return;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (!_isDisposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Menandai semua pengumuman telah dibuka sehingga badge notifikasi hilang
  void markAllAsRead() {
    repository.markAllAsRead();
    notifyListeners();
  }

  /// Menandai satu pengumuman telah dibaca
  void markAsRead(String id) {
    repository.markAsRead(id);
    notifyListeners();
  }
}
