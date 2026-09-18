import 'package:flutter/material.dart';
import 'con_app.dart';
import 'settings.dart';

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
  final TextEditingController _truckUsedPlateController =
      TextEditingController();
  final TextEditingController _comingFromController = TextEditingController();
  final TextEditingController _plateNumberController = TextEditingController();
  final TextEditingController _preferredTimeController =
      TextEditingController();

  // Stores the actual selected date and time for Laravel
  DateTime? _selectedDateTime;

  // GCash Controllers
  final TextEditingController _gcashAccountController =
      TextEditingController();
  final TextEditingController _gcashPinController = TextEditingController();

  @override
  void dispose() {
    _truckUsedPlateController.dispose();
    _comingFromController.dispose();
    _plateNumberController.dispose();
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      if (!mounted) return;

      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        final hours = pickedTime.hourOfPeriod == 0
            ? 12
            : pickedTime.hourOfPeriod;

        final period =
            pickedTime.period == DayPeriod.am ? 'AM' : 'PM';

        final minutes =
            pickedTime.minute.toString().padLeft(2, '0');

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

        final String monthName =
            months[pickedDate.month - 1];

        setState(() {
          // Save the actual date and time
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          // Keep the readable version for the UI
          _preferredTimeController.text =
              '$monthName ${pickedDate.day}, $hours:$minutes $period';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String selectedLoadText = _selectedLoadIndex == 0
        ? 'Piglets (baby)'
        : 'Hogs (large / adult)';

    return Scaffold(
      backgroundColor: const Color(0xFF0B131E),
      body: SafeArea(
        child: SingleChildScrollView(
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
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'New wash',
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Appointment details',
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

              const SizedBox(height: 24),

              // Truck Used Plate
              const Text(
                'TRUCK USED PLATE',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 6),

              TextField(
                controller: _truckUsedPlateController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Enter truck used plate',
                  hintStyle:
                      const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Coming From
              const Text(
                'COMING FROM',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 6),

              TextField(
                controller: _comingFromController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Enter origin barangay / town',
                  hintStyle:
                      const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Livestock Load selection cards
              const Text(
                'LIVESTOCK LOAD',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedLoadIndex = 0),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedLoadIndex == 0
                              ? const Color(0xFFE2ECF8)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedLoadIndex == 0
                                ? const Color(0xFF22B8CF)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: const [
                            Text(
                              'Piglets',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Baby',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedLoadIndex = 1),
                      child: Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: _selectedLoadIndex == 1
                              ? const Color(0xFFE2ECF8)
                              : Colors.white,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedLoadIndex == 1
                                ? const Color(0xFF22B8CF)
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: const [
                            Text(
                              'Hogs',
                              style: TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Large / adult',
                              style: TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Truck Plate Number
              const Text(
                'TRUCK PLATE NUMBER',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 6),

              TextField(
                controller: _plateNumberController,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Enter plate number',
                  hintStyle:
                      const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Preferred Time Picker Field
              const Text(
                'PREFERRED TIME',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 6),

              TextField(
                controller: _preferredTimeController,
                readOnly: true,
                onTap: () => _selectDateTime(context),
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Select date & time',
                  hintStyle:
                      const TextStyle(color: Colors.black38),
                  suffixIcon: const Icon(
                    Icons.calendar_today,
                    color: Colors.black54,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // --- GCASH PAYMENT SECTION ---
              const Text(
                'GCASH PAYMENT',
                style: TextStyle(
                  color: Color(0xFF22B8CF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'GCASH ACCOUNT NUMBER',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 6),

              TextField(
                controller: _gcashAccountController,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'e.g., 09123456789',
                  hintStyle:
                      const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'GCASH PIN',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 10,
                  letterSpacing: 1.1,
                ),
              ),

              const SizedBox(height: 6),

              TextField(
                controller: _gcashPinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: const TextStyle(color: Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Enter 4 or 6-digit PIN',
                  hintStyle:
                      const TextStyle(color: Colors.black38),
                  filled: true,
                  fillColor: Colors.white,
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Review Appointment Button
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ConfirmAppDriverScreen(
                          driverId: widget.driverId,

                          // Actual DateTime for Laravel
                          preferredDateTime: _selectedDateTime,

                          truckUsed:
                              _truckUsedPlateController.text.isEmpty
                                  ? 'Not specified'
                                  : _truckUsedPlateController.text,

                          comingFrom:
                              _comingFromController.text.isEmpty
                                  ? 'Not specified'
                                  : _comingFromController.text,

                          livestockLoad: selectedLoadText,

                          plateNumber:
                              _plateNumberController.text.isEmpty
                                  ? 'Not specified'
                                  : _plateNumberController.text,

                          // Display version
                          preferredTime:
                              _preferredTimeController.text.isEmpty
                                  ? 'Not specified'
                                  : _preferredTimeController.text,

                          ewalletAccount:
                              _gcashAccountController.text.isEmpty
                                  ? 'Not specified'
                                  : _gcashAccountController.text,

                          // PIN is only displayed masked.
                          // It will NOT be sent to Laravel.
                          ewalletPin:
                              _gcashPinController.text.isEmpty
                                  ? '****'
                                  : '•' *
                                      _gcashPinController.text.length,
                        ),
                      ),
                    );
                  },
                  child: const Text(
                    'REVIEW APPOINTMENT',
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
