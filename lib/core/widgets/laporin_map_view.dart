import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../config/map_config.dart';
import '../theme/app_colors.dart';

/// Reusable OpenStreetMap rendering widget powered by flutter_map.
/// Provides zero-dependency mapping without Google Maps Platform.
class LaporinMapView extends StatefulWidget {
  const LaporinMapView({
    super.key,
    this.initialCenter = MapConfig.indonesiaCenter,
    this.initialZoom = MapConfig.locationPickerZoom,
    this.mapController,
    this.markers = const [],
    this.polygons = const [],
    this.userLocation,
    this.onTap,
    this.onPositionChanged,
    this.interactive = true,
    this.showAttribution = true,
    this.isLoading = false,
    this.errorMessage,
    this.onRetry,
  });

  final LatLng initialCenter;
  final double initialZoom;
  final MapController? mapController;
  final List<Marker> markers;
  final List<Polygon> polygons;
  final LatLng? userLocation;
  final void Function(TapPosition tapPosition, LatLng point)? onTap;
  final void Function(MapCamera camera, bool hasGesture)? onPositionChanged;
  final bool interactive;
  final bool showAttribution;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback? onRetry;

  @override
  State<LaporinMapView> createState() => _LaporinMapViewState();
}

class _LaporinMapViewState extends State<LaporinMapView> {
  MapController? _internalController;
  MapController get _effectiveController =>
      widget.mapController ?? (_internalController ??= MapController());

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.errorMessage != null) {
      return _buildErrorState();
    }

    return Stack(
      children: [
        FlutterMap(
          mapController: _effectiveController,
          options: MapOptions(
            initialCenter: widget.initialCenter,
            initialZoom: widget.initialZoom,
            minZoom: MapConfig.minZoom,
            maxZoom: MapConfig.maxZoom,
            cameraConstraint: CameraConstraint.containCenter(
              bounds: MapConfig.indonesiaBounds,
            ),
            interactionOptions: InteractionOptions(
              flags: widget.interactive
                  ? InteractiveFlag.all
                  : InteractiveFlag.none,
              enableMultiFingerGestureRace: true,
              rotationThreshold: 20.0,
            ),
            onTap: widget.onTap,
            onPositionChanged: widget.onPositionChanged,
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
            if (widget.polygons.isNotEmpty)
              PolygonLayer(polygons: widget.polygons),
            if (widget.userLocation != null || widget.markers.isNotEmpty)
              MarkerLayer(
                rotate: true,
                alignment: Alignment.topCenter,
                markers: [
                  ...widget.markers,
                  if (widget.userLocation != null)
                    Marker(
                      point: widget.userLocation!,
                      width: 24,
                      height: 24,
                      rotate: true,
                      alignment: Alignment.center,
                      child: _buildUserLocationIndicator(),
                    ),
                ],
              ),
            if (widget.showAttribution) _buildAttributionBar(),
          ],
        ),
        if (widget.isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.15),
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildUserLocationIndicator() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.primary.withValues(alpha: 0.25),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.primary,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
    );
  }

  Widget _buildAttributionBar() {
    return Align(
      alignment: Alignment.bottomRight,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        margin: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          color: Color(0xCCFFFFFF),
          borderRadius: BorderRadius.all(Radius.circular(4)),
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
    );
  }

  Widget _buildErrorState() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(24),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.map_outlined, size: 48, color: AppColors.disabled),
          const SizedBox(height: 12),
          Text(
            widget.errorMessage ?? 'Gagal memuat peta',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          if (widget.onRetry != null) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: widget.onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Coba Lagi'),
            ),
          ],
        ],
      ),
    );
  }
}
