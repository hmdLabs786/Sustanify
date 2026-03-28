import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminChallengeScreen extends StatefulWidget {
  const AdminChallengeScreen({super.key});

  @override
  State<AdminChallengeScreen> createState() => _AdminChallengeScreenState();
}

class _AdminChallengeScreenState extends State<AdminChallengeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedDuration = '1 Day';
  int totalDays = 1;

  List<TextEditingController> dayControllers = [TextEditingController()];
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ---------------- GLASS BOX HELPER ----------------
  Widget _buildGlassContainer({required Widget child, double opacity = 0.2}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(opacity),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: child,
        ),
      ),
    );
  }

  // ---------------- ADD CHALLENGE ----------------
  Future<void> addChallenge() async {
    if (_titleController.text.isEmpty) return;

    String userId = _auth.currentUser!.uid;

    List<Map<String, dynamic>> tasks = [];
    for (int i = 0; i < totalDays; i++) {
      tasks.add({
        "day": i + 1,
        "text": dayControllers[i].text,
      });
    }

    final challengeData = {
      "title": _titleController.text,
      "description": _descriptionController.text,
      "duration": "$totalDays Days",
      "timestamp": FieldValue.serverTimestamp(),
      "tasks": tasks,
      "userId": userId,
    };

    await FirebaseFirestore.instance
        .collection("sustainable_challenges")
        .add(challengeData);

    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedDuration = "1 Day";
      totalDays = 1;
      dayControllers = [TextEditingController()];
    });
  }

  // ---------------- DELETE ----------------
  void deleteChallenge(String docId) {
    FirebaseFirestore.instance
        .collection("sustainable_challenges")
        .doc(docId)
        .delete();
  }

  // ---------------- EDIT CHALLENGE DIALOG ----------------
  void editChallengeDialog(String docId, Map<String, dynamic> data) {
    TextEditingController title = TextEditingController(text: data["title"]);
    TextEditingController desc = TextEditingController(text: data["description"]);

    int editDays = data["tasks"].length;
    List<TextEditingController> editTaskControllers =
        List.generate(editDays, (i) => TextEditingController(text: data["tasks"][i]["text"]));

    showDialog(
      context: context,
      builder: (context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: AlertDialog(
            backgroundColor: Colors.white.withOpacity(0.9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text("Edit Challenge", style: TextStyle(fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: title, decoration: const InputDecoration(labelText: "Title")),
                  const SizedBox(height: 10),
                  TextField(controller: desc, decoration: const InputDecoration(labelText: "Description")),
                  const SizedBox(height: 15),
                  const Divider(),
                  ...List.generate(editDays, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: TextField(
                        controller: editTaskControllers[i],
                        decoration: InputDecoration(labelText: "Day ${i + 1} Task"),
                      ),
                    );
                  }),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
              ElevatedButton(
                onPressed: () {
                  List<Map<String, dynamic>> updatedTasks = [];
                  for (int i = 0; i < editDays; i++) {
                    updatedTasks.add({"day": i + 1, "text": editTaskControllers[i].text});
                  }
                  FirebaseFirestore.instance.collection("sustainable_challenges").doc(docId).update({
                    "title": title.text,
                    "description": desc.text,
                    "tasks": updatedTasks,
                  });
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B5E20)),
                child: const Text("Save Changes", style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Challenge Admin", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Theme Background
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // --- INPUT SECTION ---
                  _buildGlassContainer(
                    opacity: 0.15,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Create Challenge", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                          const SizedBox(height: 20),
                          _buildField(_titleController, "Title", Icons.title),
                          const SizedBox(height: 12),
                          _buildField(_descriptionController, "Description", Icons.description, maxLines: 2),
                          const SizedBox(height: 12),
                          
                          // Duration Dropdown
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedDuration,
                                isExpanded: true,
                                items: ['1 Day', '2 Days', '3 Days', '4 Days', '5 Days', '6 Days', '7 Days'].map((item) {
                                  return DropdownMenuItem(value: item, child: Text(item));
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedDuration = value!;
                                    totalDays = int.parse(value.split(" ")[0]);
                                    dayControllers = List.generate(totalDays, (index) => TextEditingController());
                                  });
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          ...List.generate(totalDays, (index) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _buildField(dayControllers[index], "Day ${index + 1} Task", Icons.task_alt),
                            );
                          }),

                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: addChallenge,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withOpacity(0.9),
                                foregroundColor: const Color(0xFF1B5E20),
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              ),
                              child: const Text("Add Challenge", style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // --- LIST SECTION ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection("sustainable_challenges")
                        .orderBy("timestamp", descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                      final docs = snapshot.data!.docs;

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data = docs[index].data() as Map<String, dynamic>;
                          final tasks = List.from(data["tasks"] ?? []);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 15),
                            child: _buildGlassContainer(
                              opacity: 0.1,
                              child: ExpansionTile(
                                iconColor: Colors.white,
                                collapsedIconColor: Colors.white,
                                title: Text(data["title"] ?? "Untitiled", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                subtitle: Text("${data["duration"]} • ${tasks.length} tasks", style: const TextStyle(color: Colors.white70)),
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(data["description"] ?? "", style: const TextStyle(color: Colors.white)),
                                        const SizedBox(height: 10),
                                        ...tasks.map((t) => Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4),
                                          child: Text("• Day ${t["day"]}: ${t["text"]}", style: const TextStyle(color: Colors.white, fontSize: 13)),
                                        )),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(icon: const Icon(Icons.edit, color: Colors.white70), onPressed: () => editChallengeDialog(docs[index].id, data)),
                                            IconButton(icon: const Icon(Icons.delete, color: Colors.redAccent), onPressed: () => deleteChallenge(docs[index].id)),
                                          ],
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.black),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF1B5E20)),
        labelText: label,
        filled: true,
        fillColor: Colors.white.withOpacity(0.6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}