import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'services/station_supply_service.dart';
import 'widgets.dart';

class PowerSprayScreen extends StatefulWidget {
  const PowerSprayScreen({super.key});

  @override
  State<PowerSprayScreen> createState() => _PowerSprayScreenState();
}

class _PowerSprayScreenState extends State<PowerSprayScreen> {
  // Shared station supply levels
  double foamWashLevel = 0;
  double disinfectantLevel = 0;
  double waterLevel = 0;

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSupplies();
  }

  // Load supply levels from Laravel/MySQL
  Future<void> _loadSupplies() async {
    try {
      final supplies =
          await StationSupplyService.getSupplies();

      if (!mounted) return;

      setState(() {
        foamWashLevel =
            supplies['Foam Wash'] ?? 0;

        disinfectantLevel =
            supplies['Disinfectant'] ?? 0;

        waterLevel =
            supplies['Water'] ?? 0;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      showAppSnack(
        context,
        'Couldn\'t load supply levels. Pull down to try again.',
        error: true,
      );
    }
  }

  void _showUpdateModal() {
    double tempFoamWash = foamWashLevel;
    double tempDisinfectant = disinfectantLevel;
    double tempWater = waterLevel;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (
            BuildContext sheetContext,
            StateSetter setModalState,
          ) {
            final c = sheetContext.c;
            final t = sheetContext.t;

            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(modalContext).viewInsets.bottom + 20,
              ),
              decoration: BoxDecoration(
                color: c.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(26),
                ),
                border: Border(top: BorderSide(color: c.line)),
              ),
              child: SafeArea(
                top: false,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Handle Bar
                      Center(
                        child: Container(
                          width: 44,
                          height: 5,
                          decoration: BoxDecoration(
                            color: c.line,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      Text('Update station supplies', style: t.title),
                      const SizedBox(height: 4),
                      Text(
                        'Set each level to what you see in the tank.',
                        style: t.caption.copyWith(fontSize: 14),
                      ),

                      const SizedBox(height: 20),

                      // Foam Wash
                      _buildSliderRow(
                        c,
                        t,
                        'Foam wash',
                        tempFoamWash,
                        (val) {
                          setModalState(() {
                            tempFoamWash = val;
                          });
                        },
                      ),

                      // Disinfectant
                      _buildSliderRow(
                        c,
                        t,
                        'Disinfectant',
                        tempDisinfectant,
                        (val) {
                          setModalState(() {
                            tempDisinfectant = val;
                          });
                        },
                      ),

                      // Water
                      _buildSliderRow(
                        c,
                        t,
                        'Water',
                        tempWater,
                        (val) {
                          setModalState(() {
                            tempWater = val;
                          });
                        },
                      ),

                      const SizedBox(height: 10),

                      // Buttons
                      Row(
                        children: [
                          // CANCEL
                          Expanded(
                            child: SecondaryButton(
                              label: 'Cancel',
                              onPressed: () {
                                Navigator.pop(modalContext);
                              },
                            ),
                          ),

                          const SizedBox(width: 12),

                          // SAVE UPDATE
                          Expanded(
                            child: PrimaryButton(
                              label: 'Save levels',
                              loading: isSaving,
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        isSaving = true;
                                      });

                                      try {
                                        await StationSupplyService
                                            .updateSupplies(
                                          foamWash: tempFoamWash,
                                          disinfectant: tempDisinfectant,
                                          water: tempWater,
                                        );

                                        if (!mounted) {
                                          return;
                                        }

                                        setState(() {
                                          foamWashLevel = tempFoamWash;

                                          disinfectantLevel = tempDisinfectant;

                                          waterLevel = tempWater;

                                          isSaving = false;
                                        });

                                        Navigator.pop(modalContext);

                                        showAppSnack(
                                          context,
                                          'Supply levels updated.',
                                        );
                                      } catch (e) {
                                        setModalState(() {
                                          isSaving = false;
                                        });

                                        if (!mounted) {
                                          return;
                                        }

                                        showAppSnack(
                                          context,
                                          e
                                              .toString()
                                              .replaceFirst('Exception: ', ''),
                                          error: true,
                                        );
                                      }
                                    },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSliderRow(
    AppColors c,
    AppType t,
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    final Color color = SupplyGauge.colorFor(c, value);
    final double safeValue = value.clamp(0.0, 100.0).toDouble();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label, style: t.heading.copyWith(fontSize: 17)),
              ),
              Text(
                '${safeValue.round()}%',
                style: t.heading.copyWith(fontSize: 20, color: color),
              ),
              const SizedBox(width: 12),
              // One tap for "I just refilled it".
              Semantics(
                button: true,
                label: 'Set $label to full',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(100),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 38),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: c.accentSoft,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: c.accent.withAlpha(120)),
                    ),
                    child: Text(
                      'Full',
                      style: t.label.copyWith(
                        color: c.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          SliderTheme(
            data: SliderThemeData(
              trackHeight: 10,
              activeTrackColor: color,
              inactiveTrackColor: c.surfaceHigh,
              thumbColor: color,
              overlayColor: color.withAlpha(36),
              activeTickMarkColor: Colors.transparent,
              inactiveTickMarkColor: Colors.transparent,
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 13,
                elevation: 0,
              ),
            ),
            child: Slider(
              value: safeValue,
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Scaffold(
      backgroundColor: c.bg,
      bottomNavigationBar: BottomBar(
        child: PrimaryButton(
          label: 'Update levels',
          icon: Icons.tune_rounded,
          onPressed: isLoading
              ? null
              : () {
                  _showUpdateModal();
                },
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: ContentWidth(
          child: RefreshIndicator(
            onRefresh: _loadSupplies,
            color: c.accent,
            backgroundColor: c.surface,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                // Header
                ScreenHeader(
                  eyebrow: 'Station supplies',
                  title: 'Power spray station',
                  onBack: () {
                    Navigator.pop(context);
                  },
                  trailing: const WorkerAvatar(),
                ),

                const SizedBox(height: 24),

                // Levels Card
                _buildStationCard(),

                const SizedBox(height: 14),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: c.textMuted),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Bars turn amber at 50% and red at 20%.',
                        style: t.caption,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStationCard() {
    if (isLoading) {
      return const SkeletonBlock(height: 290, radius: 20);
    }

    return SurfaceCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          SupplyGauge(label: 'Foam wash', level: foamWashLevel),

          const SizedBox(height: 24),

          SupplyGauge(label: 'Disinfectant', level: disinfectantLevel),

          const SizedBox(height: 24),

          SupplyGauge(label: 'Water', level: waterLevel),
        ],
      ),
    );
  }
}
