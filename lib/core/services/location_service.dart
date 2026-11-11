import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../../data/services/supabase_service.dart';
import '../config/map_config.dart';
import 'boundary_service.dart';

/// Exception thrown when device GPS toggle is turned off
class LocationServiceDisabledException implements Exception {
  const LocationServiceDisabledException();
  @override
  String toString() => 'Layanan lokasi (GPS) pada perangkat belum aktif.';
}

/// Exception thrown when location permission is permanently denied in system settings
class LocationPermissionPermanentlyDeniedException implements Exception {
  const LocationPermissionPermanentlyDeniedException();
  @override
  String toString() =>
      'Izin akses lokasi ditolak permanen. Silakan aktifkan di Pengaturan.';
}

/// Data class representing a resolved geographic location
class LocationResult {
  const LocationResult({
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.areaName,
    required this.isValidRegion,
    this.provinceId,
    this.provinceCode,
    this.provinceName,
  });

  final String address;
  final double latitude;
  final double longitude;
  final String areaName;
  final bool isValidRegion;
  final String? provinceId;
  final String? provinceCode;
  final String? provinceName;
}

/// Service handling GPS permissions, position acquisition, and reverse geocoding
class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  /// Default fallback coordinate (Semarang, Central Java / Indonesia)
  static const double defaultLat = BoundaryService.defaultLat;
  static const double defaultLng = BoundaryService.defaultLng;
  static const String defaultAreaName = BoundaryService.defaultAreaName;

  /// Open device system location settings (GPS toggle page)
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  /// Open application permission settings in device Settings
  Future<bool> openAppSettings() => Geolocator.openAppSettings();

  /// Optional mock position for test environments to avoid hanging platform channels
  static Position? mockPositionForTesting;

  Position? _lastFetchedPosition;

  /// Returns the most recently acquired GPS position, if any
  Position? get lastFetchedPosition => _lastFetchedPosition;

  /// Returns the last known LatLng, either from testing mock or real GPS cache
  LatLng? get lastKnownLatLng {
    if (mockPositionForTesting != null) {
      return LatLng(
        mockPositionForTesting!.latitude,
        mockPositionForTesting!.longitude,
      );
    }
    if (_lastFetchedPosition != null) {
      return LatLng(
        _lastFetchedPosition!.latitude,
        _lastFetchedPosition!.longitude,
      );
    }
    return null;
  }

  @visibleForTesting
  void setLastFetchedPositionForTesting(Position? pos) {
    _lastFetchedPosition = pos;
  }

  /// Check GPS status and permissions, then return the current position.
  Future<Position> getCurrentLocation() async {
    if (mockPositionForTesting != null) {
      _lastFetchedPosition = mockPositionForTesting;
      return mockPositionForTesting!;
    }

    try {
      if (!kIsWeb && Platform.environment.containsKey('FLUTTER_TEST')) {
        throw const LocationServiceDisabledException();
      }
    } catch (_) {}

    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Izin akses lokasi ditolak oleh pengguna.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw const LocationPermissionPermanentlyDeniedException();
    }

    // 1. Fetch last known position as fast fallback
    Position? lastKnown;
    try {
      lastKnown = await Geolocator.getLastKnownPosition();
    } catch (_) {}

    // 2. Request current fix with balanced/medium accuracy and strict timeout
    try {
      final LocationSettings locationSettings;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        locationSettings = AndroidSettings(
          accuracy: LocationAccuracy.medium,
          distanceFilter: 5,
          intervalDuration: const Duration(seconds: 3),
        );
      } else {
        locationSettings = const LocationSettings(
          accuracy: LocationAccuracy.medium,
        );
      }

      final freshPosition = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 7));

      _lastFetchedPosition = freshPosition;
      return freshPosition;
    } catch (_) {
      // 3. Fallback to last known position if available
      if (lastKnown != null) {
        _lastFetchedPosition = lastKnown;
        return lastKnown;
      }

      // 4. Try low accuracy with short timeout as final attempt
      try {
        final lowPos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.low,
          ),
        ).timeout(const Duration(seconds: 4));
        _lastFetchedPosition = lowPos;
        return lowPos;
      } catch (_) {
        throw Exception(
          'Tidak dapat mengunci sinyal GPS saat ini. Pastikan GPS aktif dan berada di area terbuka, atau pilih titik langsung pada peta.',
        );
      }
    }
  }

  // In-memory cache for reverse geocoded coordinates to prevent redundant network I/O
  static final Map<String, LocationResult> _addressCache = {};

  /// Reverse geocode coordinates to a human-readable street address and administrative area.
  Future<LocationResult> getAddressFromCoordinates(
    double lat,
    double lng,
  ) async {
    final cacheKey = '${lat.toStringAsFixed(4)},${lng.toStringAsFixed(4)}';
    if (_addressCache.containsKey(cacheKey)) {
      return _addressCache[cacheKey]!;
    }

    final isValid = BoundaryService.instance.isInsideIndonesia(lat, lng);

    // Attempt authoritative PostGIS detection via Supabase RPC if online
    String? provId;
    String? provCode;
    String? provName;
    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        final rpcRes = await client
            .rpc(
              'detect_province_by_coordinates',
              params: {'p_lat': lat, 'p_lng': lng},
            )
            .timeout(const Duration(seconds: 3));

        if (rpcRes is Map) {
          if (rpcRes['is_valid'] == true) {
            provId = rpcRes['province_id']?.toString();
            provCode = rpcRes['province_code']?.toString();
            provName = rpcRes['province_name']?.toString();
          }
        }
      }
    } catch (_) {}

    // 1. Pada Web: gunakan OpenStreetMap Nominatim langsung
    if (kIsWeb) {
      final nominatimResult = await _reverseGeocodeNominatim(
        lat,
        lng,
        isValid,
        provId: provId,
        provCode: provCode,
        provName: provName,
      );
      if (nominatimResult != null) {
        if (_addressCache.length > 200) _addressCache.clear();
        _addressCache[cacheKey] = nominatimResult;
        return nominatimResult;
      }
    } else {
      // 2. Pada Mobile: gunakan native Geocoder dengan fallback ke Nominatim
      try {
        final placemarks = await placemarkFromCoordinates(
          lat,
          lng,
        ).timeout(const Duration(seconds: 4));
        if (placemarks.isNotEmpty) {
          final place = placemarks.first;
          final parts = <String>[];

          if (place.street != null && place.street!.trim().isNotEmpty) {
            parts.add(place.street!.trim());
          }
          if (place.subLocality != null &&
              place.subLocality!.trim().isNotEmpty) {
            parts.add('Kel. ${place.subLocality!.trim()}');
          }
          if (place.locality != null && place.locality!.trim().isNotEmpty) {
            parts.add('Kec. ${place.locality!.trim()}');
          }
          if (place.subAdministrativeArea != null &&
              place.subAdministrativeArea!.trim().isNotEmpty) {
            parts.add(place.subAdministrativeArea!.trim());
          } else if (place.administrativeArea != null &&
              place.administrativeArea!.trim().isNotEmpty) {
            parts.add(place.administrativeArea!.trim());
          }

          final fullAddress = parts.isNotEmpty
              ? parts.join(', ')
              : 'Titik Koordinat: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';

          final resolvedArea =
              provName ??
              (place.subAdministrativeArea?.trim().isNotEmpty == true
                  ? place.subAdministrativeArea!.trim()
                  : place.administrativeArea?.trim().isNotEmpty == true
                  ? place.administrativeArea!.trim()
                  : (isValid ? defaultAreaName : 'Di Luar Wilayah Indonesia'));

          final result = LocationResult(
            address: fullAddress,
            latitude: lat,
            longitude: lng,
            areaName: resolvedArea,
            isValidRegion: isValid,
            provinceId: provId,
            provinceCode: provCode,
            provinceName: provName ?? place.administrativeArea,
          );
          if (_addressCache.length > 200) _addressCache.clear();
          _addressCache[cacheKey] = result;
          return result;
        }
      } catch (_) {
        final nominatimResult = await _reverseGeocodeNominatim(
          lat,
          lng,
          isValid,
          provId: provId,
          provCode: provCode,
          provName: provName,
        );
        if (nominatimResult != null) {
          if (_addressCache.length > 200) _addressCache.clear();
          _addressCache[cacheKey] = nominatimResult;
          return nominatimResult;
        }
      }
    }

    final fallback = LocationResult(
      address:
          'Koordinat (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})',
      latitude: lat,
      longitude: lng,
      areaName:
          provName ?? (isValid ? defaultAreaName : 'Di Luar Wilayah Indonesia'),
      isValidRegion: isValid,
      provinceId: provId,
      provinceCode: provCode,
      provinceName: provName,
    );
    _addressCache[cacheKey] = fallback;
    return fallback;
  }

  /// Reverse geocoding via OpenStreetMap Nominatim for Web & cross-platform fallback
  Future<LocationResult?> _reverseGeocodeNominatim(
    double lat,
    double lng,
    bool isValid, {
    String? provId,
    String? provCode,
    String? provName,
  }) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&addressdetails=1',
      );
      final response = await http
          .get(
            uri,
            headers: {
              'User-Agent': MapConfig.userAgent,
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final addressMap = data['address'] as Map<String, dynamic>?;
        if (addressMap != null) {
          final parts = <String>[];
          final road = addressMap['road'] ?? addressMap['pedestrian'];
          if (road != null && road.toString().trim().isNotEmpty) {
            parts.add(road.toString().trim());
          }
          final village =
              addressMap['village'] ??
              addressMap['suburb'] ??
              addressMap['neighbourhood'];
          if (village != null && village.toString().trim().isNotEmpty) {
            parts.add('Kel. ${village.toString().trim()}');
          }
          final district =
              addressMap['city_district'] ??
              addressMap['subdistrict'] ??
              addressMap['municipality'];
          if (district != null && district.toString().trim().isNotEmpty) {
            parts.add('Kec. ${district.toString().trim()}');
          }
          final city =
              addressMap['city'] ??
              addressMap['regency'] ??
              addressMap['county'];
          if (city != null && city.toString().trim().isNotEmpty) {
            parts.add(city.toString().trim());
          } else if (addressMap['state'] != null) {
            parts.add(addressMap['state'].toString().trim());
          }

          final fullAddress = parts.isNotEmpty
              ? parts.join(', ')
              : (data['display_name'] as String? ??
                    'Koordinat: ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}');

          final areaName =
              provName ??
              (city != null && city.toString().trim().isNotEmpty
                  ? city.toString().trim()
                  : (addressMap['state']?.toString().trim().isNotEmpty == true
                        ? addressMap['state'].toString().trim()
                        : (isValid
                              ? defaultAreaName
                              : 'Di Luar Wilayah Indonesia')));

          return LocationResult(
            address: fullAddress,
            latitude: lat,
            longitude: lng,
            areaName: areaName,
            isValidRegion: isValid,
            provinceId: provId,
            provinceCode: provCode,
            provinceName: provName ?? addressMap['state']?.toString(),
          );
        }
      }
    } catch (_) {}
    return null;
  }
}
