// lib/logic/player_state.dart

class Oyuncu {
  final String uid;
  final String kullaniciAdi;
  int skor;
  List<String> harfler;

  Oyuncu({
    required this.uid,
    required this.kullaniciAdi,
    this.skor = 0,
    this.harfler = const [],
  });

  void harfleriGuncelle(List<String> yeniHarfler) {
    harfler = yeniHarfler;
  }

  void skoruEkle(int puan) {
    skor += puan;
  }

  void harfKullan(String harf) {
    harfler.remove(harf);
  }

  void harfEkle(String harf) {
    harfler.add(harf);
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'kullaniciAdi': kullaniciAdi,
      'skor': skor,
      'harfler': harfler,
    };
  }

  static Oyuncu fromJson(Map<String, dynamic> json) {
    return Oyuncu(
      uid: json['uid'],
      kullaniciAdi: json['kullaniciAdi'],
      skor: json['skor'],
      harfler: List<String>.from(json['harfler']),
    );
  }
}
