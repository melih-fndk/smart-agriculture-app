import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Kayıt işlemi
  Future<User?> registerWithEmailPassword({
    required String email,
    required String password,
    required String role,
    required String name,
    required String city, // ✅ EKLENDİ
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = cred.user!;
      final uid = user.uid;

      unawaited(
        _firestore
            .collection('users')
            .doc(uid)
            .set({
              'email': email,
              'name': name,
              'role': role, // 'ciftci' | 'uzman'
              'city': city,

              'createdAt': FieldValue.serverTimestamp(),
            })
            // ağ yavaşsa 2 sn sonra bırak; kullanıcıyı bekletme
            .timeout(const Duration(seconds: 2))
            .catchError((e) {}),
      );

      //RegisterPage anında yönlendirsin
      return user;
    } catch (e) {
      // print("Kayıt hatası: $e");
      return null;
    }
  }

  //Giriş işlemi
  Future<User?> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return cred.user;
    } catch (e) {
      // print("Giriş hatası: $e");
      return null;
    }
  }

  Future<void> signOut() async => _auth.signOut();
}
