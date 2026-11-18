import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/boundary_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/media_service.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

/// Controller for creating a new citizen report per skills.md & PRD.md FR-02
class CreateReportController extends ChangeNotifier {
  CreateReportController({
    required this.reportRepository,
    MediaService? mediaService,
  }) : _mediaService = mediaService ?? MediaService.instance;

  final ReportRepository reportRepository;
  final MediaService _mediaService;

  String _category = 'Jalan & Infrastruktur';
  String get category => _category;

  String _locationAddress = '';
  String get locationAddress => _locationAddress;

  double _latitude = LocationService.defaultLat;
  double get latitude => _latitude;

  double _longitude = LocationService.defaultLng;
  double get longitude => _longitude;

  String _areaName = LocationService.defaultAreaName;
  String get areaName => _areaName;

  final List<XFile> _selectedPhotos = [];
  List<XFile> get selectedPhotos => List.unmodifiable(_selectedPhotos);

  bool _isPrivate = false;
  bool get isPrivate => _isPrivate;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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

  void setCategory(String newCat) {
    _category = newCat;
    notifyListeners();
  }

  void setIsPrivate(bool value) {
    _isPrivate = value;
    notifyListeners();
  }

  void setLocation({
    required String address,
    required double lat,
    required double lng,
    String? areaName,
  }) {
    _locationAddress = address;
    _latitude = lat;
    _longitude = lng;
    if (areaName != null && areaName.isNotEmpty) {
      _areaName = areaName;
    }
    notifyListeners();
  }

  void addPhoto(XFile file) {
    if (_selectedPhotos.length < 5) {
      _selectedPhotos.add(file);
      notifyListeners();
    }
  }

  void removePhoto(int index) {
    if (index >= 0 && index < _selectedPhotos.length) {
      _selectedPhotos.removeAt(index);
      notifyListeners();
    }
  }

  Future<ReportModel?> submitReport({
    required String authorId,
    required String authorName,
    String? authorUsername,
    String? authorAvatarUrl,
    required String title,
    required String description,
    bool isCallerAdmin = false,
    bool isDraft = false,
    bool? isPrivate,
  }) async {
    final effectiveIsPrivate = isPrivate ?? _isPrivate;
    if (_isLoading) return null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (isCallerAdmin) {
      _isLoading = false;
      _errorMessage = 'Petugas / Admin tidak dapat membuat laporan baru.';
      notifyListeners();
      return null;
    }

    if (_locationAddress.trim().isEmpty) {
      _isLoading = false;
      _errorMessage = 'Harap tentukan titik lokasi kejadian terlebih dahulu.';
      notifyListeners();
      return null;
    }

    if (!BoundaryService.instance.isInsideIndonesia(_latitude, _longitude)) {
      _isLoading = false;
      _errorMessage = BoundaryService.outsideIndonesiaErrorMessage;
      notifyListeners();
      return null;
    }

    try {
      // 1. Upload photos to Supabase Storage if any
      final photoUrls = <String>[];
      if (_selectedPhotos.isNotEmpty) {
        final uploaded = await _mediaService.uploadAllPhotos(
          authorId: authorId,
          files: _selectedPhotos,
        );
        photoUrls.addAll(uploaded);
      }

      // 2. Persist report record to backend
      final report = await reportRepository.createReport(
        authorId: authorId,
        authorName: authorName,
        authorUsername: authorUsername,
        authorAvatarUrl: authorAvatarUrl,
        title: title,
        description: description,
        category: _category,
        latitude: _latitude,
        longitude: _longitude,
        locationAddress: _locationAddress,
        areaName: _areaName,
        photoUrls: photoUrls,
        isDraft: isDraft,
        isPrivate: effectiveIsPrivate,
      );

      _isLoading = false;
      notifyListeners();
      return report;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
