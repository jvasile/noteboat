import 'package:flutter_test/flutter_test.dart';
import 'package:noteboat/utils/link_extractor.dart';

void main() {
  group('LinkExtractor.extractLinks', () {
    test('extracts CamelCase links', () {
      final text = 'Visit AmherstCollege and SmithCollege for info';
      final links = LinkExtractor.extractLinks(text);

      expect(links, containsAll(['AmherstCollege', 'SmithCollege']));
      expect(links.length, equals(2));
    });

    test('extracts markdown note links', () {
      final text = 'See [Amherst College](Amherst College) and [Smith College](Smith College)';
      final links = LinkExtractor.extractLinks(text);

      expect(links, containsAll(['Amherst College', 'Smith College']));
      expect(links.length, equals(2));
    });

    test('ignores markdown links to URLs', () {
      final text = 'Visit [Google](https://google.com) and [Example](http://example.com)';
      final links = LinkExtractor.extractLinks(text);

      expect(links, isEmpty);
    });

    test('ignores markdown links to hashtags', () {
      final text = 'Tagged [college](#college) and [admissions](#admissions)';
      final links = LinkExtractor.extractLinks(text);

      expect(links, isEmpty);
    });

    test('strips query params from markdown links', () {
      final text = 'See [Title](Title?id=123)';
      final links = LinkExtractor.extractLinks(text);

      expect(links, equals(['Title']));
    });

    test('excludes self-references in CamelCase', () {
      final text = 'This AmherstCollege page links to SmithCollege';
      final links = LinkExtractor.extractLinks(text, excludeTitle: 'AmherstCollege');

      expect(links, equals(['SmithCollege']));
      expect(links, isNot(contains('AmherstCollege')));
    });

    test('excludes self-references in markdown links', () {
      final text = 'See [Current Note](Current Note) and [Other Note](Other Note)';
      final links = LinkExtractor.extractLinks(text, excludeTitle: 'Current Note');

      expect(links, equals(['Other Note']));
      expect(links, isNot(contains('Current Note')));
    });

    test('returns sorted links', () {
      final text = 'Links: ZebraNote, AppleNote, MangoNote';
      final links = LinkExtractor.extractLinks(text);

      expect(links, equals(['AppleNote', 'MangoNote', 'ZebraNote']));
    });

    test('removes duplicates', () {
      final text = 'Visit AmherstCollege and AmherstCollege again';
      final links = LinkExtractor.extractLinks(text);

      expect(links, equals(['AmherstCollege']));
    });

    test('handles mixed CamelCase and markdown links', () {
      final text = 'See AmherstCollege and [Smith College](Smith College)';
      final links = LinkExtractor.extractLinks(text);

      expect(links, containsAll(['AmherstCollege', 'Smith College']));
      expect(links.length, equals(2));
    });

    test('handles angle bracket wrapped targets', () {
      final text = 'See [Amherst College](<Amherst College>)';
      final links = LinkExtractor.extractLinks(text);

      // Should extract "Amherst College" with angle brackets
      expect(links, contains('<Amherst College>'));
    });

    test('returns empty list for text with no links', () {
      final text = 'This is just plain text with no links';
      final links = LinkExtractor.extractLinks(text);

      expect(links, isEmpty);
    });

    test('ignores single-word capitalized words', () {
      final text = 'Visit College and University for details';
      final links = LinkExtractor.extractLinks(text);

      // Single capitalized words are not CamelCase
      expect(links, isEmpty);
    });

    test('extracts links from multiple lines', () {
      final text = '''Line 1 has AmherstCollege
Line 2 has [Smith College](Smith College)
Line 3 has WilliamsCollege''';
      final links = LinkExtractor.extractLinks(text);

      expect(links, containsAll(['AmherstCollege', 'Smith College', 'WilliamsCollege']));
      expect(links.length, equals(3));
    });
  });

  group('LinkExtractor.extractAllLinks', () {
    test('extracts links from text and extra fields', () {
      final text = 'Main text has AmherstCollege';
      final extraFields = {
        'notes': 'Extra field has SmithCollege',
        'other': 'Another field has WilliamsCollege',
      };
      final links = LinkExtractor.extractAllLinks(text, extraFields);

      expect(links, containsAll(['AmherstCollege', 'SmithCollege', 'WilliamsCollege']));
      expect(links.length, equals(3));
    });

    test('ignores non-string extra fields', () {
      final text = 'Main text has AmherstCollege';
      final extraFields = {
        'number': 123,
        'bool': true,
        'list': ['item1', 'item2'],
      };
      final links = LinkExtractor.extractAllLinks(text, extraFields);

      expect(links, equals(['AmherstCollege']));
    });

    test('combines and deduplicates links from all sources', () {
      final text = 'Main has AmherstCollege';
      final extraFields = {
        'field1': 'Field has AmherstCollege and SmithCollege',
        'field2': 'Field has SmithCollege',
      };
      final links = LinkExtractor.extractAllLinks(text, extraFields);

      expect(links, equals(['AmherstCollege', 'SmithCollege']));
    });

    test('excludes self-references from all sources', () {
      final text = 'Current page AmherstCollege links to SmithCollege';
      final extraFields = {
        'notes': 'Also mentions AmherstCollege and WilliamsCollege',
      };
      final links = LinkExtractor.extractAllLinks(
        text,
        extraFields,
        excludeTitle: 'AmherstCollege',
      );

      expect(links, containsAll(['SmithCollege', 'WilliamsCollege']));
      expect(links, isNot(contains('AmherstCollege')));
    });
  });
}
