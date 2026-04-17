import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';
import '../constants/bible_books.dart';
import '../constants/features.dart';
import '../constants/theme.dart';
import '../models/saved_message.dart';
import '../providers/chat_provider.dart';
import 'bible_reader_screen.dart';

class SavedScreen extends StatelessWidget {
  const SavedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final saved = provider.savedMessages;

    // Group by feature
    final grouped = <String, List<SavedMessage>>{};
    for (final msg in saved) {
      grouped.putIfAbsent(msg.feature, () => []).add(msg);
    }

    // Order categories by kFeatures order
    final orderedKeys = kFeatures
        .map((f) => f['label']!)
        .where((label) => grouped.containsKey(label))
        .toList();

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
        title: const Text(
          'Gespeichert',
          style: TextStyle(
            color: kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: saved.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border, size: 48, color: kTextSecondary),
                  SizedBox(height: 12),
                  Text(
                    'Noch nichts gespeichert',
                    style: TextStyle(color: kTextSecondary, fontSize: 16),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Tippe auf das Lesezeichen-Icon\nim Chat, um Antworten zu speichern.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kTextSecondary, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: orderedKeys.length,
              itemBuilder: (context, i) {
                final feature = orderedKeys[i];
                final messages = grouped[feature]!;
                final icon = kFeatures
                    .firstWhere((f) => f['label'] == feature)['icon']!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                      child: Text(
                        '$icon  $feature',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: kTextPrimary,
                        ),
                      ),
                    ),
                    ...messages.map((msg) => _SavedCard(
                          message: msg,
                          onDelete: () => provider.deleteSavedMessage(msg.id),
                          onTap: () => _navigateToMessage(context, provider, msg),
                        )),
                  ],
                );
              },
            ),
    );
  }

  void _navigateToMessage(
    BuildContext context,
    ChatProvider provider,
    SavedMessage msg,
  ) {
    if (msg.isFromBible) {
      // Open Bible reader at the saved verse location
      final book = kAllBooks.where((b) => b.number == msg.bookNumber).firstOrNull;
      if (book != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BibleReaderScreen(
              initialBook: book,
              initialChapter: msg.chapter,
            ),
          ),
        );
      }
    } else {
      // Open the chat conversation
      final found = provider.openConversationAtMessage(
        msg.conversationId,
        msg.text,
      );

      if (found) {
        Navigator.pop(context); // back to HomeScreen
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Das Gespräch wurde gelöscht.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }
}

class _SavedCard extends StatelessWidget {
  final SavedMessage message;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const _SavedCard({
    required this.message,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GptMarkdown(
              message.text.length > 300
                  ? '${message.text.substring(0, 300)}…'
                  : message.text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (message.isFromBible)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.menu_book_outlined,
                        size: 14, color: kTextSecondary),
                  ),
                if (!message.isFromBible)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.chat_outlined,
                        size: 14, color: kTextSecondary),
                  ),
                Text(
                  _formatDate(message.savedAt),
                  style: const TextStyle(fontSize: 11, color: kTextSecondary),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _confirmDelete(context),
                  child: const Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: kTextSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(
                'Gespeicherten Eintrag löschen?',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red),
              title: const Text('Löschen',
                  style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                onDelete();
              },
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Abbrechen'),
              onTap: () => Navigator.pop(context),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
  }
}
