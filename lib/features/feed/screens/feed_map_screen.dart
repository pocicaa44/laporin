import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../core/config/map_config.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/laporin_map_view.dart';
import '../../../data/models/report_model.dart';
import '../../../data/repositories/report_repository.dart';
import '../../report_detail/screens/report_detail_screen.dart';

/// Full interactive map screen for exploring community reports geographically across Indonesia.
class FeedMapScreen extends StatefulWidget {
  const FeedMapScreen({super.key, this.initialReports = const []});

  final List<ReportModel> initialReports;

  @override
  State<FeedMapScreen> createState() => _FeedMapScreenState();
}

class _FeedMapScreenState extends State<FeedMapScreen> {
  late final MapController _mapController;
  final List<ReportModel> _viewportReports = [];
  ReportModel? _selectedReport;
  LatLng? _userLocation;
  bool _isLoadingViewport = false;
  Timer? _viewportDebounce;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _viewportReports.addAll(widget.initialReports);
    _fetchUserLocation();
  }

  @override
  void dispose() {
    _viewportDebounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserLocation() async {
    try {
      final pos = await LocationService.instance.getCurrentLocation();
      if (mounted) {
        setState(() {
          _userLocation = LatLng(pos.latitude, pos.longitude);
        });
      }
    } catch (_) {}
  }

  void _onPositionChanged(MapCamera camera, bool hasGesture) {
    if (!hasGesture) return;
    _viewportDebounce?.cancel();
    _viewportDebounce = Timer(const Duration(milliseconds: 400), () async {
      final bounds = camera.visibleBounds;
      final repo = context.read<ReportRepository>();
      setState(() => _isLoadingViewport = true);
      try {
        final results = await repo.fetchReportsInViewport(
          minLat: bounds.south,
          minLng: bounds.west,
          maxLat: bounds.north,
          maxLng: bounds.east,
          limit: 100,
        );
        if (mounted) {
          setState(() {
            _viewportReports.clear();
            _viewportReports.addAll(results);
            _isLoadingViewport = false;
          });
        }
      } catch (_) {
        if (mounted) setState(() => _isLoadingViewport = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final center = _viewportReports.isNotEmpty
        ? LatLng(
            _viewportReports.first.latitude,
            _viewportReports.first.longitude,
          )
        : (_userLocation ?? MapConfig.indonesiaCenter);

    final markers = _viewportReports.map((report) {
      final isSelected = _selectedReport?.id == report.id;
      return Marker(
        point: LatLng(report.latitude, report.longitude),
        width: isSelected ? 48 : 38,
        height: isSelected ? 48 : 38,
        rotate: true,
        alignment: Alignment.topCenter,
        child: GestureDetector(
          onTap: () {
            setState(() => _selectedReport = report);
          },
          child: FaIcon(
            FontAwesomeIcons.locationDot,
            color: isSelected ? AppColors.primary : AppColors.danger,
            size: isSelected ? 44 : 34,
          ),
        ),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Peta Sebaran Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoadingViewport)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          LaporinMapView(
            mapController: _mapController,
            initialCenter: center,
            initialZoom: _viewportReports.isNotEmpty
                ? 12.0
                : MapConfig.nationalOverviewZoom,
            markers: markers,
            userLocation: _userLocation,
            onPositionChanged: _onPositionChanged,
            onTap: (tapPosition, point) {
              if (_selectedReport != null) {
                setState(() => _selectedReport = null);
              }
            },
          ),
          Positioned(
            right: 16,
            top: 16,
            child: FloatingActionButton.small(
              heroTag: 'btn-feed-map-gps',
              backgroundColor: AppColors.surface,
              foregroundColor: AppColors.primary,
              shape: const CircleBorder(
                side: BorderSide(color: AppColors.border, width: 1),
              ),
              elevation: 0,
              focusElevation: 0,
              hoverElevation: 0,
              highlightElevation: 0,
              onPressed: () async {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 14.0);
                } else {
                  await _fetchUserLocation();
                  if (_userLocation != null && mounted) {
                    _mapController.move(_userLocation!, 14.0);
                  }
                }
              },
              child: const FaIcon(
                FontAwesomeIcons.locationCrosshairs,
                size: 16,
              ),
            ),
          ),
          if (_selectedReport != null)
            Positioned(
              left: 16,
              right: 16,
              bottom: 24,
              child: _buildReportPreviewCard(_selectedReport!),
            ),
        ],
      ),
    );
  }

  Widget _buildReportPreviewCard(ReportModel report) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.card,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.primarySoft,
                  borderRadius: AppRadius.pill,
                ),
                child: Text(
                  report.category,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: const Icon(
                  Icons.close,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
                onPressed: () => setState(() => _selectedReport = null),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            report.title,
            style: AppTextStyles.sectionTitle.copyWith(fontSize: 14),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            report.locationAddress,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.thumb_up_outlined,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text('${report.upvotesCount}', style: AppTextStyles.caption),
              const SizedBox(width: 12),
              const Icon(
                Icons.chat_bubble_outline,
                size: 14,
                color: AppColors.textSecondary,
              ),
              const SizedBox(width: 4),
              Text('${report.commentsCount}', style: AppTextStyles.caption),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ReportDetailScreen(reportId: report.id),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  minimumSize: const Size(0, 32),
                  shape: const RoundedRectangleBorder(
                    borderRadius: AppRadius.button,
                  ),
                ),
                child: const Text(
                  'Buka Detail',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
