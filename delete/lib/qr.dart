import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'app_theme.dart';
import 'dashboard_driver.dart';
import 'widgets.dart';

class QrCodeDriverScreen extends StatelessWidget {
  final int driverId;
  final int appointmentId;
  final String plateNumber;
  final String livestockLoad;
  final String preferredTime;
  final String comingFrom;

  /// True when opened from the dashboard's "Show gate pass" button.
  /// Then "Done" simply goes back instead of rebuilding the dashboard.
  final bool fromDashboard;

  const QrCodeDriverScreen({
    Key? key,
    required this.driverId,
    required this.appointmentId,
    required this.plateNumber,
    required this.livestockLoad,
    required this.preferredTime,
    required this.comingFrom,
    this.fromDashboard = false,
  }) : super(key: key);

  void _finish(BuildContext context) {
    if (fromDashboard && Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }

    // Replace everything with a fresh dashboard so the driver
    // can't back into the booking form.
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => MainScreenDriver(
          driverId: driverId,
          appointmentId: appointmentId,
          plateNumber: plateNumber,
          livestockLoad: livestockLoad,
          preferredTime: preferredTime,
          comingFrom: comingFrom,
        ),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    // This is the information encoded inside the QR code.
    final String qrData = 'WASH-APPOINTMENT-$appointmentId';

    return Scaffold(
      backgroundColor: c.bg,
      bottomNavigationBar: BottomBar(
        child: PrimaryButton(
          label: 'Done',
          onPressed: () => _finish(context),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                eyebrow: fromDashboard ? null : 'Booking confirmed',
                title: 'Gate pass',
                onBack: fromDashboard ? () => Navigator.pop(context) : null,
              ),

              if (!fromDashboard) ...[
                const SizedBox(height: 18),
                const FlowProgress(step: 3),
              ],

              const SizedBox(height: 22),

              // ------------------------------------------------
              // TICKET
              // ------------------------------------------------
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: c.surface,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: c.line),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 24, 22, 20),
                      child: Column(
                        children: [
                          Text('Show this at the wash station', style: t.heading),
                          const SizedBox(height: 4),
                          Text(
                            'A worker will scan it when you arrive.',
                            style: t.caption,
                            textAlign: TextAlign.center,
                          ),

                          const SizedBox(height: 20),

                          // REAL QR CODE. Always dark on white so scanners can read it,
                          // even in Night shift mode.
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: QrImageView(
                              data: qrData,
                              version: QrVersions.auto,
                              size: 210,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                            ),
                          ),

                          const SizedBox(height: 14),

                          Text(
                            'Appointment #$appointmentId',
                            style: t.body.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            qrData,
                            style: t.caption.copyWith(color: c.textFaint),
                          ),
                        ],
                      ),
                    ),

                    // Perforation with side notches
                    SizedBox(
                      height: 26,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 22),
                            child: DashedLine(),
                          ),
                          Positioned(
                            left: -13,
                            child: _Notch(color: c.bg, border: c.line, keepRightHalf: true),
                          ),
                          Positioned(
                            right: -13,
                            child: _Notch(color: c.bg, border: c.line, keepRightHalf: false),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: PlateTag(plateNumber, fontSize: 28),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _PassRow(icon: Icons.local_shipping_outlined, label: 'Load', value: livestockLoad),
                          const SizedBox(height: 10),
                          _PassRow(icon: Icons.event_outlined, label: 'Time', value: preferredTime),
                          const SizedBox(height: 10),
                          _PassRow(icon: Icons.location_on_outlined, label: 'From', value: comingFrom),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.brightness_high_outlined, size: 20, color: c.textMuted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Turn your screen brightness up so the scanner can read the code.',
                      style: t.caption,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PassRow extends StatelessWidget {
  const _PassRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: c.textMuted),
        const SizedBox(width: 10),
        SizedBox(width: 48, child: Text(label, style: t.caption.copyWith(fontSize: 14))),
        Expanded(
          child: Text(value, style: t.body.copyWith(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}

/// Half of a circle that "bites" into the ticket edge. Only the half that
/// sits inside the card is drawn, so the outline reads as a clean cut-out.
class _Notch extends StatelessWidget {
  const _Notch({
    required this.color,
    required this.border,
    required this.keepRightHalf,
  });

  final Color color;
  final Color border;
  final bool keepRightHalf;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      clipper: _HalfClipper(keepRightHalf),
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: border),
        ),
      ),
    );
  }
}

class _HalfClipper extends CustomClipper<Rect> {
  _HalfClipper(this.keepRightHalf);
  final bool keepRightHalf;

  @override
  Rect getClip(Size size) {
    return keepRightHalf
        ? Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height)
        : Rect.fromLTWH(0, 0, size.width / 2, size.height);
  }

  @override
  bool shouldReclip(covariant _HalfClipper old) => old.keepRightHalf != keepRightHalf;
}
