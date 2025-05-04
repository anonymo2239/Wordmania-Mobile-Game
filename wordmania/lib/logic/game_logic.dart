// lib/logic/game_logic.dart

import 'player_state.dart';

class GameLogic {
  final List<List<String?>> tahta = List.generate(
    15,
    (_) => List<String?>.generate(15, (_) => null),
  );

  final Map<String, int> harfPuanlari = {
    'A': 1, 'E': 1, 'İ': 1, 'K': 2, 'L': 1, 'M': 2,
    'T': 1, 'R': 1, 'N': 1, 'O': 1, 'U': 1, 'S': 1,
    'Y': 2, 'B': 3, 'D': 3, 'H': 4, 'C': 4, 'Z': 4,
    'G': 5, 'P': 5, 'Ş': 5, 'Ç': 5, 'V': 7, 'F': 7,
    'J': 8, 'Ğ': 8
  };


  bool harfYerlestir({
    required int satir,
    required int sutun,
    required String harf,
    required Oyuncu oyuncu,
  }) {
    if (tahta[satir][sutun] == null && oyuncu.harfler.contains(harf)) {
      tahta[satir][sutun] = harf;
      oyuncu.harfKullan(harf);
      return true;
    }
    return false;
  }

  int puanHesapla({
    required List<String> kelime,
  }) {
    int toplam = 0;
    for (final harf in kelime) {
      toplam += harfPuanlari[harf.toUpperCase()] ?? 0;
    }
    return toplam;
  }

  void puanVer({
    required Oyuncu oyuncu,
    required List<String> kelime,
  }) {
    final puan = puanHesapla(kelime: kelime);
    oyuncu.skoruEkle(puan);
  }

  void tahtaYazdir() {
    for (var satir in tahta) {
      print(satir.map((e) => e ?? '_').join(' '));
}
}
}
