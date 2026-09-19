import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'services/notification_service.dart';
import 'services/appointment_service.dart';
import 'services/worker_assignment_service.dart';
import 'services/deployment_service.dart';
import 'services/station_supply_service.dart';
import 'services/driver_service.dart';
import 'services/worker_service.dart';


void main() {
  runApp(const AquinoWashApp());
}

class AquinoWashApp extends StatelessWidget {
  const AquinoWashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Aquino Wash Station — Admin Dashboard',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(),
      home: const DashboardScreen(),
    );
  }
}

/// ===================== COLORS =====================

class AppColors {
  static const bg = Color(0xFF101820);
  static const panel = Color(0xFF1A242C);
  static const panel2 = Color(0xFF212D36);

  static final line = Colors.white.withOpacity(0.07);
  static final lineStrong = Colors.white.withOpacity(0.14);

  static const text = Color(0xFFEAF2F4);
  static const textDim = Color(0xFF93A6AE);
  static const textFaint = Color(0xFF5C707A);

  static const water = Color(0xFF2FB8D9);
  static const soap = Color(0xFF8C9CF5);
  static const disinfect = Color(0xFFC583F0);

  static const ok = Color(0xFF38D399);
  static const warn = Color(0xFFF5B94D);
  static const crit = Color(0xFFF0605C);
}

/// ===================== TEXT STYLES =====================

TextStyle _display({
  double size = 16,
  FontWeight weight = FontWeight.w600,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'sans-serif',
    fontWeight: weight,
    fontSize: size,
    letterSpacing: 0.2,
    color: color ?? AppColors.text,
  );
}

TextStyle _body({
  double size = 13,
  FontWeight weight = FontWeight.w400,
  Color? color,
}) {
  return TextStyle(
    fontWeight: weight,
    fontSize: size,
    color: color ?? AppColors.text,
  );
}

TextStyle _mono({
  double size = 13,
  FontWeight weight = FontWeight.w500,
  Color? color,
}) {
  return TextStyle(
    fontFamily: 'monospace',
    fontWeight: weight,
    fontSize: size,
    color: color ?? AppColors.text,
  );
}

TextStyle _eyebrow() {
  return const TextStyle(
    fontSize: 10,
    letterSpacing: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textFaint,
  );
}

/// ===================== DASHBOARD SCREEN =====================

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() =>
      _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final Timer _timer;
  late final Timer _notificationTimer;

  DateTime _now = DateTime.now();

  List<dynamic> _notifications = [];

  bool _notificationsLoaded = false;

  @override
  void initState() {
    super.initState();

    // Updates the dashboard clock every second.
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (mounted) {
          setState(() {
            _now = DateTime.now();
          });
        }
      },
    );

    // Load notifications when dashboard opens.
    _loadNotifications();

    // Check for new notifications every 5 seconds.
    // Notifications are only added to the notification list.
    // No popup/banner is shown.
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _loadNotifications();
      },
    );
  }

  Future<void> _loadNotifications() async {
    try {
      final notifications =
          await NotificationService.getAdminNotifications();

      if (!mounted) return;

      if (!_notificationsLoaded) {
        setState(() {
          _notifications = notifications;
          _notificationsLoaded = true;
        });

        return;
      }

      // Update the notification list only.
      //
      // There is intentionally NO popup notification here.
      setState(() {
        _notifications = notifications;
      });
    } catch (e) {
      // Keep dashboard working if API is temporarily unavailable.
    }
  }

  void _showNotificationHistory() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.panel,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 500,
              maxHeight: 600,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.notifications_active,
                        color: AppColors.water,
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          'Notifications',
                          style: _display(
                            size: 18,
                            weight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: const Icon(
                          Icons.close,
                          color: AppColors.textDim,
                        ),
                      ),
                    ],
                  ),

                  Divider(
                    color: AppColors.lineStrong,
                  ),

                  const SizedBox(height: 5),

                  if (_notifications.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        children: [
                          Icon(
                            Icons.notifications_none,
                            size: 40,
                            color: AppColors.textFaint,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'No notifications yet',
                            style: _body(
                              size: 13,
                              color: AppColors.textDim,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final notification =
                              _notifications[index];

                          return _NotificationHistoryItem(
                            notification: notification,
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    _notificationTimer.cancel();
    super.dispose();
  }

  String get _timeStr {
    final h24 = _now.hour;
    final h12 =
        h24 % 12 == 0 ? 12 : h24 % 12;

    final m =
        _now.minute.toString().padLeft(2, '0');

    final s =
        _now.second.toString().padLeft(2, '0');

    final ampm =
        h24 >= 12 ? 'PM' : 'AM';

    return '${h12.toString().padLeft(2, '0')}:$m:$s $ampm';
  }

  static const _weekdays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String get _dateStr {
    final wd =
        _weekdays[_now.weekday - 1];

    final mo =
        _months[_now.month - 1];

    return '$wd, $mo ${_now.day}, ${_now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.8, -0.9),
            radius: 1.1,
            colors: [
              Color(0x142FB8D9),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  timeStr: _timeStr,
                  dateStr: _dateStr,
                  notificationCount:
                      _notifications.length,
                  onNotificationTap:
                      _showNotificationHistory,
                ),

                const SizedBox(height: 16),

                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide =
                        constraints.maxWidth > 900;

                    return isWide
                        ? const _WideLayout()
                        : const _NarrowLayout();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ===================== NOTIFICATION HISTORY ITEM =====================

class _NotificationHistoryItem extends StatelessWidget {
  final Map<String, dynamic> notification;

  const _NotificationHistoryItem({
    required this.notification,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color:
                  AppColors.water.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_shipping_outlined,
              color: AppColors.water,
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
                  notification['title'] ??
                      'Notification',
                  style: _body(
                    size: 12.5,
                    weight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  notification['message'] ?? '',
                  style: _body(
                    size: 10.5,
                    color: AppColors.textDim,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  notification['created_at'] ?? '',
                  style: _mono(
                    size: 8.5,
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================== TOP BAR =====================

class _TopBar extends StatelessWidget {
  final String timeStr;
  final String dateStr;
  final int notificationCount;
  final VoidCallback onNotificationTap;

  const _TopBar({
    required this.timeStr,
    required this.dateStr,
    required this.notificationCount,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.line,
          ),
        ),
      ),
      child: Wrap(
        alignment:
            WrapAlignment.spaceBetween,
        crossAxisAlignment:
            WrapCrossAlignment.center,
        runSpacing: 10,
        children: [
          Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius:
                      BorderRadius.circular(9),
                  gradient:
                      const LinearGradient(
                    begin:
                        Alignment.topLeft,
                    end:
                        Alignment.bottomRight,
                    colors: [
                      AppColors.water,
                      Color(0xFF1C6E82),
                    ],
                  ),
                  border: Border.all(
                    color:
                        AppColors.lineStrong,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.water
                              .withOpacity(0.30),
                      blurRadius: 14,
                      offset:
                          const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.water_drop,
                  color:
                      Color(0xFF0B1116),
                  size: 20,
                ),
              ),

              const SizedBox(width: 11),

              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aquino Wash Station',
                    style: _display(
                      size: 18,
                      weight:
                          FontWeight.w700,
                    ),
                  ),

                  const SizedBox(height: 1),

                  Text(
                    'OPERATIONS DASHBOARD',
                    style:
                        const TextStyle(
                      fontSize: 10,
                      color:
                          AppColors.textDim,
                      letterSpacing: 1.4,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Row(
            mainAxisSize:
                MainAxisSize.min,
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: _mono(
                      size: 12,
                      color:
                          AppColors.textDim,
                    ),
                  ),

                  const SizedBox(height: 1),

                  Text(
                    dateStr,
                    style: _mono(
                      size: 10,
                      color:
                          AppColors.textFaint,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              const _StatusPill(
                label: 'System Online',
                color: AppColors.ok,
              ),

              const SizedBox(width: 12),

              GestureDetector(
                onTap: onNotificationTap,
                child: Stack(
                  clipBehavior:
                      Clip.none,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration:
                          BoxDecoration(
                        color:
                            AppColors.panel,
                        shape:
                            BoxShape.circle,
                        border:
                            Border.all(
                          color:
                              AppColors
                                  .lineStrong,
                        ),
                      ),
                      child: const Icon(
                        Icons
                            .notifications_none,
                        size: 17,
                        color:
                            AppColors.textDim,
                      ),
                    ),

                    if (notificationCount >
                        0)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          constraints:
                              const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                AppColors.crit,
                            shape:
                                BoxShape.circle,
                            border:
                                Border.all(
                              color:
                                  AppColors.bg,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              notificationCount >
                                      99
                                  ? '99+'
                                  : '$notificationCount',
                              style:
                                  const TextStyle(
                                fontSize: 7,
                                fontWeight:
                                    FontWeight
                                        .w800,
                                color:
                                    Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ===================== STATUS PILL =====================

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.fromLTRB(
        9,
        5,
        11,
        5,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius:
            BorderRadius.circular(100),
        border: Border.all(
          color: AppColors.lineStrong,
        ),
      ),
      child: Row(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(
              color: color,
              shape:
                  BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:
                      color.withOpacity(
                          0.18),
                  blurRadius: 0,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),

          const SizedBox(width: 6),

          Text(
            label,
            style: _body(
              size: 11.5,
              weight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================== SMALL STATUS =====================

class _SmallStatus extends StatelessWidget {
  final String text;
  final Color color;

  const _SmallStatus({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color:
            color.withOpacity(0.12),
        borderRadius:
            BorderRadius.circular(100),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 9,
          fontWeight:
              FontWeight.w700,
          letterSpacing: 0.4,
          color: color,
        ),
      ),
    );
  }
}

/// ===================== PANEL =====================

class _Panel extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget child;
  final Widget? trailing;

  const _Panel({
    required this.eyebrow,
    required this.title,
    required this.child,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius:
            BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.end,
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: _eyebrow(),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    title,
                    style: _display(
                      size: 15,
                    ),
                  ),
                ],
              ),

              if (trailing != null)
                trailing!,
            ],
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }
}

/// ===================== LAYOUTS =====================
class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;
    const bayColWidth = 270.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                width: bayColWidth,
                child: BayStatusPanel(),
              ),

              const SizedBox(
                width: gap,
              ),

              const Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TrucksWaitingPanel(),
                    SizedBox(height: gap),
                    CurrentlyWashingPanel(),
                  ],
                ),
              ),

              const SizedBox(
                width: gap,
              ),

              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SupplyLevelsPanel(),

                    SizedBox(height: gap),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: AvailableWashersPanel(),
                        ),

                        SizedBox(width: gap),

                        const Expanded(
                          child: DriversPanel(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: gap),

        const AlertsPanel(),

        const SizedBox(height: gap),

        const TrucksTablePanel(),
      ],
    );
  }
}
/// ===================== NARROW LAYOUT =====================

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout();

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;

    return const Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        BayStatusPanel(),
        SizedBox(height: gap),
        TrucksWaitingPanel(),
        SizedBox(height: gap),
        CurrentlyWashingPanel(),
        SizedBox(height: gap),
        SupplyLevelsPanel(),
        SizedBox(height: gap),
        AvailableWashersPanel(),
        SizedBox(height: gap),
        DriversPanel(),
        SizedBox(height: gap),
        AlertsPanel(),
        SizedBox(height: gap),
        TrucksTablePanel(),
      ],
    );
  }
}

/// ===================== BAY STATUS =====================

class BayStatusPanel extends StatefulWidget {
  const BayStatusPanel({super.key});

  @override
  State<BayStatusPanel> createState() =>
      _BayStatusPanelState();
}

class _BayStatusPanelState
    extends State<BayStatusPanel> {
  List<dynamic> assignments = [];

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    loadAssignments();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        loadAssignments();
      },
    );
  }

  Future<void> loadAssignments() async {
    try {
      final data =
          await WorkerAssignmentService
              .getActiveAssignments();

      if (!mounted) return;

      setState(() {
        assignments = data;
      });
    } catch (e) {
      // Keep the current panel state if the request fails.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bay1InUse = assignments.any(
      (assignment) =>
          assignment['wash_bay_id'] == 1 &&
          assignment['status'] == 'washing',
    );

    final bay2InUse = assignments.any(
      (assignment) =>
          assignment['wash_bay_id'] == 2 &&
          assignment['status'] == 'washing',
    );

    final freeCount =
        (bay1InUse ? 0 : 1) +
        (bay2InUse ? 0 : 1);

    const totalCount = 2;

    return _Panel(
      eyebrow: 'Bay Status',
      title: 'Available Wash',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,
        children: [
          Center(
            child: SizedBox(
              width: 160,
              height: 160,
              child: CustomPaint(
                painter: _DialPainter(
                  fraction:
                      freeCount / totalCount,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize:
                        MainAxisSize.min,
                    children: [
                      RichText(
                        text: TextSpan(
                          style: _display(
                            size: 34,
                            weight:
                                FontWeight.w700,
                          ),
                          children: [
                            TextSpan(
                              text:
                                  '$freeCount',
                            ),
                            TextSpan(
                              text:
                                  '/$totalCount',
                              style:
                                  const TextStyle(
                                color:
                                    AppColors
                                        .water,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 4,
                      ),

                      Text(
                        'BAYS FREE',
                        style:
                            const TextStyle(
                          fontSize: 10,
                          letterSpacing: 1.1,
                          color:
                              AppColors
                                  .textDim,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          _BayRow(
            name: 'Wash Bay 1',
            subtitle: bay1InUse
                ? 'Currently washing'
                : 'Ready for next truck',
            available: !bay1InUse,
          ),

          const SizedBox(height: 8),

          _BayRow(
            name: 'Wash Bay 2',
            subtitle: bay2InUse
                ? 'Currently washing'
                : 'Ready for next truck',
            available: !bay2InUse,
          ),
        ],
      ),
    );
  }
}

/// ===================== BAY DIAL =====================

class _DialPainter extends CustomPainter {
  final double fraction;

  _DialPainter({
    required this.fraction,
  });

  @override
  void paint(
    Canvas canvas,
    Size size,
  ) {
    final center = Offset(
      size.width / 2,
      size.height / 2,
    );

    final radius =
        (size.width - 10) / 2;

    const strokeWidth = 9.0;

    final trackPaint = Paint()
      ..color = AppColors.panel2
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(
      center,
      radius,
      trackPaint,
    );

    final rect = Rect.fromCircle(
      center: center,
      radius: radius,
    );

    final gradient =
        const SweepGradient(
      colors: [
        AppColors.water,
        AppColors.ok,
      ],
      startAngle: 0,
      endAngle: 3.14159 * 2,
    );

    final fillPaint = Paint()
      ..shader =
          gradient.createShader(rect)
      ..style =
          PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap =
          StrokeCap.round;

    const startAngle =
        -3.14159 / 2;

    final sweepAngle =
        3.14159 * 2 * fraction;

    canvas.drawArc(
      rect,
      startAngle,
      sweepAngle,
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(
    covariant _DialPainter oldDelegate,
  ) {
    return oldDelegate.fraction !=
        fraction;
  }
}

/// ===================== BAY ROW =====================

class _BayRow extends StatelessWidget {
  final String name;
  final String subtitle;
  final bool available;

  const _BayRow({
    required this.name,
    required this.subtitle,
    required this.available,
  });

  @override
  Widget build(BuildContext context) {
    final color = available
        ? AppColors.ok
        : AppColors.crit;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  color.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(7),
            ),
            child: Icon(
              available
                  ? Icons.check
                  : Icons.close,
              size: 15,
              color: color,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: _body(
                    size: 12.5,
                    weight:
                        FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 1),

                Text(
                  subtitle,
                  style: _body(
                    size: 10,
                    color:
                        AppColors
                            .textFaint,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration: BoxDecoration(
              color:
                  color.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(
                      100),
            ),
            child: Text(
              available
                  ? 'AVAILABLE'
                  : 'IN USE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight:
                    FontWeight.w700,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================== TRUCKS WAITING =====================

class TrucksWaitingPanel
    extends StatefulWidget {
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
        AppointmentService
            .getAdminAppointments(),
        WorkerAssignmentService
            .getActiveAssignments(),
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

  Map<String, dynamic>?
      _getAssignmentForAppointment(
    dynamic appointment,
  ) {
    final appointmentId =
        int.tryParse(
          appointment['id'].toString(),
        ) ??
        0;

    for (final assignment
        in assignments) {
      final assignedAppointmentId =
          int.tryParse(
            assignment['appointment_id']
                .toString(),
          ) ??
          0;

      if (assignedAppointmentId ==
          appointmentId) {
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
    return _Panel(
      eyebrow: 'Incoming',
      title: 'Trucks Waiting',
      trailing: _SmallStatus(
        text: appointments.isEmpty
            ? 'NO TRUCKS'
            : '${appointments.length} WAITING',
        color: appointments.isEmpty
            ? AppColors.textFaint
            : AppColors.water,
      ),
      child: appointments.isEmpty
          ? Container(
              padding:
                  const EdgeInsets
                      .symmetric(
                vertical: 28,
              ),
              alignment:
                  Alignment.center,
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
                    height: 8,
                  ),

                  Text(
                    'No trucks waiting',
                    style: _body(
                      size: 12.5,
                      weight:
                          FontWeight.w600,
                      color:
                          AppColors
                              .textDim,
                    ),
                  ),

                  const SizedBox(
                    height: 3,
                  ),

                  Text(
                    'Confirmed trucks will appear here',
                    style: _body(
                      size: 10,
                      color:
                          AppColors
                              .textFaint,
                    ),
                  ),
                ],
              ),
            )
          : ConstrainedBox(
              constraints:
                  const BoxConstraints(
                maxHeight: 430,
              ),
              child: Scrollbar(
                thumbVisibility: true,
                child:
                    SingleChildScrollView(
                  physics:
                      const BouncingScrollPhysics(),
                  child: Column(
                    children:
                        appointments
                            .map(
                      (appointment) {
                        final assignment =
                            _getAssignmentForAppointment(
                          appointment,
                        );

                        return Padding(
                          padding:
                              const EdgeInsets
                                  .only(
                            bottom: 8,
                          ),
                          child:
                              _AppointmentTruckRow(
                            appointment:
                                appointment,
                            assignment:
                                assignment,
                          ),
                        );
                      },
                    ).toList(),
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

  const _AppointmentTruckRow({
    required this.appointment,
    this.assignment,
  });

  @override
  State<_AppointmentTruckRow> createState() =>
      _AppointmentTruckRowState();
}

class _AppointmentTruckRowState
    extends State<_AppointmentTruckRow> {
  List<Map<String, dynamic>> workers = [];

  bool isLoadingWorkers = false;

  @override
  void initState() {
    super.initState();

    _loadWorkers();
  }

  Future<void> _loadWorkers() async {
    try {
      setState(() {
        isLoadingWorkers = true;
      });

      final data =
          await WorkerService.getWorkers();

      if (!mounted) return;

      setState(() {
        workers = data;
        isLoadingWorkers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoadingWorkers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final appointment = widget.appointment;
    final assignment = widget.assignment;

    final driver =
        appointment['driver'];

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

    final worker =
        assignment?['worker'];

    final workerName =
        worker != null
            ? '${worker['first_name'] ?? ''} '
                    '${worker['last_name'] ?? ''}'
                .trim()
            : 'Unknown worker';

    final washBay =
        assignment?['wash_bay_id'] ?? 'N/A';

    final assignmentStatus =
        assignment?['status'] ?? 'assigned';

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: isDeployed
              ? AppColors.ok.withOpacity(0.35)
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
                      ? AppColors.ok.withOpacity(0.12)
                      : AppColors.water.withOpacity(0.12),
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
                      style: _mono(
                        size: 12,
                        weight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      driverName,
                      style: _body(
                        size: 10.5,
                        color: AppColors.textDim,
                      ),
                    ),
                  ],
                ),
              ),

              _SmallStatus(
                text: isDeployed
                    ? assignmentStatus == 'washing'
                        ? 'WASHING'
                        : 'DEPLOYED'
                    : 'WAITING',
                color: isDeployed
                    ? assignmentStatus == 'washing'
                        ? AppColors.ok
                        : AppColors.warn
                    : AppColors.water,
              ),
            ],
          ),

          const SizedBox(height: 10),

          Text(
            'Coming from: $comingFrom',
            style: _body(
              size: 10.5,
              color: AppColors.textDim,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Load: $livestock',
            style: _body(
              size: 10.5,
              color: AppColors.textDim,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            'Preferred: $preferred',
            style: _body(
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
                color:
                    AppColors.ok.withOpacity(0.06),
                borderRadius:
                    BorderRadius.circular(8),
                border: Border.all(
                  color:
                      AppColors.ok.withOpacity(0.20),
                ),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 15,
                        color: AppColors.ok,
                      ),

                      const SizedBox(width: 6),

                      Text(
                        'TRUCK DEPLOYED',
                        style: _body(
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
                    style: _body(
                      size: 10.5,
                      color: AppColors.textDim,
                    ),
                  ),

                  const SizedBox(height: 2),

                  Text(
                    'Wash Bay: $washBay',
                    style: _body(
                      size: 10.5,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed:
                    appointmentId == 0
                        ? null
                        : () {
                            int? selectedWorkerId;
                            int? selectedBayId;

                            showDialog(
                              context: context,
                              builder:
                                  (dialogContext) {
                                return StatefulBuilder(
                                  builder:
                                      (
                                    context,
                                    setDialogState,
                                  ) {
                                    return AlertDialog(
                                      title:
                                          const Text(
                                        'Deploy Truck',
                                      ),
                                      content:
                                          Column(
                                        mainAxisSize:
                                            MainAxisSize.min,
                                        children: [
                                          DropdownButtonFormField<
                                              int>(
                                            decoration:
                                                const InputDecoration(
                                              labelText:
                                                  'Wash Worker',
                                            ),

                                            items:
                                                workers
                                                    .map(
                                              (
                                                worker,
                                              ) {
                                                final id =
                                                    worker['id'];

                                                final firstName =
                                                    worker['first_name']?.toString() ??
                                                        '';

                                                final lastName =
                                                    worker['last_name']?.toString() ??
                                                        '';

                                                final name =
                                                    '$firstName $lastName'
                                                        .trim();

                                                return DropdownMenuItem<
                                                    int>(
                                                  value:
                                                      id,
                                                  child:
                                                      Text(
                                                    name.isEmpty
                                                        ? 'Unknown worker'
                                                        : name,
                                                  ),
                                                );
                                              },
                                            ).toList(),

                                            onChanged:
                                                workers.isEmpty
                                                    ? null
                                                    : (
                                                        value,
                                                      ) {
                                                        setDialogState(
                                                          () {
                                                            selectedWorkerId =
                                                                value;
                                                          },
                                                        );
                                                      },
                                          ),

                                          const SizedBox(
                                            height: 15,
                                          ),

                                          DropdownButtonFormField<
                                              int>(
                                            decoration:
                                                const InputDecoration(
                                              labelText:
                                                  'Wash Bay',
                                            ),
                                            items:
                                                const [
                                              DropdownMenuItem(
                                                value:
                                                    1,
                                                child:
                                                    Text(
                                                  'Wash Bay 1',
                                                ),
                                              ),
                                              DropdownMenuItem(
                                                value:
                                                    2,
                                                child:
                                                    Text(
                                                  'Wash Bay 2',
                                                ),
                                              ),
                                            ],
                                            onChanged:
                                                (
                                              value,
                                            ) {
                                              setDialogState(
                                                () {
                                                  selectedBayId =
                                                      value;
                                                },
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed:
                                              () {
                                            Navigator
                                                .pop(
                                              dialogContext,
                                            );
                                          },
                                          child:
                                              const Text(
                                            'Cancel',
                                          ),
                                        ),

                                        ElevatedButton(
                                          onPressed:
                                              selectedWorkerId ==
                                                          null ||
                                                      selectedBayId ==
                                                          null
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

                                                        if (!context
                                                            .mounted) {
                                                          return;
                                                        }

                                                        Navigator
                                                            .pop(
                                                          dialogContext,
                                                        );

                                                        ScaffoldMessenger
                                                            .of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content:
                                                                Text(
                                                              'Truck deployed successfully.',
                                                            ),
                                                          ),
                                                        );
                                                      } catch (e) {
                                                        if (!context
                                                            .mounted) {
                                                          return;
                                                        }

                                                        ScaffoldMessenger
                                                            .of(
                                                          context,
                                                        ).showSnackBar(
                                                          SnackBar(
                                                            content:
                                                                Text(
                                                              e.toString(),
                                                            ),
                                                          ),
                                                        );
                                                      }
                                                    },
                                          child:
                                              const Text(
                                            'Deploy',
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                );
                              },
                            );
                          },
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
                child: const Text(
                  'Deploy',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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
    return _Panel(
      eyebrow: 'Active',
      title: 'Currently Washing',
      trailing: _SmallStatus(
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
                    style: _body(
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
                                .withOpacity(
                                    0.12),
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
                                    _mono(
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
                                    _body(
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
                                    _body(
                                  size: 9.5,
                                  color:
                                      AppColors
                                          .textFaint,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const _SmallStatus(
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

// ===================== AVAILABLE WASHERS =====================

class AvailableWashersPanel extends StatefulWidget {
  const AvailableWashersPanel({
    super.key,
  });

  @override
  State<AvailableWashersPanel> createState() =>
      _AvailableWashersPanelState();
}

class _AvailableWashersPanelState
    extends State<AvailableWashersPanel> {
  List<dynamic> assignments = [];
  List<Map<String, dynamic>> workers = [];

  Timer? _timer;

  // Worker form controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _workerIdController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isCreatingWorker = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    loadData();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        loadData();
      },
    );
  }

  Future<void> loadData() async {
    try {
      final activeAssignments =
          await WorkerAssignmentService.getActiveAssignments();

      final workerList =
          await WorkerService.getWorkers();

      if (!mounted) return;

      setState(() {
        assignments = activeAssignments;
        workers = workerList;
      });
    } catch (e) {
      // Keep dashboard working if API is unavailable.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    _firstNameController.dispose();
    _lastNameController.dispose();
    _workerIdController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ===================== CREATE WORKER POPUP =====================

  Future<void> _openCreateWorkerDialog() async {
    // Clear old values before opening.
    _firstNameController.clear();
    _lastNameController.clear();
    _workerIdController.clear();
    _mobileController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    _isCreatingWorker = false;
    _obscurePassword = true;
    _obscureConfirmPassword = true;

    await showDialog(
      context: context,
      barrierDismissible: !_isCreatingWorker,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.panel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                24,
                22,
                24,
                8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                24,
                8,
                24,
                12,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                24,
                4,
                24,
                18,
              ),
              title: const Text(
                'Create Worker Account',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 460,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create an account for a wash station worker.',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // FIRST NAME
                      const Text(
                        'First Name',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _firstNameController,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter first name',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // LAST NAME
                      const Text(
                        'Last Name',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _lastNameController,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter last name',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // WORKER ID
                      const Text(
                        'Worker ID',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _workerIdController,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Example: W-001',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.badge_outlined,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // MOBILE
                      const Text(
                        'Mobile Number',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _mobileController,
                        keyboardType:
                            TextInputType.phone,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter mobile number',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.phone_outlined,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // PASSWORD
                      const Text(
                        'Password',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter password',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                              color: AppColors.textDim,
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // CONFIRM PASSWORD
                      const Text(
                        'Confirm Password',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller:
                            _confirmPasswordController,
                        obscureText:
                            _obscureConfirmPassword,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Confirm password',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                              color: AppColors.textDim,
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // CANCEL
                TextButton(
                  onPressed: _isCreatingWorker
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // CREATE
                ElevatedButton(
                  onPressed: _isCreatingWorker
                      ? null
                      : () async {
                          final firstName =
                              _firstNameController.text
                                  .trim();
                          final lastName =
                              _lastNameController.text
                                  .trim();
                          final workerId =
                              _workerIdController.text
                                  .trim();
                          final mobile =
                              _mobileController.text
                                  .trim();
                          final password =
                              _passwordController.text;
                          final confirmPassword =
                              _confirmPasswordController
                                  .text;

                          // Basic validation
                          if (firstName.isEmpty ||
                              lastName.isEmpty ||
                              workerId.isEmpty ||
                              mobile.isEmpty ||
                              password.isEmpty ||
                              confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill in all fields.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (password.length < 6) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password must be at least 6 characters.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (password != confirmPassword) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Passwords do not match.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            _isCreatingWorker = true;
                          });

                          try {
                            final response =
                                await http.post(
                              Uri.parse(
                                'http://127.0.0.1:8000/api/admin/workers',
                              ),
                              headers: {
                                'Accept':
                                    'application/json',
                              },
                              body: {
                                'first_name': firstName,
                                'last_name': lastName,
                                'worker_id': workerId,
                                'mobile': mobile,
                                'password': password,
                                'password_confirmation':
                                    confirmPassword,
                              },
                            );

                            if (!mounted) return;

                            if (response.statusCode == 201) {
                              Navigator.pop(
                                dialogContext,
                              );

                              await loadData();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Worker account created successfully.',
                                  ),
                                ),
                              );
                            } else {
                              setDialogState(() {
                                _isCreatingWorker = false;
                              });

                              String message =
                                  'Failed to create worker account.';

                              if (response.body.isNotEmpty) {
                                message = response.body;
                              }

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              _isCreatingWorker = false;
                            });

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not connect to the server.\n$e',
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.water,
                    foregroundColor: AppColors.bg,
                    disabledBackgroundColor:
                        AppColors.water.withOpacity(0.4),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                  ),
                  child: _isCreatingWorker
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.bg,
                          ),
                        )
                      : const Text(
                          'Create Worker',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final busyWorkerIds = assignments
        .where(
          (assignment) =>
              assignment['status'] == 'assigned' ||
              assignment['status'] == 'washing',
        )
        .map(
          (assignment) => assignment['worker_id'],
        )
        .toSet();

    return _Panel(
      eyebrow: 'Staff',
      title: 'Available Washers',

      // ADD WORKER BUTTON
      trailing: OutlinedButton.icon(
        onPressed: _openCreateWorkerDialog,
        icon: const Icon(
          Icons.person_add_outlined,
          size: 15,
        ),
        label: const Text(
          'Add Worker',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.water,
          side: BorderSide(
            color: AppColors.water.withOpacity(0.35),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      // ===================== SCROLLABLE WORKER LIST =====================
      child: workers.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(
                vertical: 8,
              ),
              child: Text(
                'No workers available.',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 12,
                ),
              ),
            )
          : SizedBox(
              height: 130,
              child: ListView.builder(
                itemCount: workers.length,
                itemBuilder: (context, index) {
                  final worker = workers[index];

                  final workerId = worker['id'];

                  final firstName =
                      worker['first_name']?.toString() ?? '';

                  final lastName =
                      worker['last_name']?.toString() ?? '';

                  final name =
                      '$firstName $lastName'.trim();

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 8,
                    ),
                    child: _WasherRow(
                      name: name.isEmpty
                          ? 'Unknown worker'
                          : name,
                      onWork:
                          busyWorkerIds.contains(workerId),
                    ),
                  );
                },
              ),
            ),
    );
  }
}



/// ===================== WASHER ROW =====================

class _WasherRow
    extends StatelessWidget {
  final String name;
  final bool onWork;

  const _WasherRow({
    required this.name,
    required this.onWork,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        onWork
            ? AppColors.crit
            : AppColors.ok;

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  color.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(7),
            ),
            child: Icon(
              onWork
                  ? Icons.close
                  : Icons.check,
              size: 15,
              color: color,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              name,
              style: _body(
                size: 12.5,
                weight:
                    FontWeight.w600,
              ),
            ),
          ),

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 8,
              vertical: 3,
            ),
            decoration:
                BoxDecoration(
              color:
                  color.withOpacity(0.12),
              borderRadius:
                  BorderRadius.circular(
                      100),
            ),
            child: Text(
              onWork
                  ? 'ON WORK'
                  : 'AVAILABLE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight:
                    FontWeight.w700,
                letterSpacing: 0.3,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


/// ===================== DRIVERS =====================
class DriversPanel extends StatefulWidget {
  const DriversPanel({super.key});

  @override
  State<DriversPanel> createState() =>
      _DriversPanelState();
}

class _DriversPanelState
    extends State<DriversPanel> {
  List<dynamic> drivers = [];

  Timer? _timer;

  // Driver form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController();

  bool _isCreatingDriver = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();

    _loadDrivers();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _loadDrivers();
      },
    );
  }

  Future<void> _loadDrivers() async {
    try {
      final data =
          await DriverService.getDrivers();

      if (!mounted) return;

      setState(() {
        drivers = data;
      });
    } catch (e) {
      // Keep the current driver list if API is unavailable.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();

    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  // ===================== CREATE DRIVER POPUP =====================

  Future<void> _openCreateDriverDialog() async {
    // Clear old values before opening.
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();

    _isCreatingDriver = false;
    _obscurePassword = true;
    _obscureConfirmPassword = true;

    await showDialog(
      context: context,
      barrierDismissible: !_isCreatingDriver,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.panel,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              titlePadding: const EdgeInsets.fromLTRB(
                24,
                22,
                24,
                8,
              ),
              contentPadding: const EdgeInsets.fromLTRB(
                24,
                8,
                24,
                12,
              ),
              actionsPadding: const EdgeInsets.fromLTRB(
                24,
                4,
                24,
                18,
              ),
              title: const Text(
                'Create Driver Account',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 460,
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create an account for a driver.',
                        style: TextStyle(
                          color: AppColors.textDim,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // NAME
                      const Text(
                        'Name',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _nameController,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter driver name',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.person_outline,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // EMAIL
                      const Text(
                        'Email Address',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _emailController,
                        keyboardType:
                            TextInputType.emailAddress,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter email address',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.email_outlined,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // PASSWORD
                      const Text(
                        'Password',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter password',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            },
                            icon: Icon(
                              _obscurePassword
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                              color: AppColors.textDim,
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      // CONFIRM PASSWORD
                      const Text(
                        'Confirm Password',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 7),
                      TextField(
                        controller:
                            _confirmPasswordController,
                        obscureText:
                            _obscureConfirmPassword,
                        style: const TextStyle(
                          color: AppColors.text,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Confirm password',
                          hintStyle: const TextStyle(
                            color: AppColors.textFaint,
                          ),
                          prefixIcon: const Icon(
                            Icons.lock_outline,
                            color: AppColors.textDim,
                            size: 18,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              setDialogState(() {
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword;
                              });
                            },
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons
                                      .visibility_off_outlined
                                  : Icons
                                      .visibility_outlined,
                              color: AppColors.textDim,
                              size: 18,
                            ),
                          ),
                          filled: true,
                          fillColor: AppColors.panel2,
                          contentPadding:
                              const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 13,
                          ),
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          enabledBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide: BorderSide(
                              color: AppColors.lineStrong,
                            ),
                          ),
                          focusedBorder:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(9),
                            borderSide:
                                const BorderSide(
                              color: AppColors.water,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // CANCEL
                TextButton(
                  onPressed: _isCreatingDriver
                      ? null
                      : () {
                          Navigator.pop(dialogContext);
                        },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppColors.textDim,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // CREATE
                ElevatedButton(
                  onPressed: _isCreatingDriver
                      ? null
                      : () async {
                          final name =
                              _nameController.text.trim();
                          final email =
                              _emailController.text.trim();
                          final password =
                              _passwordController.text;
                          final confirmPassword =
                              _confirmPasswordController
                                  .text;

                          // Basic validation
                          if (name.isEmpty ||
                              email.isEmpty ||
                              password.isEmpty ||
                              confirmPassword.isEmpty) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please fill in all fields.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (!email.contains('@')) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter a valid email address.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (password.length < 8) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password must be at least 8 characters.',
                                ),
                              ),
                            );
                            return;
                          }

                          if (password != confirmPassword) {
                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Passwords do not match.',
                                ),
                              ),
                            );
                            return;
                          }

                          setDialogState(() {
                            _isCreatingDriver = true;
                          });

                          try {
                            final response =
                                await http.post(
                              Uri.parse(
                                'http://127.0.0.1:8000/api/admin/drivers',
                              ),
                              headers: {
                                'Accept':
                                    'application/json',
                              },
                              body: {
                                'name': name,
                                'email': email,
                                'password': password,
                                'password_confirmation':
                                    confirmPassword,
                              },
                            );

                            if (!mounted) return;

                            if (response.statusCode == 201) {
                              Navigator.pop(
                                dialogContext,
                              );

                              await _loadDrivers();

                              if (!mounted) return;

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Driver account created successfully.',
                                  ),
                                ),
                              );
                            } else {
                              setDialogState(() {
                                _isCreatingDriver = false;
                              });

                              String message =
                                  'Failed to create driver account.';

                              if (response.body.isNotEmpty) {
                                message = response.body;
                              }

                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                SnackBar(
                                  content: Text(message),
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;

                            setDialogState(() {
                              _isCreatingDriver = false;
                            });

                            ScaffoldMessenger.of(context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Could not connect to the server.\n$e',
                                ),
                              ),
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.water,
                    foregroundColor: AppColors.bg,
                    disabledBackgroundColor:
                        AppColors.water.withOpacity(0.4),
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(8),
                    ),
                  ),
                  child: _isCreatingDriver
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.bg,
                          ),
                        )
                      : const Text(
                          'Create Driver',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      eyebrow: 'Staff',
      title: 'Drivers',

      // ADD DRIVER BUTTON
      trailing: OutlinedButton.icon(
        onPressed: _openCreateDriverDialog,
        icon: const Icon(
          Icons.person_add_outlined,
          size: 15,
        ),
        label: const Text(
          'Add Driver',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.water,
          side: BorderSide(
            color: AppColors.water.withOpacity(0.35),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 8,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      child: drivers.isEmpty
          ? Container(
              padding: const EdgeInsets.symmetric(
                vertical: 20,
              ),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 30,
                    color: AppColors.textFaint,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No driver accounts',
                    style: _body(
                      size: 12,
                      weight: FontWeight.w600,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            )
          : SizedBox(
              height: drivers.length > 2
                  ? 100
                  : null,
              child: Scrollbar(
                thumbVisibility:
                    drivers.length > 2,
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: drivers.length > 2
                      ? const BouncingScrollPhysics()
                      : const NeverScrollableScrollPhysics(),
                  itemCount: drivers.length,
                  itemBuilder:
                      (context, index) {
                    final driver =
                        drivers[index];

                    final name =
                        driver['name']
                                ?.toString() ??
                            'Unknown driver';

                    return Padding(
                      padding:
                          const EdgeInsets.only(
                        bottom: 8,
                      ),
                      child: _DriverRow(
                        name: name,
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }
}

/// ===================== DRIVER ROW =====================

class _DriverRow extends StatelessWidget {
  final String name;

  const _DriverRow({
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  AppColors.water.withOpacity(
                0.12,
              ),
              borderRadius:
                  BorderRadius.circular(7),
            ),
            child: const Icon(
              Icons.person_outline,
              size: 15,
              color: AppColors.water,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              name,
              style: _body(
                size: 12.5,
                weight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================== SUPPLY LEVELS =====================

class SupplyLevelsPanel extends StatefulWidget {
  const SupplyLevelsPanel({super.key});

  @override
  State<SupplyLevelsPanel> createState() =>
      _SupplyLevelsPanelState();
}

class _SupplyLevelsPanelState
    extends State<SupplyLevelsPanel> {
  double foamWashLevel = 0;
  double disinfectantLevel = 0;
  double waterLevel = 0;

  bool isLoading = true;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _loadSupplies();

    // Refresh supply levels every 5 seconds.
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _loadSupplies();
      },
    );
  }

  Future<void> _loadSupplies() async {
    try {
      final data =
          await StationSupplyService.getSupplies();

      if (!mounted) return;

      setState(() {
        foamWashLevel =
            data['Foam Wash'] ?? 0;

        disinfectantLevel =
            data['Disinfectant'] ?? 0;

        waterLevel =
            data['Water'] ?? 0;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  String _getStatus(double level) {
    if (level <= 20) {
      return 'CRITICAL';
    }

    if (level <= 35) {
      return 'LOW';
    }

    return 'NORMAL';
  }

  Color _getStatusColor(double level) {
    if (level <= 20) {
      return AppColors.crit;
    }

    if (level <= 35) {
      return AppColors.warn;
    }

    return AppColors.ok;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _Panel(
      eyebrow: 'Supply Levels',
      title: 'Water · Foam Wash · Disinfectant',
      child: isLoading
          ? const SizedBox(
              height: 170,
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.water,
                ),
              ),
            )
          : Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                _TankUnit(
                  name: 'Water',
                  color: AppColors.water,
                  percent: waterLevel / 100,
                  liters:
                      '${waterLevel.round()}%',
                  tag: _getStatus(waterLevel),
                  tagColor:
                      _getStatusColor(waterLevel),
                ),

                _TankUnit(
                  name: 'Foam Wash',
                  color: AppColors.soap,
                  percent: foamWashLevel / 100,
                  liters:
                      '${foamWashLevel.round()}%',
                  tag: _getStatus(foamWashLevel),
                  tagColor:
                      _getStatusColor(foamWashLevel),
                ),

                _TankUnit(
                  name: 'Disinfectant',
                  color: AppColors.disinfect,
                  percent:
                      disinfectantLevel / 100,
                  liters:
                      '${disinfectantLevel.round()}%',
                  tag:
                      _getStatus(disinfectantLevel),
                  tagColor:
                      _getStatusColor(
                        disinfectantLevel,
                      ),
                ),
              ],
            ),
    );
  }
}

/// ===================== TANK =====================

class _TankUnit
    extends StatelessWidget {
  final String name;
  final Color color;
  final double percent;
  final String liters;
  final String tag;
  final Color tagColor;

  const _TankUnit({
    required this.name,
    required this.color,
    required this.percent,
    required this.liters,
    required this.tag,
    required this.tagColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 48,
            height: 105,
            clipBehavior:
                Clip.antiAlias,
            decoration:
                BoxDecoration(
              color:
                  AppColors.panel2,
              borderRadius:
                  BorderRadius.circular(
                      9),
              border: Border.all(
                color:
                    AppColors
                        .lineStrong,
              ),
            ),
            child: Stack(
              alignment:
                  Alignment.bottomCenter,
              children: [
                FractionallySizedBox(
                  heightFactor:
                      percent,
                  widthFactor: 1,
                  child: Container(
                    decoration:
                        BoxDecoration(
                      color: color,
                      boxShadow: [
                        BoxShadow(
                          color: color
                              .withOpacity(
                                  0.35),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child:
                      Container(
                    height: 5,
                    decoration:
                        BoxDecoration(
                      color:
                          AppColors
                              .panel,
                      border:
                          Border(
                        bottom:
                            BorderSide(
                          color:
                              AppColors
                                  .lineStrong,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
              height: 7),

          Text(
            '${(percent * 100).round()}%',
            style: _mono(
              size: 13,
              weight:
                  FontWeight.w600,
              color: color,
            ),
          ),

          const SizedBox(
              height: 1),

          Text(
            name,
            style: _body(
              size: 11,
              weight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
              height: 1),

          Text(
            liters,
            style: _body(
              size: 9,
              color:
                  AppColors
                      .textFaint,
            ),
          ),

          const SizedBox(
              height: 6),

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 7,
              vertical: 2,
            ),
            decoration:
                BoxDecoration(
              color: tagColor
                  .withOpacity(0.14),
              borderRadius:
                  BorderRadius.circular(
                      100),
            ),
            child: Text(
              tag,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight:
                    FontWeight.w700,
                letterSpacing: 0.4,
                color: tagColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// ===================== ALERTS =====================

class AlertsPanel extends StatefulWidget {
  const AlertsPanel({super.key});

  @override
  State<AlertsPanel> createState() =>
      _AlertsPanelState();
}

class _AlertsPanelState extends State<AlertsPanel> {
  double foamWashLevel = 0;
  double disinfectantLevel = 0;
  double waterLevel = 0;

  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _loadSupplies();

    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) {
        _loadSupplies();
      },
    );
  }

  Future<void> _loadSupplies() async {
    try {
      final data =
          await StationSupplyService.getSupplies();

      if (!mounted) return;

      setState(() {
        foamWashLevel =
            data['Foam Wash'] ?? 0;

        disinfectantLevel =
            data['Disinfectant'] ?? 0;

        waterLevel =
            data['Water'] ?? 0;
      });
    } catch (e) {
      // Keep current values if API fails.
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String supplyName;
    double level;

    // Show the lowest supply as the current alert.
    if (foamWashLevel <=
            disinfectantLevel &&
        foamWashLevel <= waterLevel) {
      supplyName = 'Foam Wash';
      level = foamWashLevel;
    } else if (disinfectantLevel <=
        waterLevel) {
      supplyName = 'Disinfectant';
      level = disinfectantLevel;
    } else {
      supplyName = 'Water';
      level = waterLevel;
    }

    final bool isLow = level <= 35;

    final Color alertColor =
        level <= 20
            ? AppColors.crit
            : AppColors.warn;

    return _Panel(
      eyebrow: 'Attention',
      title: 'Alerts',
      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.panel2,
          borderRadius:
              BorderRadius.circular(10),
          border: Border.all(
            color: isLow
                ? alertColor.withOpacity(0.35)
                : AppColors.ok.withOpacity(0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isLow
                    ? alertColor.withOpacity(0.14)
                    : AppColors.ok.withOpacity(0.14),
                borderRadius:
                    BorderRadius.circular(7),
              ),
              child: Icon(
                isLow
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline,
                size: 17,
                color: isLow
                    ? alertColor
                    : AppColors.ok,
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    isLow
                        ? '$supplyName tank running low'
                        : 'All supplies are at normal levels',
                    style: _body(
                      size: 12.5,
                      weight:
                          FontWeight.w600,
                    ),
                  ),

                  const SizedBox(height: 1),

                  Text(
                    isLow
                        ? '${level.round()}% remaining — refill recommended'
                        : 'Water, Foam Wash, and Disinfectant are currently sufficient',
                    style: _body(
                      size: 10,
                      color:
                          AppColors.textFaint,
                    ),
                  ),
                ],
              ),
            ),

            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: isLow
                    ? alertColor.withOpacity(0.14)
                    : AppColors.ok.withOpacity(0.14),
                borderRadius:
                    BorderRadius.circular(100),
              ),
              child: Text(
                isLow ? 'LOW' : 'NORMAL',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w700,
                  color: isLow
                      ? alertColor
                      : AppColors.ok,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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

    return _Panel(
      eyebrow: "Today's Log",
      title:
          'Trucks Finished Washing',
      trailing: Text(
        '${rows.length} COMPLETED',
        style: _mono(
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
                    style: _body(
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
                    style: _body(
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
                  style: _mono(
                    size: 12,
                    weight:
                        FontWeight.w600,
                  ),
                ),
              ),

              DataCell(
                Text(
                  r.type,
                  style: _body(
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
                  style: _body(
                    size: 12,
                  ),
                ),
              ),

              DataCell(
                Text(
                  r.started,
                  style: _mono(
                    size: 12,
                  ),
                ),
              ),

              DataCell(
                Text(
                  r.finished,
                  style: _mono(
                    size: 12,
                  ),
                ),
              ),

              DataCell(
                Text(
                  r.duration,
                  style: _mono(
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
                        .withOpacity(
                            0.12),
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