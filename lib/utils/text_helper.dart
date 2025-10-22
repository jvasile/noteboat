/// Helper functions for text processing
class TextHelper {
  /// Removes the first heading line if it matches the note title
  /// and trims any leading whitespace
  /// This prevents duplicate display of the title
  static String removeDuplicateHeading(String text, String noteTitle) {
    // Check if first non-blank line is "# Title" matching the note title
    final lines = text.split('\n');
    int firstNonBlankIndex = -1;

    for (int i = 0; i < lines.length; i++) {
      if (lines[i].trim().isNotEmpty) {
        firstNonBlankIndex = i;
        break;
      }
    }

    if (firstNonBlankIndex != -1) {
      final firstLine = lines[firstNonBlankIndex].trim();
      // Check if it's a heading that matches the title
      if (firstLine.startsWith('# ')) {
        final headingText = firstLine.substring(2).trim();
        if (headingText == noteTitle) {
          // Remove this line and any leading blank lines
          lines.removeRange(0, firstNonBlankIndex + 1);
          // Trim any remaining leading whitespace
          return lines.join('\n').trimLeft();
        }
      }
    }

    // Even if we didn't remove a heading, trim leading whitespace
    return text.trimLeft();
  }
}
