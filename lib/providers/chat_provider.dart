import 'package:flutter/foundation.dart';
import '../constants/features.dart';
import '../models/conversation.dart';
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

  // --- Getters ---

  List<Conversation> get conversations => _conversations;
  String? get activeId => _activeId;
  bool get isStreaming => _isStreaming;
  String get streamingText => _streamingText;

  Conversation? get activeConversation => _activeId == null
      ? null
      : _conversations.firstWhere((c) => c.id == _activeId);

  // --- Init ---

  Future<void> _init() async {
    _conversations = await _storage.loadConversations();
    notifyListeners();
  }

  // --- Navigation ---

  void startNewChat() {
    _activeId = null;
    notifyListeners();
  }

  void openConversation(String id) {
    _activeId = id;
    notifyListeners();
  }

  // --- Messaging ---

  Future<void> sendMessage(String text) async {
    text = text.trim();
    if (text.isEmpty || _isStreaming) return;

    if (_activeId == null) {
      final newConv = Conversation(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: text.length > 40 ? '${text.substring(0, 40)}…' : text,
        messages: [_userMsg(text)],
        updatedAt: DateTime.now(),
      );
      _conversations.insert(0, newConv);
      _activeId = newConv.id;
    } else {
      _updateActive((c) => c.copyWith(
            messages: [...c.messages, _userMsg(text)],
            updatedAt: DateTime.now(),
          ));
    }

    notifyListeners();
    await _storage.saveConversations(_conversations);

    final systemPrompt = _buildSystemPrompt();
    final history = activeConversation!.messages
        .map((m) => {
              'role': m['isUser'] as bool ? 'user' : 'assistant',
              'content': m['text'] as String,
            })
        .toList();

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

  // --- Helpers ---

  String _buildSystemPrompt() {
    final feature = _activeId != null
        ? kFeatures.firstWhere(
            (f) => activeConversation!.title.contains(f['label']!),
            orElse: () => kFeatures.first,
          )['label']
        : 'Bibelgespräch';

    return 'Du bist Yehior, ein KI-Bibelbegleiter. '
        'Aktueller Modus: $feature. '
        'Antworte auf Deutsch, einfühlsam und bibeltreu. '
        'Wenn du Bibelverse zitierst, formatiere sie IMMER als Blockquote mit > am Anfang jeder Zeile. '
        'Beispiel:\n'
        '> „Denn also hat Gott die Welt geliebt..."\n'
        '> — Johannes 3,16';
  }

  void _updateActive(Conversation Function(Conversation) updater) {
    _conversations = _conversations.map((c) {
      if (c.id != _activeId) return c;
      return updater(c);
    }).toList();
  }

  Map<String, dynamic> _userMsg(String text) => {'text': text, 'isUser': true};
  Map<String, dynamic> _botMsg(String text) => {'text': text, 'isUser': false};
}
