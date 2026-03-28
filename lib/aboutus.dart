import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import 'login.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  String? userRole;
  bool isLoggedIn = false;
  final Color primaryGreen = const Color(0xFF1B5E20);

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  void _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      if (mounted) setState(() => isLoggedIn = true);
      final querySnapshot = await FirebaseFirestore.instance
          .collection('User')
          .where('UserEmail', isEqualTo: user.email)
          .get();

      if (querySnapshot.docs.isNotEmpty && mounted) {
        setState(() => userRole = querySnapshot.docs.first['role']);
      }
    } else {
      if (mounted) {
        setState(() {
          isLoggedIn = false;
          userRole = null;
        });
      }
    }
  }

  Widget _glassBox({required Widget child, double opacity = 0.4, double blur = 15}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) {
      Future.microtask(() => Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Login())));
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      // Removed the drawer property here
      appBar: AppBar(
        title: const Text('OUR MISSION', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          // Changed to back arrow icon
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1B5E20), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(color: const Color(0xFFF0F4F0)),
          Positioned(top: -100, right: -50, child: _buildBlob(300, primaryGreen.withOpacity(0.07))),
          Positioned(bottom: 50, left: -100, child: _buildBlob(400, Colors.teal.withOpacity(0.05))),
          
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _glassBox(
                    opacity: 0.6,
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                          child: Image.asset(
                            'assets/about.png',
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stack) => Container(
                              height: 200,
                              color: primaryGreen.withOpacity(0.1),
                              child: Icon(Icons.eco_rounded, size: 60, color: primaryGreen),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(25),
                          child: Column(
                            children: [
                              Text(
                                'Driving a Sustainable Future',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: primaryGreen),
                              ),
                              const SizedBox(height: 15),
                              Text(
                                'Sustanify empowers you to minimize your environmental footprint through data-driven choices and collective community action.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.black.withOpacity(0.7), height: 1.6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  _sectionHeader('Core Highlights'),
                  const SizedBox(height: 20),

                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.1,
                    children: const [
                      HighlightCard(icon: Icons.recycling_rounded, title: 'Zero Waste', color: Colors.teal),
                      HighlightCard(icon: Icons.bolt_rounded, title: 'Clean Energy', color: Colors.orange),
                      HighlightCard(icon: Icons.water_drop_rounded, title: 'Conservation', color: Colors.blue),
                      HighlightCard(icon: Icons.forest_rounded, title: 'Eco Growth', color: Colors.green),
                    ],
                  ),

                  const SizedBox(height: 40),
                  _sectionHeader('How We Work'),
                  const SizedBox(height: 20),

                  _glassBox(
                    child: Column(
                      children: const [
                        ProcessStep(number: '01', title: 'Smart Assessment', sub: 'We analyze your current impact.'),
                        _StepDivider(),
                        ProcessStep(number: '02', title: 'Custom Planning', sub: 'Tailored green strategies.'),
                        _StepDivider(),
                        ProcessStep(number: '03', title: 'Active Implementation', sub: 'Real-time eco-tracking.'),
                        _StepDivider(),
                        ProcessStep(number: '04', title: 'Impact Monitoring', sub: 'Measuring your global contribution.'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 5),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: primaryGreen, letterSpacing: 2),
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }
}

class HighlightCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const HighlightCard({super.key, required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(height: 12),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class ProcessStep extends StatelessWidget {
  final String number;
  final String title;
  final String sub;
  const ProcessStep({super.key, required this.number, required this.title, required this.sub});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      leading: Text(number, style: TextStyle(color: const Color(0xFF1B5E20).withOpacity(0.2), fontWeight: FontWeight.w900, fontSize: 24)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
      subtitle: Text(sub, style: TextStyle(fontSize: 12, color: Colors.black.withOpacity(0.5))),
    );
  }
}

class _StepDivider extends StatelessWidget {
  const _StepDivider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, indent: 70, color: Colors.white30);
}