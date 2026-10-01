import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../services/driver_tracking_service.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import 'common/panel.dart';

class DriverTrackingPanel extends StatefulWidget {
  final int driverId;

  const DriverTrackingPanel({
    super.key,
    required this.driverId,
  });

  @override
  State<DriverTrackingPanel> createState() =>
      _DriverTrackingPanelState();
}

class _DriverTrackingPanelState
    extends State<DriverTrackingPanel> {
  Timer? _trackingTimer;

  List<Map<String, dynamic>> _drivers = [];

  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _loadDriverLocations();

    _trackingTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _loadDriverLocations();
      },
    );
  }

  @override
  void dispose() {
    _trackingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDriverLocations() async {
    try {
      final allDrivers =
          await DriverTrackingService.getDriverLocations();

      final drivers = allDrivers.where((driver) {
        final id = int.tryParse(
          '${driver['id']}',
        );

        return id == widget.driverId;
      }).toList();

      if (!mounted) {
        return;
      }

      setState(() {
        _drivers = drivers;
        _loading = false;
        _errorMessage = null;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to load driver location.';
      });
    }
  }

  double _latitude(
    Map<String, dynamic> driver,
  ) {
    return double.tryParse(
          '${driver['latitude']}',
        ) ??
        0;
  }

  double _longitude(
    Map<String, dynamic> driver,
  ) {
    return double.tryParse(
          '${driver['longitude']}',
        ) ??
        0;
  }

  String _driverName(
    Map<String, dynamic> driver,
  ) {
    final name = driver['name'];

    if (name == null ||
        '$name'.trim().isEmpty) {
      return 'Unknown Driver';
    }

    return '$name';
  }

  String _updatedAt(
    Map<String, dynamic> driver,
  ) {
    final updated =
        driver['location_updated_at'];

    if (updated == null ||
        '$updated'.trim().isEmpty) {
      return 'No update time';
    }

    return '$updated';
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      eyebrow: 'LIVE TRACKING',
      title: 'Live Truck Tracking',
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_loading && _drivers.isEmpty) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.water,
          ),
        ),
      );
    }

    if (_errorMessage != null &&
        _drivers.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.location_off_outlined,
                color: AppColors.crit,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                _errorMessage!,
                style: bodyStyle(
                  size: 11,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed:
                    _loadDriverLocations,
                icon: const Icon(
                  Icons.refresh,
                  size: 16,
                ),
                label: const Text(
                  'Retry',
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_drivers.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_shipping_outlined,
                color: AppColors.textFaint,
                size: 34,
              ),
              const SizedBox(height: 10),
              Text(
                'No driver location available',
                style: bodyStyle(
                  size: 11,
                  color: AppColors.textDim,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Waiting for this driver to send GPS data.',
                textAlign: TextAlign.center,
                style: bodyStyle(
                  size: 9,
                  color: AppColors.textFaint,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final driver = _drivers.first;

    final latitude =
        _latitude(driver);

    final longitude =
        _longitude(driver);

    final position = LatLng(
      latitude,
      longitude,
    );

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        _buildDriverInfo(driver),

        const SizedBox(height: 10),

        SizedBox(
          height: 330,
          child: ClipRRect(
            borderRadius:
                BorderRadius.circular(12),
            child: FlutterMap(
              options: MapOptions(
                initialCenter: position,
                initialZoom: 15,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                      'com.aquino.washstation',
                ),

                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      width: 90,
                      height: 90,
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 7,
                              vertical: 4,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors.panel,
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                7,
                              ),
                              border:
                                  Border.all(
                                color:
                                    AppColors.water,
                              ),
                            ),
                            child: Text(
                              _driverName(
                                driver,
                              ),
                              maxLines: 1,
                              overflow:
                                  TextOverflow
                                      .ellipsis,
                              style: bodyStyle(
                                size: 8,
                                weight:
                                    FontWeight
                                        .w600,
                                color:
                                    AppColors.text,
                              ),
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Container(
                            width: 38,
                            height: 38,
                            decoration:
                                BoxDecoration(
                              color:
                                  AppColors.water,
                              shape:
                                  BoxShape.circle,
                              border:
                                  Border.all(
                                color:
                                    Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors
                                      .water
                                      .withValues(
                                    alpha: 0.45,
                                  ),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child:
                                const Icon(
                              Icons.local_shipping,
                              color:
                                  Colors.white,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 8),

        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration:
                  const BoxDecoration(
                color: AppColors.ok,
                shape:
                    BoxShape.circle,
              ),
            ),

            const SizedBox(width: 6),

            Text(
              'Live location • Updates every 5 seconds',
              style: monoStyle(
                size: 8,
                color:
                    AppColors.textFaint,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDriverInfo(
    Map<String, dynamic> driver,
  ) {
    final latitude =
        _latitude(driver);

    final longitude =
        _longitude(driver);

    return Container(
      padding:
          const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.water
                  .withValues(
                alpha: 0.12,
              ),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: const Icon(
              Icons
                  .local_shipping_outlined,
              color: AppColors.water,
              size: 19,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  _driverName(driver),
                  style: bodyStyle(
                    size: 11,
                    weight:
                        FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  '${latitude.toStringAsFixed(6)}, '
                  '${longitude.toStringAsFixed(6)}',
                  style: monoStyle(
                    size: 8.5,
                    color:
                        AppColors.textDim,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  'Updated: ${_updatedAt(driver)}',
                  style: monoStyle(
                    size: 7.5,
                    color:
                        AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.ok
                  .withValues(
                alpha: 0.10,
              ),
              borderRadius:
                  BorderRadius.circular(7),
              border: Border.all(
                color: AppColors.ok
                    .withValues(
                  alpha: 0.25,
                ),
              ),
            ),
            child: Text(
              'TRACKING',
              style: monoStyle(
                size: 7.5,
                color: AppColors.ok,
              ),
            ),
          ),
        ],
      ),
    );
  }
}