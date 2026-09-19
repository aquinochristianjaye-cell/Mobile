import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'qr.dart';
import 'settings.dart';

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
  State<ConfirmAppDriverScreen> createState() =>
      _ConfirmAppDriverScreenState();
}

class _ConfirmAppDriverScreenState
    extends State<ConfirmAppDriverScreen> {
  bool _isSubmitting = false;

  Future<void> _confirmAppointment() async {
    // Make sure a date and time was selected.
    if (widget.preferredDateTime == null) {
      _showMessage('Please select a preferred date and time.');
      return;
    }

    // Make sure the truck plate number is available.
    if (widget.plateNumber.trim().isEmpty ||
        widget.plateNumber == 'Not specified') {
      _showMessage('Please enter the truck plate number.');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/api/driver/appointments',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'driver_id': widget.driverId,
          'truck_plate': widget.plateNumber,
          'coming_from': widget.comingFrom,
          'livestock_load': widget.livestockLoad,
          'preferred_datetime':
              widget.preferredDateTime!.toIso8601String(),
          'gcash_account': widget.ewalletAccount == 'Not specified'
              ? null
              : widget.ewalletAccount,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 201) {
        // Get the appointment ID created by Laravel.
        final int appointmentId =
            data['appointment']['id'];

        _showMessage('Appointment submitted successfully!');

        // Give the SnackBar a moment to appear.
        await Future.delayed(
          const Duration(milliseconds: 500),
        );

        if (!mounted) return;

        // Open the QR screen with the actual appointment ID.
        Navigator.pushReplacement(
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
        );
      } else {
        String message = 'Failed to submit appointment.';

        if (data['message'] != null) {
          message = data['message'];
        }

        _showMessage(message);
      }
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Unable to connect to the server. Make sure Laravel is running.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF1A242C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B131E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar with Back Button and Profile Avatar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          SizedBox(height: 2),
                          Text(
                            'Confirm details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Profile Avatar with Navigation to Settings
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const SettingsDriverScreen(),
                        ),
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Text(
                        'LM',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Summary White Card Container
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ListView(
                    children: [
                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'APPOINTMENT & PAYMENT',
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1,
                            ),
                          ),

                          GestureDetector(
                            onTap: _isSubmitting
                                ? null
                                : () => Navigator.pop(context),
                            child: const Text(
                              'EDIT',
                              style: TextStyle(
                                color: Color(0xFFD97706),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const Divider(height: 24),

                      _buildSummaryRow(
                        'Truck Used',
                        widget.truckUsed,
                      ),

                      _buildSummaryRow(
                        'Coming from',
                        widget.comingFrom,
                      ),

                      _buildSummaryRow(
                        'Livestock load',
                        widget.livestockLoad,
                      ),

                      _buildSummaryRow(
                        'Plate number',
                        widget.plateNumber,
                      ),

                      _buildSummaryRow(
                        'Preferred time',
                        widget.preferredTime,
                      ),

                      _buildSummaryRow(
                        'Wash station',
                        'Aquino Truck Wash Station',
                      ),

                      const Divider(height: 24),

                      const Text(
                        'GCASH PAYMENT DETAILS',
                        style: TextStyle(
                          color: Colors.black45,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),

                      const SizedBox(height: 8),

                      _buildSummaryRow(
                        'GCash Number',
                        widget.ewalletAccount,
                      ),

                      _buildSummaryRow(
                        'GCash PIN',
                        widget.ewalletPin,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Payment will be processed automatically via GCash upon confirming this appointment.',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),

              const SizedBox(height: 16),

              // Confirm Appointment Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF133254),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed:
                      _isSubmitting ? null : _confirmAppointment,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'CONFIRM APPOINTMENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),

          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
