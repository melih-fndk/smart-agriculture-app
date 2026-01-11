import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfilSayfasi extends StatelessWidget {
  const ProfilSayfasi({super.key});

  Future<Map<String, dynamic>> _getUserData() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fs = FirebaseFirestore.instance;

    final userDoc = await fs.collection("users").doc(uid).get();
    final userData = userDoc.data() ?? {};

    final role = userData["role"] ?? "farmer";

    if (role == "farmer") {
      final q = await fs
          .collection("expert_farmers")
          .where("farmerId", isEqualTo: uid)
          .limit(1)
          .get();

      if (q.docs.isNotEmpty) {
        final expertId = q.docs.first.get("expertId");
        final expertDoc = await fs.collection("users").doc(expertId).get();
        userData["bagliUzman"] = expertDoc.data();
      }
    } else {
      final q = await fs
          .collection("expert_farmers")
          .where("expertId", isEqualTo: uid)
          .get();

      List<Map<String, dynamic>> ciftciler = [];

      for (var doc in q.docs) {
        final farmerId = doc.get("farmerId");
        final farmerDoc = await fs.collection("users").doc(farmerId).get();
        if (farmerDoc.exists) {
          ciftciler.add(farmerDoc.data()!);
        }
      }

      userData["bagliCiftciler"] = ciftciler;
    }

    return userData;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Profilim"),
        backgroundColor: Colors.green,
      ),

      body: FutureBuilder(
        future: _getUserData(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snap.data as Map<String, dynamic>;
          final role = data["role"];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                Text(
                  "Ad Soyad: ${data['name'] ?? '-'}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),

                Text(
                  "E-posta: ${data['email'] ?? '-'}",
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 16),

                if (role == "farmer") ...[
                  const Text(
                    "Bağlı Olduğum Uzman:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if (data["bagliUzman"] != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.orange),
                        title: Text(data["bagliUzman"]["name"] ?? "Uzman"),
                        subtitle: Text(data["bagliUzman"]["email"] ?? ""),
                      ),
                    )
                  else
                    const Text("Henüz bir uzmana bağlı değilsiniz."),
                ],

                if (role == "expert") ...[
                  const Text(
                    "Bağlı Çiftçiler:",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  if (data["bagliCiftciler"] != null &&
                      data["bagliCiftciler"].isNotEmpty)
                    ...data["bagliCiftciler"].map<Widget>((c) {
                      return Card(
                        child: ListTile(
                          leading: const Icon(
                            Icons.agriculture,
                            color: Colors.green,
                          ),
                          title: Text(c["name"] ?? "Çiftçi"),
                          subtitle: Text(c["email"] ?? ""),
                        ),
                      );
                    }).toList()
                  else
                    const Text("Hiçbir çiftçi bağlı değil."),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}
