import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/bible_highlight.dart';
import '../models/conversation.dart';
import '../models/custom_plan.dart';
import '../models/reading_plan.dart';
import '../models/saved_message.dart';

class StorageService {
  static const _key = 'conversations';
  static const _savedKey = 'saved_messages';
  static const _highlightsKey = 'bible_highlights';
  static const _plansKey = 'plan_progress';
  static const _customPlansKey = 'custom_plans';

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

  Future<List<PlanProgress>> loadPlanProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_plansKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => PlanProgress.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> savePlanProgress(List<PlanProgress> progress) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _plansKey,
      jsonEncode(progress.map((p) => p.toJson()).toList()),
    );
  }

  Future<List<CustomPlan>> loadCustomPlans() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customPlansKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => CustomPlan.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCustomPlans(List<CustomPlan> plans) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _customPlansKey,
      jsonEncode(plans.map((p) => p.toJson()).toList()),
    );
  }
}
