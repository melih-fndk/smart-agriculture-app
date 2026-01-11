import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:tarimus/services/weather_service.dart';
import 'package:tarimus/screens/hava_durumu_page.dart';
import 'package:tarimus/screens/tarlalarim_page.dart';
import 'package:tarimus/screens/gelir_gider_page.dart';
import 'package:geolocator/geolocator.dart';
import 'package:tarimus/screens/uzmanina_sor_page.dart';
import 'package:tarimus/screens/profil_sayfasi.dart';

class CiftciPanoEkran extends StatelessWidget {
  const CiftciPanoEkran({super.key});

  // 🔥 ÇİFTÇİYE BAĞLI UZMANLARI LİSTELEYEN VE SEÇTİRTEN FONKSİYON
  void _uzmanSecVeSor(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final uzmanBaglantilari = await FirebaseFirestore.instance
        .collection("expert_farmers")
        .where("farmerId", isEqualTo: uid)
        .get();

    if (uzmanBaglantilari.docs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Bağlı bir uzmanınız yok.")));
      return;
    }

    List<Map<String, dynamic>> uzmanlar = [];

    for (var doc in uzmanBaglantilari.docs) {
      final uzmanId = doc["expertId"];
      final uzmanDoc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uzmanId)
          .get();

      uzmanlar.add({
        "id": uzmanId,
        "name": uzmanDoc["name"],
        "email": uzmanDoc["email"],
      });
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          children: uzmanlar.map((u) {
            return ListTile(
              leading: const Icon(Icons.person, color: Colors.green),
              title: Text(u["name"]),
              subtitle: Text(u["email"]),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UzmaninaSorSayfa(uzmanId: u["id"]),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  //mesaj bildirimi

  void _showAnswerNotifications(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection("notifications")
        .where("farmerId", isEqualTo: uid)
        .orderBy("createdAt", descending: true)
        .get();

    showDialog(
      context: context,
      barrierDismissible: true,

      builder: (_) {
        return AlertDialog(
          title: const Text("Cevap Bildirimleri"),
          content: SizedBox(
            width: 300,
            height: 250,
            child: snap.docs.isEmpty
                ? const Center(child: Text("Henüz cevabınız yok."))
                : ListView(
                    children: snap.docs.map((d) {
                      final data = d.data() as Map<String, dynamic>;
                      return ListTile(
                        leading: const Icon(Icons.mail, color: Colors.green),
                        title: Text(data["message"]),
                        subtitle: data["createdAt"] != null
                            ? Text(data["createdAt"].toDate().toString())
                            : null,
                      );
                    }).toList(),
                  ),
          ),
        );
      },
    );
  }

  //mesaj bildirimi

  void _showNotifications(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection("notifications")
        .where("farmerId", isEqualTo: uid)
        .orderBy("createdAt", descending: true)
        .get();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Bildirimler"),
          content: SizedBox(
            width: 300,
            height: 300,
            child: ListView(
              children: snap.docs.map((d) {
                final data = d.data() as Map<String, dynamic>;
                return ListTile(
                  title: Text(data["message"]),
                  subtitle: Text(
                    data["createdAt"] != null
                        ? data["createdAt"].toDate().toString()
                        : "",
                  ),
                );
              }).toList(),
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

    // 🔵 Bildirimleri gördü → seen = true yap
    for (var doc in snap.docs) {
      doc.reference.update({"seen": true});
    }
  }

  // --- İstek Kabul ---
  Future<void> approveRequest(
    BuildContext context,
    String reqId,
    String expertId,
    String farmerId,
  ) async {
    final firestore = FirebaseFirestore.instance;

    await firestore.collection('requests').doc(reqId).update({
      'status': 'onaylandı',
    });

    await firestore.collection('expert_farmers').add({
      'expertId': expertId,
      'farmerId': farmerId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await FirebaseFirestore.instance.collection("notifications").add({
      "expertId": expertId,

      "type": "request_approved",
      "message": "Bir çiftçi isteğinizi kabul etti.",
      "seen": false,
      "createdAt": FieldValue.serverTimestamp(),
    });

    // 🔥 Bağlantıyı hemen kontrol et
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final q = await FirebaseFirestore.instance
        .collection("expert_farmers")
        .where("farmerId", isEqualTo: uid)
        .get();
    print("Bağlı uzman var mı? => ${q.docs.isNotEmpty}");

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Uzman bağlantısı kuruldu.")));
  }

  Future<String?> getLinkedExpertId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection("expert_farmers")
        .where("farmerId", isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first["expertId"];
  }

  // --- İstek Reddet ---
  Future<void> rejectRequest(String reqId) async {
    await FirebaseFirestore.instance.collection('requests').doc(reqId).update({
      'status': 'reddedildi',
    });
  }

  // --- TARLANIN İLK KONUMUNU AL ---
  Future<LatLng?> getFirstFieldLocation() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection('fields')
        .where('ownerId', isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;

    final data = snap.docs.first.data();
    final lat = data['latitude'];
    final lon = data['longitude'];

    if (lat == null || lon == null) return null;

    return LatLng(lat, lon);
  }

  Future<LatLng?> _getDeviceLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }

      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        return null; // Konum alınamaz → Kart yine de gizlenmesin
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      return null;
    }
  }

  // --- TR Hava durumu çevirisi ---
  String weatherToTR(String desc) {
    switch (desc) {
      case "clear sky":
        return "Açık Hava";
      case "few clouds":
        return "Az Bulutlu";
      case "scattered clouds":
        return "Parçalı Bulutlu";
      case "broken clouds":
        return "Çok Bulutlu";
      case "shower rain":
        return "Sağanak Yağış";
      case "rain":
        return "Yağmurlu";
      case "thunderstorm":
        return "Fırtına";
      case "snow":
        return "Karlı";
      case "mist":
        return "Sisli";
      case "haze":
        return "Puslu";
      default:
        return desc;
    }
  }

  // --- GELİR GİDER TARLA SEÇİMİ ---
  void _openFinanceSelector(BuildContext context) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final fs = FirebaseFirestore.instance;

    final snap = await fs
        .collection("fields")
        .where("ownerId", isEqualTo: uid)
        .get();

    if (snap.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Önce bir tarla eklemelisiniz!")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) {
        return ListView(
          children: snap.docs.map((doc) {
            final d = doc.data() as Map<String, dynamic>;

            return ListTile(
              leading: const Icon(Icons.agriculture, color: Colors.green),
              title: Text(d["fieldName"]),
              subtitle: Text("Ürün: ${d['cropType']}"),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GelirGiderPage(
                      fieldId: doc.id,
                      fieldName: d["fieldName"] ?? "Tarla",
                    ),
                  ),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  // --- Bildirim Popup ---
  void _showRequestsDialog(
    BuildContext context,
    List<QueryDocumentSnapshot> requests,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Gelen Uzman İstekleri"),
        content: requests.isEmpty
            ? const Text("Henüz bekleyen isteğiniz yok.")
            : SizedBox(
                width: 300,
                height: 230,
                child: ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    final data = req.data() as Map<String, dynamic>;
                    final expertName = data['expertName'] ?? 'Uzman';

                    return ListTile(
                      title: Text(
                        "$expertName size bir bağlantı isteği gönderdi.",
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check, color: Colors.green),
                            onPressed: () async {
                              await approveRequest(
                                context, // 1) BuildContext
                                req.id, // 2) reqId
                                data['expertId'], // 3) expertId
                                data['farmerId'], // 4) farmerId
                              );

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Uzman bağlantısı kuruldu!"),
                                ),
                              );

                              Navigator.pop(context);
                            },
                          ),

                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => rejectRequest(req.id),
                          ),
                        ],
                      ),
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
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final firestore = FirebaseFirestore.instance;

    final menuItems = [
      {
        "title": "Uzmanına Sor",
        "icon": Icons.question_answer,
        "color": Colors.orange,
      },
      {"title": "Hava Durumu", "icon": Icons.cloud, "color": Colors.blue},
      {
        "title": "Gelir / Gider",
        "icon": Icons.attach_money,
        "color": Colors.green,
      },
      {
        "title": "Tarlalarım",
        "icon": Icons.agriculture,
        "color": Colors.deepPurple,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Çiftçi Paneli"),
        backgroundColor: Colors.green,
        actions: [
          //profil butonu
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilSayfasi()),
              );
            },
          ),
          //bildirim butonu
          StreamBuilder<QuerySnapshot>(
            stream: firestore
                .collection('requests')
                .where('farmerId', isEqualTo: user.uid)
                .where('status', isEqualTo: 'bekliyor')
                .snapshots(),
            builder: (context, snapshot) {
              final hasRequests =
                  snapshot.hasData && snapshot.data!.docs.isNotEmpty;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      _showRequestsDialog(context, snapshot.data?.docs ?? []);
                    },
                  ),
                  if (hasRequests)
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

          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection("notifications")
                .where("farmerId", isEqualTo: user.uid)
                .where("seen", isEqualTo: false)
                .snapshots(),
            builder: (context, snap) {
              final hasNotif = snap.hasData && snap.data!.docs.isNotEmpty;

              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mail),
                    onPressed: () {
                      _showAnswerNotifications(context);
                    },
                  ),
                  if (hasNotif)
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
        ],
      ),

      // --- ANA BODY ---
      body: FutureBuilder<LatLng?>(
        future: _getDeviceLocation(),
        builder: (context, snap) {
          final devicePos = snap.data; // null olabilir — sorun değil

          return Column(
            children: [
              // ------------------------------
              // 📌 CİHAZ KONUMUNA GÖRE MİNİ HAVA DURUMU
              // ------------------------------
              if (devicePos != null)
                FutureBuilder<Map<String, dynamic>?>(
                  future: WeatherService().getWeather(
                    devicePos.latitude,
                    devicePos.longitude,
                  ),
                  builder: (context, weatherSnap) {
                    if (!weatherSnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      );
                    }

                    final w = weatherSnap.data!;
                    final temp = w["main"]["temp"];
                    final desc = weatherToTR(w["weather"][0]["description"]);

                    return Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.lightBlue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cloud,
                              size: 40,
                              color: Colors.blue,
                            ),
                            const SizedBox(width: 15),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "$temp°C",
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(desc),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // ------------------------------------
              // 📌 ALTTA MENÜ
              // ------------------------------------
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: GridView.builder(
                    itemCount: menuItems.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 15,
                          crossAxisSpacing: 15,
                        ),
                    itemBuilder: (context, index) {
                      final item = menuItems[index];
                      final String title = item["title"] as String;
                      final IconData icon = item["icon"] as IconData;
                      final Color color = item["color"] as Color;

                      return GestureDetector(
                        onTap: () {
                          switch (title) {
                            case "Tarlalarım":
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const TarlalarimPage(),
                                ),
                              );
                              break;

                            case "Uzmanına Sor":
                              _uzmanSecVeSor(context); // 🔥 YENİ EKLEDİĞİN KOD
                              break;

                            case "Gelir / Gider":
                              _openFinanceSelector(context);
                              break;

                            case "Hava Durumu":
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HavaDurumuPage(),
                                ),
                              );
                              break;
                          }
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: color, width: 2),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(icon, size: 48, color: color),
                              const SizedBox(height: 12),
                              Text(
                                title,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 17,
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
              ),
            ],
          );
        },
      ),
    );
  }
}
