import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GelirGiderPage extends StatefulWidget {
  final String fieldId;
  final String fieldName;

  const GelirGiderPage({
    super.key,
    required this.fieldId,
    required this.fieldName,
  });

  @override
  State<GelirGiderPage> createState() => _GelirGiderPageState();
}

class _GelirGiderPageState extends State<GelirGiderPage> {
  String type = "Gelir";
  String subCategory = "Ürün Satışı";

  final amountCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  final firestore = FirebaseFirestore.instance;

  final gelirKategorileri = ["Ürün Satışı", "Destek Ödemesi", "Diğer Gelir"];

  final giderKategorileri = [
    "Akaryakıt",
    "Gübre",
    "İlaç",
    "Sulama",
    "İşçilik",
    "Makine Bakım",
    "Tohum",
    "Diğer",
  ];

  Future<void> addRecord() async {
    if (amountCtrl.text.isEmpty) return;

    await firestore.collection("income_expense").add({
      "fieldId": widget.fieldId,
      "type": type,
      "category": subCategory,
      "amount": double.parse(amountCtrl.text),
      "desc": descCtrl.text,
      "date": DateTime.now(),
    });

    amountCtrl.clear();
    descCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.fieldName} - Gelir / Gider"),
        backgroundColor: Colors.green,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 🔥 TOPLAM ÖZET ---
            StreamBuilder<QuerySnapshot>(
              stream: firestore
                  .collection("income_expense")
                  .where("fieldId", isEqualTo: widget.fieldId)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) return Text("Hata: ${snap.error}");
                if (!snap.hasData) return const SizedBox();

                double toplamGelir = 0;
                double toplamGider = 0;

                for (var d in snap.data!.docs) {
                  final type = d["type"];
                  final amount = (d["amount"] as num).toDouble();

                  if (type == "Gelir") toplamGelir += amount;
                  if (type == "Gider") toplamGider += amount;
                }

                final netKar = toplamGelir - toplamGider;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Toplam Gelir: ₺$toplamGelir",
                      style: const TextStyle(color: Colors.green, fontSize: 18),
                    ),
                    Text(
                      "Toplam Gider: ₺$toplamGider",
                      style: const TextStyle(color: Colors.red, fontSize: 18),
                    ),
                    Text(
                      "Net Kâr: ₺$netKar",
                      style: const TextStyle(color: Colors.blue, fontSize: 20),
                    ),
                    const Divider(thickness: 1),
                  ],
                );
              },
            ),

            // 🔥 LİSTE BÖLÜMÜ
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: firestore
                    .collection("income_expense")
                    .where("fieldId", isEqualTo: widget.fieldId)
                    .snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text("Hata: ${snap.error}"));
                  }

                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snap.data!.docs.toList()
                    ..sort((a, b) {
                      final da = (a["date"] as Timestamp).toDate();
                      final db = (b["date"] as Timestamp).toDate();
                      return db.compareTo(da);
                    });

                  if (docs.isEmpty) {
                    return const Center(child: Text("Henüz kayıt yok."));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final d = docs[i];
                      final type = d["type"];
                      final amount = (d["amount"] as num).toDouble();
                      final desc = d["desc"];
                      final cat = d["category"];
                      final date = (d["date"] as Timestamp).toDate();

                      return Card(
                        color: type == "Gelir"
                            ? Colors.green.shade100
                            : Colors.red.shade100,
                        child: ListTile(
                          leading: Icon(
                            type == "Gelir"
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                            color: type == "Gelir" ? Colors.green : Colors.red,
                          ),
                          title: Text(
                            "$amount ₺  •  $cat",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          subtitle: Text(
                            "$desc\n${date.day}.${date.month}.${date.year}",
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () {
                                  _duzenleDialoguAc(d);
                                },
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  _silmeOnayi(d.id);
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
            ),

            const SizedBox(height: 20),

            // 🔥 FORM - GELİR/GİDER EKLEME
            Row(
              children: [
                DropdownButton(
                  value: type,
                  items: const [
                    DropdownMenuItem(value: "Gelir", child: Text("Gelir")),
                    DropdownMenuItem(value: "Gider", child: Text("Gider")),
                  ],
                  onChanged: (v) => setState(() {
                    type = v!;
                    subCategory = type == "Gelir"
                        ? gelirKategorileri[0]
                        : giderKategorileri[0];
                  }),
                ),

                const SizedBox(width: 20),

                DropdownButton(
                  value: subCategory,
                  items:
                      (type == "Gelir" ? gelirKategorileri : giderKategorileri)
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) => setState(() => subCategory = v!),
                ),
              ],
            ),

            TextField(
              controller: amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Tutar (₺)"),
            ),

            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: "Açıklama"),
            ),

            const SizedBox(height: 12),

            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: addRecord,
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }

  void _silmeOnayi(String docId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Silinsin mi?"),
        content: const Text("Bu kayıt kalıcı olarak silinecek."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("income_expense")
                  .doc(docId)
                  .delete();

              Navigator.pop(context);
            },
            child: const Text("Sil", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _duzenleDialoguAc(DocumentSnapshot doc) {
    final kategoriCtrl = TextEditingController(text: doc['category']);
    final miktarCtrl = TextEditingController(text: doc['amount'].toString());
    final aciklamaCtrl = TextEditingController(text: doc['desc']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Kaydı Düzenle"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: kategoriCtrl,
              decoration: const InputDecoration(labelText: "Kategori"),
            ),
            TextField(
              controller: miktarCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Tutar"),
            ),
            TextField(
              controller: aciklamaCtrl,
              decoration: const InputDecoration(labelText: "Açıklama"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal"),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("income_expense")
                  .doc(doc.id)
                  .update({
                    "category": kategoriCtrl.text,
                    "amount": double.tryParse(miktarCtrl.text) ?? 0,
                    "desc": aciklamaCtrl.text,
                  });

              Navigator.pop(context);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }
}
