import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tarimus/utilities/cities.dart';

class UzmanCiftcilerPage extends StatefulWidget {
  const UzmanCiftcilerPage({super.key});

  @override
  State<UzmanCiftcilerPage> createState() => _UzmanCiftcilerPageState();
}

class _UzmanCiftcilerPageState extends State<UzmanCiftcilerPage> {
  String? selectedCity;

  @override
  void initState() {
    super.initState();
    _loadExpertCity();
  }

  // 🔹 Uzmanın kayıtlı şehrini al (varsayılan filtre)
  Future<void> _loadExpertCity() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    if (doc.exists && doc.data() != null) {
      setState(() {
        selectedCity = doc['city'];
      });
    }
  }

  // 🔹 Uzman → Çiftçiye istek gönder
  Future<void> sendRequest(String expertId, String farmerId) async {
    final firestore = FirebaseFirestore.instance;
    final expertDoc = await firestore.collection('users').doc(expertId).get();
    final expertName = expertDoc['name'] ?? 'Uzman';

    final existing = await firestore
        .collection('requests')
        .where('expertId', isEqualTo: expertId)
        .where('farmerId', isEqualTo: farmerId)
        .where('status', isEqualTo: 'bekliyor')
        .get();

    if (existing.docs.isNotEmpty) return;

    await firestore.collection('requests').add({
      'expertId': expertId,
      'expertName': expertName,
      'farmerId': farmerId,
      'status': 'bekliyor',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;
    final currentExpert = FirebaseAuth.instance.currentUser!;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Çiftçi Listesi"),
        backgroundColor: Colors.green,
      ),
      body: Column(
        children: [
          // 🔽 ŞEHİR FİLTRESİ
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              value: selectedCity,
              hint: const Text("Şehir seç"),
              items: turkiyeSehirleri.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedCity = val;
                });
              },
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
            ),
          ),

          // 🔽 ÇİFTÇİ LİSTESİ
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: selectedCity == null
                  ? firestore
                        .collection('users')
                        .where('role', isEqualTo: 'ciftci')
                        .snapshots()
                  : firestore
                        .collection('users')
                        .where('role', isEqualTo: 'ciftci')
                        .where('city', isEqualTo: selectedCity)
                        .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Bu şehirde kayıtlı çiftçi yok."),
                  );
                }

                final ciftciler = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: ciftciler.length,
                  itemBuilder: (context, index) {
                    final doc = ciftciler[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final email = data['email'] ?? 'Bilinmiyor';
                    final name = data['name'] ?? email;
                    final city = data['city'] ?? '-';
                    final farmerId = doc.id;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.green),
                        title: Text(name),
                        subtitle: Text("$email • $city"),
                        trailing: ElevatedButton.icon(
                          icon: const Icon(Icons.person_add_alt_1),
                          label: const Text("Ekle"),
                          onPressed: () async {
                            await sendRequest(currentExpert.uid, farmerId);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "$name adlı çiftçiye istek gönderildi.",
                                ),
                              ),
                            );
                          },
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
