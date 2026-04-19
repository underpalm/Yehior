import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../constants/features.dart';
import '../models/bible_highlight.dart';
import '../models/chat_attachment.dart';
import '../models/conversation.dart';
import '../models/custom_plan.dart';
import '../models/reading_plan.dart';
import '../models/saved_message.dart';
import '../services/openai_service.dart';
import '../services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  final OpenAIService _openai;
  final StorageService _storage;

  ChatProvider({required OpenAIService openai, required StorageService storage})
      : _openai = openai,
        _storage = storage {
    _init();
  }

  // --- State ---

  List<Conversation> _conversations = [];
  String? _activeId;
  bool _isStreaming = false;
  String _streamingText = '';
  List<SavedMessage> _savedMessages = [];
  List<BibleHighlight> _highlights = [];
  int? _pendingScrollIndex;
  ChatAttachment? _pendingAttachment;
  bool _isRecording = false;
  bool _isTranscribing = false;
  List<PlanProgress> _planProgress = [];
  List<CustomPlan> _customPlans = [];

  // --- Getters ---

  List<Conversation> get conversations => _conversations;
  String? get activeId => _activeId;
  bool get isStreaming => _isStreaming;
  String get streamingText => _streamingText;
  List<SavedMessage> get savedMessages => _savedMessages;
  List<BibleHighlight> get highlights => _highlights;
  int? get pendingScrollIndex => _pendingScrollIndex;
  ChatAttachment? get pendingAttachment => _pendingAttachment;
  bool get isRecording => _isRecording;
  bool get isTranscribing => _isTranscribing;
  List<PlanProgress> get planProgress => _planProgress;
  List<CustomPlan> get customPlans => _customPlans;

  List<ReadingPlan> get allPlans => [
        ...customPlans.map((c) => c.toReadingPlan()),
      ];

  void clearPendingScroll() {
    _pendingScrollIndex = null;
  }

  Conversation? get activeConversation => _activeId == null
      ? null
      : _conversations.firstWhere((c) => c.id == _activeId);

  // --- Init ---

  Future<void> _init() async {
    _conversations = await _storage.loadConversations();
    _savedMessages = await _storage.loadSavedMessages();
    _highlights = await _storage.loadHighlights();
    _planProgress = await _storage.loadPlanProgress();
    _customPlans = await _storage.loadCustomPlans();
    notifyListeners();
  }

  // --- Navigation ---

  void startNewChat() {
    _activeId = null;
    notifyListeners();
  }

  /// Opens a feature chat with a greeting message from the bot.
  /// Does NOT call the API — waits for the user's first message.
  void startFeatureChat(String feature) {
    final greeting = kGreetings[feature] ?? kGreetings[kDefaultFeature]!;

    final newConv = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: feature,
      feature: feature,
      messages: [_botMsg(greeting)],
      updatedAt: DateTime.now(),
    );

    _conversations.insert(0, newConv);
    _activeId = newConv.id;
    notifyListeners();
    _storage.saveConversations(_conversations);
  }

  void openConversation(String id) {
    _activeId = id;
    notifyListeners();
  }

  /// Opens a conversation and sets a pending scroll to the message matching [messageText].
  bool openConversationAtMessage(String conversationId, String messageText) {
    final conv = _conversations.where((c) => c.id == conversationId).firstOrNull;
    if (conv == null) return false;

    final index = conv.messages.indexWhere((m) => m['text'] == messageText);
    _activeId = conversationId;
    _pendingScrollIndex = index >= 0 ? index : null;
    notifyListeners();
    return true;
  }

  // --- Voice recording ---

  void setRecording(bool value) {
    _isRecording = value;
    notifyListeners();
  }

  void setTranscribing(bool value) {
    _isTranscribing = value;
    notifyListeners();
  }

  Future<String> transcribeAudio(String filePath) {
    return _openai.transcribeAudio(filePath);
  }

  // --- Attachments ---

  void setAttachment(ChatAttachment attachment) {
    _pendingAttachment = attachment;
    notifyListeners();
  }

  void clearAttachment() {
    _pendingAttachment = null;
    notifyListeners();
  }

  // --- Messaging ---

  Future<void> sendMessage(String text) async {
    text = text.trim();
    if (text.isEmpty && _pendingAttachment == null) return;
    if (_isStreaming) return;

    // Grab and clear attachment before async work
    final attachment = _pendingAttachment;
    _pendingAttachment = null;

    // Build display text for the chat bubble
    final displayText = _buildDisplayText(text, attachment);

    if (_activeId == null) {
      final greeting = kGreetings[kDefaultFeature]!;
      final newConv = Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: text.isNotEmpty
            ? (text.length > 40 ? '${text.substring(0, 40)}…' : text)
            : attachment?.fileName ?? 'Neuer Chat',
        feature: kDefaultFeature,
        messages: [
          _botMsg(greeting),
          _userMsg(displayText, imageBytes: attachment?.isImage == true ? attachment!.bytes : null),
        ],
        updatedAt: DateTime.now(),
      );
      _conversations.insert(0, newConv);
      _activeId = newConv.id;
    } else {
      _updateActive((c) => c.copyWith(
            messages: [
              ...c.messages,
              _userMsg(displayText, imageBytes: attachment?.isImage == true ? attachment!.bytes : null),
            ],
            updatedAt: DateTime.now(),
          ));
    }

    notifyListeners();
    await _storage.saveConversations(_conversations);

    // Build the API messages — skip the local greeting for the API
    final systemPrompt = _buildSystemPrompt();
    final allMessages = activeConversation!.messages;
    final history = <Map<String, dynamic>>[];

    for (var i = 0; i < allMessages.length; i++) {
      final m = allMessages[i];
      // Skip the initial bot greeting
      if (i == 0 && !(m['isUser'] as bool)) continue;

      final role = m['isUser'] as bool ? 'user' : 'assistant';

      // For the last user message, use multimodal content if there's an attachment
      if (i == allMessages.length - 1 && m['isUser'] == true && attachment != null) {
        history.add({
          'role': role,
          'content': OpenAIService.buildUserContent(
            text.isNotEmpty ? text : 'Was siehst du auf diesem Bild?',
            attachment,
          ),
        });
      } else {
        history.add({
          'role': role,
          'content': m['text'] as String,
        });
      }
    }

    _isStreaming = true;
    _streamingText = '';
    notifyListeners();

    try {
      await for (final chunk in _openai.streamMessage(
        messages: history,
        systemPrompt: systemPrompt,
      )) {
        _streamingText += chunk;
        notifyListeners();
      }
    } finally {
      if (_streamingText.isNotEmpty) {
        _updateActive((c) => c.copyWith(
              messages: [...c.messages, _botMsg(_streamingText)],
              updatedAt: DateTime.now(),
            ));
      }
      _isStreaming = false;
      _streamingText = '';
      notifyListeners();
      await _storage.saveConversations(_conversations);
    }
  }

  String _buildDisplayText(String text, ChatAttachment? attachment) {
    if (attachment == null) return text;
    final prefix = attachment.isImage
        ? '📷 ${attachment.fileName}'
        : '📄 ${attachment.fileName}';
    return text.isEmpty ? prefix : '$prefix\n$text';
  }

  // --- Conversation management ---

  void renameConversation(String id, String newTitle) {
    _conversations = _conversations
        .map((c) => c.id == id ? c.copyWith(title: newTitle) : c)
        .toList();
    notifyListeners();
    _storage.saveConversations(_conversations);
  }

  void deleteConversation(String id) {
    _conversations.removeWhere((c) => c.id == id);
    if (_activeId == id) _activeId = null;
    notifyListeners();
    _storage.saveConversations(_conversations);
  }

  // --- Saved messages ---

  bool isMessageSaved(String text) {
    return _savedMessages.any((m) => m.text == text);
  }

  void saveMessage(String text) {
    if (isMessageSaved(text)) return;
    final feature = activeConversation?.feature ?? kDefaultFeature;
    final convId = activeConversation?.id ?? '';
    final msg = SavedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text,
      feature: feature,
      conversationId: convId,
      savedAt: DateTime.now(),
    );
    _savedMessages.insert(0, msg);
    notifyListeners();
    _storage.saveSavedMessages(_savedMessages);
  }

  void unsaveMessage(String text) {
    _savedMessages.removeWhere((m) => m.text == text);
    notifyListeners();
    _storage.saveSavedMessages(_savedMessages);
  }

  void deleteSavedMessage(String id) {
    _savedMessages.removeWhere((m) => m.id == id);
    notifyListeners();
    _storage.saveSavedMessages(_savedMessages);
  }

  // --- Bible highlights ---

  BibleHighlight? getHighlight(int bookNumber, int chapter, int verseNumber) {
    return _highlights
        .where((h) =>
            h.bookNumber == bookNumber &&
            h.chapter == chapter &&
            h.verseNumber == verseNumber)
        .firstOrNull;
  }

  void addHighlight({
    required int bookNumber,
    required String bookName,
    required int chapter,
    required int verseNumber,
    required String text,
    required int colorValue,
  }) {
    // Remove existing highlight for this verse if any
    _highlights.removeWhere((h) =>
        h.bookNumber == bookNumber &&
        h.chapter == chapter &&
        h.verseNumber == verseNumber);

    _highlights.insert(
      0,
      BibleHighlight(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        bookNumber: bookNumber,
        bookName: bookName,
        chapter: chapter,
        verseNumber: verseNumber,
        text: text,
        colorValue: colorValue,
        createdAt: DateTime.now(),
      ),
    );
    notifyListeners();
    _storage.saveHighlights(_highlights);

    // Also save to Gespeichert
    saveVerseToSaved(
      bookNumber: bookNumber,
      bookName: bookName,
      chapter: chapter,
      verseNumber: verseNumber,
      text: text,
    );
  }

  void removeHighlight(int bookNumber, int chapter, int verseNumber) {
    _highlights.removeWhere((h) =>
        h.bookNumber == bookNumber &&
        h.chapter == chapter &&
        h.verseNumber == verseNumber);
    notifyListeners();
    _storage.saveHighlights(_highlights);
  }

  void saveVerseToSaved({
    required int bookNumber,
    required String bookName,
    required int chapter,
    required int verseNumber,
    required String text,
  }) {
    final verseText = '> „$text"\n> — $bookName $chapter,$verseNumber';
    if (isMessageSaved(verseText)) return;
    final msg = SavedMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: verseText,
      feature: 'Bibelgespräch',
      conversationId: '',
      savedAt: DateTime.now(),
      bookNumber: bookNumber,
      bookName: bookName,
      chapter: chapter,
      verseNumber: verseNumber,
    );
    _savedMessages.insert(0, msg);
    notifyListeners();
    _storage.saveSavedMessages(_savedMessages);
  }

  // --- Reading plans ---

  PlanProgress? getPlanProgress(String planId) {
    return _planProgress.where((p) => p.planId == planId).firstOrNull;
  }

  void startPlan(String planId, int totalDays) {
    // Remove any existing progress for this plan
    _planProgress.removeWhere((p) => p.planId == planId);
    final progress = PlanProgress(
      planId: planId,
      startDate: DateTime.now(),
    );
    progress.setTotalDays(totalDays);
    _planProgress.add(progress);
    notifyListeners();
    _storage.savePlanProgress(_planProgress);
  }

  void togglePlanDay(String planId, int day, int totalDays) {
    final progress = getPlanProgress(planId);
    if (progress == null) return;
    progress.setTotalDays(totalDays);
    if (progress.completedDays.contains(day)) {
      progress.completedDays.remove(day);
    } else {
      progress.completedDays.add(day);
    }
    notifyListeners();
    _storage.savePlanProgress(_planProgress);
  }

  void removePlan(String planId) {
    _planProgress.removeWhere((p) => p.planId == planId);
    notifyListeners();
    _storage.savePlanProgress(_planProgress);
  }

  // --- Custom plans ---

  void startPlanCreatorChat() {
    final greeting = kPlanCreatorGreeting['Planersteller']!;

    final newConv = Conversation(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Planersteller',
      feature: 'Planersteller',
      messages: [_botMsg(greeting)],
      updatedAt: DateTime.now(),
    );

    _conversations.insert(0, newConv);
    _activeId = newConv.id;
    notifyListeners();
    _storage.saveConversations(_conversations);
  }

  CustomPlan? parsePlanFromMessage(String messageText) {
    final regex = RegExp(r'```yehior-plan\s*\n([\s\S]*?)\n```');
    final match = regex.firstMatch(messageText);
    if (match == null) return null;

    try {
      final json = jsonDecode(match.group(1)!) as Map<String, dynamic>;
      final days = (json['days'] as List).map((day) {
        return (day as List)
            .map((r) => PlanReading.fromJson(r as Map<String, dynamic>))
            .toList();
      }).toList();

      return CustomPlan(
        id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
        title: json['title'] as String,
        description: json['description'] as String,
        icon: json['icon'] as String? ?? '📋',
        totalDays: days.length,
        dailyReadings: days,
        createdAt: DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  void addCustomPlan(CustomPlan plan) {
    _customPlans.insert(0, plan);
    notifyListeners();
    _storage.saveCustomPlans(_customPlans);
  }

  void deleteCustomPlan(String planId) {
    _customPlans.removeWhere((p) => p.id == planId);
    _planProgress.removeWhere((p) => p.planId == planId);
    notifyListeners();
    _storage.saveCustomPlans(_customPlans);
    _storage.savePlanProgress(_planProgress);
  }

  // --- Helpers ---

  String _buildSystemPrompt() {
    final feature = activeConversation?.feature ?? kDefaultFeature;
    return kSystemPrompts[feature] ?? kSystemPrompts[kDefaultFeature]!;
  }

  void _updateActive(Conversation Function(Conversation) updater) {
    _conversations = _conversations.map((c) {
      if (c.id != _activeId) return c;
      return updater(c);
    }).toList();
  }

  Map<String, dynamic> _userMsg(String text, {Uint8List? imageBytes}) {
    final msg = <String, dynamic>{'text': text, 'isUser': true};
    if (imageBytes != null) {
      msg['imageBytes'] = imageBytes;
    }
    return msg;
  }

  Map<String, dynamic> _botMsg(String text) => {'text': text, 'isUser': false};
}
