import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityForumScreen extends StatefulWidget {
  const CommunityForumScreen({super.key});

  @override
  State<CommunityForumScreen> createState() => _CommunityForumScreenState();
}

class _CommunityForumScreenState extends State<CommunityForumScreen> {
  final TextEditingController _postController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String userName = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentUserName();
  }

  Future<void> _loadCurrentUserName() async {
    final user = _auth.currentUser;
    if (user != null) {
      final doc = await _firestore.collection("User").doc(user.uid).get();
      if (doc.exists) {
        setState(() => userName = doc.data()?['UserName'] ?? 'User');
      }
    }
  }

  Future<void> _addOrUpdatePost({String? postId}) async {
    final text = _postController.text.trim();
    if (text.isEmpty) return;
    final user = _auth.currentUser;
    if (user == null) return;

    if (postId == null) {
      await _firestore.collection('community_posts').add({
        'userId': user.uid,
        'userName': userName,
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } else {
      await _firestore.collection('community_posts').doc(postId).update({
        'message': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
    }
    _postController.clear();
  }

  Future<void> _deletePost(String postId) async {
    await _firestore.collection('community_posts').doc(postId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Community Forum", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Background Gradient matching Home/Gallery
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
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('community_posts')
                        .orderBy('timestamp', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Colors.white));
                      
                      final posts = snapshot.data!.docs;
                      if (posts.isEmpty) {
                        return const Center(child: Text("No posts yet. Start the conversation!", style: TextStyle(color: Colors.white70)));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        itemCount: posts.length,
                        itemBuilder: (context, index) {
                          final post = posts[index];
                          final data = post.data() as Map<String, dynamic>;
                          return _buildGlassPostCard(post.id, data);
                        },
                      );
                    },
                  ),
                ),
                _buildMessageInput(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassPostCard(String postId, Map<String, dynamic> data) {
    final bool isMe = data['userId'] == _auth.currentUser?.uid;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isMe ? "You" : (data['userName'] ?? "Eco User"),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (isMe)
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_note, color: Colors.white70, size: 20),
                            onPressed: () => _showEditDialog(postId, data['message']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent, size: 20),
                            onPressed: () => _deletePost(postId),
                          ),
                        ],
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data['message'] ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _postController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Share your eco journey...",
                hintStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _addOrUpdatePost(),
            child: const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.send_rounded, color: Color(0xFF1B5E20)),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(String postId, String currentMsg) {
    _postController.text = currentMsg;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B5E20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Edit Post", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _postController,
          style: const TextStyle(color: Colors.white),
          maxLines: 3,
          decoration: const InputDecoration(enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white))),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel", style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () {
              _addOrUpdatePost(postId: postId);
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}