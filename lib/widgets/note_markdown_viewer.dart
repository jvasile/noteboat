import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../utils/markdown_link_helper.dart';
import '../utils/text_helper.dart';

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

  @override
  Widget build(BuildContext context) {
    var processedText = TextHelper.removeDuplicateHeading(text, noteTitle);

    // Convert to markdown links
    processedText = MarkdownLinkHelper.makeLinksClickable(
      processedText,
      noteTitle,
      existingNoteTitles: existingNoteTitles,
    );

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

    final markdownBody = MarkdownBody(
      data: processedText,
      selectable: false,  // Let SelectionArea handle selection instead
      styleSheet: styleSheet,
      onTapLink: (String text, String? href, String title) {
        if (href == null) return;

        // Determine link type and handle accordingly
        if (href.startsWith('http://') || href.startsWith('https://')) {
          // External URL
          MarkdownLinkHelper.openUrl(href);
        } else if (href.startsWith('#')) {
          // Hashtag
          final tag = href.substring(1);
          onTagTap?.call(tag);
        } else {
          // Note link - decode URL encoding
          String decodedHref;
          try {
            decodedHref = Uri.decodeComponent(href);
          } catch (e) {
            decodedHref = href;
          }
          onNoteLinkTap?.call(decodedHref);
        }
      },
      builders: {
        'a': NoteLinkBuilder(
          existingNoteTitles: existingNoteTitles,
          baseFontSize: baseFontSize,
        ),
      },
    );

    // Wrap in SelectionArea to enable continuous multi-line selection
    if (selectable) {
      return SelectionArea(child: markdownBody);
    } else {
      return markdownBody;
    }
  }
}

/// Custom link builder that styles links based on whether the target note exists
/// Note: Currently returns null to avoid flutter_markdown duplicate rendering bug
/// When returning a custom widget, flutter_markdown incorrectly renders both the
/// widget AND remaining text children when link text is split into multiple nodes
class NoteLinkBuilder extends MarkdownElementBuilder {
  final Set<String> existingNoteTitles;
  final double baseFontSize;

  NoteLinkBuilder({
    required this.existingNoteTitles,
    required this.baseFontSize,
  });

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    // Return null to let flutter_markdown handle rendering
    // This avoids a bug where custom widgets cause duplicate text when
    // link text contains multiple capitalized words (e.g., "Dumbing Of Age")

    // TODO: Find a way to customize link colors (red for non-existent notes)
    // without triggering the duplicate rendering bug

    return null;
  }
}
