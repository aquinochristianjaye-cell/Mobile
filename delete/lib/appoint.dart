import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme.dart';
import 'con_app.dart';
import 'widgets.dart';

class SetAppDriverScreen extends StatefulWidget {
  final int driverId;

  const SetAppDriverScreen({
    Key? key,
    required this.driverId,
  }) : super(key: key);

  @override
  State<SetAppDriverScreen> createState() => _SetAppDriverScreenState();
}

class _SetAppDriverScreenState extends State<SetAppDriverScreen> {
  int _selectedLoadIndex = 0; // 0 for Piglets, 1 for Hogs

  // Controllers to capture user input
  final TextEditingController _truckUsedPlateController = TextEditingController();
  final TextEditingController _comingFromController = TextEditingController();
  final TextEditingController _preferredTimeController = TextEditingController();

  // Stores the actual selected date and time for Laravel
  DateTime? _selectedDateTime;

  // GCash Controllers
  final TextEditingController _gcashAccountController = TextEditingController();
  final TextEditingController _gcashPinController = TextEditingController();

  // Inline errors
  String? _plateError;
  String? _timeError;
  String? _gcashError;
  String? _pinError;

  // Used to scroll to the first field that needs attention.
  final GlobalKey _plateKey = GlobalKey();
  final GlobalKey _timeKey = GlobalKey();
  final GlobalKey _gcashKey = GlobalKey();
  final GlobalKey _pinKey = GlobalKey();

  @override
  void dispose() {
    _truckUsedPlateController.dispose();
    _comingFromController.dispose();
    _preferredTimeController.dispose();
    _gcashAccountController.dispose();
    _gcashPinController.dispose();
    super.dispose();
  }

  // Function to open Date and Time pickers
  Future<void> _selectDateTime(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(
        const Duration(days: 365),
      ),
    );

    if (pickedDate != null) {
      if (!mounted) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final picked = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Don't allow a time that has already passed today.
        if (picked.isBefore(DateTime.now())) {
          setState(() {
            _timeError = 'That time has already passed. Pick a later time.';
          });
          return;
        }

        final hours = pickedTime.hourOfPeriod == 0 ? 12 : pickedTime.hourOfPeriod;

        final period = pickedTime.period == DayPeriod.am ? 'AM' : 'PM';

        final minutes = pickedTime.minute.toString().padLeft(2, '0');

        const months = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec',
        ];

        final String monthName = months[pickedDate.month - 1];

        setState(() {
          // Save the actual date and time
          _selectedDateTime = picked;

          // Keep a readable version for the UI
          _preferredTimeController.text =
              '$monthName ${pickedDate.day}, $hours:$minutes $period';

          _timeError = null;
        });
      }
    }
  }

  bool _validate() {
    final plate = _truckUsedPlateController.text.trim();
    final gcash = _gcashAccountController.text.trim();
    final pin = _gcashPinController.text;

    String? plateErr;
    String? timeErr;
    String? gcashErr;
    String? pinErr;

    if (plate.isEmpty) {
      plateErr = 'Enter the truck plate number.';
    }

    if (_selectedDateTime == null) {
      timeErr = _timeError ?? 'Choose a date and time.';
    }

    if (gcash.isNotEmpty && !RegExp(r'^09\d{9}$').hasMatch(gcash)) {
      gcashErr = 'Enter an 11-digit number starting with 09.';
    }

    if (pin.isNotEmpty && pin.length != 4 && pin.length != 6) {
      pinErr = 'PIN must be 4 or 6 digits.';
    }

    setState(() {
      _plateError = plateErr;
      _timeError = timeErr;
      _gcashError = gcashErr;
      _pinError = pinErr;
    });

    final GlobalKey? firstBad = plateErr != null
        ? _plateKey
        : timeErr != null
            ? _timeKey
            : gcashErr != null
                ? _gcashKey
                : pinErr != null
                    ? _pinKey
                    : null;

    if (firstBad != null) {
      final ctx = firstBad.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.2,
        );
      }
      return false;
    }

    return true;
  }

  void _review(String selectedLoadText) {
    if (!_validate()) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfirmAppDriverScreen(
          driverId: widget.driverId,

          // Actual DateTime for Laravel
          preferredDateTime: _selectedDateTime,

          // Truck Used Plate is now the appointment plate number.
          truckUsed: _truckUsedPlateController.text.trim().isEmpty
              ? 'Not specified'
              : _truckUsedPlateController.text.trim(),

          comingFrom: _comingFromController.text.trim().isEmpty
              ? 'Not specified'
              : _comingFromController.text.trim(),

          livestockLoad: selectedLoadText,

          // Use the truck used plate as the plate number.
          plateNumber: _truckUsedPlateController.text.trim().isEmpty
              ? 'Not specified'
              : _truckUsedPlateController.text.trim(),

          // Display version
          preferredTime: _preferredTimeController.text.isEmpty
              ? 'Not specified'
              : _preferredTimeController.text,

          ewalletAccount: _gcashAccountController.text.trim().isEmpty
              ? 'Not specified'
              : _gcashAccountController.text.trim(),

          // PIN is only displayed masked.
          // It will NOT be sent to Laravel.
          ewalletPin: _gcashPinController.text.isEmpty
              ? '****'
              : '•' * _gcashPinController.text.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    final String selectedLoadText =
        _selectedLoadIndex == 0 ? 'Piglets (baby)' : 'Hogs (large / adult)';

    return Scaffold(
      backgroundColor: c.bg,
      bottomNavigationBar: BottomBar(
        child: PrimaryButton(
          label: 'Review appointment',
          onPressed: () => _review(selectedLoadText),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                eyebrow: 'New wash',
                title: 'Appointment details',
                onBack: () => Navigator.pop(context),
              ),

              const SizedBox(height: 18),

              const FlowProgress(step: 1),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // TRUCK & TRIP
              // ------------------------------------------------
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Your truck', style: t.heading),
                    const SizedBox(height: 16),
                    AppField(
                      key: _plateKey,
                      label: 'Truck plate number',
                      controller: _truckUsedPlateController,
                      hint: 'e.g., ABC 1234',
                      icon: Icons.local_shipping_outlined,
                      error: _plateError,
                      capitalization: TextCapitalization.characters,
                      textInputAction: TextInputAction.next,
                      formatters: [
                        UpperCaseFormatter(),
                        LengthLimitingTextInputFormatter(10),
                      ],
                      onChanged: (_) {
                        if (_plateError != null) {
                          setState(() => _plateError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    AppField(
                      label: 'Coming from',
                      optional: true,
                      controller: _comingFromController,
                      hint: 'Barangay or town',
                      icon: Icons.location_on_outlined,
                      capitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.done,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // LIVESTOCK LOAD
              // ------------------------------------------------
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What are you hauling?', style: t.heading),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _LoadOption(
                            title: 'Piglets',
                            subtitle: 'Baby',
                            selected: _selectedLoadIndex == 0,
                            onTap: () => setState(() => _selectedLoadIndex = 0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _LoadOption(
                            title: 'Hogs',
                            subtitle: 'Large / adult',
                            selected: _selectedLoadIndex == 1,
                            onTap: () => setState(() => _selectedLoadIndex = 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // WHEN
              // ------------------------------------------------
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('When are you coming?', style: t.heading),
                    const SizedBox(height: 16),
                    AppField(
                      key: _timeKey,
                      label: 'Preferred date and time',
                      controller: _preferredTimeController,
                      hint: 'Tap to choose',
                      icon: Icons.event_outlined,
                      error: _timeError,
                      readOnly: true,
                      onTap: () => _selectDateTime(context),
                      suffix: Icon(Icons.chevron_right_rounded, color: c.textMuted),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // GCASH PAYMENT
              // ------------------------------------------------
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.account_balance_wallet_outlined, color: c.accent, size: 22),
                        const SizedBox(width: 10),
                        Text('GCash payment', style: t.heading),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppField(
                      key: _gcashKey,
                      label: 'GCash number',
                      controller: _gcashAccountController,
                      hint: '09123456789',
                      icon: Icons.smartphone_rounded,
                      error: _gcashError,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      formatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
                      onChanged: (_) {
                        if (_gcashError != null) {
                          setState(() => _gcashError = null);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    AppField(
                      key: _pinKey,
                      label: 'GCash PIN',
                      controller: _gcashPinController,
                      hint: '4 or 6 digits',
                      icon: Icons.lock_outline_rounded,
                      error: _pinError,
                      obscure: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      maxLength: 6,
                      formatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (_) {
                        if (_pinError != null) {
                          setState(() => _pinError = null);
                        }
                      },
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

/// Big, thumb-friendly choice tile.
class _LoadOption extends StatelessWidget {
  const _LoadOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Semantics(
      button: true,
      selected: selected,
      label: '$title, $subtitle',
      child: ExcludeSemantics(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color: selected ? c.accentSoft : c.field,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected ? c.accent : c.line,
                width: selected ? 2 : 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected ? c.accent : Colors.transparent,
                        border: Border.all(
                          color: selected ? c.accent : c.textFaint,
                          width: 2,
                        ),
                      ),
                      child: selected
                          ? Icon(Icons.check_rounded, size: 16, color: c.onAccent)
                          : null,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(title, style: t.heading.copyWith(fontSize: 20)),
                const SizedBox(height: 2),
                Text(subtitle, style: t.caption.copyWith(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
