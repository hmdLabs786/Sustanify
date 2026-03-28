import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EducationalContentScreen extends StatelessWidget {
  const EducationalContentScreen({super.key});

  static const Color primaryGreen = Color(0xFF1B5E20);

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case "Article": return Icons.menu_book_rounded;
      case "Video": return Icons.play_circle_fill_rounded;
      case "Infographic": return Icons.auto_awesome_mosaic_rounded;
      default: return Icons.lightbulb_outline_rounded;
    }
  }

  Color _getColor(String type) {
    switch (type) {
      case "Article": return Colors.teal;
      case "Video": return Colors.redAccent;
      case "Infographic": return Colors.blueAccent;
      default: return Colors.orangeAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F0),
      body: Stack(
        children: [
          // Background Blobs
          Positioned(top: -80, left: -80, child: _buildBlob(250, primaryGreen.withOpacity(0.08))),
          Positioned(bottom: 100, right: -50, child: _buildBlob(200, Colors.blue.withOpacity(0.04))),

          CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 120,
                floating: true,
                pinned: true,
                backgroundColor: Colors.transparent,
                elevation: 0,
                flexibleSpace: const FlexibleSpaceBar(
                  centerTitle: true,
                  title: Text(
                    "LEARNING HUB",
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
                    .collection("education_content")
                    .orderBy("timestamp", descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: primaryGreen)));
                  }

                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const SliverFillRemaining(child: Center(child: Text("No content available yet.")));
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final content = docs[index].data() as Map<String, dynamic>;
                          final String type = content["type"] ?? "Info";
                          final Color typeColor = _getColor(type);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 20),
                            child: _glassMorphicWrapper(
                              borderRadius: BorderRadius.circular(25),
                              child: InkWell(
                                onTap: () => _launchURL(content["link"] ?? ""),
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: typeColor.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(_getIcon(type), size: 16, color: typeColor),
                                                const SizedBox(width: 6),
                                                Text(
                                                  type.toUpperCase(),
                                                  style: TextStyle(
                                                    color: typeColor,
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: 1,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Spacer(),
                                          const Icon(Icons.arrow_outward_rounded, size: 20, color: Colors.black26),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Text(
                                        content["title"] ?? "Untitled",
                                        style: const TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        content["desc"] ?? "",
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.black.withOpacity(0.6),
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
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

  Widget _buildBlob(double size, Color color) {
    return Container(width: size, height: size, decoration: BoxDecoration(shape: BoxShape.circle, color: color));
  }

  Widget _glassMorphicWrapper({required Widget child, required BorderRadius borderRadius}) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: borderRadius,
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }
}