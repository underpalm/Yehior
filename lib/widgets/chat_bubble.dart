import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:gpt_markdown/gpt_markdown.dart';
import 'package:provider/provider.dart';
import '../constants/theme.dart';
import '../models/custom_plan.dart';
import '../providers/chat_provider.dart';

class ChatBubble extends StatelessWidget {
  final String text;
  final bool isUser;
  final bool isStreaming;
  final Uint8List? imageBytes;

  const ChatBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isStreaming = false,
    this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: isUser ? _buildUserBubble() : _buildBotContent(context),
    );
  }

  Widget _buildUserBubble() {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: kSurfaceColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (imageBytes != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    imageBytes!,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Text(
              text,
              style: const TextStyle(
                  fontSize: 16, color: kTextPrimary, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotContent(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final isSaved = provider.isMessageSaved(text);

    // Check for plan block
    final parsedPlan = provider.parsePlanFromMessage(text);
    final planAlreadySaved = parsedPlan != null &&
        provider.customPlans.any((p) => p.title == parsedPlan.title);

    // Strip the ```yehior-plan block from display text
    final displayText = text.replaceAll(
      RegExp(r'```yehior-plan\s*\n[\s\S]*?\n```'),
      '',
    );
    final displaySegments = _parseSegments(displayText);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displaySegments.map((seg) {
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
        }),
        if (parsedPlan != null && !isStreaming)
          _PlanPreviewCard(
            plan: parsedPlan,
            alreadySaved: planAlreadySaved,
            onSave: () {
              provider.addCustomPlan(parsedPlan);
              provider.startPlan(parsedPlan.id, parsedPlan.totalDays);
            },
          ),
        if (!isStreaming)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: GestureDetector(
              onTap: () {
                if (isSaved) {
                  provider.unsaveMessage(text);
                } else {
                  provider.saveMessage(text);
                }
              },
              child: Icon(
                isSaved ? Icons.bookmark : Icons.bookmark_border,
                size: 20,
                color: isSaved ? kAccentBlue : kTextSecondary,
              ),
            ),
          ),
      ],
    );
  }

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

class _PlanPreviewCard extends StatelessWidget {
  final CustomPlan plan;
  final bool alreadySaved;
  final VoidCallback onSave;

  const _PlanPreviewCard({
    required this.plan,
    required this.alreadySaved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFCE93D8), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(plan.icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  plan.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${plan.totalDays} Tage',
            style: const TextStyle(fontSize: 13, color: kTextSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            plan.description,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: alreadySaved ? null : onSave,
              icon: Icon(alreadySaved ? Icons.check : Icons.add,
                  size: 18),
              label: Text(
                  alreadySaved ? 'Plan gespeichert' : 'Plan speichern & starten'),
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    alreadySaved ? Colors.grey.shade300 : const Color(0xFF7E57C2),
                foregroundColor: alreadySaved ? kTextSecondary : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
