import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/text_styles.dart';
import '../services/station_supply_service.dart';
import 'common/panel.dart';

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
    return Panel(
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
                              .withValues(
                                  alpha: 0.35),
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
            style: monoStyle(
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
            style: bodyStyle(
              size: 11,
              weight:
                  FontWeight.w600,
            ),
          ),

          const SizedBox(
              height: 1),

          Text(
            liters,
            style: bodyStyle(
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
                  .withValues(alpha: 0.14),
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

