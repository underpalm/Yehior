import 'package:flutter/material.dart';
import '../constants/bible_books.dart';
import '../constants/theme.dart';
import '../services/bible_service.dart';

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
      final verses = await _bibleService.fetchChapter(_selectedBook!.number, chapter);
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
          onPressed: _selectedBook != null ? _goBack : () => Navigator.pop(context),
        ),
        title: Text(
          _selectedChapter != null
              ? '${_selectedBook!.name} ${_selectedChapter!}'
              : _selectedBook != null
                  ? _selectedBook!.name
                  : 'Bibel',
          style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
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
      subtitle: Text('${book.chapters} Kapitel', style: const TextStyle(fontSize: 12, color: kTextSecondary)),
      trailing: const Icon(Icons.chevron_right, size: 18, color: kTextSecondary),
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
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      itemCount: _verses!.length,
      itemBuilder: (context, i) {
        final verse = _verses![i];
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(fontSize: 17, color: Colors.black, height: 1.6),
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
        );
      },
    );
  }
}
