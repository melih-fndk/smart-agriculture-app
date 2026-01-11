import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Yeni kullanıcı kaydolduğunda, rolüyle birlikte
  // Firestore'da 'users' koleksiyonuna bir doküman oluşturur.
  Future<void> createUserDocument(String uid, String email, String role) async {
    try {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'role': role, // 'ciftci' veya 'uzman'
        'createdAt': Timestamp.now(),
      });
    } catch (e) {
      print('Kullanıcı dokümanı oluşturulurken hata: $e');
      rethrow;
    }
  }
}
