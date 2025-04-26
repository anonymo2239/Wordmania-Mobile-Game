// lib/services/firebase_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../logic/player_state.dart';
import '../logic/harf_havuzu.dart';

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

  Future<void> ilkOyuncuyuKaydet({
    required String uid,
    required String kullaniciAdi, // 🔥 kullanıcı adını parametreye ekledik
  }) async {
    final havuz = HarfHavuzu();
    final harfler = havuz.harfDagit(7);
    final oyuncu = Oyuncu(
      uid: uid,
      kullaniciAdi: kullaniciAdi, // 🔥 doğru şekilde kaydediyoruz
      harfler: harfler,
    );
    await oyuncuKaydet(oyuncu);
  }
}
