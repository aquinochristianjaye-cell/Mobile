import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../services/worker_assignment_service.dart';
import 'common/panel.dart';
import 'common/small_status.dart';

/// ===================== CURRENTLY WASHING =====================

class CurrentlyWashingPanel
    extends StatefulWidget {
  const CurrentlyWashingPanel({
    super.key,
  });

  @override
  State<CurrentlyWashingPanel> createState() =>
      _CurrentlyWashingPanelState();
}

class _CurrentlyWashingPanelState
    extends State<CurrentlyWashingPanel> {
  List<dynamic> assignments = [];
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _loadAssignments();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _loadAssignments();
      },
    );
  }

  Future<void> _loadAssignments() async {
    try {
      final data =
          await WorkerAssignmentService
              .getActiveAssignments();

      if (!mounted) return;

      setState(() {
        assignments = data
            .where(
              (assignment) =>
                  assignment['status'] ==
                  'washing',
            )
            .toList();
      });
    } catch (e) {
      // Keep dashboard working if API is unavailable.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Panel(
      eyebrow: 'Active',
      title: 'Currently Washing',
      trailing: SmallStatus(
        text: assignments.isEmpty
            ? '0 ACTIVE'
            : '${assignments.length} ACTIVE',
        color: assignments.isEmpty
            ? AppColors.textFaint
            : AppColors.ok,
      ),
      child: assignments.isEmpty
          ? Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 24,
              ),
              alignment:
                  Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons
                        .local_car_wash_outlined,
                    size: 30,
                    color:
                        AppColors.textFaint,
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  Text(
                    'No trucks currently washing',
                    style: bodyStyle(
                      size: 12,
                      weight:
                          FontWeight.w600,
                      color:
                          AppColors
                              .textDim,
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children:
                  assignments.map(
                (assignment) {
                  final appointment =
                      assignment[
                          'appointment'];

                  final worker =
                      assignment['worker'];

                  final plate =
                      appointment?[
                              'truck_plate'] ??
                          'N/A';

                  final livestock =
                      appointment?[
                              'livestock_load'] ??
                          'N/A';

                  final bay =
                      assignment[
                              'wash_bay_id'] ??
                          'N/A';

                  final workerName =
                      worker != null
                          ? '${worker['first_name'] ?? ''} ${worker['last_name'] ?? ''}'
                              .trim()
                          : 'Unknown worker';

                  return Container(
                    padding:
                        const EdgeInsets
                            .all(11),
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors.panel2,
                      borderRadius:
                          BorderRadius
                              .circular(
                                  10),
                      border:
                          Border.all(
                        color:
                            AppColors
                                .line,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration:
                              BoxDecoration(
                            color: AppColors
                                .ok
                                .withValues(
                                    alpha: 0.12),
                            borderRadius:
                                BorderRadius
                                    .circular(
                                        8),
                          ),
                          child:
                              const Icon(
                            Icons
                                .local_car_wash_outlined,
                            color:
                                AppColors
                                    .ok,
                            size: 18,
                          ),
                        ),

                        const SizedBox(
                            width: 10),

                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                plate,
                                style:
                                    monoStyle(
                                  size: 12,
                                  weight:
                                      FontWeight
                                          .w600,
                                ),
                              ),

                              const SizedBox(
                                  height: 2),

                              Text(
                                '$livestock · Wash Bay $bay',
                                style:
                                    bodyStyle(
                                  size: 10.5,
                                  color:
                                      AppColors
                                          .textDim,
                                ),
                              ),

                              const SizedBox(
                                  height: 1),

                              Text(
                                'Worker: $workerName',
                                style:
                                    bodyStyle(
                                  size: 9.5,
                                  color:
                                      AppColors
                                          .textFaint,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SmallStatus(
                          text: 'WASHING',
                          color:
                              AppColors.ok,
                        ),
                      ],
                    ),
                  );
                },
              ).toList(),
            ),
    );
  }
}

