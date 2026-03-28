import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EcoTravelSuggestionsScreen extends StatefulWidget {
  const EcoTravelSuggestionsScreen({super.key});

  @override
  State<EcoTravelSuggestionsScreen> createState() => _EcoTravelSuggestionsScreenState();
}

class _EcoTravelSuggestionsScreenState extends State<EcoTravelSuggestionsScreen> {
  final Map<String, bool> _expandedStates = {};
  
  static const Color primaryGreen = Color(0xFF1B5E20);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Stack(
        children: [
          Positioned(top: -50, right: -50, child: _buildBlob(250, primaryGreen.withOpacity(0.07))),
          Positioned(bottom: 100, left: -50, child: _buildBlob(300, Colors.teal.withOpacity(0.05))),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120.0,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    "ECO-TRAVEL",
                    style: TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      letterSpacing: 2,
                    ),
                  ),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: primaryGreen),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('eco_travel')
                    .orderBy('timestamp', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text("No suggestions found")));
                  }

                  final docs = snapshot.data!.docs;

                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final doc = docs[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final docId = doc.id;
                          final isExpanded = _expandedStates[docId] ?? false;

                          Uint8List? imageBytes;
                          if (data['image'] != null) {
                            imageBytes = base64Decode(data['image']);
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 25),
                            child: _glassMorphicWrapper(
                              borderRadius: BorderRadius.circular(30),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Destination Image
                                  if (imageBytes != null)
                                    Stack(
                                      children: [
                                        Image.memory(
                                          imageBytes,
                                          height: 220,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        ),
                                        Positioned(
                                          top: 15,
                                          right: 15,
                                          child: _glassMorphicWrapper(
                                            borderRadius: BorderRadius.circular(12),
                                            child: const Padding(
                                              padding: EdgeInsets.all(8.0),
                                              child: Icon(Icons.eco, color: Colors.white, size: 20),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                  // Destination Content
                                  Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (data['country'] ?? '').toUpperCase(),
                                          style: const TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w900,
                                            color: primaryGreen,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 10),
                                        AnimatedSize(
                                          duration: const Duration(milliseconds: 300),
                                          curve: Curves.easeInOut,
                                          child: Text(
                                            isExpanded
                                                ? data['fullDescription'] ?? ''
                                                : data['shortDescription'] ?? '',
                                            style: TextStyle(
                                              fontSize: 15,
                                              color: Colors.black.withOpacity(0.7),
                                              height: 1.6,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 15),
                                        
                                        // Custom Action Button
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _expandedStates[docId] = !isExpanded;
                                            });
                                          },
                                          style: TextButton.styleFrom(
                                            padding: EdgeInsets.zero,
                                            minimumSize: const Size(50, 30),
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                isExpanded ? "READ LESS" : "EXPLORE DESTINATION",
                                                style: const TextStyle(
                                                  color: primaryGreen,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              Icon(
                                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                                color: primaryGreen,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        childCount: docs.length,
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

  // UI Components matching the Sustanify design language
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
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: child,
        ),
      ),
    );
  }
}