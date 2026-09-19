import 'package:flutter/material.dart';
import 'appoint.dart';
import 'settings.dart';

class MainScreenDriver extends StatelessWidget {
  final int driverId;

  // Appointment information
  final int? appointmentId;
  final String? plateNumber;
  final String? livestockLoad;
  final String? preferredTime;
  final String? comingFrom;

  const MainScreenDriver({
    Key? key,
    required this.driverId,
    this.appointmentId,
    this.plateNumber,
    this.livestockLoad,
    this.preferredTime,
    this.comingFrom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // The Current Unit only appears when an appointment exists.
    final bool hasAppointment = appointmentId != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0B131E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Hi Logan,',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Good evening',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

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
                      width: 44,
                      height: 44,
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

              // CURRENT UNIT
              if (hasAppointment) ...[
                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'CURRENT UNIT',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 10,
                          letterSpacing: 1.1,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Row(
                        mainAxisAlignment:
                            MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '#${plateNumber ?? 'Unknown'}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.orange.shade700,
                              borderRadius:
                                  BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Driving',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      Text(
                        comingFrom ?? 'Location not specified',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        '$livestockLoad • $preferredTime',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // NEW APPOINTMENT BUTTON
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF162A45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SetAppDriverScreen(
                          driverId: driverId,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'SET NEW WASH APPOINTMENT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'RECENT DELIVERIES',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 11,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 12),

              Expanded(
                child: ListView(
                  children: [
                    _buildDeliveryItem(
                      '#CAV 1234',
                      '27 Aug • Cuyapo, Nueva Ecija',
                    ),

                    const SizedBox(height: 12),

                    _buildDeliveryItem(
                      '#CAV 1234',
                      '28 Aug • Lupao, Nueva Ecija',
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

  Widget _buildDeliveryItem(
    String unit,
    String details,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                unit,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                details,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                ),
              ),
            ],
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFD4EDDA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Delivered',
              style: TextStyle(
                color: Color(0xFF155724),
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}