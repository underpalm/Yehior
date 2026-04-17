class SavedMessage {
  final String id;
  final String text;
  final String feature;
  final String conversationId;
  final DateTime savedAt;

  // Bible verse location (set when saved from Bible reader)
  final int? bookNumber;
  final String? bookName;
  final int? chapter;
  final int? verseNumber;

  SavedMessage({
    required this.id,
    required this.text,
    required this.feature,
    required this.conversationId,
    required this.savedAt,
    this.bookNumber,
    this.bookName,
    this.chapter,
    this.verseNumber,
  });

  bool get isFromBible => bookNumber != null;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'feature': feature,
        'conversationId': conversationId,
        'savedAt': savedAt.toIso8601String(),
        if (bookNumber != null) 'bookNumber': bookNumber,
        if (bookName != null) 'bookName': bookName,
        if (chapter != null) 'chapter': chapter,
        if (verseNumber != null) 'verseNumber': verseNumber,
      };

  factory SavedMessage.fromJson(Map<String, dynamic> json) => SavedMessage(
        id: json['id'] as String,
        text: json['text'] as String,
        feature: json['feature'] as String,
        conversationId: json['conversationId'] as String? ?? '',
        savedAt: DateTime.parse(json['savedAt'] as String),
        bookNumber: json['bookNumber'] as int?,
        bookName: json['bookName'] as String?,
        chapter: json['chapter'] as int?,
        verseNumber: json['verseNumber'] as int?,
      );
}
