import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/map_config.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/laporin_map_view.dart';
import '../../../data/models/report_model.dart';

/// Fullscreen interactive map viewer for inspecting a specific report's location.
class ReportMapViewerScreen extends StatelessWidget {
  const ReportMapViewerScreen({super.key, required this.report});

  final ReportModel report;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(report.latitude, report.longitude);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lokasi Kejadian Laporan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          LaporinMapView(
            initialCenter: point,
            initialZoom: MapConfig.reportDetailZoom,
            markers: [
              Marker(
                point: point,
                width: 44,
                height: 44,
                rotate: true,
                alignment: Alignment.topCenter,
                child: const FaIcon(
                  FontAwesomeIcons.locationDot,
                  color: AppColors.danger,
                  size: 38,
                ),
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Container(
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
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
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
                      Text(
                        report.reportNumber,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    report.title,
                    style: AppTextStyles.sectionTitle.copyWith(fontSize: 15),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    report.locationAddress,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Koordinat: ${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)} (${report.areaName})',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
