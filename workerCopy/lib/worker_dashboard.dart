import 'dart:async';
import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'power_spray_screen.dart';
import 'washing_screen.dart';
import 'services/worker_assignment_service.dart';
import 'services/station_supply_service.dart';
import 'widgets.dart';
import 'worker_session.dart';

class WorkerDashboardScreen extends StatefulWidget {
  final int workerId;
  final String workerName;
  final String workerIdNumber;

  const WorkerDashboardScreen({
    super.key,
    required this.workerId,
    required this.workerName,
    required this.workerIdNumber,
  });

  @override
  State<WorkerDashboardScreen> createState() =>
      _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState
    extends State<WorkerDashboardScreen> {
  // Currently assigned trucks
  List<dynamic> assignments = [];

  // Trucks finished by this worker
  List<dynamic> completedAssignments = [];

  bool isLoadingAssignments = true;
  bool isLoadingCompleted = true;

  // Shared station supply levels
  double foamWashLevel = 0;
  double disinfectantLevel = 0;
  double waterLevel = 0;

  bool isLoadingSupplies = true;

  // Blocks double taps on Start / Finish while a request is running
  bool _actionBusy = false;

  // Refresh every 5 seconds
  Timer? _assignmentTimer;

  @override
  void initState() {
    super.initState();

    // Make sure the session knows who is signed in, even after a hot restart.
    if (WorkerSession.isEmpty) {
      WorkerSession.start(
        workerId: widget.workerId,
        workerName: widget.workerName,
        code: widget.workerIdNumber,
      );
    }

    _loadAssignments();
    _loadCompletedAssignments();
    _loadSupplies();

    _assignmentTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _loadAssignments();
        _loadCompletedAssignments();
        _loadSupplies();
      },
    );
  }

  Future<void> _loadAssignments() async {
    try {
      final data =
          await WorkerAssignmentService.getAssignments(
        widget.workerId,
      );

      if (!mounted) return;

      setState(() {
        assignments = data;
        isLoadingAssignments = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        assignments = [];
        isLoadingAssignments = false;
      });
    }
  }

  Future<void> _loadCompletedAssignments() async {
    try {
      final data =
          await WorkerAssignmentService
              .getCompletedAssignments(
        widget.workerId,
      );

      if (!mounted) return;

      setState(() {
        // Only show the latest 6 finished trucks.
        // Older records remain in the database.
        completedAssignments = data.take(6).toList();
        isLoadingCompleted = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        completedAssignments = [];
        isLoadingCompleted = false;
      });
    }
  }

  // ============================================================
  // SHARED STATION SUPPLIES
  // ============================================================

  Future<void> _loadSupplies() async {
    try {
      final data =
          await StationSupplyService.getSupplies();

      if (!mounted) return;

      setState(() {
        foamWashLevel = data['Foam Wash'] ?? 0;
        disinfectantLevel =
            data['Disinfectant'] ?? 0;
        waterLevel = data['Water'] ?? 0;
        isLoadingSupplies = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingSupplies = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _loadAssignments(),
      _loadCompletedAssignments(),
      _loadSupplies(),
    ]);
  }

  @override
  void dispose() {
    _assignmentTimer?.cancel();
    super.dispose();
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  Future<void> _startWash(
    Map<String, dynamic> assignment,
    Map<String, dynamic> appointment,
  ) async {
    if (_actionBusy) return;

    setState(() {
      _actionBusy = true;
    });

    try {
      final assignmentId = assignment['id'];

      await WorkerAssignmentService.startAssignment(
        assignmentId,
      );

      if (!mounted) return;

      await _loadAssignments();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => WashingScreen(
            appointment: appointment,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      showAppSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionBusy = false;
        });
      }
    }
  }

  Future<void> _finishWash(
    Map<String, dynamic> assignment,
  ) async {
    if (_actionBusy) return;

    setState(() {
      _actionBusy = true;
    });

    try {
      final assignmentId = assignment['id'];

      await WorkerAssignmentService.finishAssignment(
        assignmentId,
      );

      if (!mounted) return;

      // Refresh both active and
      // completed trucks immediately.
      await Future.wait([
        _loadAssignments(),
        _loadCompletedAssignments(),
      ]);

      if (!mounted) return;

      showAppSnack(context, 'Washing completed.');
    } catch (e) {
      if (!mounted) return;

      showAppSnack(
        context,
        e.toString().replaceFirst('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _actionBusy = false;
        });
      }
    }
  }

  // Opens the update sheet right on the dashboard (no extra page).
  Future<void> _openSupplyUpdater() async {
    final SupplyLevels? saved = await showSupplyUpdateSheet(
      context,
      foamWash: foamWashLevel,
      disinfectant: disinfectantLevel,
      water: waterLevel,
    );

    if (!mounted || saved == null) return;

    // Show the new levels immediately...
    setState(() {
      foamWashLevel = saved.foamWash;
      disinfectantLevel = saved.disinfectant;
      waterLevel = saved.water;
    });

    showAppSnack(context, 'Supply levels updated.');

    // ...then confirm with the server.
    _loadSupplies();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ContentWidth(
          child: RefreshIndicator(
            onRefresh: _refreshAll,
            color: c.accent,
            backgroundColor: c.surface,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                _buildHeader(t),

                const SizedBox(height: 26),

                const SectionHeader('Truck queue'),
                const SizedBox(height: 12),
                _buildTruckQueue(c, t),

                const SizedBox(height: 30),

                const SectionHeader('Chemical and fluid levels'),
                const SizedBox(height: 12),
                _buildLevelsCard(c, t),

                const SizedBox(height: 30),

                const SectionHeader('Finished trucks'),
                const SizedBox(height: 12),
                _buildCompletedTrucks(c, t),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(AppType t) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${WorkerSession.greeting},', style: t.bodyMuted),
              Text(WorkerSession.firstName, style: t.display),
              const SizedBox(height: 2),
              Text('Worker ID ${widget.workerIdNumber}', style: t.caption),
            ],
          ),
        ),
        const WorkerAvatar(),
      ],
    );
  }

  // ============================================================
  // TRUCK QUEUE
  // ============================================================

  Widget _buildTruckQueue(AppColors c, AppType t) {
    if (isLoadingAssignments) {
      return const SkeletonBlock(height: 260, radius: 20);
    }

    if (assignments.isEmpty) {
      return const SurfaceCard(
        padding: EdgeInsets.zero,
        child: EmptyState(
          icon: Icons.local_shipping_outlined,
          title: 'No truck to wash',
          message: 'There are currently no assigned trucks.',
        ),
      );
    }

    final assignment =
        Map<String, dynamic>.from(assignments.first);

    final appointment = Map<String, dynamic>.from(
      assignment['appointment'] ?? {},
    );

    final driver = Map<String, dynamic>.from(
      appointment['driver'] ?? {},
    );

    final String driverName =
        (driver['name'] ?? 'Unknown driver').toString();

    final String truckPlate =
        (appointment['truck_plate'] ?? 'Unknown truck').toString();

    final String comingFrom =
        (appointment['coming_from'] ?? 'Unknown location').toString();

    return _buildQueueCard(
      c,
      t,
      truckPlate,
      driverName,
      comingFrom,
      appointment,
      assignment,
    );
  }

  // ============================================================
  // QUEUE CARD
  // ============================================================

  Widget _buildQueueCard(
    AppColors c,
    AppType t,
    String plate,
    String name,
    String location,
    Map<String, dynamic> appointment,
    Map<String, dynamic> assignment,
  ) {
    final String assignmentStatus =
        (assignment['status'] ?? 'assigned').toString();

    final String appointmentStatus =
        (appointment['status'] ?? 'scheduled').toString();

    final bool isWashing = assignmentStatus == 'washing';

    final bool hasArrived = appointmentStatus == 'arrived';

    // Same colors and words the driver sees in their app.
    final int step = isWashing ? 2 : (hasArrived ? 1 : 0);
    final Color color =
        isWashing ? c.accent : (hasArrived ? c.success : c.signal);
    final Color soft = isWashing
        ? c.accentSoft
        : (hasArrived ? c.successSoft : c.signalSoft);
    final String statusLabel =
        isWashing ? 'Washing' : (hasArrived ? 'Arrived' : 'On the way');

    final int waiting = assignments.length - 1;

    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      borderColor: color.withAlpha(140),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isWashing ? 'Now washing' : 'Next truck', style: t.label),
              Pill(label: statusLabel, color: color, background: soft),
            ],
          ),

          const SizedBox(height: 14),

          Row(
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: PlateTag(plate, fontSize: 30),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          _InfoLine(icon: Icons.person_outline_rounded, text: name),
          const SizedBox(height: 8),
          _InfoLine(
            icon: Icons.location_on_outlined,
            text: location == 'Unknown location'
                ? location
                : 'From $location',
          ),

          if (waiting > 0) ...[
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.groups_outlined,
              text:
                  '+$waiting more ${waiting == 1 ? 'truck' : 'trucks'} waiting after this one',
              muted: true,
            ),
          ],

          const SizedBox(height: 24),

          WashTracker(stepIndex: step),

          const SizedBox(height: 22),

          // Truck is currently washing
          if (isWashing) ...[
            PrimaryButton(
              label: 'Finish washing',
              icon: Icons.check_circle_outline_rounded,
              loading: _actionBusy,
              onPressed: () => _finishWash(assignment),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              label: 'View truck details',
              icon: Icons.local_shipping_outlined,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => WashingScreen(
                      appointment: appointment,
                    ),
                  ),
                );
              },
            ),
          ]
          // Truck arrived but washing has not started
          else if (hasArrived)
            PrimaryButton(
              label: 'Start washing',
              icon: Icons.play_arrow_rounded,
              loading: _actionBusy,
              onPressed: () => _startWash(assignment, appointment),
            )
          // Truck has not arrived yet
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: c.signalSoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Icon(Icons.hourglass_bottom_rounded, size: 22, color: c.signal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Waiting for the truck to arrive. You can start once it\'s here.',
                      style: t.body.copyWith(fontSize: 15, color: c.text),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // CHEMICAL & FLUID LEVELS
  // ============================================================

  Widget _buildLevelsCard(AppColors c, AppType t) {
    if (isLoadingSupplies) {
      return const SkeletonBlock(height: 250, radius: 20);
    }

    // Names of anything running very low, so it can't be missed.
    final low = <String>[
      if (foamWashLevel <= 20) 'foam wash',
      if (disinfectantLevel <= 20) 'disinfectant',
      if (waterLevel <= 20) 'water',
    ];

    return Semantics(
      button: true,
      label: 'Update chemical and fluid levels',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _openSupplyUpdater,
        child: SurfaceCard(
          child: Column(
            children: [
              SupplyGauge(label: 'Foam wash', level: foamWashLevel),
              const SizedBox(height: 20),
              SupplyGauge(label: 'Disinfectant', level: disinfectantLevel),
              const SizedBox(height: 20),
              SupplyGauge(label: 'Water', level: waterLevel),

              const SizedBox(height: 16),
              Divider(height: 1, color: c.line),
              const SizedBox(height: 14),

              if (low.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 18, color: c.danger),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Refill soon: ${low.join(', ')}.',
                        style: t.caption.copyWith(
                          color: c.danger,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Update levels',
                    style: t.label.copyWith(
                      color: c.accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.chevron_right_rounded, color: c.accent),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // COMPLETED TRUCKS
  // ============================================================

  Widget _buildCompletedTrucks(AppColors c, AppType t) {
    if (isLoadingCompleted) {
      return Column(
        children: List.generate(
          2,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: SkeletonBlock(height: 104),
          ),
        ),
      );
    }

    if (completedAssignments.isEmpty) {
      return const SurfaceCard(
        padding: EdgeInsets.zero,
        child: EmptyState(
          icon: Icons.history_rounded,
          title: 'No finished trucks',
          message: 'Finished trucks will appear here.',
        ),
      );
    }

    // At most 6 trucks are kept, so they simply flow in the page.
    return Column(
      children: completedAssignments.map((assignment) {
        final appointment = Map<String, dynamic>.from(
          assignment['appointment'] ?? {},
        );

        final driver = Map<String, dynamic>.from(
          appointment['driver'] ?? {},
        );

        final plate =
            appointment['truck_plate'] ?? 'Unknown truck';

        final driverName =
            driver['name'] ?? 'Unknown driver';

        final finishedAt = assignment['finished_at'];

        final bay = assignment['wash_bay_id'] ?? 'N/A';

        final duration = _calculateDuration(
          assignment['started_at'],
          assignment['finished_at'],
        );

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildFinishedCard(
            c,
            t,
            plate.toString(),
            '$driverName · Bay $bay',
            _formatDateTime(finishedAt),
            duration,
          ),
        );
      }).toList(),
    );
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  String _formatDateTime(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Finished time unavailable';
    }

    try {
      final dateTime = DateTime.parse(
        value.toString(),
      ).toLocal();

      return formatMonthDayTime(dateTime);
    } catch (e) {
      return 'Finished time unavailable';
    }
  }

  String _calculateDuration(
    dynamic startedAt,
    dynamic finishedAt,
  ) {
    if (startedAt == null || finishedAt == null) {
      return 'Duration unavailable';
    }

    try {
      final started = DateTime.parse(
        startedAt.toString(),
      );

      final finished = DateTime.parse(
        finishedAt.toString(),
      );

      final difference = finished.difference(
        started,
      );

      final totalMinutes = difference.inMinutes;

      if (totalMinutes < 1) {
        return '< 1 min';
      }

      final hours = totalMinutes ~/ 60;

      final minutes = totalMinutes % 60;

      if (hours > 0) {
        return 'Duration: ${hours}h ${minutes}m';
      }

      return 'Duration: $minutes min';
    } catch (e) {
      return 'Duration unavailable';
    }
  }

  // ============================================================
  // FINISHED CARD
  // ============================================================

  Widget _buildFinishedCard(
    AppColors c,
    AppType t,
    String plate,
    String info,
    String time,
    String duration,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: c.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(info, style: t.caption.copyWith(fontSize: 14)),
                const SizedBox(height: 2),
                Text(time, style: t.caption),
                const SizedBox(height: 2),
                Text(
                  duration,
                  style: t.caption.copyWith(color: c.textFaint, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Pill(
            label: 'Finished',
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
  const _InfoLine({
    required this.icon,
    required this.text,
    this.muted = false,
  });

  final IconData icon;
  final String text;
  final bool muted;

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
            style: t.body.copyWith(
              fontSize: 15,
              color: muted ? c.textMuted : c.text,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
