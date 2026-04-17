import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_highlight.dart';
import '../models/conversation.dart';
import '../models/saved_message.dart';

class StorageService {
  static const _key = 'conversations';
  static const _savedKey = 'saved_messages';
  static const _highlightsKey = 'bible_highlights';

  Future<List<Conversation>> loadConversations() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveConversations(List<Conversation> conversations) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(conversations.map((c) => c.toJson()).toList()),
    );
  }

  Future<List<SavedMessage>> loadSavedMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_savedKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => SavedMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveSavedMessages(List<SavedMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _savedKey,
      jsonEncode(messages.map((m) => m.toJson()).toList()),
    );
  }

  Future<List<BibleHighlight>> loadHighlights() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_highlightsKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => BibleHighlight.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveHighlights(List<BibleHighlight> highlights) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _highlightsKey,
      jsonEncode(highlights.map((h) => h.toJson()).toList()),
    );
  }
}
