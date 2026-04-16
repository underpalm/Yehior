import 'dart:convert';
import 'package:flutter/services.dart';

class BibleVerse {
  final int number;
  final String text;

  const BibleVerse({required this.number, required this.text});
}

class BibleService {
  // Loaded once, cached for the app lifetime
  static List<dynamic>? _data;

  Future<void> _ensureLoaded() async {
    if (_data != null) return;
    final raw = await rootBundle.loadString('assets/bible_de.json');
    // The file has a UTF-8 BOM — strip it if present
    final cleaned = raw.startsWith('\uFEFF') ? raw.substring(1) : raw;
    _data = jsonDecode(cleaned) as List<dynamic>;
  }

  /// Returns verses for [bookNumber] (1–66) and [chapter] (1–n).
  Future<List<BibleVerse>> fetchChapter(int bookNumber, int chapter) async {
    await _ensureLoaded();

    final book = _data![bookNumber - 1] as Map<String, dynamic>;
    final chapters = book['chapters'] as List<dynamic>;

    if (chapter < 1 || chapter > chapters.length) {
      throw Exception('Kapitel $chapter existiert nicht in diesem Buch.');
    }

    final verses = chapters[chapter - 1] as List<dynamic>;
    return verses.asMap().entries.map((e) => BibleVerse(
          number: e.key + 1,
          text: e.value as String,
        )).toList();
  }
}
