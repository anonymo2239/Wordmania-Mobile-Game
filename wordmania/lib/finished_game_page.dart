import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinishedGamePage extends StatefulWidget {
  const FinishedGamePage({super.key});

  @override
  State<FinishedGamePage> createState() => _FinishedGamePageState();
}

class _FinishedGamePageState extends State<FinishedGamePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> finishedRooms = [];

  @override
  void initState() {
    super.initState();
    fetchFinishedRooms();
  }

  Future<void> fetchFinishedRooms() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final rooms = await _firestore
        .collection('rooms')
        .where('status', isEqualTo: 'finished')
        .where(Filter.or(
          Filter('player1', isEqualTo: uid),
          Filter('player2', isEqualTo: uid),
        ))
        .get();

    List<Map<String, dynamic>> tempList = [];

    for (var room in rooms.docs) {
      final data = room.data();
      final p1Id = data['player1'];
      final p2Id = data['player2'];
      final p1Snap = await _firestore.collection('oyuncular').doc(p1Id).get();
      final p2Snap = await _firestore.collection('oyuncular').doc(p2Id).get();

      final p1Data = p1Snap.data() ?? {};
      final p2Data = p2Snap.data() ?? {};

      tempList.add({
        'player1Name': p1Data['kullaniciAdi'] ?? 'Oyuncu 1',
        'player2Name': p2Data['kullaniciAdi'] ?? 'Oyuncu 2',
        'player1Score': p1Data['skor'] ?? 0,
        'player2Score': p2Data['skor'] ?? 0,
      });
    }

    setState(() {
      finishedRooms = tempList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D9),
      appBar: AppBar(
        title: const Text('Geçmiş Oyunlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : finishedRooms.isEmpty
              ? const Center(child: Text('Hiç tamamlanan oyun yok.'))
              : ListView.builder(
                  itemCount: finishedRooms.length,
                  itemBuilder: (context, index) {
                    final room = finishedRooms[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3)),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${room['player1Name']} (${room['player1Score']}) vs ${room['player2Name']} (${room['player2Score']})',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
