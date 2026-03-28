import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ManageRecipesPage extends StatefulWidget {
  const ManageRecipesPage({super.key});

  @override
  State<ManageRecipesPage> createState() => _ManageRecipesPageState();
}

class _ManageRecipesPageState extends State<ManageRecipesPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _ingredientsController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();

  Uint8List? _pickedImage;
  String? _editingDocId;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _pickedImage = bytes;
      });
    }
  }

  Future<void> _addOrUpdateRecipe() async {
    if (_nameController.text.isEmpty || _pickedImage == null) return;

    String base64Image = base64Encode(_pickedImage!);

    final data = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'ingredients': _ingredientsController.text,
      'steps': _stepsController.text,
      'image': base64Image,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (_editingDocId != null) {
        await FirebaseFirestore.instance
            .collection('recipes')
            .doc(_editingDocId)
            .update(data);
        _editingDocId = null;
      } else {
        await FirebaseFirestore.instance.collection('recipes').add(data);
      }
      _clearForm();
    } catch (e) {
      print("Error adding/updating recipe: $e");
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _ingredientsController.clear();
    _stepsController.clear();
    setState(() {
      _pickedImage = null;
    });
  }

  void _startEdit(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _nameController.text = data['name'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    _ingredientsController.text = data['ingredients'] ?? '';
    _stepsController.text = data['steps'] ?? '';
    if (data['image'] != null) {
      _pickedImage = base64Decode(data['image']);
    }
    setState(() {
      _editingDocId = doc.id;
    });
  }

  void _deleteRecipe(String docId) async {
    await FirebaseFirestore.instance.collection('recipes').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Add/Edit Recipe Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: Colors.green.withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3))
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: "Recipe Name",
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: "Description",
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _ingredientsController,
                    decoration: InputDecoration(
                      labelText: "Ingredients (comma separated)",
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _stepsController,
                    decoration: InputDecoration(
                      labelText: "Steps (comma separated)",
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 10),
                  _pickedImage != null
                      ? Image.memory(_pickedImage!, height: 100)
                      : const SizedBox(height: 0),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image),
                    label: const Text(
                      "Pick Image",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade700),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _addOrUpdateRecipe,
                    icon: const Icon(Icons.add),
                    label: Text(
                      _editingDocId != null ? "Update Recipe" : "Add Recipe",
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade900),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Display Recipes
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('recipes')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Text("Loading...");
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final imageBase64 = data['image'] as String?;
                    Uint8List? imageBytes;
                    if (imageBase64 != null) {
                      imageBytes = base64Decode(imageBase64);
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: imageBytes != null
                            ? Image.memory(imageBytes,
                                width: 50, height: 50, fit: BoxFit.cover)
                            : null,
                        title: Text(data['name'] ?? ''),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(data['description'] ?? ''),
                            const SizedBox(height: 4),
                            Text(
                              "Ingredients: ${data['ingredients'] ?? ''}",
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              "Steps: ${data['steps'] ?? ''}",
                              style: const TextStyle(fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _startEdit(docs[index]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteRecipe(docs[index].id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }
}
