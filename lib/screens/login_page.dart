import 'package:flutter/material.dart';
import 'package:tarimus/screens/register_page.dart';
import 'package:tarimus/services/auth_service.dart';
import 'package:tarimus/screens/ciftci_pano_ekran.dart';
import 'package:tarimus/screens/uzman_pano_ekran.dart';

class LoginPage extends StatefulWidget {
  final String role; // "ciftci" | "uzman"
  const LoginPage({required this.role, Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();

  bool isLoading = false;

  Future<void> _loginUser() async {
    final email = emailController.text.trim();
    final pass = passwordController.text.trim();

    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen email ve şifre giriniz.")),
      );
      return;
    }

    setState(() => isLoading = true);
    final user = await _authService.signInWithEmailPassword(
      email: email,
      password: pass,
    );
    setState(() => isLoading = false);

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Giriş başarısız! Lütfen bilgileri kontrol edin."),
        ),
      );
      return;
    }

    // Firestore'dan rol çekmiyoruz. RoleSelection'dan gelen role ile yönlendiriyoruz.
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
        ? "Çiftçi Girişi"
        : "Uzman Girişi";

    return Scaffold(
      appBar: AppBar(title: Text(pageTitle), backgroundColor: Colors.green),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hoş Geldiniz",
              style: TextStyle(fontSize: 26, color: Colors.green.shade700),
            ),
            const SizedBox(height: 30),
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
              onSubmitted: (_) => isLoading ? null : _loginUser(),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: isLoading ? null : _loginUser,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                backgroundColor: Colors.green.shade600,
              ),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("GİRİŞ", style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: isLoading
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => RegisterPage(role: widget.role),
                        ),
                      );
                    },
              child: const Text("Hesabın yok mu? Kayıt Ol"),
            ),
          ],
        ),
      ),
    );
  }
}
