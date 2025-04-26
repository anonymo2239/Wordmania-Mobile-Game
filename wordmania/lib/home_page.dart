import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:wordmania/active_games_page.dart';
import 'package:wordmania/logic/player_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String kullaniciAdi = '...';
  int kazanilanOyunlar = 0;
  int toplamOyunlar = 0;
  double kazanmaOrani = 0.0;

  @override
  void initState() {
    super.initState();
    fetchKullaniciVerisi();
  }

  Future<void> fetchKullaniciVerisi() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final doc = await FirebaseFirestore.instance.collection('oyuncular').doc(uid).get();
      if (doc.exists) {
        final oyuncu = Oyuncu.fromJson(doc.data()!);
        setState(() {
          kullaniciAdi = oyuncu.kullaniciAdi;
          // ileride kazanma oranı ve oyun istatistiklerini buradan da çekebiliriz
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D9), // Arka plan krem
      appBar: AppBar(
        title: const Text('Ana Sayfa', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Hoş Geldin Yazısı
              Text(
                'Hoş geldin, $kullaniciAdi!',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0077B6), // Mavi başlık
                ),
              ),
              const SizedBox(height: 30),

              // İstatistikler
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStatCard('Kazanma', '${kazanmaOrani.toStringAsFixed(1)}%'),
                  _buildStatCard('Kazanç', '$kazanilanOyunlar'),
                  _buildStatCard('Toplam', '$toplamOyunlar'),
                ],
              ),
              const SizedBox(height: 40),

              // Yeni Oyun Butonu
              _buildMainButton(
                text: 'Yeni Oyun',
                color: const Color(0xFFFFA500), // Turuncu
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/game');
                },
              ),
              const SizedBox(height: 20),

              // Aktif Oyunlar Butonu
              _buildMainButton(
                text: 'Aktif Oyunlar',
                color: Colors.white,
                textColor: Colors.black,
                borderColor: const Color(0xFF0077B6),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ActiveGamesPage()),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Geçmiş Oyunlar Butonu
              _buildMainButton(
                text: 'Geçmiş Oyunlar',
                color: Colors.white,
                textColor: Colors.black,
                borderColor: const Color(0xFF0077B6),
                onPressed: () {
                  // Geçmiş oyunlar sayfasına yönlendirme buraya eklenecek
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }

  Widget _buildMainButton({
    required String text,
    required Color color,
    required Color textColor,
    Color? borderColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: textColor,
          side: borderColor != null ? BorderSide(color: borderColor, width: 2) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 3,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: Text(text),
      ),
    );
  }
}
