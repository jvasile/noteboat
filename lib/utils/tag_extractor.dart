class TagExtractor {
  // Extract tags from text (words starting with #)
  static List<String> extractTags(String text) {
    final Set<String> tags = {};

    // Pattern matches hashtags: # followed by word characters
    final tagPattern = RegExp(r'#(\w+)');

    final matches = tagPattern.allMatches(text);
    for (final match in matches) {
      tags.add(match.group(1)!); // Group 1 is the tag without #
    }

    return tags.toList()..sort();
  }

  // Extract tags from all note fields (text + extra fields)
  static List<String> extractAllTags(String text, Map<String, dynamic> extraFields) {
    final Set<String> allTags = {};

    // Extract from text
    allTags.addAll(extractTags(text));

    // Extract from extra fields (convert to string and extract)
    for (final value in extraFields.values) {
      if (value != null) {
        allTags.addAll(extractTags(value.toString()));
      }
    }

    return allTags.toList()..sort();
  }
}
