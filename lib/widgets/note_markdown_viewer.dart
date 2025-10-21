import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../utils/markdown_link_helper.dart';

/// A widget that renders markdown content with automatic CamelCase and URL linking
class NoteMarkdownViewer extends StatelessWidget {
  final String text;
  final String noteTitle;
  final Function(String noteTitle)? onNoteLinkTap;
  final bool selectable;

  const NoteMarkdownViewer({
    super.key,
    required this.text,
    required this.noteTitle,
    this.onNoteLinkTap,
    this.selectable = true,
  });

  @override
  Widget build(BuildContext context) {
    return MarkdownBody(
      data: MarkdownLinkHelper.makeLinksClickable(text, noteTitle),
      selectable: selectable,
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
