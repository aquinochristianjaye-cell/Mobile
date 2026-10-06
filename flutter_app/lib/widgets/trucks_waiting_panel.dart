import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../services/appointment_service.dart';
import '../services/worker_assignment_service.dart';
import '../services/worker_service.dart';
import '../services/deployment_service.dart';

import 'common/panel.dart';
import 'common/small_status.dart';
import 'driver_tracking_panel.dart';

/// ===================== TRUCKS WAITING =====================

class TrucksWaitingPanel extends StatefulWidget {
  const TrucksWaitingPanel({super.key});

  @override
  State<TrucksWaitingPanel> createState() => _TrucksWaitingPanelState();
}

class _TrucksWaitingPanelState extends State<TrucksWaitingPanel> {
  List<dynamic> appointments = [];
  List<dynamic> assignments = [];
  List<Map<String, dynamic>> workers = [];

  Timer? _timer;
  Timer? _workersTimer;
  bool _isLoading = false;
  bool _reloadQueued = false;

  @override
  void initState() {
    super.initState();

    _loadData();
    _loadWorkers();

    // Appointments + assignments change often: poll every 3 seconds.
    _timer = Timer.periodic(
      const Duration(seconds: 3),
      (_) => _loadData(),
    );

    // Worker status changes less often.
    _workersTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadWorkers(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _workersTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    final result = await _safe<List<dynamic>>(
      WorkerService.getWorkers(),
      workers,
    );

    if (!mounted) return;

    setState(() {
      workers = result
          .map((w) => Map<String, dynamic>.from(w as Map))
          .toList();
    });
  }

  /// Shows a freshly deployed truck right away, using the response from
  /// the deploy request, without waiting for the next poll.
  void _addAssignment(dynamic assignment) {
    if (assignment == null) return;

    setState(() {
      assignments = [...assignments, assignment];
    });
  }

  /// Runs a request and returns [fallback] if it fails, so one failing
  /// endpoint never wipes out the data from the others.
  Future<T> _safe<T>(Future<T> future, T fallback) async {
    try {
      return await future;
    } catch (e) {
      debugPrint('API error: $e');
      return fallback;
    }
  }

  Future<void> _loadData() async {
    // If a poll is already running, don't start another one.
    if (_isLoading) {
      _reloadQueued = true;
      return;
    }

    _isLoading = true;

    try {
      final results = await Future.wait<Object>([
        _safe<List<dynamic>>(
          AppointmentService.getAdminAppointments(),
          appointments,
        ),
        _safe<List<dynamic>>(
          WorkerAssignmentService.getActiveAssignments(),
          assignments,
        ),
      ]);

      if (!mounted) return;

      setState(() {
        appointments = results[0] as List<dynamic>;
        assignments = results[1] as List<dynamic>;
      });
    } finally {
      _isLoading = false;
    }

    if (_reloadQueued && mounted) {
      _reloadQueued = false;
      _loadData();
    }
  }

  Map<String, dynamic>? _getAssignmentForAppointment(
    dynamic appointment,
  ) {
    final appointmentId =
        int.tryParse(appointment['id'].toString()) ?? 0;

    for (final assignment in assignments) {
      final assignedAppointmentId =
          int.tryParse(
                assignment['appointment_id'].toString(),
              ) ??
              0;

      if (assignedAppointmentId == appointmentId) {
        return Map<String, dynamic>.from(assignment);
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      eyebrow: 'Incoming',
      title: 'Trucks Waiting',
      trailing: SmallStatus(
        text: appointments.isEmpty
            ? 'NO TRUCKS'
            : '${appointments.length} WAITING',
        color: appointments.isEmpty
            ? AppColors.textFaint
            : AppColors.water,
      ),
      child: appointments.isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(vertical: 28),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.local_shipping_outlined,
                    size: 32,
                    color: AppColors.textFaint,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No trucks waiting',
                    style: bodyStyle(
                      size: 12.5,
                      weight: FontWeight.w600,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Confirmed trucks will appear here',
                    style: bodyStyle(
                      size: 10,
                      color: AppColors.textFaint,
                    ),
                  ),
                ],
              ),
            )
          : ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 430),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: appointments.map((appointment) {
                      final assignment =
                          _getAssignmentForAppointment(
                        appointment,
                      );

                      return Padding(
                        padding:
                            const EdgeInsets.only(bottom: 8),
                        child: _AppointmentTruckRow(
                          appointment: appointment,
                          assignment: assignment,
                          allAssignments: assignments,
                          workers: workers,
                          onChanged: _loadData,
                          onDeployed: _addAssignment,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
    );
  }
}

/// ===================== APPOINTMENT TRUCK ROW =====================

class _AppointmentTruckRow extends StatefulWidget {
  final Map<String, dynamic> appointment;
  final Map<String, dynamic>? assignment;
  final List<dynamic> allAssignments;
  final List<Map<String, dynamic>> workers;
  final Future<void> Function() onChanged;
  final void Function(dynamic assignment) onDeployed;

  const _AppointmentTruckRow({
    required this.appointment,
    required this.workers,
    required this.onChanged,
    required this.onDeployed,
    this.assignment,
    this.allAssignments = const [],
  });

  @override
  State<_AppointmentTruckRow> createState() =>
      _AppointmentTruckRowState();
}

class _AppointmentTruckRowState
    extends State<_AppointmentTruckRow> {
  Set<dynamic> get _busyWorkerIds {
    return widget.allAssignments
        .where(
          (assignment) =>
              assignment['status'] == 'assigned' ||
              assignment['status'] == 'washing',
        )
        .map(
          (assignment) => assignment['worker_id'],
        )
        .toSet();
  }

  Set<int> get _busyBayIds {
    return widget.allAssignments
        .where(
          (assignment) =>
              assignment['status'] == 'washing',
        )
        .map<int>(
          (assignment) =>
              int.tryParse(
                assignment['wash_bay_id'].toString(),
              ) ??
              0,
        )
        .where((id) => id != 0)
        .toSet();
  }

  // ----------------------------------------------------------
  // WORKER STATUS HELPERS
  // ----------------------------------------------------------

  bool _isWorkerAvailable(
    Map<String, dynamic> worker,
  ) {
    final value = worker['is_available'];

    return value == true ||
        value == 1 ||
        value?.toString().toLowerCase() == 'true' ||
        value?.toString() == '1';
  }

  bool _isWorkerOnBreak(
    Map<String, dynamic> worker,
  ) {
    final value = worker['is_on_break'];

    return value == true ||
        value == 1 ||
        value?.toString().toLowerCase() == 'true' ||
        value?.toString() == '1';
  }

  String _workerName(
    Map<String, dynamic> worker,
  ) {
    final firstName =
        worker['first_name']?.toString() ?? '';

    final lastName =
        worker['last_name']?.toString() ?? '';

    final name =
        '$firstName $lastName'.trim();

    return name.isEmpty ? 'Unknown worker' : name;
  }

  /// ===================== DEPLOY DIALOG =====================

  void _openDeployDialog(int appointmentId) {
    final workers = widget.workers;

    if (workers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No workers loaded yet. Try again in a moment.',
          ),
        ),
      );
      return;
    }

    final busyWorkerIds = _busyWorkerIds;
    final busyBayIds = _busyBayIds;

    // A worker can only be selected if:
    // 1. They are not already assigned/washing.
    // 2. They are marked available.
    // 3. They are not currently on break.
    final availableWorkers = workers
        .where(
          (worker) =>
              !busyWorkerIds.contains(worker['id']) &&
              _isWorkerAvailable(worker) &&
              !_isWorkerOnBreak(worker),
        )
        .toList();

    if (availableWorkers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No workers are available right now. Workers may be busy, unavailable, or on break.',
          ),
        ),
      );
      return;
    }

    final availableBays = [1, 2]
        .where(
          (bay) => !busyBayIds.contains(bay),
        )
        .toList();

    if (availableBays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No wash bays are free right now — both bays are in use.',
          ),
        ),
      );
      return;
    }

    int? selectedWorkerId;
    int? selectedBayId;
    bool isDeploying = false;

    final appointment = widget.appointment;
    final driver = appointment['driver'];

    final plate =
        appointment['truck_plate']?.toString() ?? 'N/A';

    final driverName =
        driver?['name']?.toString() ?? 'Unknown driver';

    final livestock =
        appointment['livestock_load']?.toString() ?? 'N/A';

    final comingFrom =
        appointment['coming_from']?.toString() ?? 'N/A';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            final selectedWorker = selectedWorkerId == null
                ? null
                : availableWorkers.firstWhere(
                    (worker) =>
                        int.tryParse(
                          worker['id'].toString(),
                        ) ==
                        selectedWorkerId,
                    orElse: () => {},
                  );

            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 40,
                vertical: 30,
              ),
              child: Container(
                width: 760,
                constraints: const BoxConstraints(
                  maxHeight: 720,
                ),
                decoration: BoxDecoration(
                  color: AppColors.panel,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.lineStrong,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: 0.35,
                      ),
                      blurRadius: 30,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ==================================================
                    // HEADER
                    // ==================================================

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        24,
                        22,
                        18,
                        18,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.water.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius:
                                  BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.local_shipping_outlined,
                              color: AppColors.water,
                              size: 23,
                            ),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deploy Truck',
                                  style: bodyStyle(
                                    size: 18,
                                    weight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Assign a washer and wash bay',
                                  style: bodyStyle(
                                    size: 11,
                                    color: AppColors.textDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: isDeploying
                                ? null
                                : () => Navigator.pop(
                                      dialogContext,
                                    ),
                            icon: const Icon(
                              Icons.close,
                              size: 20,
                              color: AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Divider(
                      height: 1,
                      color: AppColors.line,
                    ),

                    Flexible(
                      child: SingleChildScrollView(
                        physics:
                            const BouncingScrollPhysics(),
                        padding: const EdgeInsets.all(22),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            // ==========================================
                            // TRUCK SUMMARY
                            // ==========================================

                            Text(
                              'TRUCK DETAILS',
                              style: bodyStyle(
                                size: 9.5,
                                weight: FontWeight.w800,
                                color: AppColors.textFaint,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Container(
                              padding:
                                  const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.panel2,
                                borderRadius:
                                    BorderRadius.circular(13),
                                border: Border.all(
                                  color: AppColors.line,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.water
                                          .withValues(
                                        alpha: 0.10,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(
                                        10,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons
                                          .local_shipping_outlined,
                                      color:
                                          AppColors.water,
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          plate,
                                          style: monoStyle(
                                            size: 14,
                                            weight:
                                                FontWeight.w700,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          driverName,
                                          style: bodyStyle(
                                            size: 10.5,
                                            color:
                                                AppColors.textDim,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  _InfoChip(
                                    icon:
                                        Icons.pets_outlined,
                                    text: livestock,
                                  ),
                                  const SizedBox(width: 7),
                                  _InfoChip(
                                    icon: Icons
                                        .location_on_outlined,
                                    text: comingFrom,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 22),

                            // ==========================================
                            // WORKER SELECTION
                            // ==========================================

                            Row(
                              children: [
                                Text(
                                  'SELECT WASH WORKER',
                                  style: bodyStyle(
                                    size: 9.5,
                                    weight: FontWeight.w800,
                                    color:
                                        AppColors.textFaint,
                                  ),
                                ),
                                const Spacer(),
                                Container(
                                  padding:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.ok
                                        .withValues(
                                      alpha: 0.10,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(
                                      100,
                                    ),
                                  ),
                                  child: Text(
                                    '${availableWorkers.length} READY',
                                    style: TextStyle(
                                      color: AppColors.ok,
                                      fontSize: 9,
                                      fontWeight:
                                          FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 9),

                            LayoutBuilder(
                              builder:
                                  (context, constraints) {
                                final cardWidth =
                                    constraints.maxWidth >
                                            600
                                        ? (constraints
                                                    .maxWidth -
                                                12) /
                                            2
                                        : constraints.maxWidth;

                                return Wrap(
                                  spacing: 12,
                                  runSpacing: 10,
                                  children:
                                      availableWorkers.map(
                                    (worker) {
                                      final id =
                                          int.tryParse(
                                        worker['id']
                                            .toString(),
                                      );

                                      final isSelected =
                                          id != null &&
                                              selectedWorkerId ==
                                                  id;

                                      final name =
                                          _workerName(
                                        worker,
                                      );

                                      return SizedBox(
                                        width: cardWidth,
                                        child:
                                            _DeployWorkerCard(
                                          name: name,
                                          workerId:
                                              worker['worker_id']
                                                      ?.toString() ??
                                                  '',
                                          isSelected:
                                              isSelected,
                                          onTap: isDeploying ||
                                                  id == null
                                              ? null
                                              : () {
                                                  setDialogState(
                                                    () {
                                                      selectedWorkerId =
                                                          id;
                                                    },
                                                  );
                                                },
                                        ),
                                      );
                                    },
                                  ).toList(),
                                );
                              },
                            ),

                            const SizedBox(height: 22),

                            // ==========================================
                            // WASH BAY SELECTION
                            // ==========================================

                            Text(
                              'SELECT WASH BAY',
                              style: bodyStyle(
                                size: 9.5,
                                weight: FontWeight.w800,
                                color: AppColors.textFaint,
                              ),
                            ),

                            const SizedBox(height: 9),

                            Row(
                              children:
                                  availableBays.map(
                                (bay) {
                                  final isSelected =
                                      selectedBayId == bay;

                                  return Expanded(
                                    child: Padding(
                                      padding:
                                          EdgeInsets.only(
                                        right: bay ==
                                                availableBays
                                                    .last
                                            ? 0
                                            : 10,
                                      ),
                                      child:
                                          _DeployBayCard(
                                        bay: bay,
                                        isSelected:
                                            isSelected,
                                        onTap: isDeploying
                                            ? null
                                            : () {
                                                setDialogState(
                                                  () {
                                                    selectedBayId =
                                                        bay;
                                                  },
                                                );
                                              },
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),
                            ),

                            const SizedBox(height: 22),

                            // ==========================================
                            // DEPLOYMENT SUMMARY
                            // ==========================================

                            Container(
                              width: double.infinity,
                              padding:
                                  const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: selectedWorker != null &&
                                        selectedBayId != null
                                    ? AppColors.water
                                        .withValues(
                                        alpha: 0.055,
                                      )
                                    : AppColors.panel2,
                                borderRadius:
                                    BorderRadius.circular(13),
                                border: Border.all(
                                  color: selectedWorker !=
                                              null &&
                                          selectedBayId != null
                                      ? AppColors.water
                                          .withValues(
                                          alpha: 0.20,
                                        )
                                      : AppColors.line,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    selectedWorker != null &&
                                            selectedBayId !=
                                                null
                                        ? Icons
                                            .assignment_turned_in_outlined
                                        : Icons
                                            .assignment_outlined,
                                    size: 20,
                                    color:
                                        selectedWorker !=
                                                    null &&
                                                selectedBayId !=
                                                    null
                                            ? AppColors.water
                                            : AppColors
                                                .textFaint,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment
                                              .start,
                                      children: [
                                        Text(
                                          selectedWorker !=
                                                      null &&
                                                  selectedBayId !=
                                                      null
                                              ? 'Ready to deploy'
                                              : 'Deployment summary',
                                          style: bodyStyle(
                                            size: 11,
                                            weight:
                                                FontWeight.w700,
                                            color: selectedWorker !=
                                                        null &&
                                                    selectedBayId !=
                                                        null
                                                ? AppColors
                                                    .water
                                                : AppColors
                                                    .textDim,
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 4,
                                        ),
                                        Text(
                                          selectedWorker !=
                                                      null &&
                                                  selectedBayId !=
                                                      null
                                              ? '$plate  •  ${_workerName(selectedWorker)}  •  Wash Bay $selectedBayId'
                                              : 'Choose a worker and wash bay to continue.',
                                          style: bodyStyle(
                                            size: 10,
                                            color: AppColors
                                                .textFaint,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // ==================================================
                    // FOOTER
                    // ==================================================

                    Container(
                      padding: const EdgeInsets.fromLTRB(
                        22,
                        14,
                        22,
                        18,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.panel2,
                        borderRadius:
                            const BorderRadius.vertical(
                          bottom: Radius.circular(20),
                        ),
                        border: Border(
                          top: BorderSide(
                            color: AppColors.line,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              isDeploying
                                  ? 'Deploying truck...'
                                  : 'The selected worker will receive this assignment.',
                              style: bodyStyle(
                                size: 10,
                                color: AppColors.textFaint,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: isDeploying
                                ? null
                                : () => Navigator.pop(
                                      dialogContext,
                                    ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          ElevatedButton.icon(
                            onPressed:
                                selectedWorkerId == null ||
                                        selectedBayId == null ||
                                        isDeploying
                                    ? null
                                    : () async {
                                        setDialogState(
                                          () {
                                            isDeploying =
                                                true;
                                          },
                                        );

                                        try {
                                          final result =
                                              await DeploymentService
                                                  .deployTruck(
                                            appointmentId:
                                                appointmentId,
                                            workerId:
                                                selectedWorkerId!,
                                            washBayId:
                                                selectedBayId!,
                                          );

                                          if (!dialogContext
                                              .mounted) {
                                            return;
                                          }

                                          Navigator.pop(
                                            dialogContext,
                                          );

                                          // Show the deployed truck
                                          // immediately.
                                          widget.onDeployed(
                                            result['assignment'],
                                          );

                                          // Sync with server.
                                          widget.onChanged();

                                          if (!mounted) return;

                                          ScaffoldMessenger.of(
                                            this.context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Truck deployed successfully.',
                                              ),
                                            ),
                                          );
                                        } catch (e) {
                                          if (!dialogContext
                                              .mounted) {
                                            return;
                                          }

                                          setDialogState(
                                            () {
                                              isDeploying =
                                                  false;
                                            },
                                          );

                                          ScaffoldMessenger.of(
                                            dialogContext,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Deploy failed: $e',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                            icon: isDeploying
                                ? const SizedBox(
                                    width: 15,
                                    height: 15,
                                    child:
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(
                                    Icons
                                        .rocket_launch_outlined,
                                    size: 16,
                                  ),
                            label: Text(
                              isDeploying
                                  ? 'Deploying...'
                                  : 'Deploy Truck',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight.w800,
                              ),
                            ),
                            style:
                                ElevatedButton.styleFrom(
                              backgroundColor:
                                  AppColors.water,
                              foregroundColor:
                                  const Color(0xFF0B1116),
                              disabledBackgroundColor:
                                  AppColors.water.withValues(
                                alpha: 0.30,
                              ),
                              disabledForegroundColor:
                                  AppColors.textFaint,
                              elevation: 0,
                              padding:
                                  const EdgeInsets.symmetric(
                                horizontal: 17,
                                vertical: 12,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(9),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// ===================== TRACK DRIVER =====================

  Future<void> _openTrackDialog(int driverId) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 850,
            height: 620,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(18, 16, 10, 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: AppColors.water,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Track Driver',
                          style: bodyStyle(
                            size: 15,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pop(dialogContext),
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textDim,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  color: AppColors.line,
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: DriverTrackingPanel(
                      driverId: driverId,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final assignment = widget.assignment;

    final driver = appointment['driver'];

    final plate =
        appointment['truck_plate'] ?? 'N/A';

    final driverName =
        driver?['name'] ?? 'Unknown driver';

    final livestock =
        appointment['livestock_load'] ?? 'N/A';

    final comingFrom =
        appointment['coming_from'] ?? 'N/A';

    final preferred =
        appointment['preferred_datetime'] ?? '';

    final appointmentId =
        int.tryParse(
              appointment['id'].toString(),
            ) ??
            0;

    final isDeployed =
        assignment != null;

    final assignmentStatus =
        assignment?['status']?.toString() ?? '';

    final worker =
        assignment?['worker'];

    final workerName = worker != null
        ? '${worker['first_name'] ?? ''} ${worker['last_name'] ?? ''}'
            .trim()
        : 'Unknown worker';

    final washBay =
        assignment?['wash_bay_id'] ?? 'N/A';

    // Tracking is allowed while the truck is coming/assigned,
    // but stops once the worker starts washing.
    final canTrack =
        !isDeployed ||
        assignmentStatus == 'assigned';

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDeployed
              ? AppColors.ok.withValues(
                  alpha: 0.35,
                )
              : AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDeployed
                      ? AppColors.ok.withValues(
                          alpha: 0.12,
                        )
                      : AppColors.water.withValues(
                          alpha: 0.12,
                        ),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: Icon(
                  isDeployed
                      ? Icons.check_circle_outline
                      : Icons.local_shipping_outlined,
                  color: isDeployed
                      ? AppColors.ok
                      : AppColors.water,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      plate,
                      style: monoStyle(
                        size: 12,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      driverName,
                      style: bodyStyle(
                        size: 10.5,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),
              SmallStatus(
                text: isDeployed
                    ? assignmentStatus ==
                            'washing'
                        ? 'WASHING'
                        : 'DEPLOYED'
                    : 'WAITING',
                color: isDeployed
                    ? assignmentStatus ==
                            'washing'
                        ? AppColors.ok
                        : AppColors.warn
                    : AppColors.water,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Coming from: $comingFrom',
            style: bodyStyle(
              size: 10.5,
              color: AppColors.textDim,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Load: $livestock',
            style: bodyStyle(
              size: 10.5,
              color: AppColors.textDim,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Preferred: $preferred',
            style: bodyStyle(
              size: 10,
              color: AppColors.textFaint,
            ),
          ),

          if (isDeployed) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.ok.withValues(
                  alpha: 0.06,
                ),
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.ok.withValues(
                    alpha: 0.20,
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        assignmentStatus ==
                                'washing'
                            ? Icons.local_car_wash
                            : Icons.check_circle,
                        size: 15,
                        color: AppColors.ok,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        assignmentStatus ==
                                'washing'
                            ? 'WASHING'
                            : 'TRUCK DEPLOYED',
                        style: bodyStyle(
                          size: 10,
                          weight: FontWeight.w700,
                          color: AppColors.ok,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Worker: $workerName',
                    style: bodyStyle(
                      size: 10.5,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Wash Bay: $washBay',
                    style: bodyStyle(
                      size: 10.5,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (!isDeployed) ...[
            const SizedBox(height: 10),
            if (appointmentId == 0)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(
                  vertical: 9,
                  horizontal: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.crit.withValues(
                    alpha: 0.10,
                  ),
                  borderRadius:
                      BorderRadius.circular(8),
                  border: Border.all(
                    color:
                        AppColors.crit.withValues(
                      alpha: 0.30,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 15,
                      color: AppColors.crit,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Cannot deploy: this appointment has an invalid ID.',
                        style: bodyStyle(
                          size: 10.5,
                          weight:
                              FontWeight.w600,
                          color:
                              AppColors.crit,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () =>
                      _openDeployDialog(
                    appointmentId,
                  ),
                  icon: const Icon(
                    Icons.rocket_launch_outlined,
                    size: 15,
                  ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.water,
                    foregroundColor:
                        const Color(0xFF0B1116),
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 9,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                  ),
                  label: const Text(
                    'Deploy Truck',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],

          // TRACK BUTTON
          //
          // Stays available after deployment while the assignment
          // is still "assigned". Once it changes to "washing",
          // it disappears.
          if (canTrack &&
              appointmentId != 0) ...[
            const SizedBox(height: 7),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final driverId =
                      int.tryParse(
                    '${driver?['id']}',
                  );

                  if (driverId == null) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Driver information is not available.',
                        ),
                      ),
                    );
                    return;
                  }

                  _openTrackDialog(
                    driverId,
                  );
                },
                icon: const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                ),
                label: const Text(
                  'Track',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight:
                        FontWeight.w700,
                  ),
                ),
                style:
                    OutlinedButton.styleFrom(
                  foregroundColor:
                      AppColors.water,
                  side: BorderSide(
                    color:
                        AppColors.water.withValues(
                      alpha: 0.45,
                    ),
                  ),
                  elevation: 0,
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 9,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// ===============================================================
/// DEPLOY WORKER CARD
/// ===============================================================

class _DeployWorkerCard
    extends StatelessWidget {
  final String name;
  final String workerId;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DeployWorkerCard({
    required this.name,
    required this.workerId,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelected
        ? AppColors.water
        : AppColors.line;

    final backgroundColor = isSelected
        ? AppColors.water.withValues(
            alpha: 0.08,
          )
        : AppColors.panel2;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.water
                          .withValues(
                          alpha: 0.14,
                        )
                      : AppColors.ok.withValues(
                          alpha: 0.10,
                        ),
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.person_outline,
                  size: 20,
                  color: isSelected
                      ? AppColors.water
                      : AppColors.ok,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow:
                          TextOverflow.ellipsis,
                      style: bodyStyle(
                        size: 11.5,
                        weight:
                            FontWeight.w700,
                      ),
                    ),
                    if (workerId.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        workerId,
                        style: monoStyle(
                          size: 9,
                          color:
                              AppColors.textFaint,
                        ),
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration:
                              const BoxDecoration(
                            color:
                                AppColors.ok,
                            shape:
                                BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Available • Ready for work',
                          style: bodyStyle(
                            size: 8.5,
                            color:
                                AppColors.ok,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(
                  milliseconds: 180,
                ),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.water
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? AppColors.water
                        : AppColors.lineStrong,
                    width: 1.5,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        size: 15,
                        color:
                            Color(0xFF0B1116),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// DEPLOY BAY CARD
/// ===============================================================

class _DeployBayCard
    extends StatelessWidget {
  final int bay;
  final bool isSelected;
  final VoidCallback? onTap;

  const _DeployBayCard({
    required this.bay,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(12),
        child: AnimatedContainer(
          duration:
              const Duration(milliseconds: 180),
          padding:
              const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.water.withValues(
                    alpha: 0.08,
                  )
                : AppColors.panel2,
            borderRadius:
                BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppColors.water
                  : AppColors.line,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.water
                          .withValues(
                          alpha: 0.14,
                        )
                      : AppColors.panel,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_car_wash_outlined,
                  size: 20,
                  color: isSelected
                      ? AppColors.water
                      : AppColors.textDim,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Wash Bay $bay',
                      style: bodyStyle(
                        size: 11.5,
                        weight:
                            FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Ready for assignment',
                      style: bodyStyle(
                        size: 8.5,
                        color:
                            AppColors.ok,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color:
                      AppColors.water,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===============================================================
/// SMALL INFORMATION CHIP
/// ===============================================================

class _InfoChip
    extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints:
          const BoxConstraints(
        maxWidth: 130,
      ),
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius:
            BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: AppColors.textDim,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow:
                  TextOverflow.ellipsis,
              style: bodyStyle(
                size: 8.5,
                color:
                    AppColors.textDim,
              ),
            ),
          ),
        ],
      ),
    );
  }
}