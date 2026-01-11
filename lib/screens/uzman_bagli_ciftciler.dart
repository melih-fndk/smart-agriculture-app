import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tarimus/screens/plan_olustur_page.dart';

class UzmanBagliCiftciler extends StatelessWidget {
  final bool selectMode;
  const UzmanBagliCiftciler({super.key, this.selectMode = false});

  Future<Map<String, dynamic>?> _getFarmerInfo(String farmerId) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(farmerId)
        .get();

    return doc.data();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Bağlı Çiftçilerim"),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("expert_farmers")
            .where("expertId", isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final list = snap.data!.docs;

          if (list.isEmpty) {
            return const Center(child: Text("Bu uzmana bağlı çiftçi yok."));
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, i) {
              final farmerId = list[i]["farmerId"];

              return FutureBuilder<Map<String, dynamic>?>(
                future: _getFarmerInfo(farmerId),
                builder: (context, farmerSnap) {
                  if (!farmerSnap.hasData) {
                    return const ListTile(title: Text("Yükleniyor..."));
                  }

                  final farmer = farmerSnap.data!;
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(Icons.person, color: Colors.green),
                      title: Text(farmer["name"] ?? "İsim Yok"),
                      subtitle: Text(farmer["email"] ?? "-"),
                      trailing: selectMode
                          ? const Icon(Icons.arrow_forward_ios, size: 16)
                          : null,

                      onTap: selectMode
                          ? () {
                              _showFieldSelector(
                                context,
                                farmerId,
                                farmer["name"] ?? "Çiftçi",
                              );
                            }
                          : null,
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  void _showFieldSelector(
    BuildContext context,
    String farmerId,
    String farmerName,
  ) async {
    final fieldSnap = await FirebaseFirestore.instance
        .collection("fields")
        .where("ownerId", isEqualTo: farmerId)
        .get();

    if (fieldSnap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bu çiftçinin kayıtlı tarlası yok.")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  "Tarla Seç",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              const Divider(),

              ListView.builder(
                shrinkWrap: true,
                itemCount: fieldSnap.docs.length,
                itemBuilder: (context, index) {
                  final fieldDoc = fieldSnap.docs[index];
                  final data = fieldDoc.data();

                  final fieldId = fieldDoc.id;
                  final fieldName = (data["fieldName"] ?? "Tarla").toString();
                  final cropType = (data["cropType"] ?? "bilinmiyor")
                      .toString();

                  return ListTile(
                    leading: const Icon(Icons.agriculture, color: Colors.green),
                    title: Text(fieldName),
                    subtitle: Text("Ürün: $cropType"),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.pop(context);

                      _goToPlanCreateWithField(
                        context,
                        farmerId,
                        farmerName,
                        fieldId,
                        fieldName,
                        cropType,
                      );
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _goToPlanCreateWithField(
    BuildContext context,
    String farmerId,
    String farmerName,
    String fieldId,
    String fieldName,
    String cropType,
  ) {
    const weatherDescription = "normal";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanOlusturPage(
          farmerId: farmerId,
          farmerName: farmerName,
          fieldId: fieldId,
          fieldName: fieldName,
          cropType: cropType,
          weatherDescription: weatherDescription,
        ),
      ),
    );
  }
}
