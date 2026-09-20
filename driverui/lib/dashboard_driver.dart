import 'dart:async';
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

  // Current appointment status
  String currentStatus = 'arrived';

  // Used to check the appointment status regularly
  Timer? _statusTimer;

  // Prevent an older completed-washes request
  // from overwriting a newer result.
  int _completedLoadVersion = 0;

  @override
  void initState() {
    super.initState();

    _loadCompletedWashes();

    if (widget.appointmentId != null) {
      _loadAppointmentStatus();

      _statusTimer = Timer.periodic(
        const Duration(seconds: 3),
        (_) {
          _loadAppointmentStatus();
        },
      );
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  // ----------------------------------------------------------
  // LOAD CURRENT APPOINTMENT STATUS
  // ----------------------------------------------------------

  Future<void> _loadAppointmentStatus() async {
    if (widget.appointmentId == null) {
      return;
    }

    try {
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:8000/api/driver/${widget.driverId}/appointments/${widget.appointmentId}',
        ),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode != 200) {
        return;
      }

      final data = jsonDecode(response.body);

      final appointment = data['appointment'];

      if (appointment == null) {
        return;
      }

      final String status =
          appointment['status']?.toString() ?? '';

      if (!mounted) return;

      // ------------------------------------------------------
      // WORKER FINISHED THE WASH
      // ------------------------------------------------------

      if (status == 'completed') {
        setState(() {
          currentStatus = 'completed';
        });

        // Stop checking this appointment because it is finished.
        _statusTimer?.cancel();

        // Load the newly completed appointment.
        await _loadCompletedWashes();

        // If the completed appointment was not returned yet,
        // add the current appointment information to
        // Recent Washes.
        if (mounted &&
            widget.appointmentId != null &&
            !completedAppointments.any(
              (appointment) =>
                  appointment['id'] ==
                  widget.appointmentId,
            )) {
          setState(() {
            completedAppointments.insert(0, {
              'id': widget.appointmentId,
              'driver_id': widget.driverId,
              'truck_plate': widget.plateNumber,
              'livestock_load': widget.livestockLoad,
              'preferred_datetime':
                  widget.preferredTime,
              'coming_from': widget.comingFrom,
              'status': 'completed',
            });

            isLoadingWashes = false;
          });
        }

        return;
      }

      // ------------------------------------------------------
      // APPOINTMENT IS STILL ACTIVE
      // ------------------------------------------------------

      setState(() {
        currentStatus = status;
      });
    } catch (e) {
      // Ignore temporary connection errors.
      // The next timer cycle will try again.
    }
  }

  // ----------------------------------------------------------
  // LOAD COMPLETED WASHES
  // ----------------------------------------------------------

  Future<void> _loadCompletedWashes() async {
    // Give this request a unique version number.
    final int requestVersion =
        ++_completedLoadVersion;

    try {
      final response = await http.get(
        Uri.parse(
          'http://127.0.0.1:8000/api/driver/${widget.driverId}/completed',
        ),
        headers: {
          'Accept': 'application/json',
        },
      );

      // If another newer request was started while this
      // request was running, ignore this older response.
      if (requestVersion != _completedLoadVersion) {
        return;
      }

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
      // Ignore an old request if a newer request exists.
      if (requestVersion != _completedLoadVersion) {
        return;
      }

      if (!mounted) return;

      setState(() {
        isLoadingWashes = false;
      });
    }
  }

  // ----------------------------------------------------------
  // CURRENT UNIT STATUS TEXT
  // ----------------------------------------------------------

  String get _currentStatusText {
    switch (currentStatus) {
      case 'arrived':
        return 'Ready to wash';

      case 'washing':
        return 'Washing';

      case 'assigned':
        return 'Driving';

      default:
        return 'Ready to wash';
    }
  }

  // ----------------------------------------------------------
  // CURRENT UNIT STATUS COLOR
  // ----------------------------------------------------------

  Color get _currentStatusColor {
    switch (currentStatus) {
      case 'arrived':
        return Colors.green.shade700;

      case 'washing':
        return Colors.blue.shade700;

      case 'assigned':
        return Colors.orange.shade700;

      default:
        return Colors.green.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Current Unit disappears after the worker finishes.
    final bool hasAppointment =
        widget.appointmentId != null &&
        currentStatus != 'completed';

    return Scaffold(
      backgroundColor: const Color(0xFF0B131E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------

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

              // ------------------------------------------------
              // CURRENT UNIT
              // ------------------------------------------------

              if (hasAppointment) ...[
                const SizedBox(height: 24),

                Container(
                  padding:
                      const EdgeInsets.all(16),
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
                            MainAxisAlignment
                                .spaceBetween,
                        children: [
                          Text(
                            '#${widget.plateNumber ?? 'Unknown'}',
                            style:
                                const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),

                          Container(
                            padding:
                                const EdgeInsets
                                    .symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration:
                                BoxDecoration(
                              color:
                                  _currentStatusColor,
                              borderRadius:
                                  BorderRadius
                                      .circular(20),
                            ),
                            child: Text(
                              _currentStatusText,
                              style:
                                  const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        widget.comingFrom ??
                            'Location not specified',
                        style:
                            const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '${widget.livestockLoad} • ${widget.preferredTime}',
                        style:
                            const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ------------------------------------------------
              // NEW APPOINTMENT BUTTON
              // ------------------------------------------------

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF162A45),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),
                      side: BorderSide(
                        color: Colors.white
                            .withOpacity(0.2),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SetAppDriverScreen(
                          driverId:
                              widget.driverId,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'SET NEW WASH APPOINTMENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight:
                          FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // RECENT WASHES
              // ------------------------------------------------

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

  // ----------------------------------------------------------
  // RECENT WASHES LIST
  // ----------------------------------------------------------

  Widget _buildRecentWashes() {
    if (isLoadingWashes) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.white54,
        ),
      );
    }

    if (completedAppointments.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadCompletedWashes,
        child: ListView(
          children: const [
            SizedBox(height: 100),
            Center(
              child: Text(
                'No completed washes yet.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadCompletedWashes,
      child: ListView.separated(
        itemCount:
            completedAppointments.length,
        separatorBuilder:
            (context, index) =>
                const SizedBox(height: 12),
        itemBuilder:
            (context, index) {
          final appointment =
              completedAppointments[index];

          final String plate =
              appointment['truck_plate']
                      ?.toString() ??
                  'Unknown';

          final String comingFrom =
              appointment['coming_from']
                      ?.toString() ??
                  'Location not specified';

          final String date =
              _formatDate(
            appointment[
                'preferred_datetime'],
          );

          return _buildDeliveryItem(
            '#$plate',
            '$date • $comingFrom',
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // FORMAT DATE
  // ----------------------------------------------------------

  String _formatDate(dynamic value) {
    if (value == null) {
      return 'Date not specified';
    }

    try {
      final date =
          DateTime.parse(value.toString());

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

  // ----------------------------------------------------------
  // RECENT WASH ITEM
  // ----------------------------------------------------------

  Widget _buildDeliveryItem(
    String unit,
    String details,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color:
            Colors.white.withOpacity(0.08),
        borderRadius:
            BorderRadius.circular(16),
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
                  style:
                      const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  details,
                  style:
                      const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                  overflow:
                      TextOverflow.ellipsis,
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
            decoration:
                BoxDecoration(
              color:
                  const Color(0xFFD4EDDA),
              borderRadius:
                  BorderRadius.circular(20),
            ),
            child: const Text(
              'Washed',
              style: TextStyle(
                color:
                    Color(0xFF155724),
                fontSize: 11,
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

