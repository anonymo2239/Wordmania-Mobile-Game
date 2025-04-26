import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logic/player_state.dart';

class GameBoardPage extends StatefulWidget {
  final Oyuncu oyuncu;
  final String roomId;

  const GameBoardPage({super.key, required this.oyuncu, required this.roomId});

  @override
  State<GameBoardPage> createState() => _GameBoardPageState();
}

class _GameBoardPageState extends State<GameBoardPage> {
  static const int gridSize = 15;
  List<String?> board = List.filled(15 * 15, null);
  String? selectedLetter;
  int? selectedLetterIndex;
  Oyuncu? rakipOyuncu;
  int kalanHarfSayisi = 100;
  String? currentTurnUid;
  StreamSubscription<DocumentSnapshot>? roomListener;

  List<int> aktifHamleler = [];
  int kalanSure = 120;
  Timer? turTimer;
  bool siradaBenVarim = false;
  String currentTurnUsername = "";

  @override
  void initState() {
    super.initState();
    listenRoomUpdates();
  }

  void listenRoomUpdates() {
    roomListener = FirebaseFirestore.instance
        .collection('rooms')
        .doc(widget.roomId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.exists) {
        final roomData = snapshot.data()!;
        final newTurnUid = roomData['currentTurn'];

        if (currentTurnUid != newTurnUid) {
          currentTurnUid = newTurnUid;
          siradaBenVarim = (currentTurnUid == widget.oyuncu.uid);
          if (siradaBenVarim) {
            baslatTurTimer();
          } else {
            turTimer?.cancel();
            kalanSure = 120;
          }

          await fetchUsernames(roomData);
        }
      }
    });
  }

  Future<void> fetchUsernames(Map<String, dynamic> roomData) async {
    final rakipUid = widget.oyuncu.uid == roomData['player1']
        ? roomData['player2']
        : roomData['player1'];

    if (rakipUid != null) {
      final rakipDoc = await FirebaseFirestore.instance
          .collection('oyuncular')
          .doc(rakipUid)
          .get();
      if (rakipDoc.exists) {
        setState(() {
          rakipOyuncu = Oyuncu.fromJson(rakipDoc.data()!);
        });
      }
    }

    if (currentTurnUid == widget.oyuncu.uid) {
      setState(() {
        currentTurnUsername = widget.oyuncu.kullaniciAdi;
      });
    } else if (rakipOyuncu != null) {
      setState(() {
        currentTurnUsername = rakipOyuncu!.kullaniciAdi;
      });
    }
  }

  void baslatTurTimer() {
    turTimer?.cancel();
    kalanSure = 120;
    turTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (kalanSure > 0) {
        setState(() {
          kalanSure--;
        });
      } else {
        turTimer?.cancel();
        sirayiRakibeVer();
      }
    });
  }

  void sirayiRakibeVer() async {
    if (rakipOyuncu != null) {
      await FirebaseFirestore.instance
          .collection('rooms')
          .doc(widget.roomId)
          .update({'currentTurn': rakipOyuncu!.uid});
    }
  }

  void hamleyiOnayla() async {
    if (aktifHamleler.isEmpty) return;

    int puan = 0;
    for (int index in aktifHamleler) {
      final harf = board[index];
      puan += harf != null ? 1 : 0;
    }

    setState(() {
      widget.oyuncu.skor += puan;
      aktifHamleler.clear();
    });

    await FirebaseFirestore.instance.collection('oyuncular').doc(widget.oyuncu.uid).update({
      'skor': widget.oyuncu.skor,
    });

    turTimer?.cancel();
    kalanSure = 120;
    sirayiRakibeVer();
  }

  @override
  void dispose() {
    roomListener?.cancel();
    turTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oyun Tahtası')),
      body: Column(
        children: [
          Container(
            color: Colors.blueGrey[100],
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.oyuncu.kullaniciAdi, style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Skor: ${widget.oyuncu.skor}'),
                  ],
                ),
                Column(
                  children: [
                    const Text('Kalan Harf'),
                    Text('$kalanHarfSayisi'),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(rakipOyuncu?.kullaniciAdi ?? 'Bekleniyor...', style: const TextStyle(fontWeight: FontWeight.bold)),
                    Text('Skor: ${rakipOyuncu?.skor ?? 0}'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridSize,
                ),
                itemCount: gridSize * gridSize,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      if (siradaBenVarim && selectedLetter != null && board[index] == null) {
                        setState(() {
                          board[index] = selectedLetter;
                          aktifHamleler.add(index);
                          selectedLetter = null;
                        });
                      }
                    },
                    child: Container(
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.brown[100],
                        border: Border.all(color: Colors.grey),
                      ),
                      child: Center(
                        child: Text(
                          board[index] ?? '',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            color: Colors.blueGrey[50],
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(widget.oyuncu.harfler.length, (index) {
                    final harf = widget.oyuncu.harfler[index];
                    final isSelected = selectedLetterIndex == index;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedLetter = harf;
                          selectedLetterIndex = index;
                        });
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black45),
                          color: isSelected ? Colors.amber : Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            harf,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: siradaBenVarim ? hamleyiOnayla : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Oynat'),
                    ),
                    const SizedBox(width: 20),
                    Text(
                      '${(kalanSure ~/ 60).toString().padLeft(2, '0')}:${(kalanSure % 60).toString().padLeft(2, '0')} ($currentTurnUsername)',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Icons.more_vert),
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
