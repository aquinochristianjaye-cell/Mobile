import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';

import 'app_theme.dart';
import 'appoint.dart';
import 'driver_session.dart';
import 'qr.dart';
import 'widgets.dart';

class MainScreenDriver extends StatefulWidget {
  final int driverId;

  // Current appointment information
  final int? appointmentId;
  final String? plateNumber;
  final String? livestockLoad;
  final String? preferredTime;
  final String? comingFrom;

  const MainScreenDriver({
    super.key,
    required this.driverId,
    this.appointmentId,
    this.plateNumber,
    this.livestockLoad,
    this.preferredTime,
    this.comingFrom,
  });

  @override
  State<MainScreenDriver> createState() => _MainScreenDriverState();
}

class _MainScreenDriverState extends State<MainScreenDriver> {
  List<Map<String, dynamic>> completedAppointments = [];

  bool isLoadingWashes = true;

  // Current appointment status
  String currentStatus = 'arrived';

  // Used to check the appointment status regularly
  Timer? _statusTimer;

  // Used to update the driver's GPS location
  Timer? _locationTimer;

  // Latest driver's GPS position
  Position? _currentPosition;

  // Prevent an older completed-washes request
  // from overwriting a newer result.
  int _completedLoadVersion = 0;

  // Prevent multiple cancellation requests.
  bool _isCancelling = false;

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

      // Start GPS tracking only when there is an active appointment.
      _startLocationTracking();
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  // ----------------------------------------------------------
  // DRIVER GPS LOCATION
  // ----------------------------------------------------------

  Future<void> _startLocationTracking() async {
    try {
      bool serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        debugPrint('Location permission denied.');
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint(
          'Location permission permanently denied.',
        );
        return;
      }

      // Get the driver's current position immediately.
      await _updateCurrentLocation();

      // Then update the position regularly.
      _locationTimer = Timer.periodic(
        const Duration(seconds: 5),
        (_) {
          _updateCurrentLocation();
        },
      );
    } catch (e) {
      debugPrint('Location tracking error: $e');
    }
  }

  Future<void> _updateCurrentLocation() async {
    try {
      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5,
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _currentPosition = position;
      });

      debugPrint(
        'Driver location: '
        '${position.latitude}, ${position.longitude}',
      );

      debugPrint(
        'Sending location for appointment: '
        '${widget.appointmentId}',
      );

      // Send the driver's location to Laravel.
      if (widget.appointmentId != null &&
          currentStatus != 'cancelled' &&
          currentStatus != 'completed') {
        try {
          debugPrint(
            'Sending location to Laravel...',
          );

          final response = await http.post(
            Uri.parse(
              'http://127.0.0.1:8000/api/driver/location',
            ),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'driver_id': widget.driverId,
              'appointment_id': widget.appointmentId,
              'latitude': position.latitude,
              'longitude': position.longitude,
            }),
          );

          debugPrint(
            'Location API response: '
            '${response.statusCode} ${response.body}',
          );
        } catch (e) {
          debugPrint(
            'Could not send driver location: $e',
          );
        }
      }
    } catch (e) {
      debugPrint(
        'Could not get driver location: $e',
      );
    }
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
          'http://127.0.0.1:8000/api/driver/'
          '${widget.driverId}/appointments/'
          '${widget.appointmentId}',
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
      // APPOINTMENT WAS CANCELLED
      // ------------------------------------------------------

      if (status == 'cancelled') {
        setState(() {
          currentStatus = 'cancelled';
        });

        // Stop checking this appointment.
        _statusTimer?.cancel();

        // Stop GPS tracking.
        _locationTimer?.cancel();

        return;
      }

      // ------------------------------------------------------
      // WORKER FINISHED THE WASH
      // ------------------------------------------------------

      if (status == 'completed') {
        setState(() {
          currentStatus = 'completed';
        });

        // Stop checking this appointment because it is finished.
        _statusTimer?.cancel();

        // Stop GPS tracking because the trip is finished.
        _locationTimer?.cancel();

        // Load the newly completed appointment.
        await _loadCompletedWashes();

        // If the completed appointment was not returned yet,
        // add the current appointment information to
        // Recent Washes.
        if (mounted &&
            widget.appointmentId != null &&
            !completedAppointments.any(
              (appointment) =>
                  appointment['id'] == widget.appointmentId,
            )) {
          setState(() {
            completedAppointments.insert(0, {
              'id': widget.appointmentId,
              'driver_id': widget.driverId,
              'truck_plate': widget.plateNumber,
              'livestock_load': widget.livestockLoad,
              'preferred_datetime': widget.preferredTime,
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
  // CANCEL APPOINTMENT
  // ----------------------------------------------------------

  Future<void> _cancelAppointment() async {
    if (widget.appointmentId == null) {
      return;
    }

    if (currentStatus != 'pending' &&
        currentStatus != 'assigned') {
      return;
    }

    if (_isCancelling) {
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final c = context.c;
        final t = context.t;

        return AlertDialog(
          backgroundColor: c.surface,
          title: Text(
            'Cancel appointment?',
            style: t.heading,
          ),
          content: Text(
            'Are you sure you want to cancel this wash appointment? '
            'You can book another wash later.',
            style: t.body.copyWith(
              color: c.textMuted,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Keep appointment',
                style: TextStyle(
                  color: c.textMuted,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: Text(
                'Cancel appointment',
                style: TextStyle(
                  color: c.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isCancelling = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/api/driver/appointments/'
          '${widget.appointmentId}/cancel',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'driver_id': widget.driverId,
        }),
      );

      debugPrint(
        'Cancel appointment response: '
        '${response.statusCode} ${response.body}',
      );

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        // Mark the appointment as cancelled locally.
        setState(() {
          currentStatus = 'cancelled';
          _isCancelling = false;
        });

        // Stop polling this appointment.
        _statusTimer?.cancel();

        // Stop GPS tracking.
        _locationTimer?.cancel();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Appointment cancelled successfully.',
            ),
          ),
        );
      } else {
        String message =
            'Unable to cancel the appointment.';

        try {
          final data = jsonDecode(response.body);

          if (data['message'] != null) {
            message = data['message'].toString();
          }
        } catch (_) {
          // Keep the default message.
        }

        setState(() {
          _isCancelling = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
          ),
        );
      }
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isCancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not connect to the server. '
            'Please try again.',
          ),
        ),
      );

      debugPrint(
        'Cancel appointment error: $e',
      );
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
          'http://127.0.0.1:8000/api/driver/'
          '${widget.driverId}/completed',
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

  // Pull-to-refresh: reload the list and, if a wash is active,
  // its status.
  Future<void> _refreshAll() async {
    if (widget.appointmentId != null &&
        currentStatus != 'completed' &&
        currentStatus != 'cancelled') {
      await _loadAppointmentStatus();
    }

    await _loadCompletedWashes();

    if (widget.appointmentId != null &&
        currentStatus != 'completed' &&
        currentStatus != 'cancelled') {
      await _updateCurrentLocation();
    }
  }

  // ----------------------------------------------------------
  // STATUS HELPERS
  // ----------------------------------------------------------

  // 0 on the way, 1 arrived, 2 washing, 3 done
  int get _stepIndex {
    switch (currentStatus) {
      case 'assigned':
        return 0;
      case 'washing':
        return 2;
      case 'completed':
        return 3;
      case 'arrived':
      default:
        return 1;
    }
  }

  String get _currentStatusText {
    switch (currentStatus) {
      case 'washing':
        return 'Washing';
      case 'assigned':
        return 'On the way';
      case 'arrived':
        return 'Ready to wash';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Ready to wash';
    }
  }

  String get _statusHint {
    switch (currentStatus) {
      case 'washing':
        return 'Your truck is being washed. This screen updates when it\'s done.';
      case 'assigned':
        return 'Head to the station and show your gate pass when you arrive.';
      case 'cancelled':
        return 'This wash appointment has been cancelled. You can book another wash.';
      case 'arrived':
      default:
        return 'You\'re checked in. A worker will start your wash shortly.';
    }
  }

  Color _statusColor(AppColors c) {
    switch (currentStatus) {
      case 'washing':
        return c.accent;
      case 'assigned':
        return c.signal;
      case 'cancelled':
        return c.danger;
      case 'arrived':
      default:
        return c.success;
    }
  }

  Color _statusBackground(AppColors c) {
    switch (currentStatus) {
      case 'washing':
        return c.accentSoft;
      case 'assigned':
        return c.signalSoft;
      case 'cancelled':
        return c.danger.withAlpha(25);
      case 'arrived':
      default:
        return c.successSoft;
    }
  }

  // ----------------------------------------------------------
  // NAVIGATION
  // ----------------------------------------------------------

  void _openGatePass() {
    if (widget.appointmentId == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QrCodeDriverScreen(
          driverId: widget.driverId,
          appointmentId: widget.appointmentId!,
          plateNumber:
              widget.plateNumber ?? 'Unknown',
          livestockLoad:
              widget.livestockLoad ?? '',
          preferredTime:
              widget.preferredTime ?? '',
          comingFrom:
              widget.comingFrom ?? '',
          fromDashboard: true,
        ),
      ),
    );
  }

  void _openBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SetAppDriverScreen(
          driverId: widget.driverId,
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    // Current wash disappears after the worker finishes
    // or after the driver cancels it.
    final bool hasAppointment =
        widget.appointmentId != null &&
        currentStatus != 'completed' &&
        currentStatus != 'cancelled';

    final bool justCompleted =
        widget.appointmentId != null &&
        currentStatus == 'completed';

    final bool justCancelled =
        widget.appointmentId != null &&
        currentStatus == 'cancelled';

    return Scaffold(
      backgroundColor: c.bg,
      bottomNavigationBar: BottomBar(
        child: hasAppointment
            ? SecondaryButton(
                label: 'Book another wash',
                icon: Icons.add_rounded,
                onPressed: _openBooking,
              )
            : PrimaryButton(
                label: 'Book a wash',
                icon: Icons.add_rounded,
                onPressed: _openBooking,
              ),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          color: c.accent,
          backgroundColor: c.surface,
          child: ListView(
            physics:
                const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              28,
            ),
            children: [
              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${DriverSession.greeting},',
                          style: t.bodyMuted,
                        ),
                        Text(
                          DriverSession.firstName,
                          style: t.display,
                        ),
                      ],
                    ),
                  ),
                  const DriverAvatar(),
                ],
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // CURRENT WASH
              // ------------------------------------------------
              if (hasAppointment)
                _buildCurrentWash(c, t),

              if (justCompleted)
                _buildCompletedBanner(c, t),

              if (justCancelled)
                _buildCancelledBanner(c, t),

              if (!hasAppointment &&
                  !justCompleted &&
                  !justCancelled)
                _buildNoWashCard(c, t),

              const SizedBox(height: 32),

              // ------------------------------------------------
              // RECENT WASHES
              // ------------------------------------------------
              Text(
                'Recent washes',
                style: t.heading,
              ),

              const SizedBox(height: 14),

              _buildRecentWashes(c, t),
            ],
          ),
        ),
      ),
    );
  }

  // ----------------------------------------------------------
  // CURRENT WASH CARD
  // ----------------------------------------------------------

  Widget _buildCurrentWash(
    AppColors c,
    AppType t,
  ) {
    final bool canCancel =
        currentStatus == 'pending' ||
        currentStatus == 'assigned';

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(
        18,
        18,
        18,
        20,
      ),
      borderColor:
          c.accent.withAlpha(110),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Current wash',
                style: t.label,
              ),
              Pill(
                label: _currentStatusText,
                color: _statusColor(c),
                background:
                    _statusBackground(c),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment:
                      Alignment.centerLeft,
                  child: PlateTag(
                    widget.plateNumber ??
                        'Unknown',
                    fontSize: 30,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _InfoLine(
            icon:
                Icons.location_on_outlined,
            text:
                (widget.comingFrom == null ||
                        widget.comingFrom!.isEmpty)
                    ? 'Location not specified'
                    : 'From ${widget.comingFrom}',
          ),

          const SizedBox(height: 8),

          _InfoLine(
            icon: Icons.event_outlined,
            text:
                '${widget.livestockLoad ?? ''}  ·  '
                '${widget.preferredTime ?? ''}',
          ),

          const SizedBox(height: 24),

          WashTracker(
            stepIndex: _stepIndex,
          ),

          const SizedBox(height: 18),

          Text(
            _statusHint,
            style: t.bodyMuted.copyWith(
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 18),

          PrimaryButton(
            label: 'Show gate pass',
            icon:
                Icons.qr_code_2_rounded,
            onPressed: _openGatePass,
          ),

          // ----------------------------------------------------
          // CANCEL APPOINTMENT
          // ----------------------------------------------------

          if (canCancel) ...[
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isCancelling
                    ? null
                    : _cancelAppointment,
                icon: _isCancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.cancel_outlined,
                      ),
                label: Text(
                  _isCancelling
                      ? 'Cancelling...'
                      : 'Cancel appointment',
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      c.danger,
                  side: BorderSide(
                    color: c.danger
                        .withAlpha(150),
                  ),
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 14,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),
              ),
            ),
          ],

          // Temporary GPS information.
          if (_currentPosition != null) ...[
            const SizedBox(height: 12),
            Text(
              'GPS: '
              '${_currentPosition!.latitude.toStringAsFixed(6)}, '
              '${_currentPosition!.longitude.toStringAsFixed(6)}',
              style: t.caption,
            ),
          ],
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // CANCELLED BANNER
  // ----------------------------------------------------------

  Widget _buildCancelledBanner(
    AppColors c,
    AppType t,
  ) {
    return SurfaceCard(
      color: c.danger.withAlpha(20),
      borderColor:
          c.danger.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: c.danger,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.close_rounded,
              color: c.bg,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Appointment cancelled',
                  style: t.heading,
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.plateNumber ?? 'Your truck'} '
                  'appointment has been cancelled.',
                  style: t.bodyMuted.copyWith(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // COMPLETED BANNER
  // ----------------------------------------------------------

  Widget _buildCompletedBanner(
    AppColors c,
    AppType t,
  ) {
    return SurfaceCard(
      color: c.successSoft,
      borderColor:
          c.success.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: c.success,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_rounded,
              color: c.bg,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  'Wash complete',
                  style: t.heading,
                ),
                const SizedBox(height: 2),
                Text(
                  '${widget.plateNumber ?? 'Your truck'} '
                  'is clean and ready to go.',
                  style: t.bodyMuted.copyWith(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // NO WASH CARD
  // ----------------------------------------------------------

  Widget _buildNoWashCard(
    AppColors c,
    AppType t,
  ) {
    return SurfaceCard(
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
              Icons.local_shipping_outlined,
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
                  'No wash booked',
                  style: t.heading,
                ),
                const SizedBox(height: 2),
                Text(
                  'Book a slot before you head to the station.',
                  style: t.bodyMuted.copyWith(
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // RECENT WASHES LIST
  // ----------------------------------------------------------

  Widget _buildRecentWashes(
    AppColors c,
    AppType t,
  ) {
    if (isLoadingWashes) {
      return Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 76,
            margin:
                const EdgeInsets.only(
              bottom: 12,
            ),
            decoration:
                BoxDecoration(
              color: c.surface,
              borderRadius:
                  BorderRadius.circular(18),
              border: Border.all(
                color: c.line,
              ),
            ),
          ),
        ),
      );
    }

    if (completedAppointments.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No washes yet',
        message:
            'Your finished washes will show up here.',
      );
    }

    return Column(
      children: completedAppointments
          .map((appointment) {
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

        return Padding(
          padding:
              const EdgeInsets.only(
            bottom: 12,
          ),
          child: _buildWashTile(
            c,
            t,
            plate,
            '$date  ·  $comingFrom',
          ),
        );
      }).toList(),
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
          DateTime.parse(
        value.toString(),
      );

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

      return '${months[date.month - 1]} '
          '${date.day}';
    } catch (e) {
      return value.toString();
    }
  }

  // ----------------------------------------------------------
  // RECENT WASH ITEM
  // ----------------------------------------------------------

  Widget _buildWashTile(
    AppColors c,
    AppType t,
    String plate,
    String details,
  ) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color: c.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: c.successSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_car_wash_rounded,
              color: c.success,
              size: 23,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  plate.toUpperCase(),
                  style:
                      t.heading.copyWith(
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  style: t.caption,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Pill(
            label: 'Washed',
            color: c.success,
            background:
                c.successSoft,
            icon:
                Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.text,
  });

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: c.textMuted,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: t.body.copyWith(
              fontSize: 15,
              color: c.text,
            ),
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}