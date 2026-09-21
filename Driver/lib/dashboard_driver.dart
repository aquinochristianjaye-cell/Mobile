import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

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
    Key? key,
    required this.driverId,
    this.appointmentId,
    this.plateNumber,
    this.livestockLoad,
    this.preferredTime,
    this.comingFrom,
  }) : super(key: key);

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

      final String status = appointment['status']?.toString() ?? '';

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
              (appointment) => appointment['id'] == widget.appointmentId,
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
  // LOAD COMPLETED WASHES
  // ----------------------------------------------------------

  Future<void> _loadCompletedWashes() async {
    // Give this request a unique version number.
    final int requestVersion = ++_completedLoadVersion;

    try {
      final response = await http.get(
        Uri.parse(
          'http://192.168.100.236:8000/api/driver/${widget.driverId}/completed',
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
          completedAppointments = List<Map<String, dynamic>>.from(
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

  // Pull-to-refresh: reload the list and, if a wash is active, its status.
  Future<void> _refreshAll() async {
    if (widget.appointmentId != null && currentStatus != 'completed') {
      await _loadAppointmentStatus();
    }
    await _loadCompletedWashes();
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
          plateNumber: widget.plateNumber ?? 'Unknown',
          livestockLoad: widget.livestockLoad ?? '',
          preferredTime: widget.preferredTime ?? '',
          comingFrom: widget.comingFrom ?? '',
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

    // Current wash disappears after the worker finishes.
    final bool hasAppointment =
        widget.appointmentId != null && currentStatus != 'completed';
    final bool justCompleted =
        widget.appointmentId != null && currentStatus == 'completed';

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
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${DriverSession.greeting},', style: t.bodyMuted),
                        Text(DriverSession.firstName, style: t.display),
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
              if (hasAppointment) _buildCurrentWash(c, t),

              if (justCompleted) _buildCompletedBanner(c, t),

              if (!hasAppointment && !justCompleted) _buildNoWashCard(c, t),

              const SizedBox(height: 32),

              // ------------------------------------------------
              // RECENT WASHES
              // ------------------------------------------------
              Text('Recent washes', style: t.heading),

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

  Widget _buildCurrentWash(AppColors c, AppType t) {
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      borderColor: c.accent.withAlpha(110),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Current wash', style: t.label),
              Pill(
                label: _currentStatusText,
                color: _statusColor(c),
                background: _statusBackground(c),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: PlateTag(widget.plateNumber ?? 'Unknown', fontSize: 30),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _InfoLine(
            icon: Icons.location_on_outlined,
            text: (widget.comingFrom == null || widget.comingFrom!.isEmpty)
                ? 'Location not specified'
                : 'From ${widget.comingFrom}',
          ),
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.event_outlined,
            text: '${widget.livestockLoad ?? ''}  ·  ${widget.preferredTime ?? ''}',
          ),

          const SizedBox(height: 24),

          WashTracker(stepIndex: _stepIndex),

          const SizedBox(height: 18),

          Text(_statusHint, style: t.bodyMuted.copyWith(fontSize: 15)),

          const SizedBox(height: 18),

          PrimaryButton(
            label: 'Show gate pass',
            icon: Icons.qr_code_2_rounded,
            onPressed: _openGatePass,
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedBanner(AppColors c, AppType t) {
    return SurfaceCard(
      color: c.successSoft,
      borderColor: c.success.withAlpha(120),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: c.success, shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, color: c.bg, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Wash complete', style: t.heading),
                const SizedBox(height: 2),
                Text(
                  '${widget.plateNumber ?? 'Your truck'} is clean and ready to go.',
                  style: t.bodyMuted.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoWashCard(AppColors c, AppType t) {
    return SurfaceCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: c.accentSoft, shape: BoxShape.circle),
            child: Icon(Icons.local_shipping_outlined, color: c.accent, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('No wash booked', style: t.heading),
                const SizedBox(height: 2),
                Text(
                  'Book a slot before you head to the station.',
                  style: t.bodyMuted.copyWith(fontSize: 15),
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

  Widget _buildRecentWashes(AppColors c, AppType t) {
    if (isLoadingWashes) {
      return Column(
        children: List.generate(
          3,
          (_) => Container(
            height: 76,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: c.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: c.line),
            ),
          ),
        ),
      );
    }

    if (completedAppointments.isEmpty) {
      return const EmptyState(
        icon: Icons.history_rounded,
        title: 'No washes yet',
        message: 'Your finished washes will show up here.',
      );
    }

    return Column(
      children: completedAppointments.map((appointment) {
        final String plate = appointment['truck_plate']?.toString() ?? 'Unknown';

        final String comingFrom =
            appointment['coming_from']?.toString() ?? 'Location not specified';

        final String date = _formatDate(appointment['preferred_datetime']);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildWashTile(c, t, plate, '$date  ·  $comingFrom'),
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

      return '${months[date.month - 1]} ${date.day}';
    } catch (e) {
      return value.toString();
    }
  }

  // ----------------------------------------------------------
  // RECENT WASH ITEM
  // ----------------------------------------------------------

  Widget _buildWashTile(AppColors c, AppType t, String plate, String details) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: c.successSoft, shape: BoxShape.circle),
            child: Icon(Icons.local_car_wash_rounded, color: c.success, size: 23),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  plate.toUpperCase(),
                  style: t.heading.copyWith(letterSpacing: 1.5),
                ),
                const SizedBox(height: 3),
                Text(
                  details,
                  style: t.caption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Pill(
            label: 'Washed',
            color: c.success,
            background: c.successSoft,
            icon: Icons.check_rounded,
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Row(
      children: [
        Icon(icon, size: 20, color: c.textMuted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: t.body.copyWith(fontSize: 15, color: c.text),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
