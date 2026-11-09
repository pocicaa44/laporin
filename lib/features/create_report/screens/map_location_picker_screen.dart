import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/map_config.dart';
import '../../../core/services/boundary_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';

/// Interactive map screen with strict Indonesia territorial boundary enforcement.
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
  bool _isInsideIndonesia = true;
  Timer? _addressDebounceTimer;
  int _addressRequestId = 0;
  double _currentRotation = 0.0;
  late final ValueNotifier<double> _rotationNotifier;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _rotationNotifier = ValueNotifier<double>(_currentRotation);

    final initInIndo = BoundaryService.instance.isInsideIndonesia(
      widget.initialLat,
      widget.initialLng,
    );

    if (initInIndo) {
      _selectedPoint = LatLng(widget.initialLat, widget.initialLng);
      _isInsideIndonesia = true;
    } else {
      _selectedPoint = const LatLng(
        BoundaryService.defaultLat,
        BoundaryService.defaultLng,
      );
      _isInsideIndonesia = true;
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
    _rotationNotifier.dispose();
    _mapController.dispose();
    super.dispose();
  }

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
    final inIndo = BoundaryService.instance.isInsideIndonesia(
      point.latitude,
      point.longitude,
    );
    setState(() {
      _selectedPoint = point;
      _isInsideIndonesia = inIndo;
    });
    _scheduleResolveAddress(point.latitude, point.longitude);
  }

  Future<void> _useCurrentGps() async {
    setState(() => _isLoadingGps = true);
    try {
      final pos = await LocationService.instance.getCurrentLocation();
      final newPoint = LatLng(pos.latitude, pos.longitude);
      final inIndo = BoundaryService.instance.isInsideIndonesia(
        pos.latitude,
        pos.longitude,
      );

      setState(() {
        _selectedPoint = newPoint;
        _isInsideIndonesia = inIndo;
        _isLoadingGps = false;
      });

      _mapController.move(newPoint, 15.0);
      _scheduleResolveAddress(pos.latitude, pos.longitude);

      if (!inIndo && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(BoundaryService.gpsOutsideIndonesiaMessage),
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
              initialZoom: MapConfig.locationPickerZoom,
              minZoom: MapConfig.minZoom,
              maxZoom: MapConfig.maxZoom,
              cameraConstraint: CameraConstraint.containCenter(
                bounds: MapConfig.indonesiaBounds,
              ),
              interactionOptions: const InteractionOptions(
                enableMultiFingerGestureRace: true,
                rotationThreshold: 20.0,
              ),
              onTap: _onTapMap,
              onPositionChanged: (camera, hasGesture) {
                if ((camera.rotation - _rotationNotifier.value).abs() > 0.5) {
                  _rotationNotifier.value = camera.rotation;
                  _currentRotation = camera.rotation;
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: MapConfig.osmTileUrl,
                userAgentPackageName: MapConfig.userAgentPackageName,
                maxNativeZoom: MapConfig.maxNativeZoom,
                maxZoom: MapConfig.maxZoom,
                minZoom: MapConfig.minZoom,
                panBuffer: MapConfig.tilePanBuffer,
                keepBuffer: MapConfig.tileKeepBuffer,
                tileDisplay: const TileDisplay.instantaneous(),
                tileUpdateTransformer: TileUpdateTransformers.throttle(
                  MapConfig.tileThrottleDuration,
                ),
                tileBounds: MapConfig.indonesiaBounds,
                tileProvider: NetworkTileProvider(silenceExceptions: true),
              ),
              MarkerLayer(
                rotate: true,
                alignment: Alignment.topCenter,
                markers: [
                  Marker(
                    point: _selectedPoint,
                    width: 44,
                    height: 44,
                    rotate: true,
                    alignment: Alignment.topCenter,
                    child: FaIcon(
                      FontAwesomeIcons.locationDot,
                      color: _isInsideIndonesia
                          ? AppColors.danger
                          : AppColors.disabled,
                      size: 38,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.bottomRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(bottom: 210, right: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: AppRadius.borderXs,
                  ),
                  child: const Text(
                    MapConfig.osmAttribution,
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ValueListenableBuilder<double>(
            valueListenable: _rotationNotifier,
            builder: (context, rotation, _) {
              final isRotated = rotation.abs() > 1.0;
              return Stack(
                children: [
                  if (isRotated)
                    Positioned(
                      right: 16,
                      top: 16,
                      child: FloatingActionButton.small(
                        heroTag: 'btn-reset-north',
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.danger,
                        elevation: 0,
                        focusElevation: 0,
                        hoverElevation: 0,
                        highlightElevation: 0,
                        shape: const CircleBorder(
                          side: BorderSide(color: AppColors.border, width: 1),
                        ),
                        tooltip: 'Reset Arah Utara (Tegak)',
                        onPressed: () {
                          _mapController.rotate(0);
                          _rotationNotifier.value = 0.0;
                          _currentRotation = 0.0;
                        },
                        child: Transform.rotate(
                          angle: -rotation * (math.pi / 180),
                          child: const FaIcon(
                            FontAwesomeIcons.compass,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 16,
                    top: isRotated ? 68 : 16,
                    child: FloatingActionButton.small(
                      heroTag: 'btn-my-loc',
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.primary,
                      elevation: 0,
                      focusElevation: 0,
                      hoverElevation: 0,
                      highlightElevation: 0,
                      shape: const CircleBorder(
                        side: BorderSide(color: AppColors.border, width: 1),
                      ),
                      tooltip: 'Lokasi Saya',
                      onPressed: _isLoadingGps ? null : _useCurrentGps,
                      child: _isLoadingGps
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const FaIcon(
                              FontAwesomeIcons.locationCrosshairs,
                              size: 16,
                            ),
                    ),
                  ),
                ],
              );
            },
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
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              FaIcon(
                _isInsideIndonesia
                    ? FontAwesomeIcons.circleCheck
                    : FontAwesomeIcons.circleExclamation,
                color: _isInsideIndonesia
                    ? AppColors.success
                    : AppColors.danger,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isInsideIndonesia
                      ? (_currentResult?.areaName ?? 'Indonesia')
                      : 'Di Luar Wilayah Indonesia',
                  style: AppTextStyles.label.copyWith(
                    color: _isInsideIndonesia
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
          if (!_isInsideIndonesia) ...[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.dangerSubtle,
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Text(
                BoundaryService.outsideIndonesiaErrorMessage,
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
            text: _isInsideIndonesia
                ? 'Konfirmasi Lokasi Ini'
                : 'Lokasi Tidak Dapat Digunakan',
            onPressed: _isInsideIndonesia
                ? () {
                    final result =
                        _currentResult ??
                        LocationResult(
                          address:
                              'Koordinat ${_selectedPoint.latitude.toStringAsFixed(4)}, ${_selectedPoint.longitude.toStringAsFixed(4)}',
                          latitude: _selectedPoint.latitude,
                          longitude: _selectedPoint.longitude,
                          areaName: BoundaryService.countryName,
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
