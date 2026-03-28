import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class EnergyConservationTipsScreen extends StatefulWidget {
  const EnergyConservationTipsScreen({super.key});

  @override
  State<EnergyConservationTipsScreen> createState() => _EnergyConservationTipsScreenState();
}

class _EnergyConservationTipsScreenState extends State<EnergyConservationTipsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Define color as a static constant to prevent initialization errors in JS
  static const Color primaryGreen = Color(0xFF1B5E20);

  Set<String> _completedTips = {}; 
  String? userId;

  @override
  void initState() {
    super.initState();
    userId = _auth.currentUser?.uid;
    _loadUserProgress();
  }

  Future<void> _loadUserProgress() async {
    if (userId == null) return;
    try {
      final doc = await _firestore.collection('user_progress').doc(userId).get();
      if (doc.exists) {
        final data = doc.data()!;
        final completed = List<String>.from(data['completedTips'] ?? []);
        setState(() {
          _completedTips = completed.toSet();
        });
      }
    } catch (e) {
      debugPrint("Error loading progress: $e");
    }
  }

  Future<void> _markCompleted(String tipId) async {
    if (userId == null) return;
    setState(() {
      _completedTips.add(tipId);
    });
    await _firestore.collection('user_progress').doc(userId).set({
      'completedTips': _completedTips.toList(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    // Local variable for extra safety during build
    final Color themeColor = primaryGreen;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Stack(
        children: [
          // Background decorative blobs - Using direct Opacity to be safer
          Positioned(
            top: -50, 
            right: -50, 
            child: Opacity(
              opacity: 0.1, 
              child: _buildBlob(200, themeColor)
            )
          ),
          Positioned(
            bottom: 100, 
            left: -50, 
            child: Opacity(
              opacity: 0.05, 
              child: _buildBlob(250, Colors.teal)
            )
          ),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.white.withOpacity(0.1), // Semi-transparent
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    "ENERGY SAVING", 
                    style: TextStyle(
                      color: themeColor, 
                      fontWeight: FontWeight.w900, 
                      fontSize: 18, 
                      letterSpacing: 1.5
                    )
                  ),
                ),
                leading: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: themeColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              // Progress Card
              SliverToBoxAdapter(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('energy_tips').snapshots(),
                  builder: (context, snapshot) {
                    final total = snapshot.hasData ? snapshot.data!.docs.length : 0;
                    final completed = _completedTips.length;
                    double progress = total == 0 ? 0 : (completed / total).clamp(0.0, 1.0);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      child: _glassMorphicWrapper(
                        borderRadius: BorderRadius.circular(25),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text("Your Daily Impact", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text("$completed/$total", style: TextStyle(color: themeColor, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const SizedBox(height: 15),
                              LinearProgressIndicator(
                                value: progress,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                color: themeColor,
                                minHeight: 8,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // List of Tips
              StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('energy_tips').orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text("No tips available yet.")));
                  }

                  final tips = snapshot.data!.docs;

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = tips[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final isDone = _completedTips.contains(doc.id);
                          
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _glassMorphicWrapper(
                              borderRadius: BorderRadius.circular(20),
                              child: CheckboxListTile(
                                activeColor: themeColor,
                                value: isDone,
                                onChanged: isDone ? null : (_) => _markCompleted(doc.id),
                                title: Text(
                                  data['title'] ?? '',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                  ),
                                ),
                                subtitle: Text(data['details'] ?? ''),
                              ),
                            ),
                          );
                        },
                        childCount: tips.length,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
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
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}