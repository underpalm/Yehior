import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../providers/chat_provider.dart';
import '../screens/bible_reader_screen.dart';

class BottomInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const BottomInput({
    super.key,
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Container(
      color: kBgColor,
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        color: kInputColor,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: TextField(
                controller: controller,
                enabled: !provider.isStreaming,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: provider.isStreaming ? 'Antwort wird geladen…' : 'Fragen...',
                  border: InputBorder.none,
                  hintStyle: const TextStyle(color: kTextSecondary, fontSize: 18),
                ),
              ),
            ),
            Row(
              children: [
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.add, color: kTextPrimary),
                  onPressed: () {},
                ),
                const Spacer(),
                // Bibel-Button
                GestureDetector(
                  onTap: () => _showBibleMenu(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: kPillBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.menu_book_outlined, size: 16, color: kAccentBlue),
                        SizedBox(width: 6),
                        Text(
                          'Bibel',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: kAccentBlue,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(Icons.expand_more, size: 16, color: kAccentBlue),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Mic (Whisper — kommt später)
                IconButton(
                  icon: _circleIcon(Icons.mic_none),
                  onPressed: null,
                ),
                const SizedBox(width: 8),
                // Send
                IconButton(
                  icon: _circleIcon(
                    provider.isStreaming ? Icons.hourglass_top : Icons.send,
                    filled: true,
                  ),
                  onPressed: provider.isStreaming ? null : onSend,
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showBibleMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Text(
                'Bibel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kPillBlue, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.chat_outlined, color: kAccentBlue),
              ),
              title: const Text('Mit der Bibel chatten'),
              subtitle: const Text('Stelle Fragen, erhalte Erklärungen & Andachten'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: kSurfaceColor, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.menu_book_outlined, color: kTextPrimary),
              ),
              title: const Text('Bibel lesen'),
              subtitle: const Text('Luther-Übersetzung — alle 66 Bücher'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BibleReaderScreen()),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _circleIcon(IconData icon, {bool filled = false}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: filled ? kPillBlue : Colors.transparent,
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: kDivider),
      ),
      child: Icon(icon, color: kTextPrimary, size: 24),
    );
  }
}
