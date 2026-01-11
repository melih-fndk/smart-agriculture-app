import 'package:flutter/material.dart';
import 'package:tarimus/services/auth_service.dart';
import 'package:tarimus/screens/ciftci_pano_ekran.dart';
import 'package:tarimus/screens/uzman_pano_ekran.dart';
import 'package:tarimus/utilities/cities.dart';

class RegisterPage extends StatefulWidget {
  final String role; // "ciftci" | "uzman"
  const RegisterPage({required this.role, Key? key}) : super(key: key);

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final TextEditingController nameController = TextEditingController();

  bool isLoading = false;
  String? selectedCity;

  Future<void> _registerUser() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty || selectedCity == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen tüm alanları doldurunuz.")),
      );
      return;
    }

    setState(() => isLoading = true);
    final user = await _authService.registerWithEmailPassword(
      email: email,
      password: pass,
      role: widget.role,
      name: nameController.text.trim(),
      city: selectedCity!,
    );

    setState(() => isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Kayıt başarısız! Lütfen tekrar deneyin."),
        ),
      );
      return;
    }

    // Kayıt başarılı → seçili role göre anında yönlendir
    if (widget.role == "ciftci") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const CiftciPanoEkran()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const UzmanPanoEkran()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String pageTitle = widget.role == "ciftci"
        ? "Çiftçi Kayıt"
        : "Uzman Kayıt";

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Yeni Hesap Oluştur",
              style: TextStyle(fontSize: 26, color: Colors.green.shade700),
            ),
            const SizedBox(height: 30),

            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: "Ad Soyad",
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: "Şehir",
                prefixIcon: Icon(Icons.location_city),
              ),
              value: selectedCity,
              items: turkiyeSehirleri.map((city) {
                return DropdownMenuItem(value: city, child: Text(city));
              }).toList(),
              onChanged: (val) {
                setState(() {
                  selectedCity = val;
                });
              },
            ),
            const SizedBox(height: 10),

            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: "Email",
                prefixIcon: Icon(Icons.email),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "Şifre",
                prefixIcon: Icon(Icons.lock),
              ),
              onSubmitted: (_) => isLoading ? null : _registerUser(),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: isLoading ? null : _registerUser,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.green.shade600,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("KAYIT OL", style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}
