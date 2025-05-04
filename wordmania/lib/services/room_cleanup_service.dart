  import 'package:cloud_firestore/cloud_firestore.dart';

class RoomCleanupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> temizleEskiOdalar() async {
    try {
      final now = Timestamp.now();
      final limitTime = Timestamp.fromMillisecondsSinceEpoch(
          now.millisecondsSinceEpoch - (10 * 60 * 1000)); // 10 dakika öncesi

      final waitingRooms = await _firestore.collection('rooms')
          .where('status', isEqualTo: 'waiting')
          .where('createdAt', isLessThan: limitTime)
          .get();

      for (var doc in waitingRooms.docs) {
        await doc.reference.delete();
        print('Eski oda silindi: ${doc.id}');
      }

      print('Oda temizliği tamamlandı.');
    } catch (e) {
      print('Oda temizleme hatası: $e');
}
}
}
