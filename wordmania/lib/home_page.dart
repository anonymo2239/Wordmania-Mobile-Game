import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final username = user?.email?.split('@').first ?? 'kullanıcı';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ana Sayfa'),
        automaticallyImplyLeading: false, // Geri butonu olmasın
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Hoş geldin "$username"', style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 20),
            const Text('Kazanma oranı: %x'),
            const Text('Kazanılan oyunlar: %x'),
            const Text('Toplam oynanan oyun: %x'),
            const SizedBox(height: 30),

            // Yeni Oyun Butonu
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                child: const Text('Yeni Oyun'),
              ),
            ),
            const SizedBox(height: 16),

            // Aktif Oyunlar Butonu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Aktif Oyunlar'),
              ),
            ),
            const SizedBox(height: 16),

            // Geçmiş Oyunlar Butonu
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                child: const Text('Geçmiş Oyunlar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
