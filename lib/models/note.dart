class Note {
  final String id; // @id (GUID)
  final String title; // One word, CamelCase
  final String text; // Markdown content
  final DateTime mtime; // Modification time
  final String author;
  final List<String> types; // @type - hierarchical type list
  final List<String> links; // _links - derived field
  final List<String> tags; // _tags - derived field
  final Map<String, dynamic> extraFields; // For extensible types

  Note({
    required this.id,
    required this.title,
    required this.text,
    required this.mtime,
    this.author = '',
    List<String>? types,
    List<String>? links,
    List<String>? tags,
    Map<String, dynamic>? extraFields,
  })  : types = types ?? ['note'],
        links = links ?? [],
        tags = tags ?? [],
        extraFields = extraFields ?? {};

  // Convert from Map (YAML frontmatter)
  factory Note.fromMap(Map<String, dynamic> map, String bodyText) {
    return Note(
      id: map['@id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      text: bodyText,
      mtime: map['mtime'] != null
          ? DateTime.parse(map['mtime'].toString())
          : DateTime.now(),
      author: map['author']?.toString() ?? '',
      types: (map['@type'] as List?)?.map((e) => e.toString()).toList() ?? ['note'],
      links: (map['_links'] as List?)?.map((e) => e.toString()).toList() ?? [],
      tags: (map['_tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
      extraFields: Map<String, dynamic>.from(map)
        ..remove('@id')
        ..remove('title')
        ..remove('mtime')
        ..remove('author')
        ..remove('@type')
        ..remove('_links')
        ..remove('_tags'),
    );
  }

  // Convert to Map (YAML frontmatter)
  Map<String, dynamic> toMap() {
    return {
      '@id': id,
      'title': title,
      'mtime': mtime.toIso8601String(),
      'author': author,
      '@type': types,
      '_links': links,
      '_tags': tags,
      ...extraFields,
    };
  }

  // Create copy with updated fields
  Note copyWith({
    String? id,
    String? title,
    String? text,
    DateTime? mtime,
    String? author,
    List<String>? types,
    List<String>? links,
    List<String>? tags,
    Map<String, dynamic>? extraFields,
  }) {
    return Note(
      id: id ?? this.id,
      title: title ?? this.title,
      text: text ?? this.text,
      mtime: mtime ?? this.mtime,
      author: author ?? this.author,
      types: types ?? this.types,
      links: links ?? this.links,
      tags: tags ?? this.tags,
      extraFields: extraFields ?? this.extraFields,
    );
  }

  @override
  String toString() {
    return 'Note(id: $id, title: $title, mtime: $mtime)';
  }
}
