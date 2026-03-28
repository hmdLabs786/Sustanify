import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EcoProductsAdminPage extends StatefulWidget {
  const EcoProductsAdminPage({super.key});

  @override
  State<EcoProductsAdminPage> createState() => _EcoProductsAdminPageState();
}

class _EcoProductsAdminPageState extends State<EcoProductsAdminPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

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

  Future<void> _addOrUpdateProduct() async {
    if (_nameController.text.isEmpty || _pickedImage == null) return;

    final base64Image = base64Encode(_pickedImage!);

    final data = {
      'name': _nameController.text,
      'description': _descriptionController.text,
      'image': base64Image,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (_editingDocId != null) {
        await FirebaseFirestore.instance
            .collection('eco_products')
            .doc(_editingDocId)
            .update(data);
        _editingDocId = null;
      } else {
        await FirebaseFirestore.instance.collection('eco_products').add(data);
      }
      _clearForm();
    } catch (e) {
      print("Error adding/updating product: $e");
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    setState(() {
      _pickedImage = null;
    });
  }

  void _startEdit(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _nameController.text = data['name'] ?? '';
    _descriptionController.text = data['description'] ?? '';
    if (data['image'] != null) {
      _pickedImage = base64Decode(data['image']);
    }
    setState(() {
      _editingDocId = doc.id;
    });
  }

  void _deleteProduct(String docId) async {
    await FirebaseFirestore.instance.collection('eco_products').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔹 Add/Edit Product Form
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      prefixIcon:
                          Icon(Icons.shopping_bag, color: Colors.green.shade700),
                      hintText: "Product Name",
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.description,
                          color: Colors.green.shade700),
                      hintText: "Product Description",
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  _pickedImage != null
                      ? Image.memory(_pickedImage!, height: 100)
                      : const SizedBox(height: 0),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.image, color: Colors.white),
                    label: const Text(
                      "Pick Image",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _addOrUpdateProduct,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      _editingDocId != null ? "Update Product" : "Add Product",
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade900,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 🔹 Product List from Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('eco_products')
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
                    Uint8List? imageBytes;
                    if (data['image'] != null) {
                      imageBytes = base64Decode(data['image']);
                    }
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: imageBytes != null
                            ? Image.memory(imageBytes, width: 50, height: 50, fit: BoxFit.cover)
                            : null,
                        title: Text(data['name'] ?? ''),
                        subtitle: Text(data['description'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _startEdit(docs[index]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(docs[index].id),
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
