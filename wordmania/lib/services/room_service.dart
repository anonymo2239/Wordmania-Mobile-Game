import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoomService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<String?> findOrCreateRoom(String gameMode) async {
    try {
      // 1. Önce boşta oda ara
      final waitingRooms = await _firestore
          .collection('rooms')
          .where('status', isEqualTo: 'waiting')
          .where('gameMode', isEqualTo: gameMode)
          .limit(1)
          .get();

      final currentUid = _auth.currentUser?.uid;

      if (waitingRooms.docs.isNotEmpty) {
        // 2. Boşta oda varsa oyuncu2 olarak gir
        final roomDoc = waitingRooms.docs.first;
        await roomDoc.reference.update({
          'player2': currentUid,
          'status': 'playing',
          'startedAt': FieldValue.serverTimestamp(),
        });
        return roomDoc.id;
      } else {
        // 3. Oda yoksa yeni oda oluştur
        final newRoom = await _firestore.collection('rooms').add({
          'player1': currentUid,
          'player2': null,
          'status': 'waiting',
          'gameMode': gameMode,
          'createdAt': FieldValue.serverTimestamp(),
          'currentTurn': currentUid,
        });
        return newRoom.id;
      }
    } catch (e) {
      print('Room oluşturulamadı: $e');
      return null;
    }
  }
}
