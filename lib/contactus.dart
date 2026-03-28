import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'login.dart';

class ContactUs extends StatefulWidget {
  const ContactUs({super.key});

  @override
  State<ContactUs> createState() => _ContactUsState();
}

class _ContactUsState extends State<ContactUs> {
  bool isLoggedIn = false;
  final _formKey = GlobalKey<FormState>();
  
  // Define colors as static constants to prevent "undefined" errors during build
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color bgColor = Color(0xFFF0F4F0);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  void _checkAuth() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() => isLoggedIn = true);
    } else {
      Future.microtask(() => Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Login())));
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      await FirebaseFirestore.instance.collection("ContactMessages").add({
        "name": _nameController.text.trim(),
        "email": _emailController.text.trim(),
        "message": _messageController.text.trim(),
        "timestamp": Timestamp.now(),
      });

      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Message sent successfully!'),
          backgroundColor: primaryGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      _nameController.clear();
      _emailController.clear();
      _messageController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!isLoggedIn) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('GET IN TOUCH', 
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: primaryGreen)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(color: bgColor),
          // Blobs with fixed opacity values to avoid JS errors
          Positioned(top: -50, left: -50, child: _buildBlob(250, const Color(0x0F1B5E20))), // 0x0F is ~6% opacity
          Positioned(bottom: -50, right: -50, child: _buildBlob(300, const Color(0x0F008080))), 

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const Icon(Icons.chat_bubble_outline_rounded, size: 60, color: primaryGreen),
                    const SizedBox(height: 20),
                    const Text(
                      "We'd love to hear from you!",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Have a suggestion or need help? Send us a message.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black.withOpacity(0.5)),
                    ),
                    const SizedBox(height: 40),
                    
                    _buildGlassField(
                      label: 'Full Name',
                      icon: Icons.person_outline_rounded,
                      controller: _nameController,
                    ),
                    const SizedBox(height: 20),
                    _buildGlassField(
                      label: 'Email Address',
                      icon: Icons.alternate_email_rounded,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),
                    _buildGlassField(
                      label: 'Message',
                      icon: Icons.notes_rounded,
                      controller: _messageController,
                      maxLines: 5,
                    ),
                    const SizedBox(height: 40),
                    
                    _buildSubmitButton(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassField({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
            decoration: InputDecoration(
              labelText: label,
              labelStyle: const TextStyle(color: Color(0x991B5E20), fontWeight: FontWeight.normal),
              // REMOVED 'const' from Icon below
              prefixIcon: Icon(icon, color: primaryGreen), 
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            ),
            validator: (value) => (value == null || value.isEmpty) ? 'Required' : null,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryGreen.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _submitForm,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: const Text(
          'SEND MESSAGE',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5),
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