import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SustainableRecipesPage extends StatefulWidget {
  const SustainableRecipesPage({super.key});

  @override
  State<SustainableRecipesPage> createState() => _SustainableRecipesPageState();
}

class _SustainableRecipesPageState extends State<SustainableRecipesPage> {
  List<bool> _expanded = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Eco-Friendly Recipes',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Gradient matching the rest of the app
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recipes')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                      child: Text("No recipes found.", style: TextStyle(color: Colors.white70)));
                }

                final docs = snapshot.data!.docs;
                if (_expanded.length != docs.length) {
                  _expanded = List.generate(docs.length, (_) => false);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: docs.length + 1, // +1 for the header
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return _buildHeader();
                    }
                    return _buildRecipeCard(index - 1, docs[index - 1]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20, top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Wholesome Meal Planning 🌱",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            "Discover recipes that are kind to the planet and healthy for you.",
            style: TextStyle(fontSize: 15, color: Colors.white.withOpacity(0.8)),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(int index, QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final isExpanded = _expanded[index];

    Uint8List? imageBytes;
    if (data['image'] != null) {
      try {
        imageBytes = base64Decode(data['image']);
      } catch (_) {
        imageBytes = null;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: _buildGlassBox(
        child: InkWell(
          onTap: () => setState(() => _expanded[index] = !isExpanded),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageBytes != null)
                Stack(
                  children: [
                    Image.memory(
                      imageBytes,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                        ),
                      ),
                    ),
                  ],
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            data['name'] ?? 'Untitled Recipe',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                        Icon(
                          isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data['description'] ?? '',
                      style: const TextStyle(fontSize: 14, color: Colors.white70),
                    ),
                    if (isExpanded) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 15),
                        child: Divider(color: Colors.white24),
                      ),
                      _buildSectionTitle(Icons.restaurant_menu, "Ingredients"),
                      const SizedBox(height: 8),
                      if (data['ingredients'] != null)
                        ... (data['ingredients'] as String).split(',').map((item) => 
                          _buildListItem(item.trim())
                        ),
                      const SizedBox(height: 20),
                      _buildSectionTitle(Icons.lightbulb_outline, "Cooking Steps"),
                      const SizedBox(height: 8),
                      if (data['steps'] != null)
                        ... (data['steps'] as String).split(',').map((step) => 
                          _buildListItem(step.trim())
                        ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.orangeAccent),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
      ],
    );
  }

  Widget _buildListItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("• ", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
          Expanded(child: Text(text, style: const TextStyle(color: Colors.white70, fontSize: 14))),
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
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: child,
        ),
      ),
    );
  }
}