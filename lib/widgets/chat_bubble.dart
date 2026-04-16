import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import '../constants/theme.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isStreaming;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            const CircleAvatar(
              radius: 14,
              backgroundColor: kPillBlue,
              child: Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
            ),
          const SizedBox(width: 12),
          Expanded(child: _buildContent()),
          if (isUser) const SizedBox(width: 12),
          if (isUser)
            const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blueGrey,
              child: Text('N',
                  style: TextStyle(color: Colors.white, fontSize: 10)),
            ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (isUser) {
      return Text(
        text,
        style: const TextStyle(fontSize: 16, color: kTextPrimary, height: 1.5),
      );
    }

    // Parse text into normal text and blockquote (verse) segments
    final segments = _parseSegments(text);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: segments.map((seg) {
        if (seg.isQuote) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: _VerseQuoteCard(text: seg.text),
          );
        }
        return GptMarkdown(
          seg.text,
          style: const TextStyle(
            fontSize: 16,
            color: Colors.black87,
            height: 1.6,
          ),
        );
      }).toList(),
    );
  }

  /// Splits text into alternating normal and blockquote segments.
  /// Lines starting with `> ` are blockquote lines.
  static List<_Segment> _parseSegments(String text) {
    final lines = text.split('\n');
    final segments = <_Segment>[];
    final buffer = StringBuffer();
    var inQuote = false;

    void flush() {
      final content = buffer.toString().trim();
      if (content.isNotEmpty) {
        segments.add(_Segment(text: content, isQuote: inQuote));
      }
      buffer.clear();
    }

    for (final line in lines) {
      final isQuoteLine = line.startsWith('> ') || line == '>';
      if (isQuoteLine != inQuote) {
        flush();
        inQuote = isQuoteLine;
      }
      if (isQuoteLine) {
        // Strip the `> ` prefix
        buffer.writeln(line.length > 2 ? line.substring(2) : '');
      } else {
        buffer.writeln(line);
      }
    }
    flush();

    return segments;
  }
}

class _Segment {
  final String text;
  final bool isQuote;
  const _Segment({required this.text, required this.isQuote});
}

/// Blue verse card — same style as the VerseCard on the home screen.
class _VerseQuoteCard extends StatelessWidget {
  final String text;

  const _VerseQuoteCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F0FE),
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: kAccentBlue, width: 4),
        ),
      ),
      child: Text(
        text.trim(),
        style: const TextStyle(
          fontSize: 16,
          fontStyle: FontStyle.italic,
          color: Colors.black87,
          height: 1.6,
        ),
      ),
    );
  }
}
