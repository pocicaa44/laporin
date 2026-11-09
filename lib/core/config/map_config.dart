import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Centralized open-source map and tile configurations for Laporin.
/// Adheres strictly to OpenStreetMap tile usage policies.
class MapConfig {
  const MapConfig._();

  /// Official OpenStreetMap standard tile server URL template
  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// Required attribution string for OpenStreetMap
  static const String osmAttribution = '© OpenStreetMap contributors';

  /// Application identifier for OSM tile request headers
  static const String userAgentPackageName = 'id.laporin.app';

  /// Compliant user agent for geocoding / HTTP calls
  static const String userAgent =
      'LaporinApp/1.0.0 (contact: support@laporin.id)';

  /// Indonesia geographical center point
  static const double indonesiaCenterLat = -2.5489;
  static const double indonesiaCenterLng = 118.0149;
  static const LatLng indonesiaCenter = LatLng(
    indonesiaCenterLat,
    indonesiaCenterLng,
  );

  /// Default zoom levels for various scenarios
  static const double nationalOverviewZoom = 5.0;
  static const double provinceOverviewZoom = 8.5;
  static const double cityOverviewZoom = 12.0;
  static const double locationPickerZoom = 15.0;
  static const double reportDetailZoom = 15.5;

  /// Map camera limits
  static const double minZoom = 3.0;
  static const double maxZoom = 19.0;

  /// Approximate geographic bounding box for Indonesia
  static const double minIndonesiaLat = -11.2;
  static const double maxIndonesiaLat = 6.1;
  static const double minIndonesiaLng = 95.0;
  static const double maxIndonesiaLng = 141.05;

  /// Strict geographic bounds for Indonesia territorial mapping
  static final LatLngBounds indonesiaBounds = LatLngBounds(
    const LatLng(minIndonesiaLat, minIndonesiaLng),
    const LatLng(maxIndonesiaLat, maxIndonesiaLng),
  );

  /// Map performance & tile tuning
  static const Duration tileThrottleDuration = Duration(milliseconds: 100);
  static const int tilePanBuffer = 1;
  static const int tileKeepBuffer = 3;
  static const int maxNativeZoom = 19;
}
