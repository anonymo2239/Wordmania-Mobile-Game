import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:wordmania/logic/player_state.dart';
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
  List<DocumentSnapshot> activeRooms = [];

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

    setState(() {
      activeRooms = rooms.docs;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Aktif Oyunlar')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeRooms.isEmpty
              ? const Center(child: Text('Aktif oyunun bulunmamaktadır.'))
              : ListView.builder(
                  itemCount: activeRooms.length,
                  itemBuilder: (context, index) {
                    final room = activeRooms[index];
                    final roomId = room.id;
                    final gameMode = room['gameMode'];

                    return ListTile(
                      title: Text('Oyun Modu: $gameMode'),
                      subtitle: Text('Oda ID: $roomId'),
                      onTap: () async {
                        final oyuncu = await FirebaseService().oyuncuGetir(_auth.currentUser!.uid);
                        if (oyuncu != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => GameBoardPage(
                                oyuncu: oyuncu,
                                roomId: roomId,
                              ),
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
    );
  }
}
