import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_service.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> findOrCreateRoom(String gameMode) async {
    try {
      final currentUid = _auth.currentUser?.uid;
      if (currentUid == null) return null;

      final waitingRooms = await _firestore
          .collection('rooms')
          .where('status', isEqualTo: 'waiting')
          .where('gameMode', isEqualTo: gameMode)
          .where('player1', isNotEqualTo: currentUid)
          .limit(1)
          .get();

      if (waitingRooms.docs.isNotEmpty) {
        final roomDoc = waitingRooms.docs.first;
        await roomDoc.reference.update({
          'player2': currentUid,
          'status': 'playing',
          'startedAt': FieldValue.serverTimestamp(),
        });

        await FirebaseService().oyuncuyaIlkHarfVeSkorAyarla(currentUid, roomDoc.id);

        return roomDoc.id;
      } else {
        final harfler = _tumHarfleriOlustur();
        final board = List<String?>.filled(15 * 15, null);

        final newRoom = await _firestore.collection('rooms').add({
          'player1': currentUid,
          'player2': null,
          'status': 'waiting',
          'gameMode': gameMode,
          'createdAt': FieldValue.serverTimestamp(),
          'currentTurn': currentUid,
          'harfHavuzu': harfler,
          'kalanHarfSayisi': harfler.length,
          'sure': _sureyiBelirle(gameMode),
          'board': board,
        });

        await FirebaseService().oyuncuyaIlkHarfVeSkorAyarla(currentUid, newRoom.id);

        return newRoom.id;
      }
    } catch (e) {
      print('Room oluşturulamadı: $e');
      return null;
    }
  }

  List<String> _tumHarfleriOlustur() {
    final Map<String, int> tumHarfler = {
      'A': 12, 'B': 2, 'C': 2, 'Ç': 2, 'D': 2,
      'E': 8, 'F': 1, 'G': 1, 'Ğ': 1, 'H': 1,
      'I': 4, 'İ': 7, 'J': 1, 'K': 7, 'L': 7,
      'M': 4, 'N': 5, 'O': 3, 'Ö': 1, 'P': 1,
      'R': 6, 'S': 3, 'Ş': 2, 'T': 5, 'U': 3,
      'Ü': 2, 'V': 1, 'Y': 2, 'Z': 2,
      '🃏': 2
    };

    List<String> harfler = [];
    tumHarfler.forEach((harf, adet) {
      harfler.addAll(List.generate(adet, (_) => harf));
    });

    harfler.shuffle();
    return harfler;
  }

  int _sureyiBelirle(String gameMode) {
    switch (gameMode) {
      case '2 dakika':
        return 120;
      case '5 dakika':
        return 300;
      case '12 saat':
        return 43200;
      case '24 saat':
        return 86400;
      default:
        return 120;
    }
  }
}
