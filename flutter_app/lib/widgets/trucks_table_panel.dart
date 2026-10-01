import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../services/worker_assignment_service.dart';
import 'common/panel.dart';

/// ===================== TRUCKS TABLE =====================

class _TruckRow {
  final String plate;
  final String type;
  final String bay;
  final String started;
  final String finished;
  final String duration;

  const _TruckRow(
    this.plate,
    this.type,
    this.bay,
    this.started,
    this.finished,
    this.duration,
  );
}

class TrucksTablePanel
    extends StatefulWidget {
  const TrucksTablePanel({
    super.key,
  });

  @override
  State<TrucksTablePanel> createState() =>
      _TrucksTablePanelState();
}

class _TrucksTablePanelState
    extends State<TrucksTablePanel> {
  List<dynamic> assignments = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    loadCompletedTrucks();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        loadCompletedTrucks();
      },
    );
  }

  Future<void> loadCompletedTrucks() async {
    try {
      final data =
          await WorkerAssignmentService
              .getCompletedAssignments();

      if (!mounted) return;

      setState(() {
        // Keep only the latest 8 completed trucks.
        assignments =
            data.take(8).toList();
      });
    } catch (e) {
      // Keep the existing data if the API is temporarily unavailable.
    }
  }

  String formatDateTime(
    dynamic value,
  ) {
    if (value == null ||
        value.toString().isEmpty) {
      return 'N/A';
    }

    try {
      final dateTime =
          DateTime.parse(
        value.toString(),
      ).toLocal();

      final hour =
          dateTime.hour == 0
              ? 12
              : dateTime.hour > 12
                  ? dateTime.hour - 12
                  : dateTime.hour;

      final minute =
          dateTime.minute
              .toString()
              .padLeft(2, '0');

      final period =
          dateTime.hour >= 12
              ? 'PM'
              : 'AM';

      return '$hour:$minute $period';
    } catch (e) {
      return 'N/A';
    }
  }

  String calculateDuration(
    dynamic startedAt,
    dynamic finishedAt,
  ) {
    if (startedAt == null ||
        finishedAt == null) {
      return 'N/A';
    }

    try {
      final started =
          DateTime.parse(
        startedAt.toString(),
      );

      final finished =
          DateTime.parse(
        finishedAt.toString(),
      );

      final difference =
          finished.difference(
        started,
      );

      final totalMinutes =
          difference.inMinutes;

      if (totalMinutes < 1) {
        return '< 1 min';
      }

      final hours =
          totalMinutes ~/ 60;

      final minutes =
          totalMinutes % 60;

      if (hours > 0) {
        return '${hours}h ${minutes}m';
      }

      return '$minutes min';
    } catch (e) {
      return 'N/A';
    }
  }

  _TruckRow buildTruckRow(
    dynamic assignment,
  ) {
    final appointment =
        assignment['appointment'];

    final plate =
        appointment?[
                'truck_plate'] ??
            'N/A';

    final type =
        appointment?[
                'livestock_load'] ??
            'N/A';

    final bay =
        assignment[
                    'wash_bay_id'] !=
                null
            ? 'Bay ${assignment['wash_bay_id']}'
            : 'N/A';

    final startedAt =
        assignment['started_at'];

    final finishedAt =
        assignment['finished_at'];

    final started =
        formatDateTime(
      startedAt,
    );

    final finished =
        formatDateTime(
      finishedAt,
    );

    final duration =
        calculateDuration(
      startedAt,
      finishedAt,
    );

    return _TruckRow(
      plate.toString(),
      type.toString(),
      bay,
      started,
      finished,
      duration,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rows = assignments
        .map(
          (assignment) =>
              buildTruckRow(
            assignment,
          ),
        )
        .toList();

    return Panel(
      eyebrow: "Today's Log",
      title:
          'Trucks Finished Washing',
      trailing: Text(
        '${rows.length} COMPLETED',
        style: monoStyle(
          size: 10,
          color:
              AppColors.textFaint,
        ),
      ),
      child: rows.isEmpty
          ? Container(
              width:
                  double.infinity,
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 35,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons
                        .local_shipping_outlined,
                    size: 32,
                    color:
                        AppColors
                            .textFaint,
                  ),

                  const SizedBox(
                      height: 8),

                  Text(
                    'No trucks finished washing',
                    style: bodyStyle(
                      size: 12.5,
                      weight:
                          FontWeight.w600,
                      color:
                          AppColors
                              .textDim,
                    ),
                  ),

                  const SizedBox(
                      height: 3),

                  Text(
                    'Completed trucks will appear here',
                    style: bodyStyle(
                      size: 10,
                      color:
                          AppColors
                              .textFaint,
                    ),
                  ),
                ],
              ),
            )
          : SizedBox(
              width:
                  double.infinity,
              child:
                  SingleChildScrollView(
                scrollDirection:
                    Axis.horizontal,
                child: SizedBox(
                  width:
                      MediaQuery.of(
                                  context)
                              .size
                              .width >
                          900
                      ? MediaQuery.of(
                                  context)
                              .size
                              .width -
                          64
                      : 850,
                  child: rows.length >=
                          4
                      ? SizedBox(
                          height: 220,
                          child:
                              SingleChildScrollView(
                            scrollDirection:
                                Axis.vertical,
                            child:
                                _buildDataTable(
                              rows,
                            ),
                          ),
                        )
                      : _buildDataTable(
                          rows,
                        ),
                ),
              ),
            ),
    );
  }

  Widget _buildDataTable(
    List<_TruckRow> rows,
  ) {
    return DataTable(
      headingRowHeight: 30,
      dataRowMinHeight: 42,
      dataRowMaxHeight: 42,
      horizontalMargin: 10,
      columnSpacing: 30,
      dividerThickness: 0.5,
      headingTextStyle:
          const TextStyle(
        fontSize: 10,
        fontWeight:
            FontWeight.w600,
        letterSpacing: 0.7,
        color:
            AppColors.textFaint,
      ),
      columns: const [
        DataColumn(
          label:
              Text('PLATE NO.'),
        ),
        DataColumn(
          label:
              Text('TRUCK TYPE'),
        ),
        DataColumn(
          label:
              Text('BAY'),
        ),
        DataColumn(
          label:
              Text('STARTED'),
        ),
        DataColumn(
          label:
              Text('FINISHED'),
        ),
        DataColumn(
          label:
              Text('DURATION'),
        ),
        DataColumn(
          label:
              Text('STATUS'),
        ),
      ],
      rows: rows.map(
        (r) {
          return DataRow(
            cells: [
              DataCell(
                Text(
                  r.plate,
                  style: monoStyle(
                    size: 12,
                    weight:
                        FontWeight.w600,
                  ),
                ),
              ),

              DataCell(
                Text(
                  r.type,
                  style: bodyStyle(
                    size: 12,
                    color:
                        AppColors
                            .textDim,
                  ),
                ),
              ),

              DataCell(
                Text(
                  r.bay,
                  style: bodyStyle(
                    size: 12,
                  ),
                ),
              ),

              DataCell(
                Text(
                  r.started,
                  style: monoStyle(
                    size: 12,
                  ),
                ),
              ),

              DataCell(
                Text(
                  r.finished,
                  style: monoStyle(
                    size: 12,
                  ),
                ),
              ),

              DataCell(
                Text(
                  r.duration,
                  style: monoStyle(
                    size: 12,
                  ),
                ),
              ),

              DataCell(
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 9,
                    vertical: 3,
                  ),
                  decoration:
                      BoxDecoration(
                    color: AppColors
                        .ok
                        .withValues(
                            alpha: 0.12),
                    borderRadius:
                        BorderRadius
                            .circular(
                      100,
                    ),
                  ),
                  child: Row(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check,
                        size: 10,
                        color:
                            AppColors.ok,
                      ),

                      const SizedBox(
                          width: 4),

                      Text(
                        'Done',
                        style:
                            TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight
                                  .w700,
                          color:
                              AppColors
                                  .ok,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ).toList(),
    );
  }
}
