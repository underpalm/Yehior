class BibleHighlight {
  final String id;
  final int bookNumber;
  final String bookName;
  final int chapter;
  final int verseNumber;
  final String text;
  final int colorValue;
  final DateTime createdAt;

  BibleHighlight({
    required this.id,
    required this.bookNumber,
    required this.bookName,
    required this.chapter,
    required this.verseNumber,
    required this.text,
    required this.colorValue,
    required this.createdAt,
  });

  String get reference => '$bookName $chapter,$verseNumber';

  Map<String, dynamic> toJson() => {
        'id': id,
        'bookNumber': bookNumber,
        'bookName': bookName,
        'chapter': chapter,
        'verseNumber': verseNumber,
        'text': text,
        'colorValue': colorValue,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BibleHighlight.fromJson(Map<String, dynamic> json) => BibleHighlight(
        id: json['id'] as String,
        bookNumber: json['bookNumber'] as int,
        bookName: json['bookName'] as String,
        chapter: json['chapter'] as int,
        verseNumber: json['verseNumber'] as int,
        text: json['text'] as String,
        colorValue: json['colorValue'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
