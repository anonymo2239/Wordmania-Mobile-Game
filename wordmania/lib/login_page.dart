import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logic/player_state.dart';
import '../services/firebase_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 24),
            const CircleAvatar(
              radius: 100,
              backgroundImage: AssetImage('assets/wordmania_logo.png'),
            ),
            const SizedBox(height: 20),
            const Text('Giriş Yap', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),

            // E-posta
            TextField(
              controller: emailController,
              decoration: const InputDecoration(
                labelText: 'E-posta',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // Şifre
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),

            // Giriş Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim(),
                    );

                    final user = userCredential.user;
                    if (user != null) {
                      final oyuncu = await FirebaseService().oyuncuGetir(user.uid);
                      if (oyuncu != null) {
                        debugPrint('Oyuncu yüklendi: ${oyuncu.toJson()}');
                      }
                    }

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Giriş başarılı!")),
                    );

                    Navigator.pushReplacementNamed(context, '/home');
                  } catch (e) {
                    debugPrint('Firebase Hata: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Giriş hatası: ${e.toString()}")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text('Giriş Yap'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
