import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class LocationPickerDialog extends StatefulWidget {
  final LatLng? initialPoint;

  const LocationPickerDialog({super.key, this.initialPoint});

  static Future<LatLng?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
  }) {
    final hasValidInitialPoint = initialLatitude != null &&
        initialLongitude != null &&
        initialLatitude.isFinite &&
        initialLongitude.isFinite &&
        initialLatitude >= -90 &&
        initialLatitude <= 90 &&
        initialLongitude >= -180 &&
        initialLongitude <= 180;

    return showDialog<LatLng>(
      context: context,
      builder: (_) => LocationPickerDialog(
        initialPoint: hasValidInitialPoint
            ? LatLng(initialLatitude, initialLongitude)
            : null,
      ),
    );
  }

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  static const _defaultCenter = LatLng(16, 106);

  late LatLng? _selectedPoint = widget.initialPoint;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = math.min(850.0, screenSize.width - 64);
    final mapHeight = math.min(520.0, math.max(220.0, screenSize.height - 260));

    return AlertDialog(
      title: const Text('Chọn vị trí trên bản đồ'),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      content: SizedBox(
        width: dialogWidth,
        height: mapHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: widget.initialPoint ?? _defaultCenter,
                  initialZoom: widget.initialPoint == null ? 5 : 15,
                  onTap: (_, point) => setState(() => _selectedPoint = point),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.budget.tracker_app',
                    maxNativeZoom: 19,
                  ),
                  if (_selectedPoint case final point?)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: point,
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_pin,
                            color: Colors.red,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  SimpleAttributionWidget(
                    source: const Text('OpenStreetMap contributors'),
                  ),
                ],
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      _selectedPoint == null
                          ? 'Chạm vào bản đồ để chọn điểm'
                          : '${_selectedPoint!.latitude.toStringAsFixed(6)}, '
                              '${_selectedPoint!.longitude.toStringAsFixed(6)}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: _selectedPoint == null
              ? null
              : () => Navigator.of(context).pop(_selectedPoint),
          child: const Text('Chọn điểm'),
        ),
      ],
    );
  }
}
