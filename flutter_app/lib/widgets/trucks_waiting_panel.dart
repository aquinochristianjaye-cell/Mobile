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
  State<TrucksWaitingPanel> createState() =>
      _TrucksWaitingPanelState();
}

class _TrucksWaitingPanelState
    extends State<TrucksWaitingPanel> {
  List<dynamic> appointments = [];
  List<dynamic> assignments = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _loadData();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _loadData();
      },
    );
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        AppointmentService.getAdminAppointments(),
        WorkerAssignmentService.getActiveAssignments(),
      ]);

      if (!mounted) return;

      setState(() {
        appointments = results[0];
        assignments = results[1];
      });
    } catch (e) {
      // Keep dashboard working if API is temporarily unavailable.
    }
  }

  Map<String, dynamic>? _getAssignmentForAppointment(
    dynamic appointment,
  ) {
    final appointmentId =
        int.tryParse(
          appointment['id'].toString(),
        ) ??
        0;

    for (final assignment in assignments) {
      final assignedAppointmentId =
          int.tryParse(
            assignment['appointment_id'].toString(),
          ) ??
          0;

      if (assignedAppointmentId == appointmentId) {
        return Map<String, dynamic>.from(
          assignment,
        );
      }
    }

    return null;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
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
              padding: const EdgeInsets.symmetric(
                vertical: 28,
              ),
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
              constraints: const BoxConstraints(
                maxHeight: 430,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child: SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  child: Column(
                    children: appointments
                        .map(
                          (appointment) {
                            final assignment =
                                _getAssignmentForAppointment(
                              appointment,
                            );

                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                bottom: 8,
                              ),
                              child:
                                  _AppointmentTruckRow(
                                appointment:
                                    appointment,
                                assignment:
                                    assignment,
                                allAssignments:
                                    assignments,
                              ),
                            );
                          },
                        )
                        .toList(),
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

  const _AppointmentTruckRow({
    required this.appointment,
    this.assignment,
    this.allAssignments = const [],
  });

  @override
  State<_AppointmentTruckRow> createState() =>
      _AppointmentTruckRowState();
}

class _AppointmentTruckRowState
    extends State<_AppointmentTruckRow> {
  List<Map<String, dynamic>> workers = [];

  bool isLoadingWorkers = false;
  bool workersLoadFailed = false;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();

    _loadWorkers();

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _loadWorkers(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWorkers() async {
    final isFirstLoad = workers.isEmpty;

    try {
      if (isFirstLoad && mounted) {
        setState(() {
          isLoadingWorkers = true;
        });
      }

      final data =
          await WorkerService.getWorkers();

      if (!mounted) return;

      setState(() {
        workers = data;
        isLoadingWorkers = false;
        workersLoadFailed = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingWorkers = false;
        workersLoadFailed = workers.isEmpty;
      });
    }
  }

  Set<dynamic> get _busyWorkerIds {
    return widget.allAssignments
        .where(
          (assignment) =>
              assignment['status'] == 'assigned' ||
              assignment['status'] == 'washing',
        )
        .map(
          (assignment) =>
              assignment['worker_id'],
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
        .where(
          (id) => id != 0,
        )
        .toSet();
  }

  /// ===================== DEPLOY =====================

  Future<void> _openDeployDialog(
    int appointmentId,
  ) async {
    _loadWorkers();

    if (workers.isEmpty &&
        !workersLoadFailed) {
      await _loadWorkers();
    }

    if (!mounted) return;

    if (workers.isEmpty &&
        workersLoadFailed) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Could not load workers. Check your connection and try again.',
          ),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () =>
                _openDeployDialog(
              appointmentId,
            ),
          ),
        ),
      );
      return;
    }

    final busyWorkerIds =
        _busyWorkerIds;

    final busyBayIds =
        _busyBayIds;

    final availableWorkers = workers
        .where(
          (worker) =>
              !busyWorkerIds.contains(
            worker['id'],
          ),
        )
        .toList();

    if (availableWorkers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No available workers right now — everyone is already assigned.',
          ),
        ),
      );
      return;
    }

    final availableBays = [1, 2]
        .where(
          (bay) =>
              !busyBayIds.contains(bay),
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

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Deploy Truck',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration:
                        const InputDecoration(
                      labelText: 'Wash Worker',
                    ),
                    items:
                        availableWorkers.map(
                      (worker) {
                        final id =
                            worker['id'];

                        final firstName =
                            worker['first_name']
                                    ?.toString() ??
                                '';

                        final lastName =
                            worker['last_name']
                                    ?.toString() ??
                                '';

                        final name =
                            '$firstName $lastName'
                                .trim();

                        return DropdownMenuItem<int>(
                          value: id,
                          child: Text(
                            name.isEmpty
                                ? 'Unknown worker'
                                : name,
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedWorkerId =
                            value;
                      });
                    },
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<int>(
                    decoration:
                        const InputDecoration(
                      labelText: 'Wash Bay',
                    ),
                    items:
                        availableBays.map(
                      (bay) {
                        return DropdownMenuItem<int>(
                          value: bay,
                          child: Text(
                            'Wash Bay $bay',
                          ),
                        );
                      },
                    ).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedBayId =
                            value;
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                  child: const Text(
                    'Cancel',
                  ),
                ),
                ElevatedButton(
                  onPressed:
                      selectedWorkerId == null ||
                              selectedBayId == null
                          ? null
                          : () async {
                              try {
                                await DeploymentService
                                    .deployTruck(
                                  appointmentId:
                                      appointmentId,
                                  workerId:
                                      selectedWorkerId!,
                                  washBayId:
                                      selectedBayId!,
                                );

                                if (!context.mounted) {
                                  return;
                                }

                                Navigator.pop(
                                  dialogContext,
                                );

                                ScaffoldMessenger
                                    .of(context)
                                    .showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Truck deployed successfully.',
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!context.mounted) {
                                  return;
                                }

                                ScaffoldMessenger
                                    .of(context)
                                    .showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Deploy failed: ${e.toString()}',
                                    ),
                                  ),
                                );
                              }
                            },
                  child: const Text(
                    'Deploy',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// ===================== TRACK DRIVER =====================

  Future<void> _openTrackDialog(
    int driverId,
  ) async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: AppColors.panel,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 850,
            height: 620,
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.fromLTRB(
                    18,
                    16,
                    10,
                    12,
                  ),
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
                            weight:
                                FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                        icon: const Icon(
                          Icons.close,
                          color:
                              AppColors.textDim,
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
                    padding:
                        const EdgeInsets.all(12),
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
    final appointment =
        widget.appointment;

    final assignment =
        widget.assignment;

    final driver =
        appointment['driver'];

    final plate =
        appointment['truck_plate'] ??
            'N/A';

    final driverName =
        driver?['name'] ??
            'Unknown driver';

    final livestock =
        appointment['livestock_load'] ??
            'N/A';

    final comingFrom =
        appointment['coming_from'] ??
            'N/A';

    final preferred =
        appointment['preferred_datetime'] ??
            '';

    final appointmentId =
        int.tryParse(
              appointment['id']
                  .toString(),
            ) ??
            0;

    final isDeployed =
        assignment != null;

    final assignmentStatus =
        assignment?['status']
                ?.toString() ??
            '';

    final worker =
        assignment?['worker'];

    final workerName =
        worker != null
            ? '${worker['first_name'] ?? ''} '
                    '${worker['last_name'] ?? ''}'
                .trim()
            : 'Unknown worker';

    final washBay =
        assignment?['wash_bay_id'] ??
            'N/A';

    // Tracking is allowed while the truck is
    // coming/assigned, but stops being available
    // once the worker starts washing.
    final canTrack =
        !isDeployed ||
        assignmentStatus == 'assigned';

    return Container(
      padding:
          const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius:
            BorderRadius.circular(10),
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
                decoration:
                    BoxDecoration(
                  color: isDeployed
                      ? AppColors.ok.withValues(
                          alpha: 0.12,
                        )
                      : AppColors.water.withValues(
                          alpha: 0.12,
                        ),
                  borderRadius:
                      BorderRadius.circular(
                    8,
                  ),
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
                        weight:
                            FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
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
              padding:
                  const EdgeInsets.all(10),
              decoration:
                  BoxDecoration(
                color:
                    AppColors.ok.withValues(
                  alpha: 0.06,
                ),
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                  color:
                      AppColors.ok.withValues(
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
                            ? Icons
                                .local_car_wash
                            : Icons.check_circle,
                        size: 15,
                        color:
                            AppColors.ok,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        assignmentStatus ==
                                'washing'
                            ? 'WASHING'
                            : 'TRUCK DEPLOYED',
                        style: bodyStyle(
                          size: 10,
                          weight:
                              FontWeight.w700,
                          color:
                              AppColors.ok,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Worker: $workerName',
                    style: bodyStyle(
                      size: 10.5,
                      color:
                          AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Wash Bay: $washBay',
                    style: bodyStyle(
                      size: 10.5,
                      color:
                          AppColors.textDim,
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
                decoration:
                    BoxDecoration(
                  color:
                      AppColors.crit.withValues(
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
                      color:
                          AppColors.crit,
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
                child: ElevatedButton(
                  onPressed:
                      isLoadingWorkers
                          ? null
                          : () =>
                              _openDeployDialog(
                                appointmentId,
                              ),
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.water,
                    foregroundColor:
                        const Color(
                      0xFF0B1116,
                    ),
                    disabledBackgroundColor:
                        AppColors.water
                            .withValues(
                      alpha: 0.4,
                    ),
                    elevation: 0,
                    padding:
                        const EdgeInsets
                            .symmetric(
                      vertical: 9,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                        8,
                      ),
                    ),
                  ),
                  child:
                      isLoadingWorkers
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                                color:
                                    Color(
                                  0xFF0B1116,
                                ),
                              ),
                            )
                          : const Text(
                              'Deploy',
                              style:
                                  TextStyle(
                                fontSize: 11,
                                fontWeight:
                                    FontWeight
                                        .w700,
                              ),
                            ),
                ),
              ),
          ],

          // TRACK BUTTON
          //
          // This stays available after deployment while
          // the assignment is still "assigned".
          //
          // Once the worker changes the assignment to
          // "washing", this button disappears.
          if (canTrack &&
              (appointmentId != 0)) ...[
            const SizedBox(height: 7),

            SizedBox(
              width: double.infinity,
              child:
                  OutlinedButton.icon(
                onPressed: () {
                  final driverId =
                      int.tryParse(
                    '${driver?['id']}',
                  );

                  if (driverId == null) {
                    ScaffoldMessenger
                        .of(context)
                        .showSnackBar(
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
                    color: AppColors.water
                        .withValues(
                      alpha: 0.45,
                    ),
                  ),
                  elevation: 0,
                  padding:
                      const EdgeInsets
                          .symmetric(
                    vertical: 9,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
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