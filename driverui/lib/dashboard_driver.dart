import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'appoint.dart';
import 'settings.dart';

class MainScreenDriver extends StatefulWidget {
  final int driverId;

  // Current appointment information
  final int? appointmentId;
  final String? plateNumber;
  final String? livestockLoad;
  final String? preferredTime;
  final String? comingFrom;

  const MainScreenDriver({
    Key? key,
    required this.driverId,
    this.appointmentId,
    this.plateNumber,
    this.livestockLoad,
    this.preferredTime,
    this.comingFrom,
  }) : super(key: key);

  @override
  State<MainScreenDriver> createState() =>
      _MainScreenDriverState();
}

class _MainScreenDriverState extends State<MainScreenDriver> {
  List<Map<String, dynamic>> completedAppointments = [];

  bool isLoadingWashes = true;

  @override
  void initState() {
    super.initState();
    _loadCompletedWashes();
  }

  Future<void> _loadCompletedWashes() async {
    try {
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:8000/api/driver/${widget.driverId}/completed',
        ),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (!mounted) return;

        setState(() {
          completedAppointments =
              List<Map<String, dynamic>>.from(
            data['appointments'] ?? [],
          );

          isLoadingWashes = false;
        });
      } else {
        if (!mounted) return;

        setState(() {
          isLoadingWashes = false;
        });
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingWashes = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // The Current Unit only appears when an appointment exists.
    final bool hasAppointment = widget.appointmentId != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B131E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Hi Logan,',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Good evening',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SettingsDriverScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'LM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // CURRENT UNIT
              if (hasAppointment) ...[
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CURRENT UNIT',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 1.1,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${widget.plateNumber ?? 'Unknown'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Driving',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        widget.comingFrom ??
                            'Location not specified',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${widget.livestockLoad} • ${widget.preferredTime}',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // NEW APPOINTMENT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF162A45),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(12),
                      side: BorderSide(
                        color:
                            Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SetAppDriverScreen(
                          driverId: widget.driverId,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'SET NEW WASH APPOINTMENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // RECENT WASHES
              const Text(
                'RECENT WASHES',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: _buildRecentWashes(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentWashes() {
    if (isLoadingWashes) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white54,
        ),
      );
    }

    if (completedAppointments.isEmpty) {
      return const Center(
        child: Text(
          'No completed washes yet.',
          style: TextStyle(
            color: Colors.white54,
            fontSize: 13,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCompletedWashes,
      child: ListView.separated(
        itemCount: completedAppointments.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final appointment =
              completedAppointments[index];

          final String plate =
              appointment['truck_plate']?.toString() ??
                  'Unknown';

          final String comingFrom =
              appointment['coming_from']?.toString() ??
                  'Location not specified';

          final String date =
              _formatDate(
            appointment['preferred_datetime'],
          );

          return _buildDeliveryItem(
            '#$plate',
            '$date • $comingFrom',
          );
        },
      ),
    );
  }

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Date not specified';
    }

    try {
      final date = DateTime.parse(value.toString());

      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec',
      ];

      return '${date.day} ${months[date.month - 1]}';
    } catch (e) {
      return value.toString();
    }
  }

  Widget _buildDeliveryItem(
    String unit,
    String details,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  unit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  details,
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 10),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFD4EDDA),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Text(
              'Washed',
              style: TextStyle(
                color: Color(0xFF155724),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}