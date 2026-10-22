import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/services/boundary_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../screens/map_location_picker_screen.dart';

/// Modular widget for selecting and validating report location (< 150 lines)
class ReportLocationPicker extends StatefulWidget {
  const ReportLocationPicker({
    super.key,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.areaName,
    required this.onLocationChanged,
  });

  final String address;
  final double latitude;
  final double longitude;
  final String areaName;
  final void Function(String address, double lat, double lng, String areaName)
  onLocationChanged;

  @override
  State<ReportLocationPicker> createState() => _ReportLocationPickerState();
}

class _ReportLocationPickerState extends State<ReportLocationPicker> {
  bool _isLoadingGps = false;

  Future<void> _useGps() async {
    setState(() => _isLoadingGps = true);
    try {
      final pos = await LocationService.instance.getCurrentLocation();
      final res = await LocationService.instance.getAddressFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (mounted) {
        widget.onLocationChanged(
          res.address,
          res.latitude,
          res.longitude,
          res.areaName,
        );
        setState(() => _isLoadingGps = false);

        if (!res.isValidRegion) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(BoundaryService.gpsOutsideAreaMessage),
              backgroundColor: AppColors.warning,
            ),
          );
        }
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

  Future<void> _openMap() async {
    final result = await Navigator.push<LocationResult>(
      context,
      MaterialPageRoute(
        builder: (_) => MapLocationPickerScreen(
          initialLat: widget.latitude,
          initialLng: widget.longitude,
        ),
      ),
    );

    if (result != null && mounted) {
      widget.onLocationChanged(
        result.address,
        result.latitude,
        result.longitude,
        result.areaName,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLocation = widget.address.isNotEmpty;
    final isValidRegion =
        hasLocation &&
        BoundaryService.instance.isInsideCentralJava(
          widget.latitude,
          widget.longitude,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Titik Lokasi Kejadian *', style: AppTextStyles.label),
            if (hasLocation)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isValidRegion
                      ? AppColors.primarySoft
                      : AppColors.danger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isValidRegion ? widget.areaName : 'Di Luar Jawa Tengah',
                  style: AppTextStyles.caption.copyWith(
                    color: isValidRegion ? AppColors.primary : AppColors.danger,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasLocation && !isValidRegion
                  ? AppColors.danger
                  : AppColors.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FaIcon(
                    FontAwesomeIcons.locationDot,
                    color: hasLocation
                        ? (isValidRegion
                              ? AppColors.danger
                              : AppColors.disabled)
                        : AppColors.textSecondary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLocation
                              ? widget.address
                              : 'Belum memilih lokasi kejadian',
                          style: AppTextStyles.sectionTitle.copyWith(
                            fontSize: 14,
                            color: hasLocation
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasLocation
                              ? (isValidRegion
                                    ? 'Koordinat: ${widget.latitude.toStringAsFixed(4)}, ${widget.longitude.toStringAsFixed(4)} (Cakupan: ${widget.areaName})'
                                    : 'Koordinat di luar Provinsi Jawa Tengah')
                              : 'Buka peta interaktif atau gunakan sensor GPS perangkat Anda.',
                          style: AppTextStyles.caption.copyWith(
                            color: isValidRegion
                                ? AppColors.success
                                : AppColors.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (hasLocation && !isValidRegion) ...[
                const SizedBox(height: 10),
                const Text(
                  BoundaryService.outsideAreaErrorMessage,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.danger,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: _isLoadingGps
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const FaIcon(
                              FontAwesomeIcons.locationCrosshairs,
                              size: 13,
                            ),
                      label: Text(_isLoadingGps ? 'Mencari...' : 'Gunakan GPS'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size.fromHeight(40),
                      ),
                      onPressed: _isLoadingGps ? null : _useGps,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const FaIcon(
                        FontAwesomeIcons.mapLocationDot,
                        size: 13,
                      ),
                      label: Text(
                        hasLocation ? 'Ubah di Peta' : 'Pilih di Peta',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        minimumSize: const Size.fromHeight(40),
                      ),
                      onPressed: _openMap,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
