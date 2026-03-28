import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';


class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  String? userRole;
  bool isLoggedIn = false;
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color bgColor = Color(0xFFF0F4F0);

  final List<String> images = [
    'assets/g1.jpg', 'assets/g2.jpg', 'assets/g3.png',
    'assets/g4.jpg', 'assets/g5.png', 'assets/g6.webp',
    'assets/g7.webp', 'assets/g8.webp', 'assets/g9.jpg',
    'assets/g10.webp',
  ];

  @override
  void initState() {
    super.initState();
    _checkAuthState();
  }

  void _checkAuthState() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (mounted) {
        setState(() => isLoggedIn = user != null);
        if (isLoggedIn) _loadUserRole();
      }
    });
  }

  void _loadUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final snap = await FirebaseFirestore.instance.collection('User').doc(user.uid).get();
      if (snap.exists && mounted) {
        setState(() => userRole = snap.data()?['role']);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      // Removed drawer
      appBar: AppBar(
        title: const Text('ECO GALLERY', 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: primaryGreen)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Styling matching AboutUs and ContactUs
          Container(color: bgColor),
          Positioned(top: -50, right: -50, child: _buildBlob(250, const Color(0x0F1B5E20))),
          Positioned(bottom: -50, left: -50, child: _buildBlob(300, const Color(0x0F008080))),

          SafeArea(
            child: images.isEmpty 
              ? const Center(child: CircularProgressIndicator(color: primaryGreen))
              : MasonryGridView.count(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  itemCount: images.length,
                  itemBuilder: (context, index) => _buildImageCard(context, images[index]),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(BuildContext context, String path) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SingleImageView(imagePath: path))),
      child: Hero(
        tag: path,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              path, 
              fit: BoxFit.cover,
              errorBuilder: (context, error, stack) => Container(
                height: 150,
                color: Colors.white.withOpacity(0.5),
                child: const Icon(Icons.image_not_supported_outlined, color: primaryGreen),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlob(double size, Color color) {
    return Container(
      width: size, 
      height: size, 
      decoration: BoxDecoration(shape: BoxShape.circle, color: color)
    );
  }
}

// --- PINCH TO ZOOM VIEW ---
class SingleImageView extends StatelessWidget {
  final String imagePath;
  const SingleImageView({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const CircleAvatar(
            backgroundColor: Colors.black45, 
            child: Icon(Icons.close_rounded, color: Colors.white, size: 20)
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Hero(
          tag: imagePath,
          child: InteractiveViewer(
            panEnabled: true, 
            minScale: 0.5,
            maxScale: 4.0,
            child: Image.asset(imagePath, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }
}