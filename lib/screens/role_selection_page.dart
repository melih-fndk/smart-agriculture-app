import 'package:flutter/material.dart';
import 'package:tarimus/screens/login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //yeşil arka plan
      backgroundColor: const Color(0xFFF0F8F0),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.eco, //yaprak ikonu
                  size: 100,
                  color: Colors.green[800],
                ),
                const SizedBox(height: 10),
                Text(
                  'Akıllı Tarım', // Proje adımız
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 80),

                // Çiftçi Girişi Butonu
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Kullanıcıyı 'ciftci' rolü ile giriş ekranına yönlendir
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(role: 'ciftci'),
                      ),
                    );
                  },
                  child: const Text(
                    'ÇİFTÇİ GİRİŞİ',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),

                // Uzman Girişi Butonu
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white, // Beyaz arka plan
                    foregroundColor: Colors.green[800], // Yeşil yazı
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(
                      color: Colors.green[800]!,
                      width: 2,
                    ), // Yeşil çerçeve
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    // Kullanıcıyı 'uzman' rolü ile giriş ekranına yönlendir
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPage(role: 'uzman'),
                      ),
                    );
                  },
                  child: const Text(
                    'UZMAN GİRİŞİ',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
