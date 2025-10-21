import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class MarkdownLinkHelper {
  /// Converts CamelCase words and URLs in markdown text to clickable links
  /// Preserves code blocks and existing markdown links
  /// Skips CamelCase words that match the current note title
  static String makeLinksClickable(String text, String currentNoteTitle) {
    final camelCasePattern = RegExp(r'\b([A-Z][a-z]+(?:[A-Z][a-z]+)+)\b');
    final urlPattern = RegExp(r'(https?://[^\s\)<]+)');
    final codeBlockPattern = RegExp(r'```[\s\S]*?```');
    final inlineCodePattern = RegExp(r'`[^`]+`');
    final linkPattern = RegExp(r'\[([^\]]+)\]\(([^)]+)\)');

    final List<MapEntry<int, int>> skipRanges = [];

    for (final match in codeBlockPattern.allMatches(text)) {
      skipRanges.add(MapEntry(match.start, match.end));
    }

    for (final match in inlineCodePattern.allMatches(text)) {
      skipRanges.add(MapEntry(match.start, match.end));
    }

    for (final match in linkPattern.allMatches(text)) {
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

    String result = text;
    final List<MapEntry<int, MapEntry<String, String>>> replacements = [];

    for (final match in camelCasePattern.allMatches(text)) {
      if (!shouldSkip(match.start, match.end)) {
        final camelCase = match.group(1)!;
        if (camelCase != currentNoteTitle) {
          replacements.add(MapEntry(
            match.start,
            MapEntry(camelCase, '[$camelCase]($camelCase)'),
          ));
        }
      }
    }

    for (final match in urlPattern.allMatches(text)) {
      if (!shouldSkip(match.start, match.end)) {
        final url = match.group(1)!;
        replacements.add(MapEntry(
          match.start,
          MapEntry(url, '[$url]($url)'),
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
