import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CiftciPlanlarPage extends StatelessWidget {
  final String fieldId;
  final String fieldName;

  const CiftciPlanlarPage({
    super.key,
    required this.fieldId,
    required this.fieldName,
  });

  @override
  Widget build(BuildContext context) {
    final String farmerId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text("Plan – $fieldName"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("plans")
            .where("farmerId", isEqualTo: farmerId)
            .where("fieldId", isEqualTo: fieldId)
            .where("status", isEqualTo: "aktif")
            .orderBy("createdAt", descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("Bu tarla için henüz plan yok."));
          }

          final planDoc = snapshot.data!.docs.first;
          final List steps = planDoc["steps"];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: steps.length,
            itemBuilder: (context, index) {
              final step = Map<String, dynamic>.from(steps[index]);
              final bool completed = step["completed"] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: CheckboxListTile(
                  value: completed,
                  onChanged: (val) async {
                    steps[index]["completed"] = val ?? false;
                    steps[index]["completedAt"] = val == true
                        ? Timestamp.now()
                        : null;

                    await planDoc.reference.update({"steps": steps});
                  },
                  title: Text(
                    step["title"] ?? "",
                    style: TextStyle(
                      decoration: completed ? TextDecoration.lineThrough : null,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (step["description"] != null &&
                          step["description"].toString().isNotEmpty)
                        Text(step["description"]),

                      if (step["category"] != null)
                        Text(
                          "Kategori: ${step["category"]}",
                          style: const TextStyle(fontSize: 12),
                        ),

                      if (step["expertNote"] != null &&
                          step["expertNote"].toString().isNotEmpty)
                        Text(
                          "🧠 Uzman Notu: ${step["expertNote"]}",
                          style: const TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),

                      if (step["dueDate"] != null)
                        Text(
                          "Bitiş Tarihi: ${(step["dueDate"] as Timestamp).toDate().day}."
                          "${(step["dueDate"] as Timestamp).toDate().month}."
                          "${(step["dueDate"] as Timestamp).toDate().year}",
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
