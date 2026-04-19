import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/bible_books.dart';
import '../constants/theme.dart';
import '../models/reading_plan.dart';
import '../providers/chat_provider.dart';
import 'bible_reader_screen.dart';

class PlanDetailScreen extends StatelessWidget {
  final ReadingPlan plan;

  const PlanDetailScreen({super.key, required this.plan});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final progress = provider.getPlanProgress(plan.id);

    if (progress == null) {
      return Scaffold(
        appBar: AppBar(title: Text(plan.title)),
        body: const Center(child: Text('Plan nicht gestartet.')),
      );
    }

    progress.setTotalDays(plan.totalDays);
    final completed = progress.completedDays.length;
    final percent = completed / plan.totalDays;

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
        title: Text(
          plan.title,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Progress header
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: kSurfaceColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  '${plan.icon}  $completed von ${plan.totalDays} Tagen',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: kTextPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${(percent * 100).toStringAsFixed(0)}% abgeschlossen',
                  style:
                      const TextStyle(fontSize: 13, color: kTextSecondary),
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percent,
                    backgroundColor: kDivider,
                    color: kAccentBlue,
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // Day list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: plan.totalDays,
              itemBuilder: (context, i) {
                final day = i + 1;
                final isDone = progress.completedDays.contains(day);
                final readings = plan.dailyReadings[i];
                final readingLabel = _buildReadingLabel(readings);
                final isToday = day == progress.currentDay;

                return Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  decoration: BoxDecoration(
                    color: isToday ? kPillBlue : null,
                    borderRadius: BorderRadius.circular(12),
                    border: isToday
                        ? Border.all(color: kAccentBlue, width: 1.5)
                        : null,
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12),
                    leading: GestureDetector(
                      onTap: () =>
                          provider.togglePlanDay(plan.id, day, plan.totalDays),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isDone ? kAccentBlue : Colors.transparent,
                          shape: BoxShape.circle,
                          border: isDone
                              ? null
                              : Border.all(color: kDivider, width: 2),
                        ),
                        child: isDone
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    ),
                    title: Text(
                      'Tag $day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isToday ? FontWeight.w600 : FontWeight.normal,
                        color: isDone ? kTextSecondary : kTextPrimary,
                        decoration:
                            isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    subtitle: Text(
                      readingLabel,
                      style: const TextStyle(
                          fontSize: 12, color: kTextSecondary),
                    ),
                    trailing: isToday
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: kAccentBlue,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'HEUTE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.chevron_right,
                            size: 18, color: kTextSecondary),
                    onTap: () => _openReading(context, readings),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _buildReadingLabel(List<PlanReading> readings) {
    if (readings.isEmpty) return '';
    if (readings.length == 1) {
      final r = readings.first;
      return '${r.bookName} ${r.chapter}';
    }

    // Group consecutive chapters in the same book
    final parts = <String>[];
    var i = 0;
    while (i < readings.length) {
      final startReading = readings[i];
      var end = i;
      while (end + 1 < readings.length &&
          readings[end + 1].bookNumber == startReading.bookNumber &&
          readings[end + 1].chapter == readings[end].chapter + 1) {
        end++;
      }
      if (end == i) {
        parts.add('${startReading.bookName} ${startReading.chapter}');
      } else {
        parts.add(
            '${startReading.bookName} ${startReading.chapter}–${readings[end].chapter}');
      }
      i = end + 1;
    }
    return parts.join(', ');
  }

  void _openReading(BuildContext context, List<PlanReading> readings) {
    if (readings.isEmpty) return;
    final first = readings.first;
    final book =
        kAllBooks.where((b) => b.number == first.bookNumber).firstOrNull;
    if (book == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BibleReaderScreen(
          initialBook: book,
          initialChapter: first.chapter,
        ),
      ),
    );
  }
}
