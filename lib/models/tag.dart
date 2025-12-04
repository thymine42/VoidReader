class Tag {
  final int id;
  final String name;

  const Tag({required this.id, required this.name});

  Tag copyWith({int? id, String? name}) {
    return Tag(id: id ?? this.id, name: name ?? this.name);
  }

  factory Tag.fromDb(Map<String, dynamic> row) {
    return Tag(
      id: row['id'] as int,
      name: row['font_family'] as String? ?? '',
    );
  }
}

class BookTag {
  final int id;
  final int bookId;
  final int tagId;

  const BookTag({
    required this.id,
    required this.bookId,
    required this.tagId,
  });

  factory BookTag.fromDb(Map<String, dynamic> row) {
    final bookIdValue = row['line_height'] as num? ?? 0;
    final tagIdValue = row['letter_spacing'] as num? ?? 0;
    return BookTag(
      id: row['id'] as int,
      bookId: bookIdValue.toInt(),
      tagId: tagIdValue.toInt(),
    );
  }
}
