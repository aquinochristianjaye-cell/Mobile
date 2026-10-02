import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const WashScannerApp());
}

// ---------------------------------------------------------------------------
// Theme
// ---------------------------------------------------------------------------

class AppColors {
  static const bg = Color(0xFF0B131E);
  static const surface = Color(0xFF141F2C);
  static const surfaceAlt = Color(0xFF1A242C);
  static const accent = Color(0xFF22B8CF);
  static const accentDim = Color(0xFF16838F);
  static const textPrimary = Colors.white;
  static const textSecondary = Colors.white60;
  static const success = Color(0xFF2ECC71);
  static const error = Color(0xFFE74C3C);
}

class WashScannerApp extends StatelessWidget {
  const WashScannerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Wash Station Scanner',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.bg,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
      ),
      home: const ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

enum _CheckInStatus { idle, scanning, success, error }

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isScanned = false;
  bool _isCheckingIn = false;
  _CheckInStatus _status = _CheckInStatus.idle;
  String? _statusMessage;
  String? _truckPlate;
  String? _driverName;

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_isScanned || _isCheckingIn) return;
    if (capture.barcodes.isEmpty) return;

    final String? value = capture.barcodes.first.rawValue;
    if (value == null || value.isEmpty) return;

    setState(() {
      _isScanned = true;
      _isCheckingIn = true;
      _status = _CheckInStatus.scanning;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'http://192.168.100.253:8000/api/driver/check-in',
        ),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'qr_code': value}),
      );

      final data = jsonDecode(response.body);

      if (!mounted) return;

      if (response.statusCode == 200) {
        final appointment =
            Map<String, dynamic>.from(data['appointment'] ?? {});

        final driver =
            Map<String, dynamic>.from(appointment['driver'] ?? {});

        setState(() {
          _isCheckingIn = false;
          _status = _CheckInStatus.success;
          _truckPlate =
              appointment['truck_plate'] ?? 'Unknown truck';
          _driverName =
              driver['name'] ?? 'Unknown driver';
        });
      } else {
        setState(() {
          _isScanned = false;
          _isCheckingIn = false;
          _status = _CheckInStatus.error;
          _statusMessage =
              data['message'] ?? 'Check-in failed';
        });
      }
    } catch (e) {
      debugPrint('SCANNER CHECK-IN ERROR: $e');

      if (!mounted) return;

      setState(() {
        _isScanned = false;
        _isCheckingIn = false;
        _status = _CheckInStatus.error;
        _statusMessage = 'Connection error: $e';
      });
    }
  }

  void _reset() {
    setState(() {
      _isScanned = false;
      _isCheckingIn = false;
      _status = _CheckInStatus.idle;
      _statusMessage = null;
      _truckPlate = null;
      _driverName = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              Icons.local_car_wash_rounded,
              color: AppColors.accent,
              size: 20,
            ),
            SizedBox(width: 8),
            Text('Wash Station Scanner'),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            _buildHeader(),
            const SizedBox(height: 20),
            Expanded(child: _buildScannerCard()),
            const SizedBox(height: 16),
            _buildStatusBanner(),
            const SizedBox(height: 16),
            _buildActionButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Scan Driver QR Code',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Hold the code steady inside the frame when the truck arrives.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScannerCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white10,
              width: 1,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              MobileScanner(
                onDetect: _handleScan,
              ),

              // Dark vignette so the frame guide pops.
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.center,
                      radius: 0.9,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.35),
                      ],
                    ),
                  ),
                ),
              ),

              // Corner-bracket scan guide.
              if (!_isCheckingIn &&
                  _status == _CheckInStatus.idle)
                const Center(
                  child: _ScanFrame(size: 220),
                ),

              if (_isCheckingIn)
                Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 44,
                          height: 44,
                          child: CircularProgressIndicator(
                            color: AppColors.accent,
                            strokeWidth: 3,
                          ),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Checking in truck…',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_status == _CheckInStatus.success)
                Container(
                  color: Colors.black.withValues(alpha: 0.65),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Truck $_truckPlate arrived',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Driver: $_driverName',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    if (_status != _CheckInStatus.error ||
        _statusMessage == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _statusMessage!,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final bool showReset =
        _status == _CheckInStatus.success ||
        _status == _CheckInStatus.error;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: _isCheckingIn ? null : _reset,
          icon: Icon(
            showReset
                ? Icons.qr_code_scanner_rounded
                : Icons.refresh_rounded,
            size: 20,
          ),
          label: Text(
            showReset ? 'SCAN NEXT TRUCK' : 'SCAN AGAIN',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            disabledBackgroundColor:
                AppColors.accent.withValues(alpha: 0.3),
            foregroundColor: Colors.black,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Corner-bracket scan frame overlay
// ---------------------------------------------------------------------------

class _ScanFrame extends StatelessWidget {
  final double size;

  const _ScanFrame({required this.size});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _ScanFramePainter(
          color: AppColors.accent,
        ),
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  final Color color;

  _ScanFramePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const double strokeWidth = 4;
    const double cornerLength = 28;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    void corner(
      Offset origin,
      Offset dx,
      Offset dy,
    ) {
      canvas.drawLine(
        origin,
        origin + dx,
        paint,
      );

      canvas.drawLine(
        origin,
        origin + dy,
        paint,
      );
    }

    // Top-left
    corner(
      const Offset(0, 0),
      const Offset(cornerLength, 0),
      const Offset(0, cornerLength),
    );

    // Top-right
    corner(
      Offset(size.width, 0),
      const Offset(-cornerLength, 0),
      const Offset(0, cornerLength),
    );

    // Bottom-left
    corner(
      Offset(0, size.height),
      const Offset(cornerLength, 0),
      const Offset(0, -cornerLength),
    );

    // Bottom-right
    corner(
      Offset(size.width, size.height),
      const Offset(-cornerLength, 0),
      const Offset(0, -cornerLength),
    );
  }

  @override
  bool shouldRepaint(
    covariant _ScanFramePainter oldDelegate,
  ) =>
      false;
}