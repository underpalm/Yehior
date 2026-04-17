import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/bible_books.dart';
import '../constants/theme.dart';
import '../providers/chat_provider.dart';
import '../services/bible_service.dart';

const _highlightColors = [
  Color(0xFFFFF176), // yellow
  Color(0xFFA5D6A7), // green
  Color(0xFF90CAF9), // blue
  Color(0xFFF48FB1), // pink
  Color(0xFFFFCC80), // orange
];

class BibleReaderScreen extends StatefulWidget {
  final BibleBook? initialBook;
  final int? initialChapter;

  const BibleReaderScreen({super.key, this.initialBook, this.initialChapter});

  @override
  State<BibleReaderScreen> createState() => _BibleReaderScreenState();
}

class _BibleReaderScreenState extends State<BibleReaderScreen> {
  final _bibleService = BibleService();

  BibleBook? _selectedBook;
  int? _selectedChapter;
  List<BibleVerse>? _verses;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialBook != null) {
      _selectedBook = widget.initialBook;
      if (widget.initialChapter != null) {
        _selectChapter(widget.initialChapter!);
      }
    }
  }

  void _selectBook(BibleBook book) {
    setState(() {
      _selectedBook = book;
      _selectedChapter = null;
      _verses = null;
      _error = null;
    });
  }

  Future<void> _selectChapter(int chapter) async {
    setState(() {
      _selectedChapter = chapter;
      _verses = null;
      _loading = true;
      _error = null;
    });

    try {
      final verses =
          await _bibleService.fetchChapter(_selectedBook!.number, chapter);
      if (mounted) setState(() { _verses = verses; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _goBack() {
    setState(() {
      if (_selectedChapter != null) {
        _selectedChapter = null;
        _verses = null;
        _error = null;
      } else {
        _selectedBook = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: kBgColor,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: kTextPrimary),
          onPressed:
              _selectedBook != null ? _goBack : () => Navigator.pop(context),
        ),
        title: Text(
          _selectedChapter != null
              ? '${_selectedBook!.name} ${_selectedChapter!}'
              : _selectedBook != null
                  ? _selectedBook!.name
                  : 'Bibel',
          style: const TextStyle(
              color: kTextPrimary, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          if (_selectedBook != null)
            IconButton(
              icon: const Icon(Icons.close, color: kTextPrimary),
              tooltip: 'Zurück zum Chat',
              onPressed: () => Navigator.pop(context),
            ),
        ],
      ),
      body: _selectedChapter != null
          ? _buildChapterView()
          : _selectedBook != null
              ? _buildChapterList()
              : _buildBookList(),
    );
  }

  // --- Book list ---

  Widget _buildBookList() {
    return ListView(
      children: [
        _sectionHeader('Altes Testament'),
        ...kOldTestament.map((b) => _bookTile(b)),
        _sectionHeader('Neues Testament'),
        ...kNewTestament.map((b) => _bookTile(b)),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
          color: kTextSecondary,
        ),
      ),
    );
  }

  Widget _bookTile(BibleBook book) {
    return ListTile(
      title: Text(book.name),
      subtitle: Text('${book.chapters} Kapitel',
          style: const TextStyle(fontSize: 12, color: kTextSecondary)),
      trailing:
          const Icon(Icons.chevron_right, size: 18, color: kTextSecondary),
      onTap: () => _selectBook(book),
    );
  }

  // --- Chapter list ---

  Widget _buildChapterList() {
    final count = _selectedBook!.chapters;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: count,
      itemBuilder: (context, i) {
        final chapter = i + 1;
        return GestureDetector(
          onTap: () => _selectChapter(chapter),
          child: Container(
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(12),
            ),
            alignment: Alignment.center,
            child: Text(
              '$chapter',
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
        );
      },
    );
  }

  // --- Chapter content ---

  Widget _buildChapterView() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 40, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => _selectChapter(_selectedChapter!),
                child: const Text('Erneut versuchen'),
              ),
            ],
          ),
        ),
      );
    }
    if (_verses == null) return const SizedBox.shrink();

    final provider = context.watch<ChatProvider>();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: _verses!.length,
      itemBuilder: (context, i) {
        final verse = _verses![i];
        final highlight = provider.getHighlight(
          _selectedBook!.number,
          _selectedChapter!,
          verse.number,
        );

        return GestureDetector(
          onTap: () => _showVerseActions(context, verse, highlight != null),
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: highlight != null
                  ? Color(highlight.colorValue).withValues(alpha: 0.35)
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                    fontSize: 17, color: Colors.black, height: 1.6),
                children: [
                  TextSpan(
                    text: '${verse.number} ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: kTextSecondary,
                      fontSize: 13,
                    ),
                  ),
                  TextSpan(text: verse.text),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Verse action sheet ---

  void _showVerseActions(
      BuildContext context, BibleVerse verse, bool isHighlighted) {
    final provider = context.read<ChatProvider>();
    final ref = '${_selectedBook!.name} ${_selectedChapter!},${verse.number}';

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(ref,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(
                    verse.text.length > 80
                        ? '${verse.text.substring(0, 80)}…'
                        : verse.text,
                    style:
                        const TextStyle(fontSize: 13, color: kTextSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Color picker row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Text('Markieren:',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 12),
                  ..._highlightColors.map((color) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            provider.addHighlight(
                              bookNumber: _selectedBook!.number,
                              bookName: _selectedBook!.name,
                              chapter: _selectedChapter!,
                              verseNumber: verse.number,
                              text: verse.text,
                              colorValue: color.toARGB32(),
                            );
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.black12, width: 1),
                            ),
                          ),
                        ),
                      )),
                ],
              ),
            ),

            const Divider(height: 24),

            // Save
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kPillBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child:
                    const Icon(Icons.bookmark_border, color: kAccentBlue),
              ),
              title: const Text('Speichern'),
              subtitle: const Text('In deiner Sammlung speichern'),
              onTap: () {
                provider.saveVerseToSaved(
                  bookNumber: _selectedBook!.number,
                  bookName: _selectedBook!.name,
                  chapter: _selectedChapter!,
                  verseNumber: verse.number,
                  text: verse.text,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$ref gespeichert'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),

            // Chat
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: kSurfaceColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chat_outlined, color: kTextPrimary),
              ),
              title: const Text('Im Chat besprechen'),
              subtitle: const Text('Stelle Fragen zu diesem Vers'),
              onTap: () {
                Navigator.pop(context); // close bottom sheet
                Navigator.pop(context); // back to home
                provider.startFeatureChat('Bibelgespräch');
                provider.sendMessage(
                  'Erkläre mir diesen Bibelvers: $ref — „${verse.text}"',
                );
              },
            ),

            // Remove highlight
            if (isHighlighted)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCE4EC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.format_color_reset,
                      color: Colors.red),
                ),
                title: const Text('Markierung entfernen'),
                onTap: () {
                  provider.removeHighlight(
                    _selectedBook!.number,
                    _selectedChapter!,
                    verse.number,
                  );
                  Navigator.pop(context);
                },
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
