import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WasteReductionScreen extends StatefulWidget {
  const WasteReductionScreen({super.key});

  @override
  State<WasteReductionScreen> createState() => _WasteReductionScreenState();
}

class _WasteReductionScreenState extends State<WasteReductionScreen> {
  final recyclingController = TextEditingController();
  final compostingController = TextEditingController();
  final plasticController = TextEditingController();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? userId;
  double score = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid;
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (userId == null) return;
    setState(() => isLoading = true);

    try {
      final doc = await _firestore.collection('user_waste').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        recyclingController.text = (data['recycling'] ?? '').toString();
        compostingController.text = (data['composting'] ?? '').toString();
        plasticController.text = (data['plastic'] ?? '').toString();
        setState(() {
          score = _calculateScoreFromData(
            recycling: (data['recycling'] as num?)?.toDouble() ?? 0,
            composting: (data['composting'] as num?)?.toDouble() ?? 0,
            plastic: (data['plastic'] as num?)?.toDouble() ?? 0,
          );
        });
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  double _calculateScoreFromData({required double recycling, required double composting, required double plastic}) {
    return (recycling * 2 + composting * 3) - (plastic * 1.5);
  }

  Future<void> _saveUserData() async {
    if (userId == null) return;
    final recycling = double.tryParse(recyclingController.text) ?? 0;
    final composting = double.tryParse(compostingController.text) ?? 0;
    final plastic = double.tryParse(plasticController.text) ?? 0;

    double newScore = _calculateScoreFromData(
      recycling: recycling,
      composting: composting,
      plastic: plastic,
    );

    await _firestore.collection('user_waste').doc(userId).set({
      'recycling': recycling,
      'composting': composting,
      'plastic': plastic,
      'score': newScore,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() {
      score = newScore;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Progress Updated! 🌱"), backgroundColor: Colors.green),
    );
  }

  String getTip(double value) {
    if (value > 15) return "🌟 Waste Reduction Hero!";
    if (value > 5) return "👍 Great effort, keep going!";
    return "♻️ Small steps lead to big changes!";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Waste Tracker", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), Color(0xFF2E7D32), Color(0xFF43A047)],
              ),
            ),
          ),
          SafeArea(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Column(
                      children: [
                        _buildScoreHeader(),
                        const SizedBox(height: 20),
                        _buildInputCard(),
                        const SizedBox(height: 20),
                        _buildTipsCard(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreHeader() {
    return _buildGlassBox(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text("Your Impact Score", style: TextStyle(color: Colors.white70, fontSize: 16)),
            const SizedBox(height: 5),
            Text(
              score.toStringAsFixed(1),
              style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              getTip(score),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return _buildGlassBox(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Weekly Stats", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildTextField(recyclingController, "Items Recycled", Icons.rebase_edit),
            const SizedBox(height: 15),
            _buildTextField(compostingController, "Composting (kg)", Icons.grass),
            const SizedBox(height: 15),
            _buildTextField(plasticController, "Single-use Plastics", Icons.delete_outline, isNegative: true),
            const SizedBox(height: 25),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveUserData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1B5E20),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 0,
                ),
                child: const Text("UPDATE PROGRESS", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    final tips = [
      "Use reusable bottles & bags.",
      "Compost kitchen waste daily.",
      "Avoid excess packaging.",
      "Buy in bulk to reduce waste."
    ];

    return _buildGlassBox(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.yellow, size: 20),
                SizedBox(width: 10),
                Text("Eco Tips", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 15),
            ...tips.map((tip) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.white70, size: 16),
                      const SizedBox(width: 10),
                      Text(tip, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {bool isNegative = false}) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: isNegative ? Colors.orangeAccent : Colors.white70),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white54),
        ),
      ),
    );
  }

  Widget _buildGlassBox({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}