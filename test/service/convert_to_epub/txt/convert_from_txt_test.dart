import 'package:anx_reader/models/chapter_split_presets.dart';
import 'package:anx_reader/service/convert_to_epub/txt/convert_from_txt.dart';
import 'package:test/test.dart';

void main() {
  group('default chapter split pattern', () {
    final pattern = getDefaultChapterSplitRule().buildRegExp();

    test('matches headings with trailing ASCII whitespace', () {
      expect(pattern.hasMatch('第一章 '), isTrue);
      expect(pattern.hasMatch('第二章  '), isTrue);
    });

    test('matches headings with trailing ideographic whitespace', () {
      expect(pattern.hasMatch('第三章　'), isTrue);
    });
  });

  group('section level inference', () {
    test('treats book markers as top-level sections', () {
      expect(inferSectionLevelForTest('Book 1'), equals(1));
    });

    test('treats chapter markers with "前篇" as chapter-level', () {
      expect(inferSectionLevelForTest('第一章 前篇'), equals(2));
      expect(inferSectionLevelForTest('前篇'), equals(2));
    });
  });
}
