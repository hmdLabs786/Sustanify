import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SustainabilityDashboardScreen extends StatefulWidget {
  const SustainabilityDashboardScreen({super.key});

  @override
  State<SustainabilityDashboardScreen> createState() => _SustainabilityDashboardScreenState();
}

class _SustainabilityDashboardScreenState extends State<SustainabilityDashboardScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String? userId;
  double carbonProgress = 0;
  double wasteProgress = 0;
  double challengesProgress = 0;
  double overallProgressPercentage = 0;
  bool isLoading = true;

  static const Color primaryGreen = Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid;
    if (userId != null) _loadProgress();
  }

  Future<void> _loadProgress() async {
    setState(() => isLoading = true);
    try {
      // 1. Carbon Footprint
      final carbonDoc = await _firestore.collection("carbon_footprints").doc(userId).get();
      if (carbonDoc.exists) {
        final data = carbonDoc.data()!;
        double totalValue = 0;
        var raw = data['totalFootprint'];
        if (raw is num) {
          totalValue = raw.toDouble();
        } else if (raw is String) totalValue = double.tryParse(raw) ?? 0;
        carbonProgress = (1 - (totalValue / 50)).clamp(0.0, 1.0);
      }

      // 2. Waste Reduction
      final wasteDoc = await _firestore.collection("user_waste").doc(userId).get();
      if (wasteDoc.exists) {
        final d = wasteDoc.data()!;
        final recycling = (d['recycling'] ?? 0).toDouble();
        final composting = (d['composting'] ?? 0).toDouble();
        final plastic = (d['plastic'] ?? 0).toDouble();
        final score = (recycling * 2 + composting * 3) - (plastic * 1.5);
        wasteProgress = (score / 20).clamp(0.0, 1.0);
      }

      // 3. Challenges
      final challengesSnapshot = await _firestore.collection("sustainable_challenges").get();
      double totalCP = 0;
      int challengeCount = 0;
      for (var c in challengesSnapshot.docs) {
        final userP = await c.reference.collection("users_progress").doc(userId).get();
        if (userP.exists) {
          totalCP += (userP['progress'] ?? 0).toDouble();
          challengeCount++;
        }
      }
      challengesProgress = challengeCount > 0 ? (totalCP / challengeCount) : 0;

      // Calculate & Save
      overallProgressPercentage = ((carbonProgress + wasteProgress + challengesProgress) / 3).clamp(0.0, 1.0);
      await _firestore.collection("user_progress").doc(userId).set({
        'overallProgress': overallProgressPercentage,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
    } catch (e) {
      debugPrint("Error: $e");
    }
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Stack(
        children: [
          // Background Decor
          Positioned(top: -100, right: -100, child: _buildBlob(300, primaryGreen.withOpacity(0.1))),
          Positioned(bottom: -50, left: -100, child: _buildBlob(250, Colors.teal.withOpacity(0.05))),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 100,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: const FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text("MY FOOTPRINT", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              
              SliverToBoxAdapter(
                child: isLoading 
                  ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: primaryGreen)))
                  : Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          if (overallProgressPercentage > 0.70) _buildCongratsBadge(),
                          const SizedBox(height: 10),
                          _buildCircularSummary(overallProgressPercentage),
                          const SizedBox(height: 30),
                          
                          _buildProgressTile("Carbon Footprint", carbonProgress, Colors.teal, Icons.eco),
                          _buildProgressTile("Waste Reduction", wasteProgress, Colors.orange, Icons.delete_outline),
                          _buildProgressTile("Eco Challenges", challengesProgress, Colors.lightGreen, Icons.bolt),
                          
                          const SizedBox(height: 30),
                          _buildRefreshButton(),
                          const SizedBox(height: 50),
                        ],
                      ),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularSummary(double progress) {
    return _glassMorphicWrapper(
      borderRadius: BorderRadius.circular(30),
      child: Container(
        padding: const EdgeInsets.all(25),
        width: double.infinity,
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 12,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    color: primaryGreen,
                    strokeCap: StrokeCap.round,
                  ),
                ),
                Text("${(progress * 100).toStringAsFixed(0)}%", 
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: primaryGreen)),
              ],
            ),
            const SizedBox(height: 20),
            const Text("SUSTAINABILITY SCORE", 
              style: TextStyle(fontWeight: FontWeight.w800, color: Colors.black45, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressTile(String title, double progress, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: _glassMorphicWrapper(
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  Text("${(progress * 100).toStringAsFixed(0)}%", style: TextStyle(color: color, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.white.withOpacity(0.3),
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCongratsBadge() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(15)),
      child: Row(
        children: const [
          Icon(Icons.stars, color: primaryGreen),
          SizedBox(width: 10),
          Expanded(child: Text("You're a Sustainability Hero!", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildRefreshButton() {
    return TextButton.icon(
      onPressed: _loadProgress,
      icon: const Icon(Icons.refresh_rounded, color: primaryGreen),
      label: const Text("SYNC PROGRESS", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w900, letterSpacing: 1)),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _glassMorphicWrapper({required Widget child, required BorderRadius borderRadius}) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}