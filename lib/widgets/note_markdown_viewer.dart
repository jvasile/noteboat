import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../utils/markdown_link_helper.dart';

/// A widget that renders markdown content with automatic CamelCase and URL linking
class NoteMarkdownViewer extends StatelessWidget {
  final String text;
  final String noteTitle;
  final Function(String noteTitle)? onNoteLinkTap;
  final Function(String tag)? onTagTap;
  final bool selectable;
  final double baseFontSize;
  final Set<String> existingNoteTitles;

  const NoteMarkdownViewer({
    super.key,
    required this.text,
    required this.noteTitle,
    this.onNoteLinkTap,
    this.onTagTap,
    this.selectable = true,
    this.baseFontSize = 16.0,
    this.existingNoteTitles = const {},
  });

  String _processText(String text, String noteTitle) {
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
          // Remove this line
          lines.removeAt(firstNonBlankIndex);
          text = lines.join('\n');
        }
      }
    }

    return text;
  }

  @override
  Widget build(BuildContext context) {
    final processedText = _processText(text, noteTitle);

    // Start with theme-based stylesheet and customize with user font size
    final baseStyleSheet = MarkdownStyleSheet.fromTheme(Theme.of(context));
    final styleSheet = baseStyleSheet.copyWith(
      // Paragraph text
      p: baseStyleSheet.p?.copyWith(fontSize: baseFontSize) ?? TextStyle(fontSize: baseFontSize),

      // Headings with clear visual hierarchy
      h1: TextStyle(
        fontSize: baseFontSize * 2.5,
        fontWeight: FontWeight.w900,
        height: 1.3,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      h1Padding: const EdgeInsets.only(top: 24, bottom: 12),

      h2: TextStyle(
        fontSize: baseFontSize * 2.0,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      h2Padding: const EdgeInsets.only(top: 20, bottom: 10),

      h3: TextStyle(
        fontSize: baseFontSize * 1.5,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      h3Padding: const EdgeInsets.only(top: 16, bottom: 8),

      h4: TextStyle(
        fontSize: baseFontSize * 1.25,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      h4Padding: const EdgeInsets.only(top: 14, bottom: 6),

      h5: TextStyle(
        fontSize: baseFontSize * 1.1,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      h5Padding: const EdgeInsets.only(top: 12, bottom: 4),

      h6: TextStyle(
        fontSize: baseFontSize,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      h6Padding: const EdgeInsets.only(top: 12, bottom: 4),

      // Other elements
      code: baseStyleSheet.code?.copyWith(
        fontSize: baseFontSize * 0.9,
      ),
      listBullet: baseStyleSheet.listBullet?.copyWith(fontSize: baseFontSize),
      tableBody: baseStyleSheet.tableBody?.copyWith(fontSize: baseFontSize),
    );

    return MarkdownBody(
      data: MarkdownLinkHelper.makeLinksClickable(
        processedText,
        noteTitle,
        existingNoteTitles: existingNoteTitles,
      ),
      selectable: selectable,
      styleSheet: styleSheet,
      builders: {
        'a': NoteLinkBuilder(
          existingNoteTitles: existingNoteTitles,
          baseFontSize: baseFontSize,
          onNoteLinkTap: onNoteLinkTap,
          onTagTap: onTagTap,
        ),
      },
    );
  }
}

/// Custom link builder that styles links based on whether the target note exists
class NoteLinkBuilder extends MarkdownElementBuilder {
  final Set<String> existingNoteTitles;
  final double baseFontSize;
  final Function(String)? onNoteLinkTap;
  final Function(String)? onTagTap;

  NoteLinkBuilder({
    required this.existingNoteTitles,
    required this.baseFontSize,
    this.onNoteLinkTap,
    this.onTagTap,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final String href = element.attributes['href'] ?? '';
    final String text = element.textContent;

    // Determine if this is a URL, hashtag, or note link
    bool isUrl = href.startsWith('http://') || href.startsWith('https://');
    bool isHashtag = href.startsWith('#');

    Color linkColor;
    void Function()? onTap;

    if (isUrl) {
      // External URL - blue
      linkColor = Colors.blue;
      onTap = () async {
        await MarkdownLinkHelper.openUrl(href);
      };
    } else if (isHashtag) {
      // Hashtag - blue
      linkColor = Colors.blue;
      onTap = () {
        final tag = href.substring(1);
        onTagTap?.call(tag);
      };
    } else {
      // Note link - URL decode it first (markdown renderer encodes spaces as %20)
      String decodedHref;
      try {
        decodedHref = Uri.decodeComponent(href);
      } catch (e) {
        // If decoding fails, use original
        decodedHref = href;
      }

      // Extract the actual note title (strip query params)
      final cleanHref = decodedHref.split('?').first;
      final noteExists = existingNoteTitles.contains(cleanHref);

      linkColor = noteExists ? Colors.blue : Colors.red;
      onTap = () {
        onNoteLinkTap?.call(decodedHref);
      };
    }

    return RichText(
      text: TextSpan(
        text: text,
        style: (preferredStyle ?? TextStyle(fontSize: baseFontSize)).copyWith(
          color: linkColor,
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()..onTap = onTap,
      ),
    );
  }
}
