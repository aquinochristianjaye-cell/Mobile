import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'app_theme.dart';
import 'widgets.dart';

class DriverTrackingScreen extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const DriverTrackingScreen({
    super.key,
    required this.appointment,
  });

  @override
  State<DriverTrackingScreen> createState() =>
      _DriverTrackingScreenState();
}

class _DriverTrackingScreenState
    extends State<DriverTrackingScreen> {
  Timer? _locationTimer;

  LatLng? _driverLocation;

  bool _loading = true;
  String? _errorMessage;

  static const String apiBaseUrl =
      'http://127.0.0.1:8000/api';

  @override
  void initState() {
    super.initState();

    _loadDriverLocation();

    _locationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _loadDriverLocation();
      },
    );
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDriverLocation() async {
    try {
      final driver = Map<String, dynamic>.from(
        widget.appointment['driver'] ?? {},
      );

      final driverId =
          driver['id'] ?? widget.appointment['driver_id'];

      if (driverId == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _errorMessage = 'Driver information not found.';
        });

        return;
      }

      final response = await http.get(
        Uri.parse(
          '$apiBaseUrl/worker/driver/$driverId/location',
        ),
        headers: {
          'Accept': 'application/json',
        },
      );

    if (response.statusCode != 200) {
  debugPrint(
    'Location API error ${response.statusCode}: ${response.body}',
  );

  throw Exception(
    'Location API returned ${response.statusCode}: ${response.body}',
  );
}

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final latitude = data['latitude'];
      final longitude = data['longitude'];

      if (latitude == null || longitude == null) {
        if (!mounted) return;

        setState(() {
          _loading = false;
          _errorMessage =
              'Waiting for the driver to share their location...';
        });

        return;
      }

      final newLocation = LatLng(
        double.parse(latitude.toString()),
        double.parse(longitude.toString()),
      );

      if (!mounted) return;

      setState(() {
        _driverLocation = newLocation;
        _loading = false;
        _errorMessage = null;
      });

      debugPrint(
        'Worker received driver location: '
        '${newLocation.latitude}, '
        '${newLocation.longitude}',
      );
    } catch (e) {
      debugPrint(
        'Could not load driver location: $e',
      );

      if (!mounted) return;

      setState(() {
        _loading = false;
        _errorMessage =
            'Unable to get the driver\'s location.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    final truckPlate =
        (widget.appointment['truck_plate'] ??
                'Unknown truck')
            .toString();

    final driver = Map<String, dynamic>.from(
      widget.appointment['driver'] ?? {},
    );

    final driverName =
        (driver['name'] ?? 'Unknown driver').toString();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        title: Text(
          'Track driver',
          style: t.heading,
        ),
      ),
      body: SafeArea(
        child: ContentWidth(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  16,
                ),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: c.accentSoft,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.local_shipping_rounded,
                          color: c.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              truckPlate.toUpperCase(),
                              style: t.heading.copyWith(
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              driverName,
                              style: t.caption.copyWith(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Pill(
                        label: 'On the way',
                        color: c.signal,
                        background: c.signalSoft,
                      ),
                    ],
                  ),
                ),
              ),

              // MAP
              Expanded(
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 20,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: c.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: c.line,
                    ),
                  ),
                  child: _driverLocation == null
                      ? Center(
                          child: Column(
                            mainAxisAlignment:
                                MainAxisAlignment.center,
                            children: [
                              if (_loading)
                                const CircularProgressIndicator()
                              else
                                Icon(
                                  Icons.location_off_rounded,
                                  color: c.line,
                                  size: 42,
                                ),
                              const SizedBox(height: 14),
                              Text(
                                _errorMessage ??
                                    'Waiting for the driver\'s location...',
                                textAlign: TextAlign.center,
                                style: t.body,
                              ),
                            ],
                          ),
                        )
                      : FlutterMap(
                          options: MapOptions(
                            initialCenter:
                                _driverLocation!,
                            initialZoom: 15,
                          ),
                          children: [
                            TileLayer(
                              urlTemplate:
                                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                              userAgentPackageName:
                                  'com.example.workerui',
                            ),

                            // REAL DRIVER LOCATION
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _driverLocation!,
                                  width: 60,
                                  height: 60,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: c.accent,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: c.accent
                                              .withAlpha(70),
                                          blurRadius: 20,
                                          spreadRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons
                                          .local_shipping_rounded,
                                      color: c.bg,
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  24,
                ),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.my_location_rounded,
                        color: c.signal,
                        size: 22,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _driverLocation != null
                              ? 'Driver location is updating automatically.'
                              : (_errorMessage ??
                                  'Waiting for the driver\'s location...'),
                          style: t.body,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

