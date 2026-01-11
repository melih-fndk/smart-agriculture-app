import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:tarimus/screens/uzman_ciftciler_page.dart';
import 'package:tarimus/screens/uzman_sorulari_page.dart';
import 'package:tarimus/screens/profil_sayfasi.dart';
import 'package:tarimus/screens/uzman_bagli_ciftciler.dart';

class UzmanPanoEkran extends StatefulWidget {
  const UzmanPanoEkran({super.key});

  @override
  State<UzmanPanoEkran> createState() => _UzmanPanoEkranState();
}

class _UzmanPanoEkranState extends State<UzmanPanoEkran> {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  // 🔔 Bildirim penceresi: HEMEN AÇILIR, içerik stream ile yüklenir
  void _openNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Bildirimler"),
          content: SizedBox(
            width: 320,
            height: 320,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection("notifications")
                  .where("expertId", isEqualTo: uid)
                  .where("type", whereIn: ["message", "request_approved"])
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(child: Text("Hata: ${snap.error}"));
                }

                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snap.data!.docs.toList();

                // 🔽 SIRALAMA (Firestore yerine Dart tarafı)
                docs.sort((a, b) {
                  final aTime = a["createdAt"];
                  final bTime = b["createdAt"];
                  if (aTime == null || bTime == null) return 0;
                  return (bTime as Timestamp).compareTo(aTime as Timestamp);
                });

                if (docs.isEmpty) {
                  return const Center(child: Text("Bildirim yok"));
                }

                // 🔵 Görülenleri seen=true yap
                Future.microtask(() async {
                  for (final d in docs) {
                    final data = d.data() as Map<String, dynamic>;
                    if (data["seen"] == false) {
                      await d.reference.update({"seen": true});
                    }
                  }
                });

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final msg = (data["message"] ?? "").toString();

                    DateTime? dt;
                    final createdAt = data["createdAt"];
                    if (createdAt is Timestamp) {
                      dt = createdAt.toDate();
                    }

                    return ListTile(
                      leading: Icon(
                        data["type"] == "message"
                            ? Icons.mail
                            : Icons.notifications,
                        color: Colors.green,
                      ),
                      title: Text(msg),
                      subtitle: dt != null ? Text(dt.toString()) : null,
                    );
                  },
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Kapat"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        "title": "Plan Oluştur",
        "icon": Icons.edit_calendar,
        "color": Colors.green,
      },
      {"title": "Çiftçi Listesi", "icon": Icons.people, "color": Colors.orange},
      {"title": "Bağlı Çiftçiler", "icon": Icons.link, "color": Colors.teal},
      {"title": "Veri Analizi", "icon": Icons.bar_chart, "color": Colors.blue},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Uzman Paneli"),
        backgroundColor: Colors.green.shade700,
        actions: [
          // 🔴 Badge (seen=false) -> index gerektirmeyen basit query
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("notifications")
                .where("expertId", isEqualTo: uid)
                .where("seen", isEqualTo: false)
                .snapshots(),

            builder: (context, snapshot) {
              final hasNew = snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: _openNotificationsDialog,
                  ),
                  if (hasNew)
                    const Positioned(
                      right: 8,
                      top: 8,
                      child: CircleAvatar(
                        radius: 6,
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilSayfasi()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          itemCount: menuItems.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
          ),
          itemBuilder: (context, index) {
            final item = menuItems[index];
            return GestureDetector(
              onTap: () {
                if (item["title"] == "Çiftçi Listesi") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UzmanCiftcilerPage(),
                    ),
                  );
                } else if (item["title"] == "Plan Oluştur") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const UzmanBagliCiftciler(selectMode: true),
                    ),
                  );
                } else if (item["title"] == "Bağlı Çiftçiler") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UzmanBagliCiftciler(),
                    ),
                  );
                } else if (item["title"] == "Veri Analizi") {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const UzmanSorulariSayfa(),
                    ),
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  color: (item["color"] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: item["color"], width: 1.5),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item["icon"], color: item["color"], size: 45),
                    const SizedBox(height: 10),
                    Text(
                      item["title"],
                      style: TextStyle(
                        color: item["color"],
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
