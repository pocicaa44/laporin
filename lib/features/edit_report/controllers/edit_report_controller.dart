import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/services/boundary_service.dart';
import '../../../core/services/media_service.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';

/// Controller for editing an existing citizen report (< 200 lines per skills.md)
class EditReportController extends ChangeNotifier {
  EditReportController({
    required this.report,
    required this.reportRepository,
    MediaService? mediaService,
  }) : _mediaService = mediaService ?? MediaService.instance,
       _category = report.category,
       _locationAddress = report.locationAddress,
       _latitude = report.latitude,
       _longitude = report.longitude,
       _areaName = report.areaName,
       _existingPhotos = List<String>.from(report.photoUrls);

  final ReportModel report;
  final ReportRepository reportRepository;
  final MediaService _mediaService;

  String _category;
  String get category => _category;

  String _locationAddress;
  String get locationAddress => _locationAddress;

  double _latitude;
  double get latitude => _latitude;

  double _longitude;
  double get longitude => _longitude;

  String _areaName;
  String get areaName => _areaName;

  final List<String> _existingPhotos;
  List<String> get existingPhotos => List.unmodifiable(_existingPhotos);

  final List<XFile> _newPhotos = [];
  List<XFile> get newPhotos => List.unmodifiable(_newPhotos);

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

  void removeExistingPhoto(int index) {
    if (index >= 0 && index < _existingPhotos.length) {
      _existingPhotos.removeAt(index);
      notifyListeners();
    }
  }

  void addNewPhoto(XFile file) {
    if ((_existingPhotos.length + _newPhotos.length) < 5) {
      _newPhotos.add(file);
      notifyListeners();
    }
  }

  void removeNewPhoto(int index) {
    if (index >= 0 && index < _newPhotos.length) {
      _newPhotos.removeAt(index);
      notifyListeners();
    }
  }

  Future<ReportModel?> submitUpdate({
    required String currentUserId,
    required String title,
    required String description,
  }) async {
    if (_isLoading) return null;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    if (_locationAddress.trim().isEmpty) {
      _isLoading = false;
      _errorMessage = 'Harap tentukan titik lokasi kejadian terlebih dahulu.';
      notifyListeners();
      return null;
    }

    // Validasi lokasi Indonesia
    if (!BoundaryService.instance.isInsideIndonesia(_latitude, _longitude)) {
      _isLoading = false;
      _errorMessage = BoundaryService.outsideIndonesiaErrorMessage;
      notifyListeners();
      return null;
    }

    try {
      // 1. Upload foto baru jika ada (tanpa upload ulang foto lama)
      final finalPhotos = List<String>.from(_existingPhotos);
      if (_newPhotos.isNotEmpty) {
        final uploaded = await _mediaService.uploadAllPhotos(
          authorId: currentUserId,
          files: _newPhotos,
        );
        finalPhotos.addAll(uploaded);
      }

      // 2. Simpan perubahan ke repository dan database
      final updatedReport = await reportRepository.updateReportDetails(
        reportId: report.id,
        currentUserId: currentUserId,
        title: title,
        description: description,
        category: _category,
        latitude: _latitude,
        longitude: _longitude,
        locationAddress: _locationAddress,
        areaName: _areaName,
        photoUrls: finalPhotos,
      );

      _isLoading = false;
      notifyListeners();
      return updatedReport;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      return null;
    }
  }
}
