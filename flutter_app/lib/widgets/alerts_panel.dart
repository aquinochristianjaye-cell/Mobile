import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../services/station_supply_service.dart';
import 'common/panel.dart';

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

    return Panel(
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
                ? alertColor.withValues(alpha: 0.35)
                : AppColors.ok.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isLow
                    ? alertColor.withValues(alpha: 0.14)
                    : AppColors.ok.withValues(alpha: 0.14),
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
                    style: bodyStyle(
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
                    style: bodyStyle(
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
                    ? alertColor.withValues(alpha: 0.14)
                    : AppColors.ok.withValues(alpha: 0.14),
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

