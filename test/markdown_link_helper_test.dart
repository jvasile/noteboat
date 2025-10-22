import 'package:flutter_test/flutter_test.dart';
import 'package:noteboat/utils/markdown_link_helper.dart';

void main() {
  group('makeLinksClickable', () {
    test('preserves existing markdown links unchanged', () {
      final input = '[Dumbing Of Age](https://dumbingofage.com)';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      expect(result, equals(input));
    });

    test('preserves markdown links with multiple words in display text', () {
      final input = '[Saturday Morning Breakfast Cereal](https://smbc-comics.com)';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      expect(result, equals(input));
    });

    test('converts CamelCase to markdown links', () {
      final input = 'Check out AmherstCollege for details';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      expect(result, equals('Check out [AmherstCollege](AmherstCollege) for details'));
    });

    test('converts CamelCase to spaced note links when note exists', () {
      final input = 'Check out AmherstCollege for details';
      final existingTitles = {'Amherst College'};
      final result = MarkdownLinkHelper.makeLinksClickable(
        input,
        'Test',
        existingNoteTitles: existingTitles,
      );

      // Should link to spaced version with angle brackets
      expect(result, equals('Check out [AmherstCollege](<Amherst College>) for details'));
    });

    test('skips CamelCase that matches current note title', () {
      final input = 'This is AmherstCollege page';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'AmherstCollege');

      // Should not create self-link
      expect(result, equals(input));
    });

    test('converts URLs to markdown links', () {
      final input = 'Visit https://example.com for more';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      expect(result, equals('Visit [https://example.com](https://example.com) for more'));
    });

    test('converts hashtags to markdown links', () {
      final input = 'Tagged with #college and #admissions';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      expect(result, equals('Tagged with [#college](#college) and [#admissions](#admissions)'));
    });

    test('does not convert hashtags in CamelCase', () {
      final input = 'This is #NotAHashtag because it has CamelCase';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      // Should create hashtag link but not CamelCase link for "NotAHashtag"
      expect(result, contains('[#NotAHashtag](#NotAHashtag)'));
      expect(result, isNot(contains('[NotAHashtag](NotAHashtag)')));
    });

    test('preserves code blocks unchanged', () {
      final input = '```\nSomeCodeHere\nhttps://example.com\n```';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      // Should not create links inside code blocks
      expect(result, equals(input));
    });

    test('preserves inline code unchanged', () {
      final input = 'Use `SomeCodeHere` and `https://example.com` in code';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      // Should not create links inside inline code
      expect(result, equals(input));
    });

    test('does not modify URLs inside existing markdown links', () {
      final input = '[Click here](https://example.com)';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      // Should not double-wrap the URL
      expect(result, equals(input));
    });

    test('wraps note titles with spaces in angle brackets', () {
      final input = '[Amherst College](Amherst College)';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      // Should add angle brackets around target with spaces
      expect(result, equals('[Amherst College](<Amherst College>)'));
    });

    test('handles multiple links in same text', () {
      final input = 'Visit [Site1](https://one.com) and [Site2](https://two.com)';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      // Should preserve both links
      expect(result, contains('[Site1](https://one.com)'));
      expect(result, contains('[Site2](https://two.com)'));
    });

    test('handles mixed content with links, CamelCase, and URLs', () {
      final input = 'Check [Existing](url) and NewNote plus https://example.com';
      final result = MarkdownLinkHelper.makeLinksClickable(input, 'Test');

      expect(result, contains('[Existing](url)'));
      expect(result, contains('[NewNote](NewNote)'));
      expect(result, contains('[https://example.com](https://example.com)'));
    });
  });

  group('openUrl', () {
    test('returns true for valid URL on Linux', () async {
      // This test would require mocking Platform.isLinux and Process.run
      // Skip for now as it requires system interaction
    }, skip: 'Requires system interaction');
  });
}
