import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../services/room_service.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D9),
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
            const Text(
              'Kayıt Ol',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 30),

            // Kullanıcı Adı
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(
                labelText: 'Kullanıcı Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),

            // E-posta
            TextField(
              controller: emailController,
              keyboardType: TextInputType.emailAddress,
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

            // Kayıt Ol Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();
                  final username = usernameController.text.trim();

                  if (!isValidPassword(password)) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Şifre en az 8 karakter uzunluğunda olmalı,\nbüyük harf, küçük harf ve rakam içermelidir.",
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                    return;
                  }

                  try {
                    final userCredential = await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                          email: email,
                          password: password,
                        );

                    final uid = userCredential.user!.uid;

                    // Firestore'da kullanıcıyı oluştur
                    await FirebaseFirestore.instance
                        .collection('oyuncular')
                        .doc(uid)
                        .set({
                      'uid': uid,
                      'kullaniciAdi': username,
                      'skor': 0,
                      'harfler': [],
                    });

                    // Oda oluştur veya bul
                    final roomId = await RoomService().findOrCreateRoom('2 dakika');

                    if (roomId != null) {
                      await FirebaseService().ilkOyuncuyuKaydet(
                        uid: uid,
                        kullaniciAdi: username,
                        roomId: roomId,
                      );

                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Kayıt başarılı!")),
                      );
                      Navigator.pop(context);
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Oda oluşturulamadı.")),
                      );
                    }
                  } on FirebaseAuthException catch (e) {
                    String mesaj = "Bir hata oluştu";

                    if (e.code == 'email-already-in-use') {
                      mesaj = 'Bu e-posta zaten kayıtlı.';
                    } else if (e.code == 'weak-password') {
                      mesaj = 'Şifre çok zayıf.';
                    } else if (e.code == 'invalid-email') {
                      mesaj = 'Geçersiz e-posta adresi.';
                    }

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(mesaj)),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Beklenmeyen hata: $e")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA500),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text('Kayıt Ol'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Şifre kontrol fonksiyonu
  bool isValidPassword(String password) {
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigit = password.contains(RegExp(r'\d'));
    final hasMinLength = password.length >= 8;

    return hasUppercase && hasLowercase && hasDigit && hasMinLength;
  }
}
