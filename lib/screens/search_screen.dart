import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../models/conversation.dart';
import '../providers/chat_provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<_SearchResult> _search(List<Conversation> conversations) {
    if (_query.isEmpty) return [];
    final lower = _query.toLowerCase();
    final results = <_SearchResult>[];

    for (final conv in conversations) {
      for (var i = 0; i < conv.messages.length; i++) {
        final text = conv.messages[i]['text'] as String;
        if (text.toLowerCase().contains(lower)) {
          results.add(_SearchResult(
            conversation: conv,
            messageIndex: i,
            messageText: text,
            isUser: conv.messages[i]['isUser'] as bool,
          ));
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final results = _search(provider.conversations);

    return Scaffold(
      backgroundColor: kBgColor,
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'In Gesprächen suchen…',
            hintStyle: TextStyle(color: kTextSecondary, fontSize: 16),
            border: InputBorder.none,
          ),
          style: const TextStyle(fontSize: 16, color: kTextPrimary),
          onChanged: (v) => setState(() => _query = v.trim()),
        ),
        actions: [
          if (_query.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.close, color: kTextSecondary),
              onPressed: () {
                _controller.clear();
                setState(() => _query = '');
              },
            ),
        ],
      ),
      body: _query.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.search, size: 48, color: kTextSecondary),
                  SizedBox(height: 12),
                  Text(
                    'Suche in allen Gesprächen',
                    style: TextStyle(color: kTextSecondary, fontSize: 16),
                  ),
                ],
              ),
            )
          : results.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.search_off,
                          size: 48, color: kTextSecondary),
                      const SizedBox(height: 12),
                      Text(
                        'Keine Ergebnisse für „$_query"',
                        style: const TextStyle(
                            color: kTextSecondary, fontSize: 16),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: results.length,
                  itemBuilder: (context, i) {
                    final r = results[i];
                    return _ResultCard(
                      result: r,
                      query: _query,
                      onTap: () {
                        final provider = context.read<ChatProvider>();
                        provider.openConversationAtMessage(
                          r.conversation.id,
                          r.messageText,
                        );
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
    );
  }
}

class _SearchResult {
  final Conversation conversation;
  final int messageIndex;
  final String messageText;
  final bool isUser;

  const _SearchResult({
    required this.conversation,
    required this.messageIndex,
    required this.messageText,
    required this.isUser,
  });
}

class _ResultCard extends StatelessWidget {
  final _SearchResult result;
  final String query;
  final VoidCallback onTap;

  const _ResultCard({
    required this.result,
    required this.query,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Find the snippet around the match
    final lower = result.messageText.toLowerCase();
    final queryLower = query.toLowerCase();
    final matchIndex = lower.indexOf(queryLower);
    final snippet = _buildSnippet(result.messageText, matchIndex, query.length);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conversation title + feature badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    result.conversation.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: kTextPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: kPillBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    result.conversation.feature,
                    style: const TextStyle(fontSize: 10, color: kAccentBlue),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Snippet with highlighted match
            RichText(text: snippet),
            const SizedBox(height: 4),
            Text(
              result.isUser ? 'Du' : 'Yehior',
              style: const TextStyle(fontSize: 11, color: kTextSecondary),
            ),
          ],
        ),
      ),
    );
  }

  TextSpan _buildSnippet(String text, int matchIndex, int matchLength) {
    // Show ~60 chars before and after the match
    const window = 60;
    final start = (matchIndex - window).clamp(0, text.length);
    final end = (matchIndex + matchLength + window).clamp(0, text.length);

    final before = text.substring(start, matchIndex);
    final match = text.substring(matchIndex, matchIndex + matchLength);
    final after = text.substring(matchIndex + matchLength, end);

    return TextSpan(
      style: const TextStyle(fontSize: 14, color: kTextPrimary, height: 1.4),
      children: [
        if (start > 0) const TextSpan(text: '…'),
        TextSpan(text: before),
        TextSpan(
          text: match,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            backgroundColor: Color(0xFFFFF176),
          ),
        ),
        TextSpan(text: after),
        if (end < text.length) const TextSpan(text: '…'),
      ],
    );
  }
}
