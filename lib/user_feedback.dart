import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserFeedbackScreen extends StatelessWidget {
  const UserFeedbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    return Scaffold(
      // ⭐ REMOVE EXTRA SPACING
      body: SafeArea(
        top: false,       // <<< removes the yellow highlighted gap
        child: StreamBuilder<QuerySnapshot>(
          stream: firestore
              .collection('community_posts')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(
                child: Text(
                  "No feedback yet.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            final posts = snapshot.data!.docs;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: posts.map((post) {
                  final data = post.data() as Map<String, dynamic>;
                  final userName = data['userName'] ?? 'User';
                  final feedback = data['message'] ?? '';

                  return feedbackCard(
                    postId: post.id,
                    userName: userName,
                    feedback: feedback,
                    color: Colors.orange,
                    firestore: firestore,
                    context: context,
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget feedbackCard({
    required String postId,
    required String userName,
    required String feedback,
    required Color color,
    required FirebaseFirestore firestore,
    required BuildContext context,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black87),
            ),
            const SizedBox(height: 6),
            Text(
              feedback,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () async {
                    await firestore.collection('community_posts').doc(postId).delete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Post deleted successfully.")),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
