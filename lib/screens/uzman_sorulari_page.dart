import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UzmanSorulariSayfa extends StatelessWidget {
  const UzmanSorulariSayfa({super.key});

  @override
  Widget build(BuildContext context) {
    final String uzmanId = FirebaseAuth.instance.currentUser!.uid;

    final Stream<QuerySnapshot> soruStream = FirebaseFirestore.instance
        .collection("uzman_sorulari")
        .where("uzmanId", isEqualTo: uzmanId)
        .orderBy("tarih", descending: true)
        .snapshots();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gelen Çiftçi Soruları"),
        backgroundColor: Colors.green,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: soruStream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text("Hata: ${snap.error}"));
          }

          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data!.docs;

          if (docs.isEmpty) {
            return const Center(
              child: Text(
                "Bu uzmana ait hiç soru bulunmuyor.",
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final docRef = docs[i].reference;

              final String soru = data["soru"] ?? "Soru yazılmamış";
              final String durum = data["durum"] ?? "bekliyor";
              final String? resimUrl = data["resim"];
              final DateTime tarih = (data["tarih"] as Timestamp).toDate();
              final String? cevap = data["cevap"];

              return Card(
                margin: const EdgeInsets.all(10),
                child: ListTile(
                  leading: resimUrl != null && resimUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            resimUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image),
                          ),
                        )
                      : const Icon(Icons.image_not_supported, size: 40),

                  title: Text(
                    soru,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        durum == "bekliyor"
                            ? "Durum: Bekliyor"
                            : "Durum: Cevaplandı",
                        style: TextStyle(
                          color: durum == "bekliyor"
                              ? Colors.orange
                              : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Tarih: ${tarih.day}.${tarih.month}.${tarih.year}",
                        style: const TextStyle(fontSize: 12),
                      ),
                      if (cevap != null)
                        Text(
                          "Cevap: $cevap",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                    ],
                  ),

                  onTap: () {
                    _cevapPenceresi(
                      context,
                      docRef,
                      soru,
                      cevap,
                      data["ciftciId"], // 🔥 yeni
                      data["uzmanId"], // 🔥 yeni
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // -------------------------------------------------------------------
  // 📌 CEVAP PENCERESİ
  // -------------------------------------------------------------------
  void _cevapPenceresi(
    BuildContext context,
    DocumentReference ref,
    String soru,
    String? mevcutCevap,
    String ciftciId, // 🔥 yeni parametre
    String uzmanId, // 🔥 yeni parametre
  ) {
    final cevapCtrl = TextEditingController(text: mevcutCevap);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Soruyu Cevapla"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Soru:", style: TextStyle(fontWeight: FontWeight.bold)),
              Text(soru),
              const SizedBox(height: 10),
              TextField(
                controller: cevapCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: "Cevabınız",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: const Text("İptal"),
              onPressed: () => Navigator.pop(context),
            ),
            TextButton(
              child: const Text("Kaydet"),
              onPressed: () async {
                await ref.update({
                  "cevap": cevapCtrl.text.trim(),
                  "durum": "cevaplandı",
                  "cevapTarihi": DateTime.now(),
                });

                //  Çiftçiye bildirim gönder
                await FirebaseFirestore.instance
                    .collection("notifications")
                    .add({
                      "farmerId": ciftciId,
                      "expertId": uzmanId,
                      "soruId": ref.id,
                      "message": "Uzman sorunuza cevap verdi.",
                      "seen": false,
                      "createdAt": FieldValue.serverTimestamp(),
                    });

                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }
}
