import '../models/reading_plan.dart';
import 'bible_books.dart';

/// Generates daily readings by distributing chapters across days.
List<List<PlanReading>> _distribute(List<BibleBook> books, int days) {
  // Collect all chapters
  final allChapters = <PlanReading>[];
  for (final book in books) {
    for (var ch = 1; ch <= book.chapters; ch++) {
      allChapters.add(PlanReading(
        bookNumber: book.number,
        bookName: book.name,
        chapter: ch,
      ));
    }
  }

  final daily = <List<PlanReading>>[];
  final perDay = allChapters.length / days;
  var index = 0.0;

  for (var d = 0; d < days; d++) {
    final start = index.round();
    index += perDay;
    final end = index.round().clamp(start + 1, allChapters.length);
    daily.add(allChapters.sublist(start, end));
  }

  return daily;
}

final List<ReadingPlan> kReadingPlans = [
  ReadingPlan(
    id: 'bible_1_year',
    title: 'Bibel in einem Jahr',
    description: 'Die ganze Bibel — Altes und Neues Testament — in 365 Tagen.',
    icon: '📖',
    totalDays: 365,
    dailyReadings: _distribute(kAllBooks, 365),
  ),
  ReadingPlan(
    id: 'nt_30_days',
    title: 'Neues Testament in 30 Tagen',
    description: 'Alle 27 Bücher des Neuen Testaments in einem Monat.',
    icon: '✝️',
    totalDays: 30,
    dailyReadings: _distribute(kNewTestament, 30),
  ),
  ReadingPlan(
    id: 'psalms_31',
    title: 'Psalmen in 31 Tagen',
    description: 'Alle 150 Psalmen — ein Monat voller Lobpreis und Gebet.',
    icon: '🎵',
    totalDays: 31,
    dailyReadings: _distribute(
      [const BibleBook(number: 19, name: 'Psalmen', chapters: 150)],
      31,
    ),
  ),
  ReadingPlan(
    id: 'gospels_14',
    title: 'Die Evangelien in 14 Tagen',
    description: 'Matthäus, Markus, Lukas und Johannes — das Leben Jesu.',
    icon: '🕊️',
    totalDays: 14,
    dailyReadings: _distribute([
      const BibleBook(number: 40, name: 'Matthäus', chapters: 28),
      const BibleBook(number: 41, name: 'Markus', chapters: 16),
      const BibleBook(number: 42, name: 'Lukas', chapters: 24),
      const BibleBook(number: 43, name: 'Johannes', chapters: 21),
    ], 14),
  ),
  ReadingPlan(
    id: 'proverbs_31',
    title: 'Sprüche in 31 Tagen',
    description: 'Ein Kapitel Weisheit pro Tag — für jeden Tag im Monat.',
    icon: '💡',
    totalDays: 31,
    dailyReadings: _distribute(
      [const BibleBook(number: 20, name: 'Sprüche', chapters: 31)],
      31,
    ),
  ),
];
