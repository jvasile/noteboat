import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/markdown_link_helper.dart';

/// A widget that renders markdown content with automatic CamelCase and URL linking
class NoteMarkdownViewer extends StatelessWidget {
  final String text;
  final String noteTitle;
  final Function(String noteTitle)? onNoteLinkTap;
  final Function(String tag)? onTagTap;
  final bool selectable;
  final double baseFontSize;

  const NoteMarkdownViewer({
    super.key,
    required this.text,
    required this.noteTitle,
    this.onNoteLinkTap,
    this.onTagTap,
    this.selectable = true,
    this.baseFontSize = 16.0,
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

    // Create custom style sheet with user-specified base font size
    final styleSheet = MarkdownStyleSheet(
      p: TextStyle(fontSize: baseFontSize),
      h1: TextStyle(fontSize: baseFontSize * 2.0, fontWeight: FontWeight.bold),
      h2: TextStyle(fontSize: baseFontSize * 1.5, fontWeight: FontWeight.bold),
      h3: TextStyle(fontSize: baseFontSize * 1.25, fontWeight: FontWeight.bold),
      h4: TextStyle(fontSize: baseFontSize * 1.1, fontWeight: FontWeight.bold),
      h5: TextStyle(fontSize: baseFontSize, fontWeight: FontWeight.bold),
      h6: TextStyle(fontSize: baseFontSize * 0.9, fontWeight: FontWeight.bold),
      code: TextStyle(fontSize: baseFontSize * 0.9, fontFamily: 'monospace'),
      listBullet: TextStyle(fontSize: baseFontSize),
      tableBody: TextStyle(fontSize: baseFontSize),
    );

    return MarkdownBody(
      data: MarkdownLinkHelper.makeLinksClickable(processedText, noteTitle),
      selectable: selectable,
      styleSheet: styleSheet,
      onTapLink: (linkText, href, linkTitle) async {
        if (href != null) {
          // Check if it's a web URL
          if (href.startsWith('http://') || href.startsWith('https://')) {
            final success = await MarkdownLinkHelper.openUrl(href);
            if (!success && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Could not open URL: $href')),
              );
            }
          } else if (href.startsWith('#')) {
            // It's a hashtag link
            final tag = href.substring(1); // Remove the # prefix
            if (onTagTap != null) {
              onTagTap!(tag);
            }
          } else {
            // It's a note link
            if (onNoteLinkTap != null) {
              onNoteLinkTap!(href);
            }
          }
        }
      },
    );
  }
}
