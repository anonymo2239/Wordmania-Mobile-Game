import 'package:cloud_firestore/cloud_firestore.dart';
import '../logic/player_state.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> oyuncuKaydet(Oyuncu oyuncu) async {
    await _firestore.collection('oyuncular').doc(oyuncu.uid).set(oyuncu.toJson());
  }

  Future<void> oyuncuGuncelle(Oyuncu oyuncu) async {
    await _firestore.collection('oyuncular').doc(oyuncu.uid).update({
      'skor': oyuncu.skor,
      'harfler': oyuncu.harfler,
    });
  }

  Future<Oyuncu?> oyuncuGetir(String uid) async {
    final doc = await _firestore.collection('oyuncular').doc(uid).get();
    if (doc.exists) {
      return Oyuncu.fromJson(doc.data()!);
    }
    return null;
  }

  Future<void> oyuncuyaIlkHarfVeSkorAyarla(String uid, String roomId) async {
    final roomDoc = _firestore.collection('rooms').doc(roomId);
    final roomSnapshot = await roomDoc.get();

    if (!roomSnapshot.exists) return;

    List<dynamic> mevcutHarfHavuzu = roomSnapshot.data()?['harfHavuzu'] ?? [];

    // 7 harf çekelim
    final verilecekHarfSayisi = mevcutHarfHavuzu.length >= 7 ? 7 : mevcutHarfHavuzu.length;
    final dagitilanHarfler = mevcutHarfHavuzu.take(verilecekHarfSayisi).toList();
    mevcutHarfHavuzu.removeRange(0, verilecekHarfSayisi);

    // Oyuncuya 7 harf ver
    await _firestore.collection('oyuncular').doc(uid).update({
      'skor': 0,
      'harfler': dagitilanHarfler,
    });

    // Odayı güncelle: hem havuz hem kalanHarfSayisi
    await roomDoc.update({
      'harfHavuzu': mevcutHarfHavuzu,
      'kalanHarfSayisi': mevcutHarfHavuzu.length, // 🔥 Burada da azaltıyoruz
    });
  }


  Future<void> ilkOyuncuyuKaydet({
    required String uid,
    required String kullaniciAdi,
    required String roomId,
  }) async {
    final firestore = FirebaseFirestore.instance;
    final roomDoc = firestore.collection('rooms').doc(roomId);
    final roomSnapshot = await roomDoc.get();

    if (!roomSnapshot.exists) return;

    final oyuncu = {
      'uid': uid,
      'kullaniciAdi': kullaniciAdi,
      'skor': 0,
      'harfler': [],
      'oyunlar': 0,
      'kazanim': 0,
    };

    await firestore.collection('oyuncular').doc(uid).set(oyuncu);
  }

}
