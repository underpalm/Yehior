class Conversation {
  final String id;
  final String title;
  final String feature;
  final List<Map<String, dynamic>> messages;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.title,
    required this.feature,
    required this.messages,
    required this.updatedAt,
  });

  Conversation copyWith({
    String? title,
    List<Map<String, dynamic>>? messages,
    DateTime? updatedAt,
  }) =>
      Conversation(
        id: id,
        title: title ?? this.title,
        feature: feature,
        messages: messages ?? this.messages,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'feature': feature,
        'messages': messages,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Conversation.fromJson(Map<String, dynamic> json) => Conversation(
        id: json['id'] as String,
        title: json['title'] as String,
        feature: json['feature'] as String? ?? 'Seelsorge',
        messages: List<Map<String, dynamic>>.from(json['messages'] as List),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}
