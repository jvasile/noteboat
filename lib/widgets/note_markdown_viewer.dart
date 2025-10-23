import 'package:flutter/material.dart';
import 'package:markdown_widget/markdown_widget.dart';
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

    // Create custom link generator that colors links based on whether note exists
    final linkGenerator = _CustomLinkGenerator(
      existingNoteTitles: existingNoteTitles,
      onNoteLinkTap: onNoteLinkTap,
      onTagTap: onTagTap,
      baseFontSize: baseFontSize,
    );

    // Configure markdown rendering with custom typography
    final config = MarkdownConfig(
      configs: [
        // Headings with clear visual hierarchy
        H1Config(
          style: TextStyle(
            fontSize: baseFontSize * 2.5,
            fontWeight: FontWeight.w900,
            height: 1.3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        H2Config(
          style: TextStyle(
            fontSize: baseFontSize * 2.0,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        H3Config(
          style: TextStyle(
            fontSize: baseFontSize * 1.5,
            fontWeight: FontWeight.w700,
            height: 1.3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        H4Config(
          style: TextStyle(
            fontSize: baseFontSize * 1.25,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        H5Config(
          style: TextStyle(
            fontSize: baseFontSize * 1.1,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        H6Config(
          style: TextStyle(
            fontSize: baseFontSize,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        PConfig(
          textStyle: TextStyle(fontSize: baseFontSize),
        ),
        CodeConfig(
          style: TextStyle(fontSize: baseFontSize * 0.9),
        ),
      ],
    );

    final markdownGenerator = MarkdownGenerator(
      generators: [
        SpanNodeGeneratorWithTag(
          tag: 'a',
          generator: linkGenerator.generateLinkNode,
        ),
      ],
    );

    final markdownWidget = MarkdownWidget(
      data: processedText,
      config: config,
      markdownGenerator: markdownGenerator,
      shrinkWrap: true,
      selectable: false,  // Let SelectionArea handle selection
      padding: EdgeInsets.zero,
    );

    // Wrap in SelectionArea to enable continuous multi-line selection
    if (selectable) {
      return SelectionArea(child: markdownWidget);
    } else {
      return markdownWidget;
    }
  }
}

/// Custom link generator that styles links based on whether the target note exists
/// Uses markdown_widget's SpanNodeGenerator to provide per-link color customization
class _CustomLinkGenerator {
  final Set<String> existingNoteTitles;
  final Function(String noteTitle)? onNoteLinkTap;
  final Function(String tag)? onTagTap;
  final double baseFontSize;

  _CustomLinkGenerator({
    required this.existingNoteTitles,
    this.onNoteLinkTap,
    this.onTagTap,
    required this.baseFontSize,
  });

  SpanNode generateLinkNode(md.Element element, MarkdownConfig config, WidgetVisitor visitor) {
    // Extract href from the link element
    final href = element.attributes['href'] ?? '';

    // Determine link color based on type
    Color linkColor;
    VoidCallback? onTap;

    if (href.startsWith('http://') || href.startsWith('https://')) {
      // External URL - blue
      linkColor = const Color(0xff0969da);
      onTap = () => MarkdownLinkHelper.openUrl(href);
    } else if (href.startsWith('#')) {
      // Hashtag - blue
      linkColor = const Color(0xff0969da);
      final tag = href.substring(1);
      onTap = () => onTagTap?.call(tag);
    } else {
      // Note link - check if it exists
      String decodedHref;
      try {
        decodedHref = Uri.decodeComponent(href);
      } catch (e) {
        decodedHref = href;
      }

      // Red for non-existent notes, blue for existing notes
      final noteExists = existingNoteTitles.contains(decodedHref);
      linkColor = noteExists ? const Color(0xff0969da) : Colors.red;
      onTap = () => onNoteLinkTap?.call(decodedHref);
    }

    // Create a custom LinkConfig with the determined color
    final customLinkConfig = LinkConfig(
      style: TextStyle(
        color: linkColor,
        decoration: TextDecoration.underline,
        fontSize: baseFontSize,
      ),
      onTap: (_) {
        onTap?.call();
      },
    );

    // Return a LinkNode with the custom config
    return LinkNode(element.attributes, customLinkConfig);
  }
}
