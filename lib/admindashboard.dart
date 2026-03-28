import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'user_feedback.dart';
import 'livingchallenges.dart';
import 'eco_travel_dashboard.dart';
import 'eco_products_admin.dart';
import 'addeducation_content.dart';
import 'manage_recipe.dart';
import 'energy_tips_admin.dart';
import 'home.dart';
import 'login.dart';
import 'admin_contact_messages.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String selectedPage = "Dashboard";

  @override
  Widget build(BuildContext context) {
    bool isHome = selectedPage == "Dashboard";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          child: Text(
            isHome ? "SUSTANIFY ELITE" : selectedPage.toUpperCase(),
            key: ValueKey(selectedPage),
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              fontSize: 16,
              color: Colors.white,
            ),
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: !isHome
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                onPressed: () => setState(() => selectedPage = "Dashboard"),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white70),
            onPressed: () => _handleLogout(context),
          )
        ],
      ),
      body: Stack(
        children: [
          // LUXURY BACKGROUND
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF061407), Color(0xFF133821), Color(0xFF061407)],
              ),
            ),
          ),
          
          // ANIMATED PAGE TRANSITION
          SafeArea(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              switchInCurve: Curves.easeInOutCubic,
              switchOutCurve: Curves.easeInOutCubic,
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: isHome 
                  ? _buildLuxuryHome(key: const ValueKey("Home")) 
                  : _buildInternalPage(key: ValueKey(selectedPage)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInternalPage({required Key key}) {
    return Container(
      key: key,
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 30,
            spreadRadius: 5,
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: _getPageWidget(selectedPage),
      ),
    );
  }

  Widget _buildLuxuryHome({required Key key}) {
    return SingleChildScrollView(
      key: key,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          _buildHeroHeader(),
          const SizedBox(height: 25),
          _buildQuickStats(),
          const SizedBox(height: 40),
          const Text("MANAGEMENT CONSOLE", 
              style: TextStyle(color: Colors.white38, fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 10)),
          const SizedBox(height: 20),
          _buildStaggeredGrid(),
          const SizedBox(height: 30),
          _buildUserSwitchButton(),
          const SizedBox(height: 50),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("SYSTEM STATUS: OPTIMAL", 
          style: TextStyle(color: Colors.greenAccent.withAlpha(200), fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 10)),
        const SizedBox(height: 5),
        const Text("Welcome, Admin", 
          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildStaggeredGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.2,
      children: [
        _luxuryTile("User Feedback", Icons.analytics_outlined, "Insights"),
        _luxuryTile("Living Challenges", Icons.military_tech_outlined, "Events"),
        _luxuryTile("Eco Travel", Icons.map_outlined, "Global"),
        _luxuryTile("Eco Products", Icons.inventory_2_outlined, "Supply"),
        _luxuryTile("Education Content", Icons.menu_book_rounded, "Assets"),
        _luxuryTile("Manage Recipes", Icons.restaurant_rounded, "Culinary"),
        _luxuryTile("Energy Tips", Icons.bolt_rounded, "Usage"),
        _luxuryTile("Show Contacts", Icons.mail_outline_rounded, "Inbox"),
      ],
    );
  }

  Widget _luxuryTile(String title, IconData icon, String tag) {
    return InkWell(
      onTap: () => setState(() => selectedPage = title),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(12),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(20)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.greenAccent, size: 28),
            const Spacer(),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text(tag, style: const TextStyle(color: Colors.white30, fontSize: 10, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildUserSwitchButton() {
    return InkWell(
      onTap: () => _handleGoBackToUser(context),
      child: Container(
        height: 65,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFAC8A33)]),
        ),
        child: const Center(
          child: Text("VIEW USER EXPERIENCE", 
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
        ),
      ),
    );
  }

  Widget _buildQuickStats() {
    return FutureBuilder(
      future: _fetchStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        return Row(
          children: [
            _statCard("ACTIVE USERS", stats?['users']?.toString() ?? "...", Colors.cyanAccent),
            const SizedBox(width: 15),
            _statCard("INQUIRIES", stats?['contacts']?.toString() ?? "...", Colors.amberAccent),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color accent) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white)),
            Text(label, style: TextStyle(fontSize: 9, color: accent, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }

  // --- LOGIC ---
  Future<Map<String, int>> _fetchStats() async {
    try {
      final results = await Future.wait([
        FirebaseFirestore.instance.collection("User").count().get(),
        FirebaseFirestore.instance.collection("contact_messages").count().get(),
      ]);
      return {"users": results[0].count ?? 0, "contacts": results[1].count ?? 0};
    } catch (e) {
      return {"users": 0, "contacts": 0};
    }
  }

  Widget _getPageWidget(String page) {
    switch (page) {
      case "User Feedback": return const UserFeedbackScreen();
      case "Living Challenges": return const AdminChallengeScreen();
      case "Eco Travel": return const EcoTravelAdminPage();
      case "Eco Products": return const EcoProductsAdminPage();
      case "Education Content": return const AddEducationContent();
      case "Manage Recipes": return const ManageRecipesPage();
      case "Energy Tips": return const EnergyTipsAdminPage();
      case "Show Contacts": return const AdminContactMessages();
      default: return const SizedBox();
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    if (mounted) Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const Login()), (route) => false);
  }

  void _handleGoBackToUser(BuildContext context) {
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
  }
}