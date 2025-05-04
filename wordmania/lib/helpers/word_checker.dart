import 'package:flutter/services.dart' show rootBundle;

class WordChecker {
  static List<String> _words = [];

  static Future<void> loadWords() async {
    final content = await rootBundle.loadString('assets/words_tr.txt');
    _words = content.split('\n').map((e) => e.trim().toUpperCase()).toList();
  }

  static bool isWordValid(String word) {
    return _words.contains(word.toUpperCase());
  }
}
