import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;

List<Map<String, dynamic>> generatePlanSteps({
  required String cropType,
  required String weatherDescription,
}) {
  List<Map<String, dynamic>> steps = [];

  if (cropType == "bugday") {
    steps.add({
      "title": "Azotlu Gübreleme",
      "description": "Buğday gelişimi için önerilir",
      "suggestedBySystem": true,
      "completed": false,
      "completedAt": null,
      "dueDate": Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 5)),
      ),
    });
  }

  if (weatherDescription.contains("sıcak") ||
      weatherDescription.contains("az yağış")) {
    steps.add({
      "title": "Sulama",
      "description": "Kurak hava koşulları tespit edildi",
      "suggestedBySystem": true,
      "completed": false,
      "completedAt": null,
      "dueDate": Timestamp.fromDate(
        DateTime.now().add(const Duration(days: 2)),
      ),
    });
  }

  return steps;
}
