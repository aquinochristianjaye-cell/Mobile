import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WashScannerApp());
}

class WashScannerApp extends StatelessWidget {
  const WashScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wash Station Scanner',
      theme: ThemeData.dark(),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanned = false;
  bool _isCheckingIn = false;

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_isScanned || _isCheckingIn) return;

    if (capture.barcodes.isEmpty) return;

    final String? value = capture.barcodes.first.rawValue;

    if (value == null || value.isEmpty) {
      return;
    }

    setState(() {
      _isScanned = true;
      _isCheckingIn = true;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://127.0.0.1:8000/api/driver/check-in',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'qr_code': value,
        }),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final appointment =
            Map<String, dynamic>.from(
          data['appointment'] ?? {},
        );

        final driver =
            Map<String, dynamic>.from(
          appointment['driver'] ?? {},
        );

        final truckPlate =
            appointment['truck_plate'] ??
                'Unknown truck';

        final driverName =
            driver['name'] ??
                'Unknown driver';

        setState(() {
          _isCheckingIn = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Truck $truckPlate arrived.\n'
              'Driver: $driverName',
            ),
            backgroundColor:
                const Color(0xFF1A242C),
            duration:
                const Duration(seconds: 4),
          ),
        );
      } else {
        setState(() {
          _isScanned = false;
          _isCheckingIn = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message'] ??
                  'Check-in failed',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isScanned = false;
        _isCheckingIn = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Connection error: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B131E),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFF0B131E),
        title: const Text(
          'Wash Station Scanner',
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 30),

          const Text(
            'Scan Driver QR Code',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          const Text(
            'Scan the QR when the truck arrives.',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 30),

          Expanded(
            child: Stack(
              children: [
                MobileScanner(
                  onDetect: _handleScan,
                ),

                if (_isCheckingIn)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: Column(
                        mainAxisSize:
                            MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            color: Color(0xFF22B8CF),
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Checking in truck...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 20,
            ),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isCheckingIn
                    ? null
                    : () {
                        setState(() {
                          _isScanned = false;
                        });
                      },
                style:
                    ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF22B8CF),
                  foregroundColor: Colors.black,
                ),
                child: const Text(
                  'SCAN AGAIN',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}