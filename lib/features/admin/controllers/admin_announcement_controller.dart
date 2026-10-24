import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/media_service.dart';
import '../../../data/models/announcement_model.dart';
import '../../../data/repositories/announcement_repository.dart';

/// Controller untuk manajemen pengumuman oleh Admin
class AdminAnnouncementController extends ChangeNotifier {
  AdminAnnouncementController({required this.repository}) {
    repository.addListener(_onRepositoryChanged);
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
    XFile? imageFile,
    String? imageUrl,
  }) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? resolvedImageUrl = imageUrl;
      if (imageFile != null) {
        resolvedImageUrl = await MediaService.instance.uploadAnnouncementPhoto(
          authorId: authorId,
          file: imageFile,
        );
      }

      await repository.createAnnouncement(
        title: title,
        content: content,
        category: category,
        imageUrl: resolvedImageUrl,
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

  Future<bool> updateAnnouncement({
    required String id,
    required String title,
    required String content,
    String category = 'Umum',
    String? currentImageUrl,
    XFile? newImageFile,
    bool removeImage = false,
    String? authorId,
  }) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      String? resolvedImageUrl = currentImageUrl;
      if (removeImage) {
        resolvedImageUrl = null;
      } else if (newImageFile != null) {
        resolvedImageUrl = await MediaService.instance.uploadAnnouncementPhoto(
          authorId: authorId ?? 'admin',
          file: newImageFile,
        );
      }

      await repository.updateAnnouncement(
        id: id,
        title: title,
        content: content,
        category: category,
        imageUrl: resolvedImageUrl,
        clearImageUrl: removeImage,
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

  Future<bool> deleteAnnouncement(String id) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await repository.deleteAnnouncement(id);
      _announcements = repository.cachedAnnouncements;
      _isSubmitting = false;
      notifyListeners();
      return success;
    } catch (e) {
      _isSubmitting = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return false;
    }
  }
}
