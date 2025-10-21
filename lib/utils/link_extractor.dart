class LinkExtractor {
  // Extract CamelCase words from text (potential links to other notes)
  // CamelCase pattern: starts with uppercase, contains at least one more uppercase
  static List<String> extractLinks(String text) {
    final Set<String> links = {};

    // Pattern matches CamelCase words: starts with uppercase, has at least one more uppercase
    // e.g., MyNote, CamelCase, ThisIsALink
    final camelCasePattern = RegExp(r'\b[A-Z][a-z]+(?:[A-Z][a-z]+)+\b');

    final matches = camelCasePattern.allMatches(text);
    for (final match in matches) {
      links.add(match.group(0)!);
    }

    return links.toList()..sort();
  }

  // Extract links from all note fields (text + extra fields)
  static List<String> extractAllLinks(String text, Map<String, dynamic> extraFields) {
    final Set<String> allLinks = {};

    // Extract from text
    allLinks.addAll(extractLinks(text));

    // Extract from extra fields (convert to string and extract)
    for (final value in extraFields.values) {
      if (value != null) {
        allLinks.addAll(extractLinks(value.toString()));
      }
    }

    return allLinks.toList()..sort();
  }
}
