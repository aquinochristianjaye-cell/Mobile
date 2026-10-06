import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'main.dart';
import 'widgets.dart';
import 'worker_availability_service.dart';
import 'worker_break_service.dart';
import 'worker_session.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _onBreak = false;

  // ----------------------------------------------------------
  // WORKER AVAILABILITY
  // ----------------------------------------------------------

  bool _isAvailable = true;
  bool _loadingAvailability = true;
  bool _updatingAvailability = false;

  // ----------------------------------------------------------
  // WORKER BREAK
  // ----------------------------------------------------------

  bool _loadingBreak = true;
  bool _updatingBreak = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
    _loadBreak();
  }

  Future<void> _loadAvailability() async {
    final workerId = WorkerSession.id;

    if (workerId == null) {
      if (mounted) {
        setState(() {
          _loadingAvailability = false;
        });
      }
      return;
    }

    try {
      final isAvailable =
          await WorkerAvailabilityService.getAvailability(workerId);

      if (!mounted) return;

      setState(() {
        _isAvailable = isAvailable;
        _loadingAvailability = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingAvailability = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load worker availability.',
          ),
        ),
      );
    }
  }

  Future<void> _changeAvailability(bool value) async {
    final workerId = WorkerSession.id;

    if (workerId == null) return;

    final oldValue = _isAvailable;

    setState(() {
      _isAvailable = value;
      _updatingAvailability = true;
    });

    try {
      final updated =
          await WorkerAvailabilityService.updateAvailability(
        workerId,
        value,
      );

      if (!mounted) return;

      setState(() {
        _isAvailable = updated;
        _updatingAvailability = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isAvailable = oldValue;
        _updatingAvailability = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  // ----------------------------------------------------------
  // WORKER BREAK
  // ----------------------------------------------------------

  Future<void> _loadBreak() async {
    final workerId = WorkerSession.id;

    if (workerId == null) {
      if (mounted) {
        setState(() {
          _loadingBreak = false;
        });
      }
      return;
    }

    try {
      final isOnBreak =
          await WorkerBreakService.getBreak(workerId);

      if (!mounted) return;

      setState(() {
        _onBreak = isOnBreak;
        _loadingBreak = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loadingBreak = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to load worker break status.',
          ),
        ),
      );
    }
  }

  Future<void> _changeBreak(bool value) async {
    final workerId = WorkerSession.id;

    if (workerId == null) return;

    final oldValue = _onBreak;

    setState(() {
      _onBreak = value;
      _updatingBreak = true;
    });

    try {
      final updated =
          await WorkerBreakService.updateBreak(
        workerId,
        value,
      );

      if (!mounted) return;

      setState(() {
        _onBreak = updated;
        _updatingBreak = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _onBreak = oldValue;
        _updatingBreak = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  Future<void> _signOut(BuildContext context) async {
    await WorkerSession.clear();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AuthScreen()),
      (route) => false,
    );
  }

  void _showAbout(BuildContext context) {
    final c = context.c;
    final t = context.t;

    _sheet(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const BrandLockup(subtitle: 'Worker portal'),
          const SizedBox(height: 20),
          Text(
            'Manage the truck queue, start and finish washes, and keep the station\'s chemical and water levels up to date.',
            style: t.body,
          ),
          const SizedBox(height: 12),
          Text(
            'Aquino Truck Wash Station',
            style: t.caption.copyWith(
              color: c.textFaint,
            ),
          ),
        ],
      ),
    );
  }

  void _showHelp(BuildContext context) {
    final t = context.t;

    _sheet(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Help and FAQ',
            style: t.title,
          ),
          const SizedBox(height: 8),
          const _Faq(
            question: 'How do I start a wash?',
            answer:
                'When the truck in the queue shows Arrived, tap Start washing. The truck\'s details open on the next screen.',
          ),
          const _Faq(
            question: 'Why is there no Start button?',
            answer:
                'Start appears once the truck has arrived. While it shows On the way, the truck isn\'t at the station yet.',
          ),
          const _Faq(
            question: 'How do I finish a wash?',
            answer:
                'Tap Finish washing on the queue card. The truck then moves to your Finished trucks list.',
          ),
          const _Faq(
            question: 'How do I update chemical and water levels?',
            answer:
                'Tap the levels card on the home screen. The update sheet opens right away. Move the sliders, or tap Full after a refill, then save.',
          ),
          const _Faq(
            question: 'I can\'t sign in.',
            answer:
                'Worker accounts are created by the administrator. Ask them to check your Worker ID and password.',
            last: true,
          ),
        ],
      ),
    );
  }

  void _sheet(
    BuildContext context, {
    required Widget child,
  }) {
    final c = context.c;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(26),
        ),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              22,
              12,
              22,
              24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(
                      bottom: 18,
                    ),
                    decoration: BoxDecoration(
                      color: c.line,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                child,
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: ContentWidth(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              16,
              20,
              28,
            ),
            children: [
              ScreenHeader(
                title: 'Settings',
                onBack: () => Navigator.pop(context),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // PROFILE
              // ------------------------------------------------

              SurfaceCard(
                child: Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.accentSoft,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: c.accent.withAlpha(120),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        WorkerSession.initials,
                        style: t.heading.copyWith(
                          color: c.accent,
                          fontSize: 21,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            WorkerSession.displayName,
                            style: t.heading.copyWith(
                              fontSize: 20,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            (WorkerSession.workerCode == null ||
                                    WorkerSession.workerCode!.isEmpty)
                                ? 'Worker account'
                                : 'Worker ID ${WorkerSession.workerCode}',
                            style: t.caption,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // APPEARANCE
              // ------------------------------------------------

              Text(
                'Appearance',
                style: t.label,
              ),
              const SizedBox(height: 10),

              SurfaceCard(
                padding: const EdgeInsets.fromLTRB(
                  16,
                  10,
                  12,
                  10,
                ),
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: themeController,
                  builder: (context, mode, _) {
                    final isDark =
                        Theme.of(context).brightness ==
                            Brightness.dark;

                    return Row(
                      children: [
                        _IconChip(
                          icon: isDark
                              ? Icons.dark_mode_outlined
                              : Icons.light_mode_outlined,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Dark mode',
                                style: t.body.copyWith(
                                  fontWeight:
                                      FontWeight.w700,
                                ),
                              ),
                              Text(
                                isDark
                                    ? 'Easier on the eyes at night'
                                    : 'Switch on for night shifts',
                                style: t.caption,
                              ),
                            ],
                          ),
                        ),
                        AppSwitch(
                          label: 'Dark mode',
                          value: isDark,
                          onChanged: (v) =>
                              themeController.setDark(v),
                        ),
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // SUPPORT
              // ------------------------------------------------

              Text(
                'Support',
                style: t.label,
              ),
              const SizedBox(height: 10),

              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _SettingsItem(
                      icon: Icons.info_outline_rounded,
                      title: 'About application',
                      onTap: () => _showAbout(context),
                    ),
                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: c.line,
                    ),
                    _SettingsItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help and FAQ',
                      onTap: () => _showHelp(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // ACCOUNT
              // ------------------------------------------------

              Text(
                'Account',
                style: t.label,
              ),
              const SizedBox(height: 10),

              SurfaceCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    // ------------------------------------------------
                    // WORKER AVAILABILITY
                    // ------------------------------------------------

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        10,
                        12,
                        10,
                      ),
                      child: Row(
                        children: [
                          _IconChip(
                            icon: _isAvailable
                                ? Icons
                                    .check_circle_outline_rounded
                                : Icons.block_outlined,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AVAILABILITY',
                                  style: t.body.copyWith(
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _loadingAvailability
                                      ? 'Loading...'
                                      : _isAvailable
                                          ? 'You are available for work'
                                          : 'You are currently unavailable',
                                  style: t.caption,
                                ),
                              ],
                            ),
                          ),
                          if (_loadingAvailability ||
                              _updatingAvailability)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          else
                            AppSwitch(
                              label: 'Availability',
                              value: _isAvailable,
                              onChanged: _changeAvailability,
                            ),
                        ],
                      ),
                    ),

                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: c.line,
                    ),

                    // ------------------------------------------------
                    // BREAK
                    // ------------------------------------------------

                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        10,
                        12,
                        10,
                      ),
                      child: Row(
                        children: [
                          const _IconChip(
                            icon: Icons.coffee_outlined,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BREAK',
                                  style: t.body.copyWith(
                                    fontWeight:
                                        FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _loadingBreak
                                      ? 'Loading...'
                                      : _onBreak
                                          ? 'You\'re currently on break'
                                          : 'Turn on when you step away',
                                  style: t.caption,
                                ),
                              ],
                            ),
                          ),
                          if (_loadingBreak || _updatingBreak)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child:
                                  CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            )
                          else
                            AppSwitch(
                              label: 'Break',
                              value: _onBreak,
                              onChanged: _changeBreak,
                            ),
                        ],
                      ),
                    ),

                    Divider(
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                      color: c.line,
                    ),

                    _SettingsItem(
                      icon: Icons.logout_rounded,
                      title: 'Sign out',
                      onTap: () => _signOut(context),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconChip extends StatelessWidget {
  const _IconChip({
    required this.icon,
    this.danger = false,
  });

  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: danger
            ? c.dangerSoft
            : c.accentSoft,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: danger
            ? c.danger
            : c.accent,
        size: 22,
      ),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
  }) : danger = false;

  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              _IconChip(
                icon: icon,
                danger: danger,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: t.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: danger
                        ? c.danger
                        : c.text,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: c.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({
    required this.question,
    required this.answer,
    this.last = false,
  });

  final String question;
  final String answer;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 14,
      ),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: c.line,
                ),
              ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            question,
            style: t.body.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            answer,
            style: t.bodyMuted.copyWith(
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
