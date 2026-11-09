import 'dart:isolate';

import 'package:flutter/foundation.dart';

import 'boundary_data.dart';

/// Official boundary polygon data and geospatial validation for Indonesia and regions.
/// Enforces territorial bounds across all of Indonesia while maintaining backward compatibility.
class BoundaryService {
  BoundaryService._();
  static final BoundaryService instance = BoundaryService._();

  static const String provinceName = 'Jawa Tengah';
  static const String countryName = 'Indonesia';

  /// Standard user-facing message when selected location is outside Indonesia
  static const String outsideIndonesiaErrorMessage =
      'Lokasi laporan hanya tersedia di wilayah Indonesia.';

  /// User-facing message when device GPS is outside Indonesia
  static const String gpsOutsideIndonesiaMessage =
      'Posisi GPS perangkat Anda berada di luar wilayah Indonesia. Silakan pilih titik kejadian di dalam wilayah Indonesia.';

  /// Standard user-facing message when selected location is outside Central Java (legacy pilot)
  static const String outsideAreaErrorMessage =
      'Laporan hanya dapat dibuat untuk lokasi kejadian di Provinsi Jawa Tengah. Silakan pilih lokasi lain di dalam wilayah Jawa Tengah.';

  /// User-facing message when device GPS is outside Central Java (legacy pilot)
  static const String gpsOutsideAreaMessage =
      'Posisi GPS perangkat Anda berada di luar Provinsi Jawa Tengah. Silakan pilih titik kejadian di dalam wilayah Jawa Tengah secara manual pada peta.';

  /// Recommended center coordinate for Central Java (Semarang)
  static const double defaultLat = -6.9932;
  static const double defaultLng = 110.4203;
  static const String defaultAreaName = 'Jawa Tengah';

  /// Recommended center coordinate for Indonesia
  static const double defaultIndonesiaLat = -2.5489;
  static const double defaultIndonesiaLng = 118.0149;

  // Central Java bounding box for fast preliminary filtering
  static const double _minJatengLat = -8.35;
  static const double _maxJatengLat = -5.70;
  static const double _minJatengLng = 108.50;
  static const double _maxJatengLng = 111.75;

  // Indonesia bounding box
  static const double _minIndoLat = -11.50;
  static const double _maxIndoLat = 6.50;
  static const double _minIndoLng = 94.50;
  static const double _maxIndoLng = 141.50;

  /// Primary validation method for nationwide Laporin applications
  bool isValidReportLocation(double lat, double lng) {
    return isInsideIndonesia(lat, lng);
  }

  /// Tests whether coordinates fall within the sovereign territory of Indonesia (NKRI).
  bool isInsideIndonesia(double lat, double lng) {
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) return false;

    // Fast bounding box check
    if (lat < _minIndoLat ||
        lat > _maxIndoLat ||
        lng < _minIndoLng ||
        lng > _maxIndoLng) {
      return false;
    }

    // Precise ray-casting across Indonesian territorial rings
    for (final polygon in BoundaryData.indonesiaRings) {
      if (_isPointInPolygon(lng, lat, polygon)) {
        return true;
      }
    }

    return false;
  }

  /// Asynchronously tests whether coordinates fall within Indonesia on a background isolate.
  Future<bool> isInsideIndonesiaAsync(double lat, double lng) async {
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat < _minIndoLat ||
        lat > _maxIndoLat ||
        lng < _minIndoLng ||
        lng > _maxIndoLng) {
      return false;
    }
    if (kIsWeb) {
      return isInsideIndonesia(lat, lng);
    }
    return await Isolate.run<bool>(() => isInsideIndonesia(lat, lng));
  }

  /// Tests whether coordinates fall within Provinsi Jawa Tengah (backward compatible).
  bool isInsideCentralJava(double lat, double lng) {
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat < -90.0 || lat > 90.0 || lng < -180.0 || lng > 180.0) return false;

    // Fast bounding box check
    if (lat < _minJatengLat ||
        lat > _maxJatengLat ||
        lng < _minJatengLng ||
        lng > _maxJatengLng) {
      return false;
    }

    // Precise ray-casting across Central Java rings
    for (final polygon in BoundaryData.jawaTengahPolygons) {
      if (_isPointInPolygon(lng, lat, polygon)) {
        return true;
      }
    }

    return false;
  }

  /// Asynchronously tests Central Java bounds on a background isolate.
  Future<bool> isInsideCentralJavaAsync(double lat, double lng) async {
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat < _minJatengLat ||
        lat > _maxJatengLat ||
        lng < _minJatengLng ||
        lng > _maxJatengLng) {
      return false;
    }
    if (kIsWeb) {
      return isInsideCentralJava(lat, lng);
    }
    return await Isolate.run<bool>(() => isInsideCentralJava(lat, lng));
  }

  /// Ray-casting algorithm to determine if point (px, py) is inside polygon.
  /// Treats points on borders/edges as inside (consistent with ST_Covers).
  static bool _isPointInPolygon(double px, double py, List<List<double>> ring) {
    bool inside = false;
    final int n = ring.length;

    for (int i = 0, j = n - 1; i < n; j = i++) {
      final xi = ring[i][0];
      final yi = ring[i][1];
      final xj = ring[j][0];
      final yj = ring[j][1];

      // Check if point is directly on edge segment
      final double crossProduct = (py - yi) * (xj - xi) - (px - xi) * (yj - yi);
      if (crossProduct.abs() < 1e-9) {
        if (px >= (xi < xj ? xi : xj) &&
            px <= (xi > xj ? xi : xj) &&
            py >= (yi < yj ? yi : yj) &&
            py <= (yi > yj ? yi : yj)) {
          return true; // Point is on the boundary
        }
      }

      // Ray-casting horizontal ray intersection test
      final bool intersect =
          ((yi > py) != (yj > py)) &&
          (px < (xj - xi) * (py - yi) / (yj - yi + 1e-12) + xi);
      if (intersect) {
        inside = !inside;
      }
    }

    return inside;
  }
}
