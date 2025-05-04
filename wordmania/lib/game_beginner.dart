import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../logic/player_state.dart';
import '../services/firebase_service.dart';
import 'game_board.dart';
import '../services/room_service.dart';

class GameBeginnerPage extends StatelessWidget {
  const GameBeginnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D9),
      appBar: AppBar(
        title: const Text('Yeni Oyun', style: TextStyle(color: Colors.black)),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'Hızlı Oyun',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0077B6),
                ),
              ),
              const SizedBox(height: 16),
              _buildCustomButton(context, '2 dakika'),
              const SizedBox(height: 10),
              _buildCustomButton(context, '5 dakika'),
              const SizedBox(height: 40),
              const Text(
                'Genişletilmiş Oyun',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0077B6),
                ),
              ),
              const SizedBox(height: 16),
              _buildCustomButton(context, '12 saat'),
              const SizedBox(height: 10),
              _buildCustomButton(context, '24 saat'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomButton(BuildContext context, String text) {
    return SizedBox(
      width: 250,
      height: 55,
      child: ElevatedButton(
        onPressed: () async {
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null) {
            final oyuncu = await FirebaseService().oyuncuGetir(uid);
            if (oyuncu != null) {
              final roomId = await RoomService().findOrCreateRoom(text);
              if (roomId != null) {

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameBoardPage(
                      oyuncu: oyuncu,
                      roomId: roomId,
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Oda oluşturulamadı')),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Oyuncu verisi alınamadı')),
              );
            }
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kullanıcı oturumu yok')),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFFFA500),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 5,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        child: Text(text),
      ),
    );
  }
}
