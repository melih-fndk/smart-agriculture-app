import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tarimus/services/plan_service.dart';

class PlanOlusturPage extends StatefulWidget {
  final String farmerId;
  final String farmerName;
  final String fieldId;
  final String fieldName;
  final String cropType;
  final String weatherDescription;

  const PlanOlusturPage({
    super.key,
    required this.farmerId,
    required this.farmerName,
    required this.fieldId,
    required this.fieldName,
    required this.cropType,
    required this.weatherDescription,
  });

  @override
  State<PlanOlusturPage> createState() => _PlanOlusturPageState();
}

class _PlanOlusturPageState extends State<PlanOlusturPage> {
  List<Map<String, dynamic>> steps = [];

  @override
  void initState() {
    super.initState();

    steps = generatePlanSteps(
      cropType: widget.cropType,
      weatherDescription: widget.weatherDescription,
    );
  }

  // ------------------------------------------------------
  // 📌 YENİ ADIM EKLE
  // ------------------------------------------------------
  void _addManualStep() {
    setState(() {
      steps.add({
        "title": "Yeni Adım",
        "description": "",
        "category": "Genel", // ✅ EKLENDİ
        "expertNote": "", // ✅ EKLENDİ
        "suggestedBySystem": false,
        "completed": false,
        "completedAt": null,
        "dueDate": null,
      });
    });
  }

  // ------------------------------------------------------
  // 📌 PLANI KAYDET
  // ------------------------------------------------------
  Future<void> _savePlan() async {
    final expertId = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection("plans").add({
      "expertId": expertId,
      "farmerId": widget.farmerId,
      "farmerName": widget.farmerName,
      "fieldId": widget.fieldId,
      "fieldName": widget.fieldName,
      "cropType": widget.cropType,
      "createdAt": FieldValue.serverTimestamp(),
      "status": "aktif",
      "steps": steps,
    });

    // 🔔 BİLDİRİM
    await FirebaseFirestore.instance.collection("notifications").add({
      "farmerId": widget.farmerId,
      "expertId": expertId,
      "type": "plan",
      "message": "Uzmanınız sizin için yeni bir plan oluşturdu.",
      "seen": false,
      "createdAt": FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Plan başarıyla oluşturuldu")));

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Plan Oluştur"),
        backgroundColor: Colors.green,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addManualStep,
        backgroundColor: Colors.green,
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Çiftçi: ${widget.farmerName}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text("Tarla: ${widget.fieldName}"),
            Text("Ürün: ${widget.cropType}"),
            const SizedBox(height: 16),

            const Text(
              "Plan Adımları",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: steps.length,
                itemBuilder: (context, index) {
                  final step = steps[index];

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: step["title"],
                                  decoration: const InputDecoration(
                                    labelText: "Adım Başlığı",
                                  ),
                                  onChanged: (v) => step["title"] = v,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () {
                                  setState(() {
                                    steps.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),

                          TextFormField(
                            initialValue: step["description"],
                            decoration: const InputDecoration(
                              labelText: "Açıklama",
                            ),
                            onChanged: (v) => step["description"] = v,
                          ),

                          // 🔹 KATEGORİ
                          DropdownButtonFormField<String>(
                            value: step["category"],
                            decoration: const InputDecoration(
                              labelText: "Kategori",
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: "Ekim",
                                child: Text("🌱 Ekim"),
                              ),
                              DropdownMenuItem(
                                value: "Sulama",
                                child: Text("💧 Sulama"),
                              ),
                              DropdownMenuItem(
                                value: "Gübreleme",
                                child: Text("🧪 Gübreleme"),
                              ),
                              DropdownMenuItem(
                                value: "İlaçlama",
                                child: Text("🐛 İlaçlama"),
                              ),
                              DropdownMenuItem(
                                value: "Hasat",
                                child: Text("📦 Hasat"),
                              ),
                              DropdownMenuItem(
                                value: "Genel",
                                child: Text("📋 Genel"),
                              ),
                            ],
                            onChanged: (v) => step["category"] = v,
                          ),

                          // 🧠 UZMAN NOTU
                          TextFormField(
                            initialValue: step["expertNote"],
                            decoration: const InputDecoration(
                              labelText: "Uzman Notu",
                            ),
                            onChanged: (v) => step["expertNote"] = v,
                          ),

                          // 📅 TARİH
                          TextButton.icon(
                            icon: const Icon(Icons.calendar_today),
                            label: Text(
                              step["dueDate"] == null
                                  ? "Bitiş Tarihi Seç"
                                  : "Bitiş: ${(step["dueDate"] as Timestamp).toDate().day}."
                                        "${(step["dueDate"] as Timestamp).toDate().month}."
                                        "${(step["dueDate"] as Timestamp).toDate().year}",
                            ),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                                initialDate: DateTime.now(),
                              );
                              if (picked != null) {
                                setState(() {
                                  step["dueDate"] = Timestamp.fromDate(picked);
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: _savePlan,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text("Planı Kaydet"),
            ),
          ],
        ),
      ),
    );
  }
}
