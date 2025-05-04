import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'game_board.dart';
import '../services/firebase_service.dart';

class ActiveGamesPage extends StatefulWidget {
  const ActiveGamesPage({super.key});

  @override
  State<ActiveGamesPage> createState() => _ActiveGamesPageState();
}

class _ActiveGamesPageState extends State<ActiveGamesPage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  bool isLoading = true;
  List<Map<String, dynamic>> activeRooms = [];

  @override
  void initState() {
    super.initState();
    fetchActiveRooms();
  }

  Future<void> fetchActiveRooms() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final rooms = await _firestore.collection('rooms')
        .where('status', isEqualTo: 'playing')
        .where(Filter.or(
          Filter('player1', isEqualTo: uid),
          Filter('player2', isEqualTo: uid),
        ))
        .get();

    List<Map<String, dynamic>> tempList = [];

    for (var room in rooms.docs) {
      final roomData = room.data();
      final player1Id = roomData['player1'];
      final player2Id = roomData['player2'];
      final currentTurnUid = roomData['currentTurn'];

      final player1Snap = await _firestore.collection('oyuncular').doc(player1Id).get();
      final player2Snap = await _firestore.collection('oyuncular').doc(player2Id).get();

      final player1Data = player1Snap.data() ?? {};
      final player2Data = player2Snap.data() ?? {};

      tempList.add({
        'gameMode': roomData['gameMode'],
        'currentTurn': currentTurnUid,
        'player1Name': player1Data['kullaniciAdi'] ?? 'Oyuncu 1',
        'player2Name': player2Data['kullaniciAdi'] ?? 'Oyuncu 2',
        'player1Score': player1Data['skor'] ?? 0,
        'player2Score': player2Data['skor'] ?? 0,
        'roomId': room.id,
        'player1Id': player1Id,
        'player2Id': player2Id,
      });
    }

    setState(() {
      activeRooms = tempList;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF2E8D9),
      appBar: AppBar(
        title: const Text('Aktif Oyunlar'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        titleTextStyle: const TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeRooms.isEmpty
              ? const Center(child: Text('Aktif oyunun bulunmamaktadır.'))
              : ListView.builder(
                  itemCount: activeRooms.length,
                  itemBuilder: (context, index) {
                    final room = activeRooms[index];
                    final siradakiOyuncu = room['currentTurn'] == uid
                        ? "Siz"
                        : room['currentTurn'] == room['player1Id']
                            ? room['player1Name']
                            : room['player2Name'];

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: InkWell(
                        onTap: () async {
                          final oyuncu = await FirebaseService().oyuncuGetir(uid!);
                          if (oyuncu != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GameBoardPage(
                                  oyuncu: oyuncu,
                                  roomId: room['roomId'],
                                ),
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Oyun Modu: ${room['gameMode']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0077B6),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${room['player1Name']} (${room['player1Score']})  vs  ${room['player2Name']} (${room['player2Score']})',
                                style: const TextStyle(fontSize: 15),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sıra: $siradakiOyuncu',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFF0077B6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
