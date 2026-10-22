import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/services/boundary_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';

/// Interactive map screen with strict Central Java boundary enforcement
class MapLocationPickerScreen extends StatefulWidget {
  const MapLocationPickerScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  final double initialLat;
  final double initialLng;

  @override
  State<MapLocationPickerScreen> createState() =>
      _MapLocationPickerScreenState();
}

class _MapLocationPickerScreenState extends State<MapLocationPickerScreen> {
  late final MapController _mapController;
  late LatLng _selectedPoint;
  LocationResult? _currentResult;
  bool _isLoadingGps = false;
  bool _isResolvingAddress = false;
  bool _isInsideJateng = true;
  Timer? _addressDebounceTimer;
  int _addressRequestId = 0;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();

    // Default to initial coordinates or Semarang if initial is invalid
    final initInJateng = BoundaryService.instance.isInsideCentralJava(
      widget.initialLat,
      widget.initialLng,
    );

    if (initInJateng) {
      _selectedPoint = LatLng(widget.initialLat, widget.initialLng);
      _isInsideJateng = true;
    } else {
      _selectedPoint = const LatLng(
        BoundaryService.defaultLat,
        BoundaryService.defaultLng,
      );
      _isInsideJateng = true;
    }

    _scheduleResolveAddress(_selectedPoint.latitude, _selectedPoint.longitude);

    final isDefaultCoord =
        widget.initialLat == BoundaryService.defaultLat &&
        widget.initialLng == BoundaryService.defaultLng;
    if (isDefaultCoord) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _useCurrentGps();
      });
    }
  }

  @override
  void dispose() {
    _addressDebounceTimer?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  /// Debounces reverse geocoding to prevent firing multiple rapid network calls on map gestures
  void _scheduleResolveAddress(double lat, double lng) {
    _addressDebounceTimer?.cancel();
    _addressRequestId++;
    final currentReqId = _addressRequestId;

    setState(() {
      _isResolvingAddress = true;
    });

    _addressDebounceTimer = Timer(const Duration(milliseconds: 250), () async {
      try {
        final res = await LocationService.instance.getAddressFromCoordinates(
          lat,
          lng,
        );
        if (mounted && currentReqId == _addressRequestId) {
          setState(() {
            _currentResult = res;
            _isResolvingAddress = false;
          });
        }
      } catch (_) {
        if (mounted && currentReqId == _addressRequestId) {
          setState(() => _isResolvingAddress = false);
        }
      }
    });
  }

  void _onTapMap(TapPosition tapPosition, LatLng point) {
    final inJateng = BoundaryService.instance.isInsideCentralJava(
      point.latitude,
      point.longitude,
    );
    setState(() {
      _selectedPoint = point;
      _isInsideJateng = inJateng;
    });
    _scheduleResolveAddress(point.latitude, point.longitude);
  }

  Future<void> _useCurrentGps() async {
    setState(() => _isLoadingGps = true);
    try {
      final pos = await LocationService.instance.getCurrentLocation();
      final newPoint = LatLng(pos.latitude, pos.longitude);
      final inJateng = BoundaryService.instance.isInsideCentralJava(
        pos.latitude,
        pos.longitude,
      );

      setState(() {
        _selectedPoint = newPoint;
        _isInsideJateng = inJateng;
        _isLoadingGps = false;
      });

      _mapController.move(newPoint, 15.0);
      _scheduleResolveAddress(pos.latitude, pos.longitude);

      if (!inJateng && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(BoundaryService.gpsOutsideAreaMessage),
            backgroundColor: AppColors.warning,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } on LocationServiceDisabledException {
      if (mounted) {
        setState(() => _isLoadingGps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Layanan lokasi (GPS) pada perangkat belum aktif.',
            ),
            backgroundColor: AppColors.danger,
            action: SnackBarAction(
              label: 'Aktifkan',
              textColor: Colors.white,
              onPressed: () => LocationService.instance.openLocationSettings(),
            ),
          ),
        );
      }
    } on LocationPermissionPermanentlyDeniedException {
      if (mounted) {
        setState(() => _isLoadingGps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Izin akses lokasi ditolak permanen.'),
            backgroundColor: AppColors.danger,
            action: SnackBarAction(
              label: 'Pengaturan',
              textColor: Colors.white,
              onPressed: () => LocationService.instance.openAppSettings(),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingGps = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pilih Titik Lokasi Kejadian'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedPoint,
              initialZoom: 14.0,
              onTap: _onTapMap,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.laporin.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _selectedPoint,
                    width: 44,
                    height: 44,
                    child: FaIcon(
                      FontAwesomeIcons.locationDot,
                      color: _isInsideJateng
                          ? AppColors.danger
                          : AppColors.disabled,
                      size: 38,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              heroTag: 'btn-my-loc',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              onPressed: _isLoadingGps ? null : _useCurrentGps,
              child: _isLoadingGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const FaIcon(FontAwesomeIcons.locationCrosshairs, size: 16),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: _buildLocationSummaryCard(),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FaIcon(
                _isInsideJateng
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circleExclamation,
                color: _isInsideJateng ? AppColors.success : AppColors.danger,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isInsideJateng
                      ? (_currentResult?.areaName ?? 'Provinsi Jawa Tengah')
                      : 'Di Luar Wilayah Layanan',
                  style: AppTextStyles.label.copyWith(
                    color: _isInsideJateng
                        ? AppColors.success
                        : AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isResolvingAddress)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!_isInsideJateng) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                BoundaryService.outsideAreaErrorMessage,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.danger,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            _currentResult?.address ?? 'Memuat alamat...',
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            'Koordinat: ${_selectedPoint.latitude.toStringAsFixed(5)}, ${_selectedPoint.longitude.toStringAsFixed(5)}',
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          AppButton(
            text: _isInsideJateng
                ? 'Konfirmasi Lokasi Ini'
                : 'Lokasi Tidak Dapat Digunakan',
            onPressed: _isInsideJateng
                ? () {
                    final result =
                        _currentResult ??
                        LocationResult(
                          address:
                              'Koordinat ${_selectedPoint.latitude.toStringAsFixed(4)}, ${_selectedPoint.longitude.toStringAsFixed(4)}',
                          latitude: _selectedPoint.latitude,
                          longitude: _selectedPoint.longitude,
                          areaName: BoundaryService.defaultAreaName,
                          isValidRegion: true,
                        );
                    Navigator.pop(context, result);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
