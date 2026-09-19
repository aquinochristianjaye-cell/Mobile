import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'settings.dart';
import 'dashboard_driver.dart';

class QrCodeDriverScreen extends StatelessWidget {
  final int driverId;
  final int appointmentId;
  final String plateNumber;
  final String livestockLoad;
  final String preferredTime;
  final String comingFrom;

  const QrCodeDriverScreen({
    Key? key,
    required this.driverId,
    required this.appointmentId,
    required this.plateNumber,
    required this.livestockLoad,
    required this.preferredTime,
    required this.comingFrom,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This is the information encoded inside the QR code.
    final String qrData = 'WASH-APPOINTMENT-$appointmentId';

    return Scaffold(
      backgroundColor: const Color(0xFF0B131E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      SizedBox(height: 2),
                      Text(
                        'Appointment QR',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
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

              // QR Card
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Scan at Wash Station',
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Text(
                        'Present this QR code upon arrival',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      // REAL QR CODE
                      Container(
                        width: 220,
                        height: 220,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.black12,
                          ),
                        ),
                        child: QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 200,
                          backgroundColor: Colors.white,
                          errorCorrectionLevel: QrErrorCorrectLevel.M,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Text(
                        'Appointment #$appointmentId',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        qrData,
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Quick info summary
                      Text(
                        'Plate: $plateNumber',
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Load: $livestockLoad',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        'Time: $preferredTime',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Done / Home Button
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
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MainScreenDriver(
                          driverId: driverId,
                          appointmentId: appointmentId,
                          plateNumber: plateNumber,
                          livestockLoad: livestockLoad,
                          preferredTime: preferredTime,
                          comingFrom: comingFrom,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'DONE',
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
}