import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GreenCertificationsScreen extends StatefulWidget {
  const GreenCertificationsScreen({super.key});

  @override
  State<GreenCertificationsScreen> createState() => _GreenCertificationsScreenState();
}

class _GreenCertificationsScreenState extends State<GreenCertificationsScreen> {
  final nameController = TextEditingController();
  bool showCertificate = false;
  String userName = "";
  bool canGenerate = false;
  double currentProgress = 0.0;
  bool isLoading = true; 

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _checkUserProgress();
  }

  Future<void> _checkUserProgress() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection("user_progress").doc(userId).get();
      if (doc.exists && doc.data() != null) {
        // Safe casting: handle both int and double from Firestore
        final progressValue = doc.data()!['overallProgress'];
        final double progress = (progressValue is num) ? progressValue.toDouble() : 0.0;

        setState(() {
          // NaN check to prevent the "Unsupported operation" error
          currentProgress = progress.isNaN ? 0.0 : progress;
          canGenerate = currentProgress >= 0.7;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint("Error fetching progress: $e");
      setState(() => isLoading = false);
    }
  }

  void _generateCertificate() {
    if (!canGenerate) {
      _showLockedDialog();
      return;
    }
    if (nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your name for the certificate.")),
      );
      return;
    }
    setState(() {
      userName = nameController.text.trim();
      showCertificate = true;
    });
  }

  void _showLockedDialog() {
    showDialog(
      context: context,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          backgroundColor: Colors.white.withOpacity(0.9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text("Keep Going! 🌱", textAlign: TextAlign.center),
          content: Text(
            "You need 70% progress to unlock this. You are currently at ${(currentProgress * 100).clamp(0, 100).toInt()}%",
            textAlign: TextAlign.center,
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK")),
          ],
        ),
      ),
    );
  }

  Future<void> _downloadCertificate() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (pw.Context context) => pw.Container(
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.green900, width: 10),
          ),
          padding: const pw.EdgeInsets.all(40),
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Text('CERTIFICATE OF EXCELLENCE', style: pw.TextStyle(fontSize: 30, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
              pw.SizedBox(height: 20),
              pw.Text('This is to certify that', style: pw.TextStyle(fontSize: 18)),
              pw.SizedBox(height: 10),
              pw.Text(userName, style: pw.TextStyle(fontSize: 40, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Text('has successfully completed the sustainability program with outstanding commitment to the environment.', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 40),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Green Earth Organization', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
                  pw.Text('Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: pw.TextStyle(fontSize: 12)),
                ],
              )
            ],
          ),
        ),
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: "Green_Certificate.pdf");
  }

@override
  Widget build(BuildContext context) {
    // We avoid calling .isNaN on something that might be undefined (JS level)
    // First check if null, then check if it's actually NaN
    double safeProgress = 0.0;
    
    // Use a double check to satisfy the JS engine
    try {
      if (!currentProgress.isNaN) {
        safeProgress = currentProgress.clamp(0.0, 1.0);
      }
    } catch (e) {
      safeProgress = 0.0;
    }
  
    final int displayPercentage = (safeProgress * 100).toInt();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Certifications", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1B5E20), Color(0xFF43A047)],
              ),
            ),
          ),
          SafeArea(
            child: isLoading 
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      _buildGlassBox(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              const Icon(Icons.workspace_premium, size: 60, color: Colors.white),
                              const SizedBox(height: 10),
                              const Text(
                                "Green Champion Status",
                                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              const SizedBox(height: 15),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: safeProgress,
                                  minHeight: 12,
                                  backgroundColor: Colors.white.withOpacity(0.1),
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "$displayPercentage% Progress towards Certificate",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      
                      if (!canGenerate)
                        _buildGlassBox(
                          child: const Padding(
                            padding: EdgeInsets.all(20.0),
                            child: Row(
                              children: [
                                Icon(Icons.lock, color: Colors.white70),
                                SizedBox(width: 15),
                                Expanded(
                                  child: Text(
                                    "Complete more guides (reach 70%) to unlock your official Green Certificate!",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      if (canGenerate) ...[
                        _buildGlassBox(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              children: [
                                TextField(
                                  controller: nameController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: "Full Name for Certificate",
                                    labelStyle: const TextStyle(color: Colors.white70),
                                    prefixIcon: const Icon(Icons.person, color: Colors.white),
                                    filled: true,
                                    fillColor: Colors.white.withOpacity(0.1),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                                  ),
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: _generateCertificate,
                                    icon: const Icon(Icons.auto_awesome),
                                    label: const Text("Generate Preview"),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: const Color(0xFF1B5E20),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      if (showCertificate) ...[
                        const SizedBox(height: 30),
                        _buildCertificatePreview(),
                      ],
                    ],
                  ),
                ),
          ),
        ],
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
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildCertificatePreview() {
    return _buildGlassBox(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white54, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  const Icon(Icons.eco, color: Colors.white, size: 40),
                  const Text("CERTIFICATE", style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 4)),
                  const SizedBox(height: 10),
                  Text(userName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text("For Environmental Excellence", style: TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _downloadCertificate,
              icon: const Icon(Icons.download),
              label: const Text("Download PDF"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade900,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}