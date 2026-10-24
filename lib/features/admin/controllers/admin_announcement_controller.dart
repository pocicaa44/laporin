import 'package:flutter/material.dart';

import '../../../data/models/announcement_model.dart';
import '../../../data/repositories/announcement_repository.dart';

/// Controller untuk manajemen pengumuman oleh Admin
class AdminAnnouncementController extends ChangeNotifier {
  AdminAnnouncementController({required this.repository}) {
    fetchAnnouncements();
  }

  final AnnouncementRepository repository;

  List<AnnouncementModel> _announcements = [];
  List<AnnouncementModel> get announcements => _announcements;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSubmitting = false;
  bool get isSubmitting => _isSubmitting;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

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

  Future<bool> createAnnouncement({
    required String title,
    required String content,
    String category = 'Umum',
    required String authorId,
    required String authorName,
  }) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await repository.createAnnouncement(
        title: title,
        content: content,
        category: category,
        authorId: authorId,
        authorName: authorName,
      );
      _announcements = repository.cachedAnnouncements;
      _isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
