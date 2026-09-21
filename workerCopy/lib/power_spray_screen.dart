import 'package:flutter/material.dart';

import 'app_theme.dart';
import 'services/station_supply_service.dart';
import 'widgets.dart';

/// The three supply levels, 0 to 100.
class SupplyLevels {
  const SupplyLevels({
    required this.foamWash,
    required this.disinfectant,
    required this.water,
  });

  final double foamWash;
  final double disinfectant;
  final double water;
}

/// Opens the "Update station supplies" sheet right where you are (the
/// dashboard), with no extra page in between.
///
/// Returns the saved levels, or null if the worker cancelled / dismissed it.
Future<SupplyLevels?> showSupplyUpdateSheet(
  BuildContext context, {
  required double foamWash,
  required double disinfectant,
  required double water,
}) {
  return showModalBottomSheet<SupplyLevels>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (BuildContext modalContext) {
      return _SupplyUpdateSheet(
        foamWash: foamWash,
        disinfectant: disinfectant,
        water: water,
      );
    },
  );
}

class _SupplyUpdateSheet extends StatefulWidget {
  const _SupplyUpdateSheet({
    required this.foamWash,
    required this.disinfectant,
    required this.water,
  });

  final double foamWash;
  final double disinfectant;
  final double water;

  @override
  State<_SupplyUpdateSheet> createState() => _SupplyUpdateSheetState();
}

class _SupplyUpdateSheetState extends State<_SupplyUpdateSheet> {
  late double _foamWash = widget.foamWash;
  late double _disinfectant = widget.disinfectant;
  late double _water = widget.water;

  bool _isSaving = false;

  // Shown inside the sheet, because a snackbar would hide behind it.
  String? _error;

  Future<void> _save() async {
    if (_isSaving) return;

    setState(() {
      _isSaving = true;
      _error = null;
    });

    try {
      await StationSupplyService.updateSupplies(
        foamWash: _foamWash,
        disinfectant: _disinfectant,
        water: _water,
      );

      if (!mounted) return;

      Navigator.pop(
        context,
        SupplyLevels(
          foamWash: _foamWash,
          disinfectant: _disinfectant,
          water: _water,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
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
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
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

                  _sliderRow(
                    c,
                    t,
                    'Foam wash',
                    _foamWash,
                    (val) => setState(() => _foamWash = val),
                  ),

                  _sliderRow(
                    c,
                    t,
                    'Disinfectant',
                    _disinfectant,
                    (val) => setState(() => _disinfectant = val),
                  ),

                  _sliderRow(
                    c,
                    t,
                    'Water',
                    _water,
                    (val) => setState(() => _water = val),
                  ),

                  if (_error != null) ...[
                    const SizedBox(height: 2),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.dangerSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 20, color: c.danger),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: t.caption.copyWith(
                                color: c.danger,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 14),

                  // Buttons
                  Row(
                    children: [
                      // CANCEL
                      Expanded(
                        child: SecondaryButton(
                          label: 'Cancel',
                          onPressed: _isSaving
                              ? null
                              : () {
                                  Navigator.pop(context);
                                },
                        ),
                      ),

                      const SizedBox(width: 12),

                      // SAVE UPDATE
                      Expanded(
                        child: PrimaryButton(
                          label: 'Save levels',
                          loading: _isSaving,
                          onPressed: _isSaving ? null : _save,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sliderRow(
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
              onChanged: _isSaving ? null : onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
