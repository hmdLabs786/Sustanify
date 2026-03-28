import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

class CarbonFootprintScreen extends StatefulWidget {
  const CarbonFootprintScreen({super.key});

  @override
  State<CarbonFootprintScreen> createState() => _CarbonFootprintScreenState();
}

class _CarbonFootprintScreenState extends State<CarbonFootprintScreen> {
  final transportController = TextEditingController();
  final energyController = TextEditingController();
  final foodController = TextEditingController();

  double transportCO2 = 0;
  double energyCO2 = 0;
  double foodCO2 = 0;
  double totalFootprint = 0;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  final Color primaryGreen = const Color(0xFF1B5E20);

  String get userId => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() async {
    try {
      final doc = await _firestore.collection('carbon_footprints').doc(userId).get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          transportCO2 = (data['transportCO2'] ?? 0).toDouble();
          energyCO2 = (data['energyCO2'] ?? 0).toDouble();
          foodCO2 = (data['foodCO2'] ?? 0).toDouble();
          totalFootprint = (data['totalFootprint'] ?? 0).toDouble();
          transportController.text = (data['transport'] ?? '').toString();
          energyController.text = (data['energy'] ?? '').toString();
          foodController.text = (data['food'] ?? '').toString();
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  void _calculateFootprint() {
    final transport = double.tryParse(transportController.text) ?? 0;
    final energy = double.tryParse(energyController.text) ?? 0;
    final food = double.tryParse(foodController.text) ?? 0;

    setState(() {
      transportCO2 = transport * 0.12;
      energyCO2 = energy * 0.85;
      foodCO2 = food * 2.5;
      totalFootprint = transportCO2 + energyCO2 + foodCO2;
    });

    final carbonProgress = (1 - (totalFootprint / 50)).clamp(0.0, 1.0);

    _firestore.collection('carbon_footprints').doc(userId).set({
      'transport': transport,
      'energy': energy,
      'food': food,
      'transportCO2': transportCO2,
      'energyCO2': energyCO2,
      'foodCO2': foodCO2,
      'totalFootprint': totalFootprint,
      'carbonProgress': carbonProgress,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Widget _glassBox({required Widget child, double opacity = 0.3}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Footprint Tracker", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E7D32), Color(0xFF81C784)], // Darker top for AppBar visibility
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                children: [
                  _glassBox(
                    opacity: 0.8,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Icon(Icons.eco, color: primaryGreen, size: 40),
                          const SizedBox(width: 20),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Daily CO₂ Impact", style: TextStyle(fontSize: 14, color: Colors.black54)),
                              Text(
                                "${totalFootprint.toStringAsFixed(2)} kg",
                                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _glassBox(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildGlassInput("Car Distance", "km", transportController, Icons.directions_car),
                          const SizedBox(height: 12),
                          _buildGlassInput("Electricity", "kWh", energyController, Icons.bolt),
                          const SizedBox(height: 12),
                          _buildGlassInput("Meat Meals", "count", foodController, Icons.restaurant),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _calculateFootprint,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryGreen,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("Calculate", style: TextStyle(color: Colors.white, fontSize: 16)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (totalFootprint > 0)
                    _glassBox(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const Text("Breakdown", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            SizedBox(height: 200, child: _buildPieChart()),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInput(String label, String unit, TextEditingController controller, IconData icon) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)), // Hardcoded color for safety
        labelText: "$label ($unit)",
        filled: true,
        fillColor: Colors.white.withOpacity(0.5),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildPieChart() {
    // If all values are 0, don't show chart
    if (totalFootprint == 0) return const SizedBox();

    return PieChart(
      PieChartData(
        sections: [
          PieChartSectionData(color: Colors.green, value: transportCO2, title: 'Car', radius: 50, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.orange, value: energyCO2, title: 'Energy', radius: 50, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
          PieChartSectionData(color: Colors.redAccent, value: foodCO2, title: 'Food', radius: 50, titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
        ],
      ),
    );
  }
}