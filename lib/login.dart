import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'home.dart';
import 'signup.dart';
import 'admindashboard.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _resetEmailController = TextEditingController(); 
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Color primaryGreen = const Color(0xFF1B5E20);

  Future<void> _handleForgotPassword() async {
    String email = _resetEmailController.text.trim();
    if (email.isEmpty) {
      _showSnackBar("Please enter your email first.");
      return;
    }

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) Navigator.pop(context); 
      _showSnackBar("Reset link sent to $email", isSuccess: true);
      _resetEmailController.clear();
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "An error occurred");
    }
  }

  void _showSnackBar(String message, {bool isSuccess = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI DIALOG FOR FORGOT PASSWORD ---
  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
          title: Text("Reset Password", style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Enter your email and we'll send you a link to reset your password.", 
                style: TextStyle(fontSize: 13, color: Colors.black54)),
              const SizedBox(height: 20),
              _buildGlassField(
                controller: _resetEmailController,
                hint: "Email Address",
                icon: Icons.email_outlined,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: _handleForgotPassword,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Send Link", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              ),
            ),
          ),
          Positioned(top: -50, right: -50, child: _buildBlob(200, primaryGreen.withOpacity(0.1))),
          Positioned(bottom: -50, left: -50, child: _buildBlob(250, Colors.teal.withOpacity(0.1))),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.5),
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 80,
                        errorBuilder: (context, error, stack) => Icon(Icons.eco_rounded, size: 80, color: primaryGreen),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "SUSTANIFY",
                      style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: primaryGreen, letterSpacing: 6),
                    ),
                    const SizedBox(height: 40),

                    _glassMorphicWrapper(
                      child: Padding(
                        padding: const EdgeInsets.all(25),
                        child: Column(
                          children: [
                            _buildGlassField(
                              controller: _emailController,
                              hint: "Email Address",
                              icon: Icons.email_outlined,
                            ),
                            const SizedBox(height: 20),
                            _buildGlassField(
                              controller: _passwordController,
                              hint: "Password",
                              icon: Icons.lock_outline,
                              isPassword: true,
                            ),
                            
                            // --- ADDED FORGOT PASSWORD LINK ---
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: _showForgotPasswordDialog,
                                child: const Text("Forgot Password?", 
                                  style: TextStyle(color: Colors.black54, fontSize: 13, fontWeight: FontWeight.w600)),
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                            _buildPrimaryButton(
                              text: "Sign In",
                              onPressed: _isLoading ? () {} : _handleLogin,
                              loading: _isLoading,
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen())),
                      child: RichText(
                        text: TextSpan(
                          text: "Don't have an account? ",
                          style: const TextStyle(color: Colors.black54),
                          children: [
                            TextSpan(
                              text: "Sign Up",
                              style: TextStyle(color: primaryGreen, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---
  Widget _buildBlob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _glassMorphicWrapper({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.3),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.4)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryGreen, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.4),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
      ),
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback onPressed, bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGreen,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: loading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
          : Text(text, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('User').doc(userCredential.user!.uid).get();
      if (userDoc.exists && mounted) {
        String role = userDoc['role'];
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => role == "admin" ? const AdminDashboard() : const HomeScreen()));
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Failed");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}