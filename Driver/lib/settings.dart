import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'driver_session.dart';
import 'login_driver.dart';
import 'widgets.dart';

class SettingsDriverScreen extends StatelessWidget {
  const SettingsDriverScreen({Key? key}) : super(key: key);

  void _signOut(BuildContext context) {
    DriverSession.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginDriverScreen()),
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
          const BrandLockup(),
          const SizedBox(height: 20),
          Text(
            'Book truck wash appointments, pay with GCash, and follow your wash from arrival to finish.',
            style: t.body,
          ),
          const SizedBox(height: 12),
          Text(
            'Aquino Truck Wash Station',
            style: t.caption.copyWith(color: c.textFaint),
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
          Text('Help and FAQ', style: t.title),
          const SizedBox(height: 8),
          const _Faq(
            question: 'How do I book a wash?',
            answer:
                'Tap Book a wash on the home screen. Enter your truck and load details, choose a date and time, then review and confirm.',
          ),
          const _Faq(
            question: 'What is the gate pass?',
            answer:
                'After you confirm, the app shows a QR code. Show it to the station worker when you arrive so they can check you in.',
          ),
          const _Faq(
            question: 'Where can I see my gate pass again?',
            answer:
                'While a wash is active, tap Show gate pass on the home screen.',
          ),
          const _Faq(
            question: 'How do I know my truck is done?',
            answer:
                'The home screen updates by itself. When the wash is finished, it moves to Recent washes.',
          ),
          const _Faq(
            question: 'I can\'t sign in.',
            answer:
                'Driver accounts are created by the station admin. Ask them to check your email and password.',
            last: true,
          ),
        ],
      ),
    );
  }

  void _showDeactivate(BuildContext context) {
    final c = context.c;
    final t = context.t;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: c.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: Text('Deactivate account', style: t.heading),
        content: Text(
          'Driver accounts are managed by the station admin. Ask them to deactivate your account.',
          style: t.bodyMuted,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'OK',
              style: t.label.copyWith(color: c.accent, fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  void _sheet(BuildContext context, {required Widget child}) {
    final c = context.c;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 18),
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
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                      border: Border.all(color: c.accent.withAlpha(120), width: 1.5),
                    ),
                    child: Text(
                      DriverSession.initials,
                      style: t.heading.copyWith(color: c.accent, fontSize: 21),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(DriverSession.displayName, style: t.heading.copyWith(fontSize: 20)),
                        const SizedBox(height: 2),
                        Text('Driver account', style: t.caption),
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
            Text('Appearance', style: t.label),
            const SizedBox(height: 10),

            SurfaceCard(
              padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: themeController,
                builder: (context, mode, _) {
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Row(
                    children: [
                      _IconChip(
                        icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Dark mode',
                              style: t.body.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              isDark
                                  ? 'Easier on the eyes at night'
                                  : 'Switch on for night driving',
                              style: t.caption,
                            ),
                          ],
                        ),
                      ),
                      AppSwitch(
                        label: 'Dark mode',
                        value: isDark,
                        onChanged: (v) => themeController.setDark(v),
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
            Text('Support', style: t.label),
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
                  Divider(height: 1, indent: 16, endIndent: 16, color: c.line),
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
            Text('Account', style: t.label),
            const SizedBox(height: 10),

            SurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsItem(
                    icon: Icons.logout_rounded,
                    title: 'Sign out',
                    onTap: () => _signOut(context),
                  ),
                  Divider(height: 1, indent: 16, endIndent: 16, color: c.line),
                  _SettingsItem(
                    icon: Icons.person_off_outlined,
                    title: 'Deactivate my account',
                    danger: true,
                    onTap: () => _showDeactivate(context),
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

class _IconChip extends StatelessWidget {
  const _IconChip({required this.icon, this.danger = false});
  final IconData icon;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: danger ? c.dangerSoft : c.accentSoft,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: danger ? c.danger : c.accent, size: 22),
    );
  }
}

class _SettingsItem extends StatelessWidget {
  const _SettingsItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.danger = false,
  });

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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              _IconChip(icon: icon, danger: danger),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: t.body.copyWith(
                    fontWeight: FontWeight.w700,
                    color: danger ? c.danger : c.text,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: c.textFaint),
            ],
          ),
        ),
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  const _Faq({required this.question, required this.answer, this.last = false});
  final String question;
  final String answer;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(question, style: t.body.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(answer, style: t.bodyMuted.copyWith(fontSize: 15)),
        ],
      ),
    );
  }
}
