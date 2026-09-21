import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'app_theme.dart';
import 'qr.dart';
import 'widgets.dart';

class ConfirmAppDriverScreen extends StatefulWidget {
  // Driver ID from the logged-in driver
  final int driverId;

  // Actual selected date and time
  final DateTime? preferredDateTime;

  final String truckUsed;
  final String comingFrom;
  final String livestockLoad;
  final String plateNumber;
  final String preferredTime;
  final String ewalletAccount;
  final String ewalletPin;

  const ConfirmAppDriverScreen({
    Key? key,
    required this.driverId,
    required this.preferredDateTime,
    required this.truckUsed,
    required this.comingFrom,
    required this.livestockLoad,
    required this.plateNumber,
    required this.preferredTime,
    required this.ewalletAccount,
    required this.ewalletPin,
  }) : super(key: key);

  @override
  State<ConfirmAppDriverScreen> createState() => _ConfirmAppDriverScreenState();
}

class _ConfirmAppDriverScreenState extends State<ConfirmAppDriverScreen> {
  bool _isSubmitting = false;

  bool get _hasGcash => widget.ewalletAccount != 'Not specified';

  Future<void> _confirmAppointment() async {
    if (_isSubmitting) return;

    // Make sure a date and time was selected.
    if (widget.preferredDateTime == null) {
      _showMessage('Choose a preferred date and time.', error: true);
      return;
    }

    // Make sure the truck plate number is available.
    if (widget.plateNumber.trim().isEmpty ||
        widget.plateNumber == 'Not specified') {
      _showMessage('Enter the truck plate number.', error: true);
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://127.0.0.1:8000/api/driver/appointments'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'driver_id': widget.driverId,
          'truck_plate': widget.plateNumber,
          'coming_from': widget.comingFrom,
          'livestock_load': widget.livestockLoad,
          'preferred_datetime': widget.preferredDateTime!.toIso8601String(),
          'gcash_account': widget.ewalletAccount == 'Not specified'
              ? null
              : widget.ewalletAccount,
        }),
      );

      dynamic data;
      try {
        data = jsonDecode(response.body);
      } catch (_) {
        data = null;
      }

      if (!mounted) return;

      if (response.statusCode == 201 && data is Map) {
        // Get the appointment ID created by Laravel.
        final int appointmentId = data['appointment']['id'];

        // The gate pass is the confirmation. Replace the booking screens
        // so "back" doesn't return to a form that's already been submitted.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => QrCodeDriverScreen(
              driverId: widget.driverId,
              appointmentId: appointmentId,
              plateNumber: widget.plateNumber,
              livestockLoad: widget.livestockLoad,
              preferredTime: widget.preferredTime,
              comingFrom: widget.comingFrom,
            ),
          ),
          (route) => route.isFirst,
        );
      } else {
        String message = 'Couldn\'t submit your appointment. Try again.';

        if (data is Map && data['message'] != null) {
          message = data['message'].toString();
        } else if (data == null) {
          message = 'The server sent an unexpected response. Try again in a moment.';
        }

        _showMessage(message, error: true);
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Can\'t reach the server. Check your connection and make sure Laravel is running.',
        error: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message, {bool error = false}) {
    showAppSnack(context, message, error: error);
  }

  // 09123456789 -> 0912 345 6789
  String get _gcashDisplay {
    final s = widget.ewalletAccount;
    if (s.length == 11) {
      return '${s.substring(0, 4)} ${s.substring(4, 7)} ${s.substring(7)}';
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;

    return Scaffold(
      backgroundColor: c.bg,
      bottomNavigationBar: BottomBar(
        child: PrimaryButton(
          label: 'Confirm appointment',
          loading: _isSubmitting,
          onPressed: _confirmAppointment,
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScreenHeader(
                eyebrow: 'Almost done',
                title: 'Confirm details',
                onBack: _isSubmitting ? null : () => Navigator.pop(context),
              ),

              const SizedBox(height: 18),

              const FlowProgress(step: 2),

              const SizedBox(height: 24),

              // ------------------------------------------------
              // APPOINTMENT
              // ------------------------------------------------
              SurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Appointment', style: t.heading),
                        _EditLink(
                          onTap: _isSubmitting ? null : () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: PlateTag(widget.plateNumber, fontSize: 28),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    _SummaryRow(label: 'Coming from', value: widget.comingFrom),
                    _SummaryRow(label: 'Livestock load', value: widget.livestockLoad),
                    _SummaryRow(label: 'Preferred time', value: widget.preferredTime),
                    const _SummaryRow(
                      label: 'Wash station',
                      value: 'Aquino Truck Wash Station',
                      last: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ------------------------------------------------
              // PAYMENT
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
                    const SizedBox(height: 8),
                    _SummaryRow(label: 'GCash number', value: _gcashDisplay),
                    _SummaryRow(label: 'GCash PIN', value: widget.ewalletPin, last: true),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Only claims automatic payment when a GCash number was added.
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    _hasGcash ? Icons.info_outline_rounded : Icons.warning_amber_rounded,
                    size: 20,
                    color: _hasGcash ? c.textMuted : c.signal,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _hasGcash
                          ? 'Payment is processed through GCash when you confirm this appointment.'
                          : 'No GCash number added, so payment won\'t be taken automatically. Tap Edit to add one.',
                      style: t.caption.copyWith(
                        fontSize: 14,
                        color: _hasGcash ? c.textMuted : c.signal,
                      ),
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

class _EditLink extends StatelessWidget {
  const _EditLink({required this.onTap});
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Semantics(
      button: true,
      label: 'Edit appointment details',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, size: 18, color: onTap == null ? c.textFaint : c.accent),
              const SizedBox(width: 6),
              Text(
                'Edit',
                style: t.label.copyWith(
                  color: onTap == null ? c.textFaint : c.accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.last = false,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final t = context.t;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last ? null : Border(bottom: BorderSide(color: c.line)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: t.bodyMuted.copyWith(fontSize: 15)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: t.body.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
