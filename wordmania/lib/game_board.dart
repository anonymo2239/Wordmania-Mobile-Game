// lib/pages/game_board.dart

import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../logic/player_state.dart';
import '../logic/mayin_turu.dart';
import '../logic/carpan_turu.dart';
import '../helpers/word_checker.dart';

class GameBoardPage extends StatefulWidget {
  final Oyuncu oyuncu;
  final String roomId;

  const GameBoardPage({super.key, required this.oyuncu, required this.roomId});

  @override
  State<GameBoardPage> createState() => _GameBoardPageState();
}

enum HamleYon { yatay, dikey, caprazSag, caprazSol }

HamleYon? belirleHamleYonu(List<int> aktifHamleler) {
  if (aktifHamleler.length < 2) return null;
  aktifHamleler.sort();
  int d1 = aktifHamleler[1] - aktifHamleler[0];

  if (d1 == 1) return HamleYon.yatay;
  if (d1 == 15) return HamleYon.dikey;
  if (d1 == 16) return HamleYon.caprazSag;
  if (d1 == 14) return HamleYon.caprazSol;

  return null;
}

class _GameBoardPageState extends State<GameBoardPage> {
  static const int gridSize = 15;
  List<String?> board = List.filled(225, null);
  List<CarpanTuru> carpans = List.filled(225, CarpanTuru.none);
  Map<int, Color> hamleRenkleri = {};
  String? selectedLetter;
  int? selectedLetterIndex;
  Oyuncu? rakipOyuncu;
  int kalanHarfSayisi = 0;
  int kalanSure = 120;
  String? currentTurnUid;
  String currentTurnUsername = "";
  bool siradaBenVarim = false;
  bool carpanlarIptalMi = false; // Ekstra Hamle Engeli etkisi
  bool puanBolunuyorMu = false;  // Puan Bölünmesi etkisi
  bool puanTransferiMi = false;  // Puan Transferi etkisi
  bool kelimeIptalMi = false;    // Kelime İptali etkisi
  bool ekstraHamleJokeriMi = false; // Ekstra Hamle Jokeri aktif mi
  bool ekstraHamleKullanildiMi = false;
  bool rakipSolTarafaYasak = false; // sadece sağ tarafa koyabilir
  bool rakipSagTarafaYasak = false;
  List<String> dondurulenHarfler = [];
  Set<int> acilanMayinlar = {};
  bool _resultScreenGosterildi = false;
  int hamleSayaci = 0;

  List<int> aktifHamleler = [];
  Timer? turTimer;
  final Map<int, MayinTuru> mayinlar = {};
  final Random random = Random();
  StreamSubscription<DocumentSnapshot>? roomListener;
  StreamSubscription<DocumentSnapshot>? oyuncuListener;

  final Map<String, int> harfPuanlari = {
    'A': 1, 'E': 1, 'İ': 1, 'K': 1, 'L': 1, 'M': 2,
    'T': 1, 'R': 1, 'N': 1, 'O': 2, 'U': 2, 'S': 2,
    'Y': 3, 'B': 3, 'D': 3, 'H': 5, 'C': 4, 'Z': 4,
    'G': 5, 'P': 5, 'Ş': 4, 'Ç': 4, 'V': 7, 'F': 7,
    'J': 10, 'Ğ': 8, 'Ö': 7, 'Ü': 3
  };

  @override
  void initState() {
    super.initState();
    WordChecker.loadWords();
    setupMayinlar(); 
    dagitMayinlar();
    ayarlaCarpanlar();
    listenRoomUpdates();
    listenOyuncuUpdates();
  }

  @override
  void dispose() {
    turTimer?.cancel();
    roomListener?.cancel();
    oyuncuListener?.cancel();
    super.dispose();
  }

  void dagitMayinlar() {
    Map<MayinTuru, int> mayinSayilari = {
      MayinTuru.puanBolunmesi: 5,
      MayinTuru.puanTransferi: 4,
      MayinTuru.harfKaybi: 3,
      MayinTuru.ekstraHamleEngeli: 2,
      MayinTuru.kelimeIptali: 2,
      MayinTuru.bolgeYasagi: 2,
      MayinTuru.harfYasagi: 3,
      MayinTuru.ekstraHamleJokeri: 2,
    };

    mayinSayilari.forEach((mayinTuru, adet) {
      for (int i = 0; i < adet; i++) {
        int index;
        do {
          index = random.nextInt(gridSize * gridSize);
        } while (mayinlar.containsKey(index));
        mayinlar[index] = mayinTuru;
      }
    });
  }

  void ayarlaCarpanlar() {
    List<int> harf2Yerler = [5, 9, 21, 23,75,80,84,89,91,96,98,103,121,126,128,133,135,140,144,149,201,203,215,219];
    List<int> harf3Yerler = [16,28,64,70,154,160,196,208];
    List<int> kelime2Yerler = [37,48,56,107,117,168,176,187];
    List<int> kelime3Yerler = [2, 12,30,42,180,194,212,222];

    for (int index in harf2Yerler) {
      carpans[index] = CarpanTuru.harf2;
    }
    for (int index in harf3Yerler) {
      carpans[index] = CarpanTuru.harf3;
    }
    for (int index in kelime2Yerler) {
      carpans[index] = CarpanTuru.kelime2;
    }
    for (int index in kelime3Yerler) {
      carpans[index] = CarpanTuru.kelime3;
    }
  }

void listenRoomUpdates() {
  roomListener = FirebaseFirestore.instance
      .collection('rooms')
      .doc(widget.roomId)
      .snapshots()
      .listen((snapshot) async {
    if (!snapshot.exists) return;

    final roomData = snapshot.data()!;

    if (roomData['status'] == 'finished' && !_resultScreenGosterildi) {
      await fetchRakipBilgisi(roomData); 
      _resultScreenGosterildi = true;
      await showResultScreen(); 
      return;
    }

    setState(() {
      kalanHarfSayisi = roomData['kalanHarfSayisi'] ?? 0;
      kalanSure = roomData['sure'] ?? 120;
      currentTurnUid = roomData['currentTurn'];
      siradaBenVarim = (currentTurnUid == widget.oyuncu.uid);
      board = List<String?>.from(roomData['board'] ?? List.filled(225, null));

      if (roomData.containsKey('mayinlar')) {
        final savedMayinlar = Map<String, dynamic>.from(roomData['mayinlar']);
        mayinlar.clear();
        savedMayinlar.forEach((key, value) {
          mayinlar[int.parse(key)] = MayinTuru.values[value];
        });
      }

      if (roomData.containsKey('acilanMayinlar')) {
        final list = List<String>.from(roomData['acilanMayinlar']);
        acilanMayinlar = list.map(int.parse).toSet();
      }

      if (roomData.containsKey('bolgeYasagi')) {
        final bolgeYasagi = roomData['bolgeYasagi'];
        if (bolgeYasagi != null && bolgeYasagi['hedef'] == widget.oyuncu.uid) {
          rakipSolTarafaYasak = bolgeYasagi['taraf'] == 'sol';
          rakipSagTarafaYasak = bolgeYasagi['taraf'] == 'sag';
        } else {
          rakipSolTarafaYasak = false;
          rakipSagTarafaYasak = false;
        }
      } else {
        rakipSolTarafaYasak = false;
        rakipSagTarafaYasak = false;
      }
      if (roomData.containsKey('harfYasagi')) {
        final hy = roomData['harfYasagi'];
        if (hy != null && hy['hedef'] == widget.oyuncu.uid) {
          final harfler = List<String>.from(hy['harfler']);
          dondurulenHarfler = harfler;
        } else {
          dondurulenHarfler.clear();
        }
      } else {
        dondurulenHarfler.clear();
      }

    });
    await fetchRakipBilgisi(roomData);
    if (siradaBenVarim && rakipOyuncu != null) {
      baslatTurTimer();
    } else {
      turTimer?.cancel();
    }
  });
}

  void listenOyuncuUpdates() {
    oyuncuListener = FirebaseFirestore.instance
        .collection('oyuncular')
        .doc(widget.oyuncu.uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        final updatedOyuncu = Oyuncu.fromJson(snapshot.data()!);
        setState(() {
          widget.oyuncu.skor = updatedOyuncu.skor;
          widget.oyuncu.harfler = updatedOyuncu.harfler;
        });
      }
    });
  }
  Future<void> fetchRakipBilgisi(Map<String, dynamic> roomData) async {
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
    turTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {

      if (kalanSure > 0) {
        setState(() {
          kalanSure--;
        });
      } else {
        turTimer?.cancel();
        await showResultScreen();

      }
    });
  }

Future<void> showResultScreen() async {
  if (_resultScreenGosterildi) return;
  _resultScreenGosterildi = true;

  final benimSkor = widget.oyuncu.skor;
  final rakipSkor = rakipOyuncu?.skor ?? 0;
  final uid = widget.oyuncu.uid;
  final rakipUid = rakipOyuncu?.uid;
  final kazandinMi = benimSkor > rakipSkor;

  final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
  final roomSnapshot = await roomRef.get();

  final resultField = 'resultUpdated_$uid';
  final alreadyUpdated = roomSnapshot.data()?[resultField] ?? false;

  if (!alreadyUpdated) {
    await roomRef.update({
      'status': 'finished',
      resultField: true,
    });

    await FirebaseFirestore.instance.collection('oyuncular').doc(uid).set({
      'oyunlar': FieldValue.increment(1),
      'kazanim': kazandinMi ? FieldValue.increment(1) : FieldValue.increment(0),
    }, SetOptions(merge: true));

    if (rakipUid != null) {
      await FirebaseFirestore.instance.collection('oyuncular').doc(rakipUid).set({
        'oyunlar': FieldValue.increment(1),
        'kazanim': kazandinMi ? FieldValue.increment(0) : FieldValue.increment(1),
      }, SetOptions(merge: true));
    }
  }

  String mesaj;
  if (benimSkor > rakipSkor) {
    mesaj = "Kazandın!";
  } else if (benimSkor < rakipSkor) {
    mesaj = "Kaybettin.";
  } else {
    mesaj = "Berabere!";
  }

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Oyun Bitti'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(mesaj, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Text("Senin Skorun: $benimSkor"),
          Text("Rakip Skoru: $rakipSkor"),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Ana Sayfaya Dön'),
        )
      ],
    ),
  );
}

Future<void> setupMayinlar() async {
  final roomDoc = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
  final roomSnapshot = await roomDoc.get();

  if (roomSnapshot.exists) {
    final data = roomSnapshot.data();
    if (data != null && data.containsKey('mayinlar')) {
      final savedMayinlar = Map<String, dynamic>.from(data['mayinlar']);
      savedMayinlar.forEach((key, value) {
        mayinlar[int.parse(key)] = MayinTuru.values[value];
      });
    } else {
      dagitMayinlar();
      final mayinlarToSave = mayinlar.map((key, value) => MapEntry(key.toString(), value.index));
      await roomDoc.update({'mayinlar': mayinlarToSave});
    }
  }
}


  Future<void> kaydetHamle(int index, String harf) async {
    try {
      final roomDoc = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
      setState(() {
        board[index] = harf;
      });

      await roomDoc.update({
        'board': board,
        'kalanHarfSayisi': FieldValue.increment(-1),
      });
    } catch (e) {
      debugPrint('Hamle kaydedilirken hata oluştu: $e');
    }
  }

    bool temasVarMi(List<int> aktifHamleler, List<String?> board) {
      for (int index in aktifHamleler) {
        int row = index ~/ gridSize;
        int col = index % gridSize;

        List<int> komsular = [
          if (row > 0) (row - 1) * gridSize + col,     // üst
          if (row < gridSize - 1) (row + 1) * gridSize + col, // alt
          if (col > 0) row * gridSize + (col - 1),     // sol
          if (col < gridSize - 1) row * gridSize + (col + 1), // sağ
        ];

        for (int komsu in komsular) {
          if (board[komsu] != null && !aktifHamleler.contains(komsu)) {
            return true;
          }
        }
      }
      return false;
    }



Future<void> hamleyiOnayla() async {
  if (rakipOyuncu == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Rakip bekleniyor...')),
    );
    return;
  }

  print("DEBUG: hamleSayaci = $hamleSayaci");
  print("DEBUG: aktifHamleler = $aktifHamleler");
  print("DEBUG: board üzerindeki dolu hücre sayısı = ${board.where((e) => e != null).length}");

  final bool ilkHamleMi = board.where((e) => e != null).length == aktifHamleler.length;

  if (ilkHamleMi) {
    List<int> olusanIndexler = [];
    final yon = belirleHamleYonu(aktifHamleler);

    if (yon != null) {
      int start = aktifHamleler.reduce(min);
      int end = aktifHamleler.reduce(max);
      int step = (yon == HamleYon.yatay)
          ? 1
          : (yon == HamleYon.dikey)
              ? 15
              : (yon == HamleYon.caprazSag)
                  ? 16
                  : 14;

      for (int i = start; i <= end; i += step) {
        olusanIndexler.add(i);
      }
    }

    if (!olusanIndexler.contains(112)) {
      print("DEBUG: İlk kelime 112 üzerinden geçmiyor.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('İlk kelime tahtanın ortasından geçmelidir.')),
      );
      return;
    } else {
      print("DEBUG: İlk hamle başarılı, merkezden geçiyor.");
    }
  } else {
    print("DEBUG: Temas kontrolüne geçiliyor...");
    if (!temasVarMi(aktifHamleler, board)) {
      print("DEBUG: temasVarMi() = FALSE, temas bulunamadı.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yeni kelime tahtada bulunan harflerden en az birine temas edecek şekilde konumlandırılmalıdır.')),
      );
      return;
    } else {
      print("DEBUG: temasVarMi() = TRUE, temas bulundu");
    }
  }

  List<Map<String, dynamic>> kelimeBilgileri = tumKelimeleriBul(aktifHamleler);
  List<String> kelimeler = kelimeBilgileri.map((e) => e['kelime'] as String).toList();
  hamleRenkleri.clear();
  bool tumKelimelerGecerliMi = true;

  for (var bilgi in kelimeBilgileri) {
    String kelime = bilgi['kelime'];
    List<int> indexler = bilgi['indexler'];
    bool gecerli = WordChecker.isWordValid(kelime);

    for (int i in indexler) {
      hamleRenkleri[i] = gecerli ? Colors.green : Colors.red;
    }

    if (!gecerli) tumKelimelerGecerliMi = false;
  }

  int toplamPuan = 0;

  for (var bilgi in kelimeBilgileri) {
    String kelime = bilgi['kelime'];
    List<int> indexler = bilgi['indexler'];
    bool gecerli = WordChecker.isWordValid(kelime);

    for (int i in indexler) {
      hamleRenkleri[i] = gecerli ? Colors.green : Colors.red;
    }
    if (gecerli) {
      int kelimePuani = 0;
      int kelimeCarpani = 1;

      for (int i in indexler) {
        final harf = board[i]!;
        int harfPuani = harfPuanlari[harf] ?? 0;

        if (!carpanlarIptalMi && aktifHamleler.contains(i)) {
          if (carpans[i] == CarpanTuru.harf2) harfPuani *= 2;
          if (carpans[i] == CarpanTuru.harf3) harfPuani *= 3;
        }

        kelimePuani += harfPuani;

        if (!carpanlarIptalMi && aktifHamleler.contains(i)) {
          if (carpans[i] == CarpanTuru.kelime2) kelimeCarpani *= 2;
          if (carpans[i] == CarpanTuru.kelime3) kelimeCarpani *= 3;
        }
      }

      toplamPuan += kelimePuani * kelimeCarpani;
    }
  }

  // Mayınlar her durumda uygulanır
  for (int index in aktifHamleler) {
    if (mayinlar.containsKey(index)) {
      await applyMayinEffect(mayinlar[index]!);
      acilanMayinlar.add(index);
    }
  }

  await FirebaseFirestore.instance
      .collection('rooms')
      .doc(widget.roomId)
      .update({
        'acilanMayinlar': acilanMayinlar.map((i) => i.toString()).toList(),
      });

  // Puan etkileri
  if (kelimeIptalMi) {
    toplamPuan = 0;
  } else if (puanBolunuyorMu) {
    toplamPuan = (toplamPuan * 0.3).floor();
  } else if (puanTransferiMi) {
    rakipOyuncu?.skor += toplamPuan;
    if (rakipOyuncu != null) {
      await FirebaseFirestore.instance
          .collection('oyuncular')
          .doc(rakipOyuncu!.uid)
          .update({'skor': rakipOyuncu!.skor});
    }
    toplamPuan = 0;
  }

  setState(() {
    widget.oyuncu.skor += toplamPuan;
  });

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('+$toplamPuan puan')),
  );

  await yeniHarfAlVeFirestoreGuncelle();
  hamleSayaci++;
  await Future.delayed(const Duration(seconds: 2));

  if (!mounted) return;

  setState(() {
    aktifHamleler.clear();
    hamleRenkleri.clear();
  });

  turTimer?.cancel();
  kalanSure = 120;

  final updatedRoom = await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).get();
  final kalanHarf = updatedRoom.data()?['kalanHarfSayisi'] ?? 0;

  if (kalanHarf <= 0) {
    await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
      'status': 'finished',
    });
    await showResultScreen();
    return;
  }

  if (ekstraHamleJokeriMi && !ekstraHamleKullanildiMi) {
    ekstraHamleKullanildiMi = true;
    baslatTurTimer();
  } else {
    ekstraHamleJokeriMi = false;
    ekstraHamleKullanildiMi = false;
    sirayiRakibeVer();
  }

  puanBolunuyorMu = false;
  puanTransferiMi = false;
  carpanlarIptalMi = false;
  kelimeIptalMi = false;
  ekstraHamleJokeriMi = false;
}

  Future<void> yeniHarfAlVeFirestoreGuncelle() async {
  final roomDoc = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
  final roomSnapshot = await roomDoc.get();

  if (!roomSnapshot.exists) return;

  List<dynamic> mevcutHavuz = roomSnapshot.data()?['harfHavuzu'] ?? [];
  final eksikHarfSayisi = aktifHamleler.length;

  List<String> yeniHarfler = [];
  if (mevcutHavuz.length >= eksikHarfSayisi) {
    yeniHarfler = mevcutHavuz.take(eksikHarfSayisi).toList().cast<String>();
    mevcutHavuz.removeRange(0, eksikHarfSayisi);
  } else {
    yeniHarfler = mevcutHavuz.cast<String>();
    mevcutHavuz.clear();
  }

  widget.oyuncu.harfler.addAll(yeniHarfler);

  await FirebaseFirestore.instance.collection('oyuncular').doc(widget.oyuncu.uid).update({
    'harfler': widget.oyuncu.harfler,
    'skor': widget.oyuncu.skor,
  });

  await roomDoc.update({
    'harfHavuzu': mevcutHavuz,
    'kalanHarfSayisi': mevcutHavuz.length,
  });
}

    void sirayiRakibeVer() async {
    // Yasakları 1 turla sınırlı tut (lokal)
    rakipSolTarafaYasak = false;
    rakipSagTarafaYasak = false;
    dondurulenHarfler.clear(); // Harf yasağı da sıfırlanır

    final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

    Map<String, dynamic> updateData = {
      'bolgeYasagi': FieldValue.delete(),
      'harfYasagi': FieldValue.delete(),
    };

    if (rakipOyuncu != null) {
      updateData['currentTurn'] = rakipOyuncu!.uid;
    }

    await roomRef.update(updateData);
  }

List<Map<String, dynamic>> tumKelimeleriBul(List<int> aktifHamleler) {
  Set<String> kelimeSet = {};
  List<Map<String, dynamic>> sonuc = [];

  for (int index in aktifHamleler) {
    int row = index ~/ gridSize;
    int col = index % gridSize;

    List<List<int>> yonler = [
      [0, 1],   // yatay →
      [1, 0],   // dikey ↓
      [1, 1],   // çapraz sağ ↘
      [1, -1],  // çapraz sol ↙
    ];

    for (var yon in yonler) {
      int dr = yon[0];
      int dc = yon[1];

      int r = row;
      int c = col;

      // Başlangıcı bul
      while (r - dr >= 0 &&
             r - dr < gridSize &&
             c - dc >= 0 &&
             c - dc < gridSize &&
             board[(r - dr) * gridSize + (c - dc)] != null) {
        r -= dr;
        c -= dc;
      }

      List<int> indexler = [];
      String kelime = '';

      // Tüm kelimeyi oku
      while (r >= 0 &&
             r < gridSize &&
             c >= 0 &&
             c < gridSize &&
             board[r * gridSize + c] != null) {
        int idx = r * gridSize + c;
        kelime += board[idx]!;
        indexler.add(idx);
        r += dr;
        c += dc;
      }

      final uniqueKey = '$kelime-${indexler.join(",")}';
      if (kelime.length > 1 && !kelimeSet.contains(uniqueKey)) {
        kelimeSet.add(uniqueKey);
        sonuc.add({'kelime': kelime, 'indexler': indexler});
      }
    }
  }

  return sonuc;
}


  Future<void> applyMayinEffect(MayinTuru turu, [List<int>? aktifHamleler]) async {
    switch (turu) {
      case MayinTuru.puanBolunmesi:
        puanBolunuyorMu = true;
        await gorselliMayinBildirimi(turu, "💥 Puan Bölünmesi: Bu kelimenin puanı %30’a düşürüldü.");
        break;

      case MayinTuru.puanTransferi:
        puanTransferiMi = true;
        await gorselliMayinBildirimi(turu, "💥 Puan Transferi: Kazandığın puan rakibine aktarıldı.");
        break;

      case MayinTuru.harfKaybi:
        // 1. Kullanılan harf sayısını hesapla
        int kullanilanHarfSayisi = aktifHamleler?.length ?? 0;

        // 2. Kullanılmayan harfleri al
        List<String> eldeKalanHarfler = List.from(widget.oyuncu.harfler);

        // 3. Firestore'dan havuz verisini al
        final roomDoc = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);
        final roomSnapshot = await roomDoc.get();
        List<dynamic> mevcutHavuz = roomSnapshot.data()?['harfHavuzu'] ?? [];

        // 4. Kullanılmayan harfleri havuza ekle
        mevcutHavuz.addAll(eldeKalanHarfler);

        // 5. Oyuncunun elindeki harfleri temizle
        widget.oyuncu.harfler.clear();

        // 6. Yeni 7 harfi havuzdan çek
        List<String> yeniHarfler = [];
        if (mevcutHavuz.length >= 7) {
          yeniHarfler = mevcutHavuz.take(7).toList().cast<String>();
          mevcutHavuz.removeRange(0, 7);
        } else {
          yeniHarfler = mevcutHavuz.cast<String>();
          mevcutHavuz.clear();
        }

        // 7. Yeni harfleri oyuncuya ver
        widget.oyuncu.harfler.addAll(yeniHarfler);

        // 8. Firestore'a güncellemeleri yaz
        await FirebaseFirestore.instance.collection('oyuncular').doc(widget.oyuncu.uid).update({
          'harfler': widget.oyuncu.harfler,
        });
        await roomDoc.update({
          'harfHavuzu': mevcutHavuz,
          'kalanHarfSayisi': mevcutHavuz.length,
        });

        // 9. Bildirim göster
        await gorselliMayinBildirimi(
          turu,
          "💥 Harf Kaybı: Kullanmadığın harfler havuza aktarıldı. Yeni 7 harf aldın!"
        );
        break;

      case MayinTuru.ekstraHamleEngeli:
        carpanlarIptalMi = true;
        await gorselliMayinBildirimi(turu, "💥 Ekstra Hamle Engeli: Tüm çarpanlar iptal edildi.");
        break;

      case MayinTuru.kelimeIptali:
        kelimeIptalMi = true;
        await gorselliMayinBildirimi(turu, "💥 Kelime İptali: Bu turda yazdığın kelimeler iptal edildi.");
        break;

      case MayinTuru.bolgeYasagi:
        bool yasakSol = Random().nextBool();
        final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

        if (yasakSol) {
          await roomRef.update({
            'bolgeYasagi': {
              'hedef': rakipOyuncu?.uid,
              'taraf': 'sol',
            }
          });
          await gorselliMayinBildirimi(turu, "💥 Bölge Yasağı: Rakip artık sadece SAĞ tarafa hamle yapabilir.");
        } else {
          await roomRef.update({
            'bolgeYasagi': {
              'hedef': rakipOyuncu?.uid,
              'taraf': 'sag',
            }
          });
          await gorselliMayinBildirimi(turu, "💥 Bölge Yasağı: Rakip artık sadece SOL tarafa hamle yapabilir.");
        }
        break;

      case MayinTuru.harfYasagi:
        final rakipHarfler = rakipOyuncu?.harfler ?? [];
        rakipHarfler.shuffle();
        final dondurulecekler = rakipHarfler.take(2).toList();

        await FirebaseFirestore.instance.collection('rooms').doc(widget.roomId).update({
          'harfYasagi': {
            'hedef': rakipOyuncu?.uid,
            'harfler': dondurulecekler,
          }
        });

        await gorselliMayinBildirimi(turu, "💥 Harf Yasağı: Rakibin 2 harfi geçici olarak kullanılamaz.");
        break;

      case MayinTuru.ekstraHamleJokeri:
        ekstraHamleJokeriMi = true;
        await gorselliMayinBildirimi(turu, "🎁 Ekstra Hamle Jokeri: Bu tur bir hamle daha yapabilirsin!");
        break;
    }
  }

  Future<void> gorselliMayinBildirimi(MayinTuru turu, String aciklama) async {
    if (!mounted) return;

    final String resimYolu = mayinAssetYolu(turu);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(resimYolu, width: 48, height: 48),
            const SizedBox(height: 12),
            Text(aciklama, textAlign: TextAlign.center),
          ],
        ),
      ),
    );

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) Navigator.of(context).pop(); // dialogu kapat
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Oyun Tahtası')),
      body: Column(
        children: [
          buildTopBar(),
          const SizedBox(height: 8),
          Expanded(child: buildBoard()),
          buildBottomBar(),
        ],
      ),
    );
  }

  Widget buildTopBar() {
    return Container(
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
    );
  }
  String carpanYazisi(CarpanTuru turu) {
  switch (turu) {
    case CarpanTuru.harf2:
      return 'H²';
    case CarpanTuru.harf3:
      return 'H³';
    case CarpanTuru.kelime2:
      return 'K²';
    case CarpanTuru.kelime3:
      return 'K³';
    case CarpanTuru.none:
    default:
      return '';
  }
}

Widget buildBoard() {
  if (board.isEmpty) {
    return const Center(child: CircularProgressIndicator());
  }

  return GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridSize),
    itemCount: gridSize * gridSize,
    itemBuilder: (context, index) {
      final mayin = mayinlar[index];
      final carpan = carpans[index];

      return GestureDetector(
        onTap: () async {
          if (!siradaBenVarim || selectedLetter == null || board[index] != null) return;

          if (rakipOyuncu == null) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rakip bekleniyor...')),
            );
            return;
          }

          final bool globalIlkHamleMi = board.where((e) => e != null).isEmpty;
          if (globalIlkHamleMi && aktifHamleler.isEmpty && index != 112) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('İlk hamlede sadece ortadaki kareye harf koyabilirsin.')),
            );
            return;
          }

          final col = index % gridSize;
          if (rakipSolTarafaYasak && col < 7) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bu bölgeye hamle yapamazsın! (Sol yasaklandı)')),
            );
            return;
          }
          if (rakipSagTarafaYasak && col > 7) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Bu bölgeye hamle yapamazsın! (Sağ yasaklandı)')),
            );
            return;
          }

          aktifHamleler.add(index);
          await kaydetHamle(index, selectedLetter!);
          setState(() {
            widget.oyuncu.harfler.removeAt(selectedLetterIndex!);
            selectedLetter = null;
            selectedLetterIndex = null;
          });
        },
        child: Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: board[index] != null
                ? (mayin != null && acilanMayinlar.contains(index)
                    ? mayinRenk(mayin)
                    : Colors.brown[100])
                : (carpan == CarpanTuru.harf2
                    ? Colors.lightBlue[100]
                    : carpan == CarpanTuru.harf3
                        ? Colors.lightBlue[200]
                        : carpan == CarpanTuru.kelime2
                            ? Colors.pink[100]
                            : carpan == CarpanTuru.kelime3
                                ? Colors.pink[200]
                                : Colors.brown[100]),
            border: Border.all(color: Colors.grey),
          ),
          child: Center(
            child: board[index] != null
                ? (mayin != null && acilanMayinlar.contains(index)
                    ? Image.asset(
                        mayinAssetYolu(mayin),
                        width: 24,
                        height: 24,
                        fit: BoxFit.contain,
                      )
                    : Text(
                        board[index]!,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: hamleRenkleri.containsKey(index)
                              ? hamleRenkleri[index]
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ))
                : index == 112
                    ? const Text('⭐️', style: TextStyle(fontSize: 16))
                    : Text(
                        carpanYazisi(carpans[index]),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
          ),
        ),
      );
    },
  );
}


Widget buildBottomBar() {
  return Container(
    color: Colors.blueGrey[50],
    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
    child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(widget.oyuncu.harfler.length, (index) {
            final harf = widget.oyuncu.harfler[index];
            final isSelected = selectedLetterIndex == index;
            final dondurulmus = dondurulenHarfler.contains(harf); // ✅ kontrol

            return GestureDetector(
              onTap: (siradaBenVarim && !dondurulmus)
                  ? () {
                      setState(() {
                        selectedLetter = harf;
                        selectedLetterIndex = index;
                      });
                    }
                  : null,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black45),
                  color: dondurulmus
                      ? Colors.grey[400]
                      : (isSelected ? Colors.amber : Colors.white),
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

        // 👇 Ekstra Hamle Jokeri Butonu
        if (ekstraHamleJokeriMi && !ekstraHamleKullanildiMi)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Ekstra hamle hakkı aktif!")),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text("Ekstra Hamle Aktif"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
              ),
            ),
          ),

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
PopupMenuButton<String>(
  icon: const Icon(Icons.more_vert),
  onSelected: (value) {
    if (value == 'terk') {
      _maciTerkEt();
    }
  },
  itemBuilder: (context) => [
    const PopupMenuItem<String>(
      value: 'terk',
      child: Text('Maçı Terk Et'),
    ),
  ],
),

          ],
        ),
      ],
    ),
  );
}

Future<void> _maciTerkEt() async {
  final uid = widget.oyuncu.uid;
  final rakipUid = rakipOyuncu?.uid;
  final roomRef = FirebaseFirestore.instance.collection('rooms').doc(widget.roomId);

  await roomRef.update({
    'status': 'finished',
    'resultUpdated_$uid': true,
  });

  // Kaybeden oyuncu (kendisi)
  await FirebaseFirestore.instance.collection('oyuncular').doc(uid).set({
    'oyunlar': FieldValue.increment(1),
    'kazanim': FieldValue.increment(0),
  }, SetOptions(merge: true));

  // Kazanan oyuncu (rakip)
  if (rakipUid != null) {
    await FirebaseFirestore.instance.collection('oyuncular').doc(rakipUid).set({
      'oyunlar': FieldValue.increment(1),
      'kazanim': FieldValue.increment(1),
    }, SetOptions(merge: true));
  }

  // Sonuç ekranı göster
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Text('Maçı Terk Ettiniz'),
      content: const Text('Rakibiniz bu maçı kazandı.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Ana Sayfa'),
        )
      ],
    ),
  );
}


  Color? mayinRenk(MayinTuru turu) {
    switch (turu) {
      case MayinTuru.puanBolunmesi:
        return Colors.lightBlue;
      case MayinTuru.puanTransferi:
        return Colors.purple;
      case MayinTuru.harfKaybi:
        return Colors.black;
      case MayinTuru.ekstraHamleEngeli:
        return Colors.grey;
      case MayinTuru.kelimeIptali:
        return Colors.orange;
      case MayinTuru.bolgeYasagi:
        return Colors.red;
      case MayinTuru.harfYasagi:
        return Colors.yellow;
      case MayinTuru.ekstraHamleJokeri:
        return Colors.green;
    }
  }

  String mayinAssetYolu(MayinTuru turu) {
    switch (turu) {
      case MayinTuru.puanBolunmesi:
        return 'assets/mayinlar/puan_bolunmesi.png';
      case MayinTuru.puanTransferi:
        return 'assets/mayinlar/puan_transferi.png';
      case MayinTuru.harfKaybi:
        return 'assets/mayinlar/harf_kaybi.png';
      case MayinTuru.ekstraHamleEngeli:
        return 'assets/mayinlar/ekstra_hamle_engeli.png';
      case MayinTuru.kelimeIptali:
        return 'assets/mayinlar/kelime_iptali.png';
      case MayinTuru.bolgeYasagi:
        return 'assets/mayinlar/bolge_yasagi.png';
      case MayinTuru.harfYasagi:
        return 'assets/mayinlar/harf_yasagi.png';
      case MayinTuru.ekstraHamleJokeri:
        return 'assets/mayinlar/ekstra_hamle_jokeri.png';
    }
  }
}