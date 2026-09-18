import 'package:flutter/material.dart';
import 'setting_screen.dart';

class WashingScreen extends StatelessWidget {
  final Map<String, dynamic> appointment;

  const WashingScreen({
    super.key,
    required this.appointment,
  });

  static const bgCream = Color(0xFFF3EFE7);
  static const darkText = Color(0xFF13233F);
  static const tealHeader = Color(0xFF1F7A8C);
  static const greenButton = Color(0xFF81C784);
  static const cardBg = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgCream,
      body: SafeArea(
        child: Column(
          children: [
            // Top Accent Bar
            Container(
              height: 8,
              width: double.infinity,
              color: tealHeader,
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Greeting
                    _buildHeader(context),

                    const SizedBox(height: 32),

                    // Truck Details Card
                    _buildTruckInfoCard(),

                    const Spacer(),

                    // Finish Washing Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: greenButton,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'COMPLETE WASHING',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final driver = appointment['driver'] ?? {};

    final driverName =
        driver['name'] ?? 'Unknown driver';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Driver: $driverName',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 2),

              const Text(
                'Truck Washing',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: darkText,
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
                      const SettingsScreen(),
                ),
              );
            },
            child: const CircleAvatar(
              radius: 24,
              backgroundColor: Color(0xFFDCD2C0),
              child: Icon(
                Icons.local_shipping,
                color: darkText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTruckInfoCard() {
    // Get information from Laravel appointment
    final truckPlate =
        appointment['truck_plate'] ?? 'Unknown';

    final comingFrom =
        appointment['coming_from'] ?? 'Unknown';

    final livestockLoad =
        appointment['livestock_load'] ?? 'Unknown';

    final preferredDateTime =
        appointment['preferred_datetime'] ?? 'Unknown';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 24,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'TRUCK INFORMATION',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              color: darkText.withValues(alpha: 0.7),
            ),
          ),

          const SizedBox(height: 20),

          // Truck
          _buildInfoRow(
            'Truck',
            truckPlate,
            isRightAligned: true,
          ),

          const Divider(
            height: 24,
            thickness: 0.8,
          ),

          // Coming from
          _buildInfoRow(
            'Coming from',
            comingFrom,
          ),

          const Divider(
            height: 24,
            thickness: 0.8,
          ),

          // Livestock load
          _buildInfoRow(
            'Livestock load',
            livestockLoad,
          ),

          const Divider(
            height: 24,
            thickness: 0.8,
          ),

          // Plate number
          _buildInfoRow(
            'Plate number',
            truckPlate,
          ),

          const Divider(
            height: 24,
            thickness: 0.8,
          ),

          // Preferred departure
          _buildInfoRow(
            'Preferred time to depart',
            preferredDateTime,
            isSmallLabel: true,
          ),

          const Divider(
            height: 24,
            thickness: 0.8,
          ),

          // Destination is not currently stored
          // in the appointments table.
          _buildInfoRow(
            'Next Destination',
            'Not provided',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isRightAligned = false,
    bool isSmallLabel = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallLabel ? 11 : 13,
            color: darkText.withValues(alpha: 0.6),
            fontWeight: FontWeight.w500,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: darkText,
            ),
          ),
        ),
      ],
    );
  }
}