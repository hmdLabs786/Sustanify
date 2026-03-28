import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddEducationContent extends StatefulWidget {
  const AddEducationContent({super.key});

  @override
  State<AddEducationContent> createState() => _AddEducationContentState();
}

class _AddEducationContentState extends State<AddEducationContent> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController linkController = TextEditingController();

  String selectedType = "Article";

  Future<void> uploadToFirebase() async {
    if (titleController.text.isEmpty ||
        descController.text.isEmpty ||
        linkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    await FirebaseFirestore.instance.collection("education_content").add({
      "title": titleController.text,
      "desc": descController.text,
      "type": selectedType,
      "link": linkController.text,
      "timestamp": DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Content Added Successfully!")),
    );

    titleController.clear();
    descController.clear();
    linkController.clear();
  }

  Future<void> deleteContent(String id) async {
    await FirebaseFirestore.instance.collection("education_content").doc(id).delete();
  }

  void showEditDialog(DocumentSnapshot doc) {
    titleController.text = doc["title"];
    descController.text = doc["desc"];
    linkController.text = doc["link"];
    selectedType = doc["type"];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Content"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: "Title"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: "Description"),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(labelText: "Link"),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField(
                  initialValue: selectedType,
                  items: const [
                    DropdownMenuItem(value: "Article", child: Text("Article")),
                    DropdownMenuItem(value: "Video", child: Text("Video")),
                    DropdownMenuItem(value: "Infographic", child: Text("Infographic")),
                  ],
                  onChanged: (value) => setState(() => selectedType = value!),
                ),
              ],
            ),
          ),

          actions: [
            TextButton(
              child: const Text("Cancel"),
              onPressed: () => Navigator.pop(context),
            ),
            ElevatedButton(
              child: const Text("Update"),
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection("education_content")
                    .doc(doc.id)
                    .update({
                  "title": titleController.text,
                  "desc": descController.text,
                  "type": selectedType,
                  "link": linkController.text,
                });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  // UI START -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),

      body: Column(
        children: [

          // ---------------------- Add Form ----------------------
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                DropdownButtonFormField(
                  initialValue: selectedType,
                  items: const [
                    DropdownMenuItem(value: "Article", child: Text("Article")),
                    DropdownMenuItem(value: "Video", child: Text("Video")),
                    DropdownMenuItem(value: "Infographic", child: Text("Infographic")),
                  ],
                  onChanged: (value) => setState(() => selectedType = value!),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),

                const SizedBox(height: 12),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Short Description",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),

                TextField(
                  controller: linkController,
                  decoration: const InputDecoration(
                    labelText: "Content Link",
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: uploadToFirebase,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    "Add Content",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),

          // ---------------------- SHOW DATA AREA ----------------------
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection("education_content")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),

              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No content added yet."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(doc["title"]),
                        subtitle: Text(doc["desc"]),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Edit Button
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => showEditDialog(doc),
                            ),

                            // Delete Button
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => deleteContent(doc.id),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
