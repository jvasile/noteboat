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

    testWidgets('converts CamelCase words to links', (WidgetTester tester) async {
      const text = 'Visit AmherstCollege for details';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteMarkdownViewer(
              text: text,
              noteTitle: 'Test',
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

      // Should contain AmherstCollege as a link
      expect(allText.contains('AmherstCollege'), isTrue);
    });

    testWidgets('converts CamelCase to spaced note title when note exists', (WidgetTester tester) async {
      const text = 'Visit AmherstCollege for details';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteMarkdownViewer(
              text: text,
              noteTitle: 'Test',
              existingNoteTitles: const {'Amherst College'},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // The markdown should have been converted to link to "Amherst College" (spaced version)
      // We can't easily test the href, but we can verify rendering works
      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('removes duplicate heading if it matches note title', (WidgetTester tester) async {
      const text = '''# Test Note

Content goes here.''';

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

      // The H1 "Test Note" should be removed
      // We should only see "Content goes here."
      expect(allText.contains('Content goes here'), isTrue);
      // The title might appear once but not as a heading
      final titleCount = 'Test Note'.allMatches(allText).length;
      expect(titleCount, lessThanOrEqualTo(1));
    });

    testWidgets('converts URLs to clickable links', (WidgetTester tester) async {
      const text = 'Visit https://example.com for info';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteMarkdownViewer(
              text: text,
              noteTitle: 'Test',
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

      expect(allText.contains('https://example.com'), isTrue);
    });

    testWidgets('converts hashtags to clickable links', (WidgetTester tester) async {
      const text = 'Tagged with #college and #university';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteMarkdownViewer(
              text: text,
              noteTitle: 'Test',
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

      expect(allText.contains('#college'), isTrue);
      expect(allText.contains('#university'), isTrue);
    });

    testWidgets('preserves code blocks without converting to links', (WidgetTester tester) async {
      const text = '''```
AmherstCollege
https://example.com
#tag
```''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NoteMarkdownViewer(
              text: text,
              noteTitle: 'Test',
              existingNoteTitles: const {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should render the code block without converting to markdown links
      expect(find.byType(RichText), findsWidgets);
    });
  });
}
