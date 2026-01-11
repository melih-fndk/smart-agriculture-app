import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tarimus/services/weather_service.dart';

class HavaDurumuPage extends StatefulWidget {
  const HavaDurumuPage({super.key});

  @override
  State<HavaDurumuPage> createState() => _HavaDurumuPageState();
}

class _HavaDurumuPageState extends State<HavaDurumuPage> {
  final firestore = FirebaseFirestore.instance;

  // Açıklamayı Türkçeye çevir
  String toTR(String desc) {
    switch (desc) {
      case "clear sky":
        return "Açık";
      case "few clouds":
        return "Az Bulutlu";
      case "scattered clouds":
        return "Parçalı Bulutlu";
      case "broken clouds":
        return "Çok Bulutlu";
      case "rain":
        return "Yağmurlu";
      case "shower rain":
        return "Sağanak Yağış";
      case "thunderstorm":
        return "Fırtına";
      case "snow":
        return "Karlı";
      case "mist":
        return "Sisli";
      case "haze":
        return "Puslu";
      case "overcast clouds":
        return "Kapalı";

      default:
        return desc;
    }
  }

  // Risk analizi
  String riskDurumu(String desc, double temp, double wind) {
    if (temp <= 2) return "⚠️ Don riski";
    if (desc.contains("rain")) return "🌧 Sağanak riski";
    if (desc.contains("storm")) return "🌩 Fırtına riski";
    if (wind > 12) return "💨 Rüzgar riski";
    return "🍃 Normal";
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text("Tarlalarda Hava Durumu")),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection("fields")
            .where("ownerId", isEqualTo: uid) // 🔥 doğru ownerId
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final fields = snap.data!.docs;

          if (fields.isEmpty) {
            return const Center(
              child: Text("Hava durumunu görmek için en az 1 tarla ekleyin."),
            );
          }

          return ListView.builder(
            itemCount: fields.length,
            itemBuilder: (context, index) {
              final f = fields[index];
              final lat = f["latitude"];
              final lon = f["longitude"];

              return FutureBuilder(
                future: WeatherService().getWeather(lat, lon),
                builder: (context, wSnap) {
                  if (!wSnap.hasData) {
                    return ListTile(
                      title: Text(f["fieldName"]),
                      subtitle: const Text("Yükleniyor..."),
                      leading: const CircularProgressIndicator(),
                    );
                  }

                  final w = wSnap.data!;
                  final temp = w["main"]["temp"];
                  final desc = w["weather"][0]["description"];
                  final wind = w["wind"]["speed"];

                  final tr = toTR(desc);
                  final risk = riskDurumu(desc, temp, wind);

                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: Icon(
                        risk == "🍃 Normal" ? Icons.cloud : Icons.warning,
                        color: risk == "🍃 Normal" ? Colors.blue : Colors.red,
                        size: 32,
                      ),
                      title: Text(
                        f["fieldName"],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text("🌡 Sıcaklık: $temp°C\n🌥 Durum: $tr"),
                      trailing: Text(
                        risk,
                        style: TextStyle(
                          color: risk == "🍃 Normal"
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
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
}
