import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  final apiKey = "5afc46a875afd1bad068394c06d0a824";

  Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
    final url =
        "https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric";

    final res = await http.get(Uri.parse(url));

    if (res.statusCode != 200) {
      print("API HATA: ${res.body}");
      return null;
    }

    return jsonDecode(res.body);
  }
}
