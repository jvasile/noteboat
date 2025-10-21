class LinkExtractor {
  // Extract CamelCase words and markdown links from text (potential links to other notes)
  // CamelCase pattern: starts with uppercase, contains at least one more uppercase
  // Markdown pattern: [display text](target)
  static List<String> extractLinks(String text, {String? excludeTitle}) {
    final Set<String> links = {};

    // Pattern matches CamelCase words: starts with uppercase, has at least one more uppercase
    // e.g., MyNote, CamelCase, ThisIsALink
    final camelCasePattern = RegExp(r'\b[A-Z][a-z]+(?:[A-Z][a-z]+)+\b');

    // Pattern matches markdown links: [text](target)
    final markdownLinkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

    // Extract CamelCase links
    final camelCaseMatches = camelCasePattern.allMatches(text);
    for (final match in camelCaseMatches) {
      final link = match.group(0)!;
      // Exclude links to the note itself
      if (excludeTitle == null || link != excludeTitle) {
        links.add(link);
      }
    }

    // Extract markdown link targets
    final markdownMatches = markdownLinkPattern.allMatches(text);
    for (final match in markdownMatches) {
      final target = match.group(2)!; // The part in parentheses

      // Skip URLs (http/https) and hashtags
      if (!target.startsWith('http://') &&
          !target.startsWith('https://') &&
          !target.startsWith('#')) {
        // Remove query string if present (e.g., "Title?id=xxx" -> "Title")
        final cleanTarget = target.split('?').first;

        // Exclude links to the note itself
        if (excludeTitle == null || cleanTarget != excludeTitle) {
          links.add(cleanTarget);
        }
      }
    }

    return links.toList()..sort();
  }

  // Extract links from all note fields (text + extra fields)
  static List<String> extractAllLinks(String text, Map<String, dynamic> extraFields, {String? excludeTitle}) {
    final Set<String> allLinks = {};

    // Extract from text
    allLinks.addAll(extractLinks(text, excludeTitle: excludeTitle));

    // Extract from extra fields (convert to string and extract)
    for (final value in extraFields.values) {
      if (value != null) {
        allLinks.addAll(extractLinks(value.toString(), excludeTitle: excludeTitle));
      }
    }

    return allLinks.toList()..sort();
  }
}
