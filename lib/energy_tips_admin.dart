import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EnergyTipsAdminPage extends StatefulWidget {
  const EnergyTipsAdminPage({super.key});

  @override
  State<EnergyTipsAdminPage> createState() => _EnergyTipsAdminPageState();
}

class _EnergyTipsAdminPageState extends State<EnergyTipsAdminPage> {
  final _titleController = TextEditingController();
  final _detailsController = TextEditingController();
  String? _selectedIcon;
  String? _editingDocId;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<Map<String, dynamic>> _availableIcons = [
    {'label': 'Light Bulb', 'icon': Icons.lightbulb_outline},
    {'label': 'Solar', 'icon': Icons.wb_sunny_outlined},
    {'label': 'Battery', 'icon': Icons.battery_charging_full},
    {'label': 'Power', 'icon': Icons.power_settings_new},
  ];

  void _saveTip() async {
    if (_titleController.text.isEmpty ||
        _detailsController.text.isEmpty ||
        _selectedIcon == null) {
      return;
    }

    final iconData = _availableIcons
        .firstWhere((e) => e['label'] == _selectedIcon)['icon'] as IconData;

    final tip = {
      'title': _titleController.text,
      'details': _detailsController.text,
      'iconLabel': _selectedIcon,
      'iconCodePoint': iconData.codePoint,
      'createdAt': FieldValue.serverTimestamp(),
    };

    if (_editingDocId == null) {
      await _firestore.collection('energy_tips').add(tip);
    } else {
      await _firestore.collection('energy_tips').doc(_editingDocId).update(tip);
    }

    _titleController.clear();
    _detailsController.clear();
    setState(() {
      _selectedIcon = null;
      _editingDocId = null;
    });
  }

  // ---------------- DELETE TIP ----------------
  void _deleteTip(String docId) async {
    await _firestore.collection('energy_tips').doc(docId).delete();
  }

  // ---------------- EDIT TIP ----------------
  void _editTip(String docId, Map<String, dynamic> data) {
    setState(() {
      _editingDocId = docId;
      _titleController.text = data['title'] ?? '';
      _detailsController.text = data['details'] ?? '';
      _selectedIcon = data['iconLabel'];
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      appBar: AppBar(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ---------------- FORM CARD ----------------
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(),
                    const SizedBox(height: 16),
                    // -------- TITLE INPUT --------
                    TextField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.title),
                        labelText: 'Tip Title',
                        filled: true,
                        fillColor: Colors.green[50],
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // -------- DETAILS INPUT --------
                    TextField(
                      controller: _detailsController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 70),
                          child: Icon(Icons.description_outlined),
                        ),
                        labelText: 'Details',
                        filled: true,
                        fillColor: Colors.green[50],
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // -------- ICON DROPDOWN --------
                    DropdownButtonFormField<String>(
                      initialValue: _selectedIcon,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.green[50],
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      ),
                      hint: const Text('Select Icon'),
                      items: _availableIcons.map((e) {
                        return DropdownMenuItem<String>(
                          value: e['label'],
                          child: Row(
                            children: [
                              Icon(e['icon'], color: Colors.green),
                              const SizedBox(width: 8),
                              Text(e['label']),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedIcon = val;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    // -------- BUTTON --------
                    ElevatedButton.icon(
                      onPressed: _saveTip,
                      icon: Icon(
                          _editingDocId == null ? Icons.add : Icons.save),
                      label: Text(
                        _editingDocId == null
                            ? "Add Tip"
                            : "Save Changes",
                        style: const TextStyle(color: Colors.white), // <--- Text color changed
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            // ---------------- TIP LIST ----------------
            StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('energy_tips')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final tips = snapshot.data!.docs;

                return Column(
                  children: tips.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final icon = IconData(
                      data['iconCodePoint'],
                      fontFamily: 'MaterialIcons',
                    );

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(icon, color: Colors.green, size: 32),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    data['title'] ?? '',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              data['details'] ?? '',
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                IconButton(
                                  onPressed: () => _editTip(doc.id, data),
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                ),
                                IconButton(
                                  onPressed: () => _deleteTip(doc.id),
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
