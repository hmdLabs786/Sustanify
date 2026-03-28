import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:ui';


import 'carbontracker.dart';
import 'ecoproductsuggestions.dart';
import 'sustainablechallenges.dart';
import 'greencertifications.dart';
import 'wastereduction.dart';
import 'sustainablerecipes.dart';
import 'energyconservationtips.dart';
import 'ecotravelsuggestions.dart';
import 'communityforum.dart';
import 'sustainabilitydashboard.dart';
import 'educationalcontent.dart';
import 'aboutus.dart';
import 'notification_service.dart'; 
import 'contactus.dart';
import 'gallery.dart';
import 'admindashboard.dart';
import 'userprofile.dart';
import 'login.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _searchQuery = '';
  String? userRole;
  bool isLoggedIn = false;
  final Color primaryGreen = const Color(0xFF1B5E20);

  final List<String> imageUrls = ['assets/b1.jpg', 'assets/b2.jpg', 'assets/b3.jpg'];
  final List<Map<String, dynamic>> features = [];

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _initFeatures();
    WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoSlider());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initFeatures() {
    features.addAll([
      {"title": "Carbon Track", "desc": "Monitor Footprint", "icon": Icons.analytics_outlined, "screen": const CarbonFootprintScreen()},
      {"title": "Eco Shop", "desc": "Sustainable Picks", "icon": Icons.shopping_basket_outlined, "screen": const EcoProductSuggestionsScreen()},
      {"title": "Life Challenges", "desc": "Join the Movement", "icon": Icons.emoji_events_outlined, "screen": const SustainableChallengesPage()},
      {"title": "Certifications", "desc": "Verified Green", "icon": Icons.verified_user_outlined, "screen": const GreenCertificationsScreen()},
      {"title": "Waste Tracker", "desc": "Reduce & Recycle", "icon": Icons.delete_sweep_outlined, "screen": const WasteReductionScreen()},
      {"title": "Green Recipes", "desc": "Plant-based Meals", "icon": Icons.restaurant_menu, "screen": const SustainableRecipesPage()},
      {"title": "Energy Tips", "desc": "Save Electricity", "icon": Icons.lightbulb_outline, "screen": const EnergyConservationTipsScreen()},
      {"title": "Eco Travel", "desc": "Green Journeys", "icon": Icons.moped_outlined, "screen": const EcoTravelSuggestionsScreen()},
      {"title": "Progress", "desc": "Your Impact", "icon": Icons.dashboard_outlined, "screen": const SustainabilityDashboardScreen()},
      {"title": "Education", "desc": "Learn & Grow", "icon": Icons.school_outlined, "screen": const EducationalContentScreen()},
    ]);
  }

  void _startAutoSlider() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _pageController.hasClients) {
        _currentPage = (_currentPage + 1) % imageUrls.length;
        _pageController.animateToPage(_currentPage, duration: const Duration(milliseconds: 900), curve: Curves.fastOutSlowIn);
        _startAutoSlider();
      }
    });
  }

  void _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => isLoggedIn = true);
      final doc = await FirebaseFirestore.instance.collection('User').where('UserEmail', isEqualTo: user.email).get();
      if (doc.docs.isNotEmpty) {
        setState(() => userRole = doc.docs.first.data()['role']);
      }
    } else {
      setState(() => isLoggedIn = false);
    }
  }

  // Inside build() -> CustomScrollView -> slivers: [ ... ]

// Place this after your Hero Slider and before the Feature Grid


  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    final displayedFeatures = features.where((f) => f['title'].toString().toLowerCase().contains(_searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      drawer: _buildGlassDrawer(),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildBlob(200, primaryGreen.withOpacity(0.1))),
          Positioned(bottom: 100, left: -50, child: _buildBlob(250, Colors.teal.withOpacity(0.1))),
          
          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 90.0,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                leading: Builder(
                  builder: (context) => IconButton(
                    icon: Icon(Icons.menu_rounded, color: primaryGreen),
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text("SUSTANIFY", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 2)),
                ),
                actions: [
                  IconButton(
                    icon: CircleAvatar(backgroundColor: Colors.white.withOpacity(0.5), child: Icon(Icons.person_outline, color: primaryGreen)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfileScreen())),
                  ),
                  const SizedBox(width: 10),
                ],
              ),

              // 1. THE SEARCH BAR
SliverToBoxAdapter(
  child: Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: _glassMorphicWrapper(
      borderRadius: BorderRadius.circular(20),
      child: TextField(
        onChanged: (v) => setState(() => _searchQuery = v),
        decoration: const InputDecoration(
          hintText: "Search sustainability...",
          prefixIcon: Icon(Icons.search_rounded),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    ),
  ),
),

// 2. THE NOTIFICATION REMINDER (The new feature!)
SliverToBoxAdapter(
  child: _buildNotificationReminder(),
),



              // Hero Slider
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 200,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(25),
                          image: DecorationImage(image: AssetImage(imageUrls[index]), fit: BoxFit.cover),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 5))]
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            gradient: LinearGradient(begin: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent]),
                          ),
                          padding: const EdgeInsets.all(20),
                          alignment: Alignment.bottomLeft,
                          child: const Text("Save the Planet\nOne Step at a Time", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Feature Grid
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 15,
                    crossAxisSpacing: 15,
                    childAspectRatio: 1.0,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildFeatureCard(displayedFeatures[index]),
                    childCount: displayedFeatures.length,
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),

              
            ],
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildBottomNav(),
    );
  }

  Widget _buildGlassDrawer() {
    return Drawer(
      backgroundColor: Colors.transparent,
      child: _glassMorphicWrapper(
        borderRadius: BorderRadius.zero,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryGreen.withOpacity(0.1)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(radius: 30, backgroundColor: primaryGreen, child: const Icon(Icons.eco, color: Colors.white, size: 30)),
                  const SizedBox(height: 15),
                  const Text("Eco Guide", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            _drawerTile(Icons.info_outline, "About Us", const AboutUsPage()),
            _drawerTile(Icons.contact_support_outlined, "Contact Us", const ContactUs()),
            _drawerTile(Icons.collections_outlined, "Gallery", const GalleryScreen()),
            if (userRole == "admin") _drawerTile(Icons.admin_panel_settings_outlined, "Admin Dashboard", const AdminDashboard()),
            const Divider(),
            _drawerTile(Icons.logout, "Logout", null, isLogout: true),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, Widget? screen, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: primaryGreen),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: () async {
        if (isLogout) {
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Login()));
        } else if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
    );
  }

  Widget _buildNotificationReminder() {
  // Array of tips to make it "Top of the Month" quality
  final List<String> ecoTips = [
    "Switch to LED bulbs to save 75% more energy!",
    "Unplug electronics when not in use to stop 'vampire' energy.",
    "Shorten your shower by 2 minutes to save 10 gallons of water!",
    "Use cold water for laundry to save energy and protect clothes.",
    "Try a meatless Monday to reduce your carbon footprint!"
  ];

  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
    child: InkWell(
      onTap: () {
        // Pick a random tip from the list
        final randomTip = (ecoTips..shuffle()).first;
        NotificationService.showInstantNotification(
          "🌱 Daily Eco Tip",
          randomTip,
        );
      },
      child: _glassMorphicWrapper(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryGreen.withOpacity(0.1), Colors.teal.withOpacity(0.05)]
            )
          ),
          child: Row(
            children: [
              const Icon(Icons.tips_and_updates, color: Colors.orangeAccent),
              const SizedBox(width: 15),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("DAILY REMINDER", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2, color: Colors.black54)),
                    Text("Tap for your daily eco-tip!", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ],
                ),
              ),
              Icon(Icons.notifications_active_outlined, color: primaryGreen),
            ],
          ),
        ),
      ),
    ),
  );
}

  Widget _buildFeatureCard(Map<String, dynamic> item) {
    return _glassMorphicWrapper(
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => item["screen"])),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(item["icon"], color: primaryGreen, size: 32),
            const SizedBox(height: 10),
            Text(item["title"], textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            Text(item["desc"], textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return _glassMorphicWrapper(
      borderRadius: BorderRadius.circular(35),
      child: Container(
        height: 65,
        width: MediaQuery.of(context).size.width * 0.9,
        color: primaryGreen.withOpacity(0.85),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _navIcon(Icons.home_rounded, true),
            _navIcon(Icons.forum_outlined, false, screen: const CommunityForumScreen()),
            _navIcon(Icons.bar_chart_rounded, false, screen: const SustainabilityDashboardScreen()),
            if (userRole == "admin") _navIcon(Icons.settings_suggest_outlined, false, screen: const AdminDashboard()),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, bool isActive, {Widget? screen}) {
    return IconButton(
      icon: Icon(icon, color: isActive ? Colors.white : Colors.white60, size: 28),
      onPressed: () {
        if (screen != null) Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
      },
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _glassMorphicWrapper({required Widget child, required BorderRadius borderRadius}) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: child,
        ),
      ),
    );
  }
}