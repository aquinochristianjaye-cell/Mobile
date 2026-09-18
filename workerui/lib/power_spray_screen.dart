import 'package:flutter/material.dart';
import 'setting_screen.dart';
import 'services/station_supply_service.dart';

class PowerSprayScreen extends StatefulWidget {
  const PowerSprayScreen({super.key});

  @override
  State<PowerSprayScreen> createState() => _PowerSprayScreenState();
}

class _PowerSprayScreenState extends State<PowerSprayScreen> {
  static const bgCream = Color(0xFFF3EFE7);
  static const darkText = Color(0xFF13233F);
  static const tealHeader = Color(0xFF1F7A8C);
  static const tealButton = Color(0xFF146B70);
  static const greenBar = Color(0xFF7CB342);
  static const orangeBar = Color(0xFFE6A135);
  static const redBar = Color(0xFFD9534F);
  static const cardBg = Colors.white;

  // Shared station supply levels
  double foamWashLevel = 0;
  double disinfectantLevel = 0;
  double waterLevel = 0;

  bool isLoading = true;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSupplies();
  }

  // Load supply levels from Laravel/MySQL
  Future<void> _loadSupplies() async {
    try {
      final supplies =
          await StationSupplyService.getSupplies();

      if (!mounted) return;

      setState(() {
        foamWashLevel =
            supplies['Foam Wash'] ?? 0;

        disinfectantLevel =
            supplies['Disinfectant'] ?? 0;

        waterLevel =
            supplies['Water'] ?? 0;

        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Failed to load supply levels.',
          ),
        ),
      );
    }
  }

  Color _getBarColor(double value) {
    if (value <= 20) return redBar;
    if (value <= 50) return orangeBar;
    return greenBar;
  }

  String _getSubtitle(double value) {
    if (value <= 20) {
      return 'Low supply level';
    }

    if (value <= 50) {
      return 'Running low';
    }

    return 'Normal supply level';
  }

  void _showUpdateModal() {
    double tempFoamWash = foamWashLevel;
    double tempDisinfectant = disinfectantLevel;
    double tempWater = waterLevel;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext modalContext) {
        return StatefulBuilder(
          builder: (
            BuildContext context,
            StateSetter setModalState,
          ) {
            return Container(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom:
                    MediaQuery.of(modalContext)
                            .viewInsets
                            .bottom +
                        20,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Handle Bar
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color:
                              Colors.grey.shade300,
                          borderRadius:
                              BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    const Text(
                      'Update station supplies',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: darkText,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Foam Wash
                    _buildSliderRow(
                      'Foam Wash',
                      tempFoamWash,
                      (val) {
                        setModalState(() {
                          tempFoamWash = val;
                        });
                      },
                    ),

                    // Disinfectant
                    _buildSliderRow(
                      'Disinfectant',
                      tempDisinfectant,
                      (val) {
                        setModalState(() {
                          tempDisinfectant = val;
                        });
                      },
                    ),

                    // Water
                    _buildSliderRow(
                      'Water',
                      tempWater,
                      (val) {
                        setModalState(() {
                          tempWater = val;
                        });
                      },
                    ),

                    const SizedBox(height: 12),

                    // Buttons
                    Row(
                      children: [
                        // CANCEL
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pop(
                                  modalContext,
                                );
                              },
                              style:
                                  OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color:
                                      Colors.grey.shade300,
                                ),
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    12,
                                  ),
                                ),
                              ),
                              child: const Text(
                                'CANCEL',
                                style: TextStyle(
                                  color: darkText,
                                  fontWeight:
                                      FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // SAVE UPDATE
                        Expanded(
                          child: SizedBox(
                            height: 48,
                            child: ElevatedButton(
                              onPressed: isSaving
                                  ? null
                                  : () async {
                                      setModalState(() {
                                        isSaving = true;
                                      });

                                      try {
                                        await StationSupplyService
                                            .updateSupplies(
                                          foamWash:
                                              tempFoamWash,
                                          disinfectant:
                                              tempDisinfectant,
                                          water:
                                              tempWater,
                                        );

                                        if (!mounted) {
                                          return;
                                        }

                                        setState(() {
                                          foamWashLevel =
                                              tempFoamWash;

                                          disinfectantLevel =
                                              tempDisinfectant;

                                          waterLevel =
                                              tempWater;

                                          isSaving = false;
                                        });

                                        Navigator.pop(
                                          modalContext,
                                        );

                                        ScaffoldMessenger.of(
                                          this.context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                              'Supply levels updated successfully.',
                                            ),
                                          ),
                                        );
                                      } catch (e) {
                                        setModalState(() {
                                          isSaving = false;
                                        });

                                        ScaffoldMessenger.of(
                                          this.context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString(),
                                            ),
                                          ),
                                        );
                                      }
                                    },
                              style:
                                  ElevatedButton.styleFrom(
                                backgroundColor:
                                    tealButton,
                                foregroundColor:
                                    Colors.white,
                                elevation: 0,
                                shape:
                                    RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(
                                    12,
                                  ),
                                ),
                              ),
                              child: isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child:
                                          CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color:
                                            Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'SAVE UPDATE',
                                      style: TextStyle(
                                        fontWeight:
                                            FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSliderRow(
    String label,
    double value,
    ValueChanged<double> onChanged,
  ) {
    final color = _getBarColor(value);

    return Column(
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkText,
              ),
            ),
            Text(
              '${value.round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),

        SliderTheme(
          data: SliderThemeData(
            trackHeight: 6,
            activeTrackColor: tealButton,
            inactiveTrackColor:
                const Color(0xFFECE6D8),
            thumbColor: tealButton,
            overlayColor:
                tealButton.withValues(alpha: 0.1),
            thumbShape:
                const RoundSliderThumbShape(
              enabledThumbRadius: 10,
              elevation: 2,
            ),
          ),
          child: Slider(
            value: value.clamp(0, 100),
            min: 0,
            max: 100,
            divisions: 100,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

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
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 16.0,
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: darkText,
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                        Expanded(
                          child: _buildHeader(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'POWER SPRAY STATION',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: darkText.withValues(
                          alpha: 0.6,
                        ),
                        letterSpacing: 0.8,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Levels Card
                    _buildStationCard(),

                    const SizedBox(height: 24),

                    // UPDATE Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                _showUpdateModal();
                              },
                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor: darkText,
                          foregroundColor:
                              Colors.white,
                          elevation: 0,
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),
                        ),
                        child: const Text(
                          'UPDATE',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight:
                                FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F1F2),
        borderRadius:
            BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: const [
              Text(
                'Hi Logan,',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Good evening',
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
              backgroundColor:
                  Color(0xFFDCD2C0),
              child: Text(
                'LM',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: darkText,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStationCard() {
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(30),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius:
              BorderRadius.circular(20),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: tealButton,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius:
            BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black.withValues(
              alpha: 0.03,
            ),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildItemRow(
            'Foam Wash',
            foamWashLevel,
          ),

          const SizedBox(height: 18),

          _buildItemRow(
            'Disinfectant',
            disinfectantLevel,
          ),

          const SizedBox(height: 18),

          _buildItemRow(
            'Water',
            waterLevel,
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(
    String title,
    double level,
  ) {
    final color = _getBarColor(level);
    final subtitle = _getSubtitle(level);

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment:
              MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: darkText,
              ),
            ),

            Text(
              '${level.round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: darkText.withValues(
                  alpha: 0.8,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 6),

        ClipRRect(
          borderRadius:
              BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: level / 100,
            minHeight: 10,
            backgroundColor:
                const Color(0xFFECE6D8),
            valueColor:
                AlwaysStoppedAnimation<Color>(
              color,
            ),
          ),
        ),

        const SizedBox(height: 4),

        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: darkText.withValues(
              alpha: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}