import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:tarimus/screens/gelir_gider_page.dart';
import 'package:tarimus/screens/map_select_page.dart';
import 'package:tarimus/screens/ciftci_planlar_page.dart';

class TarlalarimPage extends StatefulWidget {
  const TarlalarimPage({super.key});

  @override
  State<TarlalarimPage> createState() => _TarlalarimPageState();
}

class _TarlalarimPageState extends State<TarlalarimPage> {
  final user = FirebaseAuth.instance.currentUser!;
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tarlalarım")),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
        onPressed: () => _showAddFieldDialog(context),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('fields')
            .where('ownerId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final fields = snapshot.data!.docs;

          if (fields.isEmpty) {
            return const Center(child: Text("Henüz tarla eklenmemiş."));
          }

          return ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final field = fields[index];
              final data = field.data() as Map<String, dynamic>;

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.agriculture, color: Colors.green),

                  title: Text(data['fieldName']),
                  subtitle: Text(
                    "Ürün: ${data['cropType']}\n"
                    "Konum: ${data['latitude']}, ${data['longitude']}",
                  ),

                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CiftciPlanlarPage(
                          fieldId: field.id,
                          fieldName: data["fieldName"] ?? "Tarla",
                        ),
                      ),
                    );
                  },

                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ✏️ DÜZENLE
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          _showEditFieldDialog(context, field.id, data);
                        },
                      ),

                      // 🗑 SİL
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteField(field.id);
                        },
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

  // 🔥 TARLA SİLME
  Future<void> _deleteField(String fieldId) async {
    await _firestore.collection('fields').doc(fieldId).delete();
  }

  // 🔥 TARLA DÜZENLEME DİYALOĞU
  void _showEditFieldDialog(
    BuildContext context,
    String fieldId,
    Map<String, dynamic> oldData,
  ) {
    final nameCtrl = TextEditingController(text: oldData['fieldName']);
    final cropCtrl = TextEditingController(text: oldData['cropType']);
    final noteCtrl = TextEditingController(text: oldData['notes']);

    double? latitude = oldData['latitude'];
    double? longitude = oldData['longitude'];

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Tarlayı Düzenle"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Tarla Adı"),
                  ),
                  TextField(
                    controller: cropCtrl,
                    decoration: const InputDecoration(labelText: "Ürün Türü"),
                  ),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: "Not"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text("Konumu Değiştir"),
                    onPressed: () async {
                      final LatLng? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapSelectPage(),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          latitude = result.latitude;
                          longitude = result.longitude;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("İptal"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Kaydet"),
                onPressed: () async {
                  await _firestore.collection('fields').doc(fieldId).update({
                    'fieldName': nameCtrl.text,
                    'cropType': cropCtrl.text,
                    'notes': noteCtrl.text,
                    'latitude': latitude,
                    'longitude': longitude,
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // 🔥 TARLA EKLEME
  void _showAddFieldDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final cropCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    double? latitude;
    double? longitude;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Yeni Tarla Ekle"),
            content: SingleChildScrollView(
              child: Column(
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: "Tarla Adı"),
                  ),
                  TextField(
                    controller: cropCtrl,
                    decoration: const InputDecoration(labelText: "Ürün Türü"),
                  ),
                  TextField(
                    controller: noteCtrl,
                    decoration: const InputDecoration(labelText: "Not"),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.map),
                    label: const Text("Haritadan Seç"),
                    onPressed: () async {
                      final LatLng? result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MapSelectPage(),
                        ),
                      );
                      if (result != null) {
                        setState(() {
                          latitude = result.latitude;
                          longitude = result.longitude;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text("İptal"),
                onPressed: () => Navigator.pop(context),
              ),
              ElevatedButton(
                child: const Text("Kaydet"),
                onPressed: () async {
                  await _firestore.collection('fields').add({
                    'ownerId': user.uid,
                    'fieldName': nameCtrl.text,
                    'cropType': cropCtrl.text,
                    'notes': noteCtrl.text,
                    'latitude': latitude,
                    'longitude': longitude,
                    'sowingDate': DateTime.now(),
                  });

                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
