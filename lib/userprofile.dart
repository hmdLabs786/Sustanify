import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String userName = 'Loading...';
  String userEmail = '';
  String userAddress = '';
  String userGender = '';
  String userPhone = '';
  String userRole = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final user = _auth.currentUser;
    if (user != null) {
      try {
        DocumentSnapshot snapshot = await FirebaseFirestore.instance
            .collection('User')
            .doc(user.uid)
            .get();

        if (snapshot.exists) {
          // SAFE ACCESS: Cast to Map
          final data = snapshot.data() as Map<String, dynamic>;
          
          setState(() {
            userName = data['UserName']?.toString() ?? 'No Name';
            userEmail = data['UserEmail']?.toString() ?? 'No Email';
            userAddress = data['UserAddress']?.toString() ?? 'Not Set';
            userGender = data['UserGender']?.toString() ?? 'Not Set';
            userPhone = data['UserNumber']?.toString() ?? 'Not Provided';
            userRole = data['role']?.toString() ?? 'user';
            isLoading = false;
          });
        }
      } catch (e) {
        setState(() => isLoading = false);
        debugPrint("Error fetching profile: $e");
      }
    }
  }


  Future<void> _logout() async {
    await _auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Profile", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Theme Background Gradient
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    child: Column(
                      children: [
                        _buildProfileHeader(),
                        const SizedBox(height: 30),
                        _buildGlassBox(
                          child: Column(
                            children: [
                              _buildInfoRow("Email", userEmail, Icons.email_outlined),
                              _buildDivider(),
                              _buildInfoRow("Phone", userPhone, Icons.phone_android_outlined),
                              _buildDivider(),
                              _buildInfoRow("Gender", userGender, Icons.person_outline),
                              _buildDivider(),
                              _buildInfoRow("Address", userAddress, Icons.home_outlined),
                              _buildDivider(),
                              _buildInfoRow("Account Role", userRole.toUpperCase(), Icons.verified_user_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                        _buildLogoutButton(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        CircleAvatar(
          radius: 55,
          backgroundColor: Colors.white.withOpacity(0.2),
          child: const Icon(Icons.person, size: 65, color: Colors.white),
        ),
        const SizedBox(height: 15),
        Text(
          userName,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        const SizedBox(height: 5),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            userEmail,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(color: Colors.white.withOpacity(0.1), height: 1, indent: 64, endIndent: 20);
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _logout,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.redAccent,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 0,
        ),
        icon: const Icon(Icons.logout_rounded),
        label: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold)),
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
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}