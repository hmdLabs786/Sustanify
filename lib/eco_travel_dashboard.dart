import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EcoTravelAdminPage extends StatefulWidget {
  const EcoTravelAdminPage({super.key});

  @override
  State<EcoTravelAdminPage> createState() => _EcoTravelAdminPageState();
}

class _EcoTravelAdminPageState extends State<EcoTravelAdminPage> {
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _shortDescController = TextEditingController();
  final TextEditingController _fullDescController = TextEditingController();

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

  Future<void> _addOrUpdateTravel() async {
    if (_countryController.text.isEmpty || _pickedImage == null) return;

    final base64Image = base64Encode(_pickedImage!);

    final data = {
      'country': _countryController.text,
      'shortDescription': _shortDescController.text,
      'fullDescription': _fullDescController.text,
      'image': base64Image,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (_editingDocId != null) {
        await FirebaseFirestore.instance
            .collection('eco_travel')
            .doc(_editingDocId)
            .update(data);
        _editingDocId = null;
      } else {
        await FirebaseFirestore.instance.collection('eco_travel').add(data);
      }
      _clearForm();
    } catch (e) {
      print("Error adding/updating travel suggestion: $e");
    }
  }

  void _clearForm() {
    _countryController.clear();
    _shortDescController.clear();
    _fullDescController.clear();
    setState(() {
      _pickedImage = null;
    });
  }

  void _startEdit(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    _countryController.text = data['country'] ?? '';
    _shortDescController.text = data['shortDescription'] ?? '';
    _fullDescController.text = data['fullDescription'] ?? '';
    if (data['image'] != null) {
      _pickedImage = base64Decode(data['image']);
    }
    setState(() {
      _editingDocId = doc.id;
    });
  }

  void _deleteTravel(String docId) async {
    await FirebaseFirestore.instance.collection('eco_travel').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
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
                    controller: _countryController,
                    decoration: InputDecoration(
                      hintText: "Country",
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
                    controller: _shortDescController,
                    decoration: InputDecoration(
                      hintText: "Short Description",
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
                  TextField(
                    controller: _fullDescController,
                    decoration: InputDecoration(
                      hintText: "Full Description",
                      filled: true,
                      fillColor: Colors.green.shade50,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    maxLines: 4,
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
                    onPressed: _addOrUpdateTravel,
                    icon: const Icon(Icons.add, color: Colors.white),
                    label: Text(
                      _editingDocId != null ? "Update Travel" : "Add Travel",
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
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('eco_travel')
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
                            ? Image.memory(imageBytes,
                                width: 50, height: 50, fit: BoxFit.cover)
                            : null,
                        title: Text(data['country'] ?? ''),
                        subtitle: Text(data['shortDescription'] ?? ''),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _startEdit(docs[index]),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteTravel(docs[index].id),
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
