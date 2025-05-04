// lib/logic/harf_havuzu.dart

import 'dart:math';

class HarfHavuzu {
  final Map<String, int> _tumHarfler = {
    'A': 12, 'E': 8, 'İ': 8, 'K': 7, 'L': 6,
    'M': 6, 'T': 6, 'R': 6, 'N': 6, 'O': 5,
    'U': 5, 'S': 5, 'Y': 5, 'B': 4, 'D': 4,
    'H': 4, 'C': 3, 'Z': 3, 'G': 3, 'P': 2,
    'Ş': 2, 'Ç': 2, 'V': 2, 'F': 2, 'J': 1,
    'Ğ': 1
  };

  final List<String> _aktifHavuz = [];
  

  HarfHavuzu() {
    _olusturHavuz();
  }

  void _olusturHavuz() {
    _tumHarfler.forEach((harf, adet) {
      for (int i = 0; i < adet; i++) {
        _aktifHavuz.add(harf);
      }
    });
    _aktifHavuz.shuffle();
  }

  List<String> harfDagit(int adet) {
    if (_aktifHavuz.length < adet) {
      return _aktifHavuz.sublist(0);
    }
    final dagitilan = _aktifHavuz.sublist(0, adet);
    _aktifHavuz.removeRange(0, adet);
    return dagitilan;
  }

  int kalanHarfSayisi() => _aktifHavuz.length;

  void harfleriGeriEkle(List<String> harfler) {
    _aktifHavuz.addAll(harfler);
    _aktifHavuz.shuffle();
}
}
