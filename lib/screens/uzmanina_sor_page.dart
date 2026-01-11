import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_picker_web/image_picker_web.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class UzmaninaSorSayfa extends StatefulWidget {
  final String uzmanId;

  const UzmaninaSorSayfa({super.key, required this.uzmanId});

  @override
  State<UzmaninaSorSayfa> createState() => _UzmaninaSorSayfaState();
}

class _UzmaninaSorSayfaState extends State<UzmaninaSorSayfa> {
  final TextEditingController soruCtrl = TextEditingController();

  Uint8List? webResim;
  File? mobilResim;

  bool yukleniyor = false;

  // ------------------------------------------------------------
  // FOTOĞRAF SEÇ
  // ------------------------------------------------------------
  Future<void> resimSec() async {
    if (kIsWeb) {
      final bytes = await ImagePickerWeb.getImageAsBytes();
      if (bytes != null) {
        setState(() {
          webResim = bytes;
        });
      }
    } else {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          mobilResim = File(picked.path);
        });
      }
    }
  }

  // ------------------------------------------------------------
  // SORUYU GÖNDER (MESAJ ANINDA GİDER)
  // ------------------------------------------------------------
  Future<void> soruyuGonder() async {
    if (soruCtrl.text.trim().isEmpty &&
        webResim == null &&
        mobilResim == null) {
      return;
    }

    setState(() => yukleniyor = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // 1️⃣ Firestore’a MESAJI ANINDA YAZ
    final docRef = await FirebaseFirestore.instance
        .collection("uzman_sorulari")
        .add({
          "ciftciId": uid,
          "uzmanId": widget.uzmanId,
          "soru": soruCtrl.text.trim(),
          "resim": null,
          "tarih": FieldValue.serverTimestamp(),
          "durum": "bekliyor",
          "cevap": null,
        });
    await FirebaseFirestore.instance.collection("notifications").add({
      "expertId": widget.uzmanId,
      "farmerId": uid,
      "type": "message",
      "message": "Yeni mesajınız var.",
      "seen": false,
      "createdAt": FieldValue.serverTimestamp(),
    });

    // 2️⃣ Foto varsa ARKADAN yükle
    if (webResim != null || mobilResim != null) {
      _resmiYukleVeGuncelle(docRef.id);
    }

    // UI temizliği
    soruCtrl.clear();
    setState(() {
      webResim = null;
      mobilResim = null;
      yukleniyor = false;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Soru gönderildi")));

    Navigator.pop(context);
  }

  // ------------------------------------------------------------
  // FOTOĞRAF YÜKLE + FIRESTORE UPDATE
  // ------------------------------------------------------------
  Future<void> _resmiYukleVeGuncelle(String docId) async {
    try {
      final fileName = "soru_${DateTime.now().millisecondsSinceEpoch}.jpg";
      final ref = FirebaseStorage.instance.ref().child(
        "uzman_sorular/$fileName",
      );

      if (kIsWeb && webResim != null) {
        await ref.putData(
          webResim!,
          SettableMetadata(contentType: "image/jpeg"),
        );
      } else if (!kIsWeb && mobilResim != null) {
        await ref.putFile(mobilResim!);
      } else {
        return;
      }

      final url = await ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection("uzman_sorulari")
          .doc(docId)
          .update({"resim": url});

      debugPrint("✅ Resim yüklendi: $url");
    } catch (e) {
      debugPrint("🚨 Resim yükleme hatası: $e");
    }
  }

  // ------------------------------------------------------------
  // UI
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    Widget fotoWidget;

    if (kIsWeb && webResim != null) {
      fotoWidget = Image.memory(webResim!, fit: BoxFit.cover);
    } else if (!kIsWeb && mobilResim != null) {
      fotoWidget = Image.file(mobilResim!, fit: BoxFit.cover);
    } else {
      fotoWidget = const Center(child: Text("Fotoğraf eklemek için tıkla"));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Uzmanına Sor"),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text("Sorunuzu Yazın:"),
            const SizedBox(height: 8),
            TextField(
              controller: soruCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Örn: Yapraklar sarardı...",
              ),
            ),
            const SizedBox(height: 16),
            const Text("Fotoğraf Seç (isteğe bağlı):"),
            const SizedBox(height: 8),
            InkWell(
              onTap: resimSec,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey),
                ),
                child: fotoWidget,
              ),
            ),
            const SizedBox(height: 24),
            yukleniyor
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: soruyuGonder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text("Gönder"),
                  ),
          ],
        ),
      ),
    );
  }
}
