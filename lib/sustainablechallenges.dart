import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SustainableChallengesPage extends StatefulWidget {
  const SustainableChallengesPage({super.key});

  @override
  _SustainableChallengesPageState createState() =>
      _SustainableChallengesPageState();
}

class _SustainableChallengesPageState extends State<SustainableChallengesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    String userId = _auth.currentUser!.uid;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Eco-Challenges", 
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
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
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("sustainable_challenges")
                  .orderBy("timestamp", descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final tasks = List.from(data["tasks"] ?? []);
                    final challengeId = docs[index].id;

                    return StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection("sustainable_challenges")
                          .doc(challengeId)
                          .collection("users_progress")
                          .doc(userId)
                          .snapshots(),
                      builder: (context, userSnap) {
                        bool isJoined = false;
                        Map checkedTasks = {};
                        double progress = 0.0;

                        if (userSnap.hasData && userSnap.data!.exists) {
                          final userData = userSnap.data!.data() as Map<String, dynamic>;
                          isJoined = true;
                          checkedTasks = Map.from(userData["checkedTasks"] ?? {});
                          progress = (userData["progress"] ?? 0.0).toDouble();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: _buildGlassChallengeCard(
                            data, 
                            tasks, 
                            isJoined, 
                            checkedTasks, 
                            progress, 
                            challengeId, 
                            userId
                          ),
                        );
                      },
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

  Widget _buildGlassChallengeCard(
    Map<String, dynamic> data,
    List tasks,
    bool isJoined,
    Map checkedTasks,
    double progress,
    String challengeId,
    String userId,
  ) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        data["title"] ?? "Challenge",
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                    if (progress == 1.0)
                      const Icon(Icons.stars, color: Colors.amber, size: 28),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  data["description"] ?? "",
                  style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                ),
                const SizedBox(height: 12),
                
                // Join / Progress UI
                if (!isJoined)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _joinChallenge(challengeId, userId),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white.withOpacity(0.9),
                        foregroundColor: const Color(0xFF1B5E20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("Join Challenge", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  )
                else ...[
                  // Progress Bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "${(progress * 100).toInt()}% Completed • ${data["duration"]}",
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                  const Divider(color: Colors.white24, height: 24),
                  
                  // Task List
                  ...List.generate(tasks.length, (i) {
                    bool isChecked = checkedTasks["day$i"] ?? false;
                    return Theme(
                      data: ThemeData(unselectedWidgetColor: Colors.white70),
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          "Day ${tasks[i]["day"]}: ${tasks[i]["text"]}",
                          style: TextStyle(
                            color: isChecked ? Colors.white60 : Colors.white,
                            decoration: isChecked ? TextDecoration.lineThrough : null,
                            fontSize: 14,
                          ),
                        ),
                        value: isChecked,
                        activeColor: Colors.white,
                        checkColor: const Color(0xFF1B5E20),
                        onChanged: progress == 1.0 ? null : (_) => _toggleDay(i, checkedTasks, tasks.length, challengeId, userId),
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _joinChallenge(String challengeId, String userId) {
    FirebaseFirestore.instance
        .collection("sustainable_challenges")
        .doc(challengeId)
        .collection("users_progress")
        .doc(userId)
        .set({
      "checkedTasks": {},
      "progress": 0.0,
      "joinedAt": FieldValue.serverTimestamp(),
    });
  }

  void _toggleDay(int dayIndex, Map checkedTasks, int totalTasks, String challengeId, String userId) {
    // Local update logic
    Map<String, dynamic> updatedTasks = Map<String, dynamic>.from(checkedTasks);
    updatedTasks["day$dayIndex"] = !(updatedTasks["day$dayIndex"] ?? false);

    int completedCount = updatedTasks.values.where((val) => val == true).length;
    double newProgress = completedCount / totalTasks;

    FirebaseFirestore.instance
        .collection("sustainable_challenges")
        .doc(challengeId)
        .collection("users_progress")
        .doc(userId)
        .update({
      "checkedTasks": updatedTasks,
      "progress": newProgress,
    });
  }
}