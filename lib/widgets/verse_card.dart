import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/bible_books.dart';
import '../constants/theme.dart';
import '../providers/chat_provider.dart';
import '../screens/bible_reader_screen.dart';

// The daily verse — update these three values to change the verse.
const _verseText    = '„Denn ich weiß wohl, was ich für Gedanken über euch habe..."';
const _verseRef     = 'Jeremia 29,11';
const _verseBook    = BibleBook(number: 24, name: 'Jeremia', chapters: 52);
const _verseChapter = 29;

class VerseCard extends StatelessWidget {
  const VerseCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showOptions(context),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.auto_awesome, color: Colors.blueAccent, size: 16),
                SizedBox(width: 8),
                Text(
                  'VERS DES TAGES',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
                Spacer(),
                Icon(Icons.chevron_right, size: 16, color: kTextSecondary),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              _verseText,
              style: TextStyle(fontSize: 16, height: 1.4, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 8),
            const Text(
              _verseRef,
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vers des Tages',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _verseRef,
                    style: const TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                ],
              ),
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPillBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_outlined, color: kAccentBlue),
              ),
              title: const Text('Im Chat besprechen'),
              subtitle: const Text('Stelle Fragen zu diesem Vers'),
              onTap: () {
                Navigator.pop(context);
                final provider = context.read<ChatProvider>();
                provider.startFeatureChat('Bibelgespräch');
                provider.sendMessage(
                      'Erkläre mir diesen Bibelvers: $_verseRef — $_verseText',
                    );
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.menu_book_outlined, color: kTextPrimary),
              ),
              title: const Text('In der Bibel lesen'),
              subtitle: const Text('Ganzes Kapitel öffnen'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BibleReaderScreen(
                      initialBook: _verseBook,
                      initialChapter: _verseChapter,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
