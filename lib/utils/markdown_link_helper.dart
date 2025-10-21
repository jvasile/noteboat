import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class MarkdownLinkHelper {
  /// Converts CamelCase to spaced words
  /// Example: "AmherstCollege" -> "Amherst College"
  static String _camelCaseToSpaced(String text) {
    if (text.isEmpty) return text;

    final buffer = StringBuffer();
    buffer.write(text[0]);

    for (int i = 1; i < text.length; i++) {
      if (text[i].toUpperCase() == text[i] && text[i].toLowerCase() != text[i]) {
        // It's an uppercase letter
        buffer.write(' ');
      }
      buffer.write(text[i]);
    }

    return buffer.toString();
  }

  /// Converts CamelCase words, URLs, and hashtags in markdown text to clickable links
  /// Preserves code blocks and existing markdown links
  /// Fixes markdown links with spaces in targets by adding angle brackets
  /// Skips CamelCase words that match the current note title
  /// Uses existingNoteTitles to check if spaced version of CamelCase exists
  static String makeLinksClickable(
    String text,
    String currentNoteTitle, {
    Set<String> existingNoteTitles = const {},
  }) {
    // CamelCase pattern with negative lookbehind to not match if preceded by #
    final camelCasePattern = RegExp(r'(?<!#)\b([A-Z][a-z]+(?:[A-Z][a-z]+)+)\b');
    final urlPattern = RegExp(r'(https?://[^\s\)<]+)');
    final hashtagPattern = RegExp(r'(#\w+)');
    final codeBlockPattern = RegExp(r'```[\s\S]*?```');
    final inlineCodePattern = RegExp(r'`[^`]+`');
    final linkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

    // First pass: fix markdown links with spaces in targets
    String result = text;
    final List<MapEntry<int, MapEntry<String, String>>> linkFixes = [];

    for (final match in linkPattern.allMatches(text)) {
      final displayText = match.group(1)!;
      final target = match.group(2)!;

      // If target contains spaces and isn't already wrapped in angle brackets
      // and isn't a URL, wrap it in angle brackets
      if (target.contains(' ') &&
          !target.startsWith('<') &&
          !target.startsWith('http://') &&
          !target.startsWith('https://')) {
        final originalLink = match.group(0)!;
        final fixedLink = '[$displayText](<$target>)';
        linkFixes.add(MapEntry(
          match.start,
          MapEntry(originalLink, fixedLink),
        ));
      }
    }

    // Apply fixes in reverse order to maintain positions
    linkFixes.sort((a, b) => b.key.compareTo(a.key));
    for (final fix in linkFixes) {
      final start = fix.key;
      final original = fix.value.key;
      final fixed = fix.value.value;
      final end = start + original.length;
      result = result.substring(0, start) + fixed + result.substring(end);
    }

    // Now build skip ranges from the fixed text
    final List<MapEntry<int, int>> skipRanges = [];

    for (final match in codeBlockPattern.allMatches(result)) {
      skipRanges.add(MapEntry(match.start, match.end));
    }

    for (final match in inlineCodePattern.allMatches(result)) {
      skipRanges.add(MapEntry(match.start, match.end));
    }

    for (final match in linkPattern.allMatches(result)) {
      skipRanges.add(MapEntry(match.start, match.end));
    }

    skipRanges.sort((a, b) => a.key.compareTo(b.key));

    bool shouldSkip(int start, int end) {
      for (final range in skipRanges) {
        if ((start >= range.key && start < range.value) ||
            (end > range.key && end <= range.value)) {
          return true;
        }
      }
      return false;
    }

    final List<MapEntry<int, MapEntry<String, String>>> replacements = [];

    for (final match in camelCasePattern.allMatches(result)) {
      if (!shouldSkip(match.start, match.end)) {
        final camelCase = match.group(1)!;
        if (camelCase != currentNoteTitle) {
          // Check if spaced version exists in note titles
          String targetTitle = camelCase;
          if (existingNoteTitles.isNotEmpty) {
            final spacedVersion = _camelCaseToSpaced(camelCase);
            if (existingNoteTitles.contains(spacedVersion)) {
              // Use spaced version if it exists
              targetTitle = spacedVersion;
            }
          }

          // Wrap target in angle brackets if it contains spaces
          final targetHref = targetTitle.contains(' ') ? '<$targetTitle>' : targetTitle;

          replacements.add(MapEntry(
            match.start,
            MapEntry(camelCase, '[$camelCase]($targetHref)'),
          ));
        }
      }
    }

    for (final match in urlPattern.allMatches(result)) {
      if (!shouldSkip(match.start, match.end)) {
        final url = match.group(1)!;
        replacements.add(MapEntry(
          match.start,
          MapEntry(url, '[$url]($url)'),
        ));
      }
    }

    for (final match in hashtagPattern.allMatches(result)) {
      if (!shouldSkip(match.start, match.end)) {
        final hashtag = match.group(1)!;
        replacements.add(MapEntry(
          match.start,
          MapEntry(hashtag, '[$hashtag]($hashtag)'),
        ));
      }
    }

    replacements.sort((a, b) => b.key.compareTo(a.key));

    for (final replacement in replacements) {
      final start = replacement.key;
      final original = replacement.value.key;
      final replaced = replacement.value.value;
      final end = start + original.length;

      result = result.substring(0, start) + replaced + result.substring(end);
    }

    return result;
  }

  /// Opens a URL in the system browser
  /// Returns true if successful, false otherwise
  static Future<bool> openUrl(String url) async {
    // On Linux, use xdg-open directly to avoid GTK issues
    if (Platform.isLinux) {
      try {
        final result = await Process.run('xdg-open', [url]);
        return result.exitCode == 0;
      } catch (e) {
        return false;
      }
    } else {
      // Use url_launcher on other platforms
      try {
        final uri = Uri.parse(url);
        return await launchUrl(uri);
      } catch (e) {
        return false;
      }
    }
  }
}
