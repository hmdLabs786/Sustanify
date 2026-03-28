import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';
import 'login.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String _selectedGender = 'Male';
  bool _isLoading = false;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Color primaryGreen = const Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomLeft,
                end: Alignment.topRight,
                colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9)],
              ),
            ),
          ),
          Positioned(bottom: 20, right: -30, child: Container(width: 200, height: 200, decoration: BoxDecoration(shape: BoxShape.circle, color: primaryGreen.withOpacity(0.05)))),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Text("Create Account", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: primaryGreen)),
                  const Text("Join our green community today", style: TextStyle(color: Colors.black54)),
                  const SizedBox(height: 30),
                  
                  _glassMorphicWrapper(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          _buildGlassField(controller: _nameController, hint: "Full Name", icon: Icons.person_outline),
                          const SizedBox(height: 15),
                          _buildGlassField(controller: _emailController, hint: "Email", icon: Icons.email_outlined, inputType: TextInputType.emailAddress),
                          const SizedBox(height: 15),
                          _buildGlassField(controller: _phoneNumberController, hint: "Phone", icon: Icons.phone_android_outlined, inputType: TextInputType.phone),
                          const SizedBox(height: 15),
                          _buildGlassField(controller: _passwordController, hint: "Password", icon: Icons.lock_outline, isPassword: true),
                          const SizedBox(height: 20),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [_genderChip("Male"), const SizedBox(width: 15), _genderChip("Female")],
                          ),
                          const SizedBox(height: 25),
                          
                          _buildPrimaryButton(text: "Sign Up", onPressed: _isLoading ? () {} : _handleSignUp, loading: _isLoading),
                        ],
                      ),
                    ),
                  ),
                  
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text("Already a member? Sign In", style: TextStyle(color: primaryGreen)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassMorphicWrapper({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.4),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildGlassField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false, TextInputType inputType = TextInputType.text}) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: inputType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: primaryGreen, size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.3),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _genderChip(String title) {
    bool isSelected = _selectedGender == title;
    return ChoiceChip(
      label: Text(title),
      selected: isSelected,
      onSelected: (v) => setState(() => _selectedGender = title),
      selectedColor: primaryGreen,
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
      backgroundColor: Colors.white.withOpacity(0.3),
    );
  }

  Widget _buildPrimaryButton({required String text, required VoidCallback onPressed, bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(backgroundColor: primaryGreen, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
        child: loading ? const CircularProgressIndicator(color: Colors.white) : Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Future<void> _handleSignUp() async {
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      await FirebaseFirestore.instance.collection("User").doc(userCredential.user?.uid).set({
        "UserName": _nameController.text.trim(),
        "UserEmail": _emailController.text.trim(),
        "UserNumber": _phoneNumberController.text.trim(),
        "UserGender": _selectedGender,
        "role": "user",
        "createdAt": DateTime.now(),
      });
      if (mounted) Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Login()));
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}