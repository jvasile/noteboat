import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:noteboat/widgets/note_markdown_viewer.dart';

// Helper to extract all text from a TextSpan tree
String _extractText(InlineSpan span) {
  final buffer = StringBuffer();
  if (span is TextSpan) {
    if (span.text != null) {
      buffer.write(span.text);
    }
    if (span.children != null) {
      for (final child in span.children!) {
        buffer.write(_extractText(child));
      }
    }
  }
  return buffer.toString();
}

void main() {
  group('NoteMarkdownViewer rendering', () {
    testWidgets('renders links with multiple words without duplication', (WidgetTester tester) async {
      // This test ensures we don't regress on the duplicate text bug
      // where "[Dumbing Of Age](url)" was rendering as "Dumbing Of AgeOf Age"

      const text = '''
 * [Dumbing Of Age](https://dumbingofage.com)
 * [Saturday Morning Breakfast Cereal](https://smbc-comics.com)
 * [Between Failures](https://betweenfailures.com)
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteMarkdownViewer(
              text: text,
              noteTitle: 'Test Note',
              existingNoteTitles: const {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Get all rendered text
      final richTextFinder = find.byType(RichText);
      final richTexts = tester.widgetList<RichText>(richTextFinder);

      String allText = '';
      for (final richText in richTexts) {
        final textSpan = richText.text as TextSpan;
        allText += _extractText(textSpan);
      }

      // Each link text should appear exactly once, not duplicated
      expect('Dumbing Of Age'.allMatches(allText).length, equals(1),
          reason: 'Dumbing Of Age should appear once, found in: $allText');
      expect('Saturday Morning Breakfast Cereal'.allMatches(allText).length, equals(1),
          reason: 'Saturday Morning Breakfast Cereal should appear once, found in: $allText');
      expect('Between Failures'.allMatches(allText).length, equals(1),
          reason: 'Between Failures should appear once, found in: $allText');

      // Check that duplicate fragments don't exist
      // If the bug exists, we'd see "Dumbing Of AgeOf Age"
      expect(allText.contains('AgeOf Age'), isFalse,
          reason: 'Should not have duplicate "Of Age" fragment');
      expect(allText.contains('CerealMorning Breakfast Cereal'), isFalse,
          reason: 'Should not have duplicate fragment');
    });

    testWidgets('renders markdown links with special characters without duplication', (WidgetTester tester) async {
      // Regression test: ensure links with parentheses, dashes, etc work
      const text = '''
 * [Site (with parens)](https://example.com)
 * [Site-with-dashes](https://example.com)
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteMarkdownViewer(
              text: text,
              noteTitle: 'Test Note',
              existingNoteTitles: const {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final richTexts = tester.widgetList<RichText>(find.byType(RichText));
      String allText = '';
      for (final richText in richTexts) {
        allText += _extractText(richText.text as TextSpan);
      }

      expect('Site (with parens)'.allMatches(allText).length, equals(1));
      expect('Site-with-dashes'.allMatches(allText).length, equals(1));
    });
  });
}
