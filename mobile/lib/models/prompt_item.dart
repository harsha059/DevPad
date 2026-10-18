import 'dart:convert';

class PromptItem {
  final String id;
  final String title;
  final String content;
  final String category;
  final bool isCustom;

  const PromptItem({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    this.isCustom = false,
  });

  PromptItem copyWith({
    String? id,
    String? title,
    String? content,
    String? category,
    bool? isCustom,
  }) {
    return PromptItem(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      category: category ?? this.category,
      isCustom: isCustom ?? this.isCustom,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'isCustom': isCustom,
    };
  }

  factory PromptItem.fromMap(Map<String, dynamic> map) {
    return PromptItem(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      category: map['category'] as String? ?? 'General',
      isCustom: map['isCustom'] as bool? ?? false,
    );
  }

  String toJson() => json.encode(toMap());

  factory PromptItem.fromJson(String source) =>
      PromptItem.fromMap(json.decode(source) as Map<String, dynamic>);
}

class ContextTag {
  final String label;
  final String tag;
  final String description;

  const ContextTag({
    required this.label,
    required this.tag,
    required this.description,
  });
}
