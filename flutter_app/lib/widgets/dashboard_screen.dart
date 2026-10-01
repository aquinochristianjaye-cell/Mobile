import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../services/notification_service.dart';
import '../admin_session.dart';
import '../login_page.dart';

import 'common/status_pill.dart';
import 'bay_status_panel.dart';
import 'trucks_waiting_panel.dart';
import 'currently_washing_panel.dart';
import 'supply_levels_panel.dart';
import 'available_washers_panel.dart';
import 'drivers_panel.dart';
import 'alerts_panel.dart';
import 'trucks_table_panel.dart';

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
                          style: displayStyle(
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
                            style: bodyStyle(
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
                        separatorBuilder: (_, _) =>
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

  /// ===================== ADMIN LOGOUT =====================

  Future<void> _logout() async {
    await AdminSession.clear();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
      (route) => false,
    );
  }

  /// ===================== ADMIN SETTINGS =====================

  void _showAdminSettings() {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 24,
          ),
          child: _AdminSettingsDialog(
            onLogout: _logout,
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
      body: Stack(
        children: [
          // Layer 1 — cyan glow, upper right.
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0.9, -0.95),
                  radius: 1.15,
                  colors: [
                    Color(0x1F2FB8D9),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Layer 2 — violet glow, lower left,
          // for a subtle two-tone mesh.
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(-1.0, 1.0),
                  radius: 1.2,
                  colors: [
                    Color(0x148C9CF5),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Layer 3 — faint vignette to keep edges calm
          // and add depth.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.3,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.22),
                  ],
                  stops: const [0.7, 1.0],
                ),
              ),
            ),
          ),

          SafeArea(
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
                    onSettingsTap:
                        _showAdminSettings,
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
        ],
      ),
    );
  }
}

/// ===================== ADMIN SETTINGS DIALOG =====================

class _AdminSettingsDialog extends StatelessWidget {
  final VoidCallback onLogout;

  const _AdminSettingsDialog({
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final email =
        AdminSession.email?.trim().isNotEmpty == true
            ? AdminSession.email!.trim()
            : 'Administrator';

    return Container(
      constraints: const BoxConstraints(
        maxWidth: 430,
      ),
      decoration: BoxDecoration(
        color: AppColors.panel,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.lineStrong,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 35,
            offset: const Offset(0, 18),
          ),
          BoxShadow(
            color: AppColors.water.withValues(alpha: 0.08),
            blurRadius: 30,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// HEADER
            Container(
              padding: const EdgeInsets.fromLTRB(
                20,
                20,
                14,
                18,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.panelTop.withValues(alpha: 0.95),
                    AppColors.panelBottom.withValues(alpha: 0.95),
                  ],
                ),
                border: Border(
                  bottom: BorderSide(
                    color: AppColors.line,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color:
                          AppColors.water.withValues(alpha: 0.12),
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            AppColors.water.withValues(alpha: 0.28),
                      ),
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_outlined,
                      color: AppColors.water,
                      size: 23,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Admin Settings',
                          style: displayStyle(
                            size: 17,
                            weight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Manage your dashboard account',
                          style: bodyStyle(
                            size: 10.5,
                            color: AppColors.textDim,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    tooltip: 'Close',
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.close,
                      size: 19,
                      color: AppColors.textDim,
                    ),
                  ),
                ],
              ),
            ),

            /// CONTENT
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  /// ADMIN ACCOUNT
                  _AdminSettingsSection(
                    icon: Icons.person_outline,
                    iconColor: AppColors.water,
                    title: 'Admin Account',
                    subtitle: 'Signed in administrator',
                    child: Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: AppColors.panel2,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.line,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: AppColors.water
                                  .withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppColors.water,
                              size: 19,
                            ),
                          ),

                          const SizedBox(width: 11),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow:
                                      TextOverflow.ellipsis,
                                  style: bodyStyle(
                                    size: 12,
                                    weight:
                                        FontWeight.w600,
                                  ),
                                ),

                                const SizedBox(height: 5),

                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration:
                                          const BoxDecoration(
                                        color:
                                            AppColors.ok,
                                        shape:
                                            BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Account Active',
                                      style: bodyStyle(
                                        size: 9.5,
                                        color:
                                            AppColors.ok,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// DASHBOARD
                  _AdminSettingsSection(
                    icon: Icons.dashboard_outlined,
                    iconColor: const Color(0xFF8C9CF5),
                    title: 'Dashboard',
                    subtitle:
                        'Current system appearance',
                    child: _AdminSettingsTile(
                      icon: Icons.dark_mode_outlined,
                      title: 'Dark Dashboard',
                      subtitle:
                          'Optimized for operations monitoring',
                      trailing: Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFF8C9CF5).withValues(
                            alpha: 0.12,
                          ),
                          borderRadius:
                              BorderRadius.circular(7),
                          border: Border.all(
                            color:
                                const Color(0xFF8C9CF5).withValues(
                              alpha: 0.25,
                            ),
                          ),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: monoStyle(
                            size: 8,
                            color: const Color(0xFF8C9CF5),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  /// SYSTEM
                  _AdminSettingsSection(
                    icon: Icons.settings_outlined,
                    iconColor: AppColors.ok,
                    title: 'System',
                    subtitle:
                        'Aquino Wash Station status',
                    child: Column(
                      children: [
                        _AdminSettingsTile(
                          icon: Icons.cloud_done_outlined,
                          title: 'System Connection',
                          subtitle:
                              'Backend connection is monitored by the dashboard',
                          trailing: const Icon(
                            Icons.check_circle,
                            color: AppColors.ok,
                            size: 18,
                          ),
                        ),

                        const SizedBox(height: 8),

                        _AdminSettingsTile(
                          icon: Icons.info_outline,
                          title: 'Application',
                          subtitle:
                              'Aquino Wash Station Admin Dashboard',
                          trailing: Text(
                            'ADMIN',
                            style: monoStyle(
                              size: 8.5,
                              color: AppColors.textFaint,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  /// LOGOUT
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onLogout();
                      },
                      icon: const Icon(
                        Icons.logout,
                        size: 18,
                      ),
                      label: const Text(
                        'Logout',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor:
                            AppColors.crit,
                        side: BorderSide(
                          color:
                              AppColors.crit.withValues(
                            alpha: 0.35,
                          ),
                        ),
                        backgroundColor:
                            AppColors.crit.withValues(
                          alpha: 0.06,
                        ),
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 13,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(11),
                        ),
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
  }
}

/// ===================== SETTINGS SECTION =====================

class _AdminSettingsSection extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  const _AdminSettingsSection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color:
                    iconColor.withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
            ),

            const SizedBox(width: 9),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: bodyStyle(
                      size: 11.5,
                      weight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: bodyStyle(
                      size: 9,
                      color: AppColors.textFaint,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        child,
      ],
    );
  }
}

/// ===================== SETTINGS TILE =====================

class _AdminSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _AdminSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.panel2,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(
          color: AppColors.line,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color:
                  AppColors.panel.withValues(alpha: 0.8),
              borderRadius:
                  BorderRadius.circular(9),
            ),
            child: Icon(
              icon,
              size: 17,
              color: AppColors.textDim,
            ),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: bodyStyle(
                    size: 10.5,
                    weight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: bodyStyle(
                    size: 8.5,
                    color: AppColors.textFaint,
                  ),
                ),
              ],
            ),
          ),

          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
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
                  AppColors.water.withValues(alpha: 0.12),
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
                  style: bodyStyle(
                    size: 12.5,
                    weight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 3),

                Text(
                  notification['message'] ?? '',
                  style: bodyStyle(
                    size: 10.5,
                    color: AppColors.textDim,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  notification['created_at'] ?? '',
                  style: monoStyle(
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
  final VoidCallback onSettingsTap;

  const _TopBar({
    required this.timeStr,
    required this.dateStr,
    required this.notificationCount,
    required this.onNotificationTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        18,
        14,
        18,
        14,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.panelTop.withValues(alpha: 0.9),
            AppColors.panelBottom.withValues(alpha: 0.9),
          ],
        ),
        border: Border.all(
          color: AppColors.line,
        ),
        boxShadow: AppColors.elevation(
          strength: 0.7,
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
                              .withValues(alpha: 0.30),
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
                    style: displayStyle(
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
                    style: monoStyle(
                      size: 12,
                      color:
                          AppColors.textDim,
                    ),
                  ),

                  const SizedBox(height: 1),

                  Text(
                    dateStr,
                    style: monoStyle(
                      size: 10,
                      color:
                          AppColors.textFaint,
                    ),
                  ),
                ],
              ),

              const SizedBox(width: 12),

              const StatusPill(
                label: 'System Online',
                color: AppColors.ok,
              ),

              const SizedBox(width: 12),

              /// NOTIFICATION BUTTON
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
                          color: notificationCount > 0
                              ? AppColors.water.withValues(
                                  alpha: 0.5,
                                )
                              : AppColors.lineStrong,
                        ),
                        boxShadow: notificationCount > 0
                            ? AppColors.glow(
                                AppColors.water,
                                strength: 0.6,
                              )
                            : null,
                      ),
                      child: Icon(
                        notificationCount > 0
                            ? Icons.notifications
                            : Icons.notifications_none,
                        size: 17,
                        color: notificationCount > 0
                            ? AppColors.water
                            : AppColors.textDim,
                      ),
                    ),

                    if (notificationCount >
                        0)
                      Positioned(
                        right: -3,
                        top: -3,
                        child: Container(
                          constraints:
                              const BoxConstraints(
                            minWidth: 17,
                            minHeight: 17,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal: 4,
                          ),
                          decoration:
                              BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFFF7A70),
                                AppColors.crit,
                              ],
                            ),
                            shape:
                                BoxShape.circle,
                            border:
                                Border.all(
                              color:
                                  AppColors.bg,
                              width: 2,
                            ),
                            boxShadow: AppColors.glow(
                              AppColors.crit,
                              strength: 0.8,
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

              const SizedBox(width: 8),

              /// SETTINGS BUTTON
              GestureDetector(
                onTap: onSettingsTap,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.panel,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.lineStrong,
                    ),
                  ),
                  child: const Icon(
                    Icons.settings_outlined,
                    size: 17,
                    color: AppColors.textDim,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// ===================== WIDE LAYOUT =====================

class _WideLayout extends StatelessWidget {
  const _WideLayout();

  @override
  Widget build(BuildContext context) {
    const gap = 14.0;
    const bayColWidth = 270.0;

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
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
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
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
                  crossAxisAlignment:
                      CrossAxisAlignment.stretch,
                  children: [
                    const SupplyLevelsPanel(),

                    SizedBox(height: gap),

                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child:
                              AvailableWashersPanel(),
                        ),

                        SizedBox(width: gap),

                        const Expanded(
                          child:
                              DriversPanel(),
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