import 'dart:async';
import 'package:flutter/material.dart';
import 'setting_screen.dart';
import 'power_spray_screen.dart';
import 'washing_screen.dart';
import 'services/worker_assignment_service.dart';
import 'services/station_supply_service.dart';

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
  static const bgCream = Color(0xFFF3EFE7);
  static const darkText = Color(0xFF13233F);
  static const tealHeader = Color(0xFF1F7A8C);
  static const greenBar = Color(0xFF7CB342);
  static const orangeBar = Color(0xFFE6A135);
  static const redBar = Color(0xFFD9534F);
  static const cardBg = Colors.white;

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

  // Refresh every 5 seconds
  Timer? _assignmentTimer;

  @override
  void initState() {
    super.initState();

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

  @override
  void dispose() {
    _assignmentTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          children: [
            // Top Accent Bar
            Container(
              height: 8,
              width: double.infinity,
              color: tealHeader,
            ),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                physics:
                    const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Header
                    _buildHeader(context),

                    const SizedBox(height: 24),

                    // Truck Queue
                    _buildSectionTitle(
                      'TRUCK QUEUE',
                    ),

                    const SizedBox(height: 8),

                    _buildTruckQueue(context),

                    const SizedBox(height: 24),

                    // Chemical & Fluid Levels
                    _buildSectionTitle(
                      'CHEMICAL & FLUID LEVELS',
                    ),

                    const SizedBox(height: 8),

                    _buildLevelsCard(context),

                    const SizedBox(height: 24),

                    // Truck Information
                    _buildSectionTitle(
                      'TRUCK INFORMATION',
                    ),

                    const SizedBox(height: 8),

                    // 1–3 trucks = normal
                    // 4–6 trucks = scrollable
                    _buildCompletedTrucks(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F2),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                'Hi ${widget.workerName},',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 2),

              const Text(
                'Good evening',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight:
                      FontWeight.bold,
                  color: darkText,
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
                      const SettingsScreen(),
                ),
              );
            },
            child: CircleAvatar(
              radius: 24,
              backgroundColor:
                  const Color(0xFFDCD2C0),
              child: Text(
                _getInitials(
                  widget.workerName,
                ),
                style: const TextStyle(
                  fontWeight:
                      FontWeight.bold,
                  color: darkText,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight:
            FontWeight.bold,
        color:
            darkText.withValues(
          alpha: 0.6,
        ),
        letterSpacing: 0.8,
      ),
    );
  }

  // ============================================================
  // TRUCK QUEUE
  // ============================================================

  Widget _buildTruckQueue(
    BuildContext context,
  ) {
    if (isLoadingAssignments) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius:
              BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.03,
              ),
              blurRadius: 8,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (assignments.isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          vertical: 28,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius:
              BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.03,
              ),
              blurRadius: 8,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons
                  .local_shipping_outlined,
              size: 32,
              color:
                  darkText.withValues(
                alpha: 0.35,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'No truck to wash',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    darkText.withValues(
                  alpha: 0.65,
                ),
              ),
            ),

            const SizedBox(height: 3),

            Text(
              'There are currently no assigned trucks.',
              style: TextStyle(
                fontSize: 10,
                color:
                    darkText.withValues(
                  alpha: 0.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final assignment =
        assignments.first;

    final appointment =
        Map<String, dynamic>.from(
      assignment['appointment'] ?? {},
    );

    final driver =
        Map<String, dynamic>.from(
      appointment['driver'] ?? {},
    );

    final driverName =
        driver['name'] ??
            'Unknown driver';

    final truckPlate =
        appointment['truck_plate'] ??
            'Unknown truck';

    final comingFrom =
        appointment['coming_from'] ??
            'Unknown location';

    return _buildQueueCard(
      context,
      truckPlate,
      driverName,
      comingFrom,
      appointment,
      Map<String, dynamic>.from(
        assignment,
      ),
    );
  }

  // ============================================================
  // INITIALS
  // ============================================================

  String _getInitials(String name) {
    final parts =
        name.trim().split(' ');

    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}';
    }

    return parts.first[0];
  }

  // ============================================================
  // QUEUE CARD
  // ============================================================

  Widget _buildQueueCard(
    BuildContext context,
    String plate,
    String name,
    String location,
    Map<String, dynamic> appointment,
    Map<String, dynamic> assignment,
  ) {
    final assignmentStatus =
        assignment['status'] ??
            'assigned';

    final appointmentStatus =
        appointment['status'] ??
            'scheduled';

    final isWashing =
        assignmentStatus == 'washing';

    final hasArrived =
        appointmentStatus == 'arrived';

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: isWashing
                    ? orangeBar
                    : hasArrived
                        ? greenBar
                        : tealHeader,
                width: 8,
              ),
            ),
          ),
          padding:
              const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      plate,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            darkText,
                      ),
                    ),

                    const SizedBox(
                        height: 4),

                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            darkText
                                .withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),

                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            darkText
                                .withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 6),

                    Container(
                      padding:
                          const EdgeInsets
                              .symmetric(
                        horizontal: 9,
                        vertical: 4,
                      ),
                      decoration:
                          BoxDecoration(
                        color: isWashing
                            ? const Color(
                                0xFFFFF3E0,
                              )
                            : hasArrived
                                ? const Color(
                                    0xFFE8F5E9,
                                  )
                                : const Color(
                                    0xFFE8F1F2,
                                  ),
                        borderRadius:
                            BorderRadius
                                .circular(
                          10,
                        ),
                      ),
                      child: Text(
                        isWashing
                            ? 'WASHING'
                            : hasArrived
                                ? 'ARRIVED'
                                : 'DRIVING',
                        style:
                            TextStyle(
                          fontSize: 10,
                          fontWeight:
                              FontWeight
                                  .bold,
                          color: isWashing
                              ? const Color(
                                  0xFFE65100,
                                )
                              : hasArrived
                                  ? const Color(
                                      0xFF2E7D32,
                                    )
                                  : tealHeader,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 12),

              // Truck has not arrived yet
              if (!hasArrived &&
                  !isWashing)
                Container(
                  padding:
                      const EdgeInsets
                          .symmetric(
                    horizontal: 12,
                    vertical: 9,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFE8F1F2,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      16,
                    ),
                  ),
                  child:
                      const Text(
                    'DRIVING',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                      color:
                          tealHeader,
                      fontSize: 12,
                    ),
                  ),
                ),

              // Truck arrived but washing has not started
              if (hasArrived &&
                  !isWashing)
                ElevatedButton(
                  onPressed:
                      () async {
                    final assignmentId =
                        assignment['id'];

                    try {
                      await WorkerAssignmentService
                          .startAssignment(
                        assignmentId,
                      );

                      if (!context
                          .mounted) {
                        return;
                      }

                      await _loadAssignments();

                      if (!context
                          .mounted) {
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  WashingScreen(
                            appointment:
                                appointment,
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context
                          .mounted) {
                        return;
                      }

                      ScaffoldMessenger
                              .of(context)
                          .showSnackBar(
                        SnackBar(
                          content:
                              Text(
                            e.toString()
                                .replaceFirst(
                              'Exception: ',
                              '',
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFE8F5E9,
                    ),
                    foregroundColor:
                        const Color(
                      0xFF2E7D32,
                    ),
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child:
                      const Text(
                    'Start',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),

              // Truck is currently washing
              if (isWashing)
                ElevatedButton(
                  onPressed:
                      () async {
                    final assignmentId =
                        assignment['id'];

                    try {
                      await WorkerAssignmentService
                          .finishAssignment(
                        assignmentId,
                      );

                      if (!context
                          .mounted) {
                        return;
                      }

                      // Refresh both active and
                      // completed trucks immediately.
                      await Future.wait([
                        _loadAssignments(),
                        _loadCompletedAssignments(),
                      ]);

                      if (!context
                          .mounted) {
                        return;
                      }

                      ScaffoldMessenger
                              .of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Washing completed',
                          ),
                        ),
                      );
                    } catch (e) {
                      if (!context
                          .mounted) {
                        return;
                      }

                      ScaffoldMessenger
                              .of(context)
                          .showSnackBar(
                        SnackBar(
                          content:
                              Text(
                            e.toString()
                                .replaceFirst(
                              'Exception: ',
                              '',
                            ),
                          ),
                        ),
                      );
                    }
                  },
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        const Color(
                      0xFFE8F5E9,
                    ),
                    foregroundColor:
                        const Color(
                      0xFF2E7D32,
                    ),
                    elevation: 0,
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        16,
                      ),
                    ),
                    padding:
                        const EdgeInsets
                            .symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                  ),
                  child:
                      const Text(
                    'Finished',
                    style:
                        TextStyle(
                      fontWeight:
                          FontWeight
                              .bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // CHEMICAL & FLUID LEVELS
  // ============================================================

  Widget _buildLevelsCard(
    BuildContext context,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                const PowerSprayScreen(),
          ),
        ).then((_) {
          // Refresh immediately when returning
          // from the Power Spray screen.
          _loadSupplies();
        });
      },
      child: Container(
        padding:
            const EdgeInsets.all(16),
        decoration:
            BoxDecoration(
          color: cardBg,
          borderRadius:
              BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.03,
              ),
              blurRadius: 8,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),
        child: isLoadingSupplies
            ? const Padding(
                padding:
                    EdgeInsets.all(12),
                child: Center(
                  child:
                      CircularProgressIndicator(),
                ),
              )
            : Column(
                children: [
                  _buildProgressRow(
                    'Foam wash',
                    foamWashLevel / 100,
                    '${foamWashLevel.round()}%',
                    _getSupplyColor(
                      foamWashLevel,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _buildProgressRow(
                    'Disinfectant',
                    disinfectantLevel / 100,
                    '${disinfectantLevel.round()}%',
                    _getSupplyColor(
                      disinfectantLevel,
                    ),
                  ),

                  const SizedBox(
                    height: 14,
                  ),

                  _buildProgressRow(
                    'Water',
                    waterLevel / 100,
                    '${waterLevel.round()}%',
                    _getSupplyColor(
                      waterLevel,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ============================================================
  // SUPPLY COLOR
  // ============================================================

  Color _getSupplyColor(
    double value,
  ) {
    if (value <= 20) {
      return redBar;
    }

    if (value <= 50) {
      return orangeBar;
    }

    return greenBar;
  }

  // ============================================================
  // PROGRESS ROW
  // ============================================================

  Widget _buildProgressRow(
    String title,
    double percentage,
    String label,
    Color color,
  ) {
    return Column(
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment
                  .spaceBetween,
          children: [
            Text(
              title,
              style:
                  const TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.bold,
                color: darkText,
              ),
            ),

            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    darkText.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(6),
          child:
              LinearProgressIndicator(
            value: percentage,
            minHeight: 10,
            backgroundColor:
                const Color(
              0xFFECE6D8,
            ),
            valueColor:
                AlwaysStoppedAnimation<
                    Color>(
              color,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // COMPLETED TRUCKS
  // ============================================================

  Widget _buildCompletedTrucks() {
    if (isLoadingCompleted) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius:
              BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.03,
              ),
              blurRadius: 8,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child:
              CircularProgressIndicator(),
        ),
      );
    }

    if (completedAssignments
        .isEmpty) {
      return Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(
          vertical: 28,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius:
              BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color:
                  Colors.black.withValues(
                alpha: 0.03,
              ),
              blurRadius: 8,
              offset:
                  const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(
              Icons
                  .local_shipping_outlined,
              size: 32,
              color:
                  darkText.withValues(
                alpha: 0.35,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'No finished trucks',
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
                color:
                    darkText.withValues(
                  alpha: 0.65,
                ),
              ),
            ),

            const SizedBox(height: 3),

            Text(
              'Finished trucks will appear here.',
              style: TextStyle(
                fontSize: 10,
                color:
                    darkText.withValues(
                  alpha: 0.45,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Build the finished truck cards.
    final truckCards = completedAssignments
        .map(
          (assignment) {
            final appointment =
                Map<String, dynamic>.from(
              assignment[
                      'appointment'] ??
                  {},
            );

            final driver =
                Map<String, dynamic>.from(
              appointment[
                      'driver'] ??
                  {},
            );

            final plate =
                appointment[
                        'truck_plate'] ??
                    'Unknown truck';

            final driverName =
                driver['name'] ??
                    'Unknown driver';

            final finishedAt =
                assignment[
                    'finished_at'];

            final bay =
                assignment[
                        'wash_bay_id'] ??
                    'N/A';

            final duration =
                _calculateDuration(
              assignment[
                  'started_at'],
              assignment[
                  'finished_at'],
            );

            return Padding(
              padding:
                  const EdgeInsets.only(
                bottom: 12,
              ),
              child:
                  _buildFinishedCard(
                plate.toString(),
                '$driverName · Bay $bay',
                _formatDateTime(
                  finishedAt,
                ),
                duration,
              ),
            );
          },
        )
        .toList();

    // 4–6 finished trucks become
    // vertically scrollable.
    if (completedAssignments.length >= 4) {
      return SizedBox(
        height: 300,
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),
          child: Column(
            children: truckCards,
          ),
        ),
      );
    }

    // 1–3 finished trucks display normally.
    return Column(
      children: truckCards,
    );
  }

  // ============================================================
  // DATE / TIME
  // ============================================================

  String _formatDateTime(
    dynamic value,
  ) {
    if (value == null ||
        value.toString().isEmpty) {
      return 'Finished time unavailable';
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

      final month =
          dateTime.month
              .toString()
              .padLeft(2, '0');

      final day =
          dateTime.day
              .toString()
              .padLeft(2, '0');

      return '$month/$day/${dateTime.year} · '
          '$hour:$minute $period';
    } catch (e) {
      return 'Finished time unavailable';
    }
  }

  String _calculateDuration(
    dynamic startedAt,
    dynamic finishedAt,
  ) {
    if (startedAt == null ||
        finishedAt == null) {
      return 'Duration unavailable';
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
    String plate,
    String info,
    String time,
    String duration,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius:
            BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(16),
        child: Container(
          decoration:
              const BoxDecoration(
            border: Border(
              left: BorderSide(
                color: greenBar,
                width: 8,
              ),
            ),
          ),
          padding:
              const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment:
                MainAxisAlignment
                    .spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      plate,
                      style:
                          const TextStyle(
                        fontSize: 18,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            darkText,
                      ),
                    ),

                    const SizedBox(
                        height: 4),

                    Text(
                      info,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            darkText
                                .withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 2),

                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            darkText
                                .withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),

                    const SizedBox(
                        height: 2),

                    Text(
                      duration,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            darkText
                                .withValues(
                          alpha: 0.55,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(
                  width: 12),

              Container(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE8F5E9,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(16),
                ),
                child:
                    const Text(
                  'Finished',
                  style:
                      TextStyle(
                    color:
                        Color(
                      0xFF2E7D32,
                    ),
                    fontWeight:
                        FontWeight
                            .bold,
                    fontSize: 13,
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

