import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'widgets.dart';

class WashingScreen extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const WashingScreen({
    super.key,
    required this.appointment,
  });

  // The appointment time arrives as text like 2026-09-22T10:30:00.
  String _formatBooked(dynamic value) {
    if (value == null || value.toString().isEmpty) {
      return 'Not provided';
    }

    try {
      return formatMonthDayTime(DateTime.parse(value.toString()));
    } catch (e) {
      return value.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    // Get information from Laravel appointment
    final driver = appointment['driver'] ?? {};

    final String driverName =
        (driver['name'] ?? 'Unknown driver').toString();

    final String truckPlate =
        (appointment['truck_plate'] ?? 'Unknown').toString();

    final String comingFrom =
        (appointment['coming_from'] ?? 'Unknown').toString();

    final String livestockLoad =
        (appointment['livestock_load'] ?? 'Unknown').toString();

    final String preferredDateTime =
        _formatBooked(appointment['preferred_datetime']);

    return Scaffold(
      backgroundColor: c.bg,
      bottomNavigationBar: BottomBar(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded, size: 20, color: c.textMuted),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'When the truck is done, tap Finish washing in the queue.',
                    style: t.caption.copyWith(fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              label: 'Back to queue',
              icon: Icons.arrow_back_rounded,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ContentWidth(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ScreenHeader(
                  eyebrow: 'Driver: $driverName',
                  title: 'Truck washing',
                  onBack: () => Navigator.pop(context),
                  trailing: const WorkerAvatar(),
                ),

                const SizedBox(height: 22),

                // ------------------------------------------------
                // STATUS
                // ------------------------------------------------
                SurfaceCard(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                  borderColor: c.accent.withAlpha(140),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Now washing', style: t.label),
                          Pill(
                            label: 'In progress',
                            color: c.accent,
                            background: c.accentSoft,
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: PlateTag(truckPlate, fontSize: 34),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      const WashTracker(stepIndex: 2),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ------------------------------------------------
                // TRUCK DETAILS
                // ------------------------------------------------
                SurfaceCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Truck details', style: t.heading),
                      const SizedBox(height: 6),
                      DetailRow(label: 'Driver', value: driverName),
                      DetailRow(label: 'Coming from', value: comingFrom),
                      DetailRow(label: 'Livestock load', value: livestockLoad),
                      DetailRow(
                        label: 'Preferred time',
                        value: preferredDateTime,
                        last: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
