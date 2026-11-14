import 'package:bidi/bidi.dart' as bidi;
import 'package:test/test.dart';

void main() {
  test('lam-alef ligatures preserve following source character offsets', () {
    for (final text in ['لاX', 'لأX', 'لإX', 'لآX']) {
      final paragraph = bidi.BidiString.fromLogical(text).paragraphs.single;
      final visual = String.fromCharCodes(paragraph.bidiText);
      final positionOfX = visual.indexOf('X');
      expect(positionOfX, isNonNegative, reason: text);
      expect(paragraph.indices[positionOfX], 2, reason: text);
      expect(paragraph.n.lengths.reduce((a, b) => a + b), text.length,
          reason: text);
    }
  });

  test('joined medial lam-alef has correct following logical offset', () {
    for (final text in ['بلاX', 'بلأX', 'بلإX', 'بلآX']) {
      final paragraph = bidi.BidiString.fromLogical(text).paragraphs.single;
      final visual = String.fromCharCodes(paragraph.bidiText);
      final positionOfX = visual.indexOf('X');
      expect(positionOfX, isNonNegative, reason: text);
      expect(paragraph.indices[positionOfX], 3, reason: text);
      expect(paragraph.n.lengths.reduce((a, b) => a + b), text.length,
          reason: text);
    }
  });

  test('a second alef remains separate after the first ligature', () {
    for (final text in ['لااX', 'لأاX', 'لإاX', 'لآاX']) {
      final paragraph = bidi.BidiString.fromLogical(text).paragraphs.single;
      final visual = String.fromCharCodes(paragraph.bidiText);
      expect(visual.runes.length, 3, reason: text);
      expect(paragraph.indices[visual.indexOf('X')], 3, reason: text);
      expect(paragraph.n.lengths.reduce((a, b) => a + b), 4,
          reason: text);
    }
  });

  test('a transparent Arabic mark does not lose the following index', () {
    const text = 'ل\u064eاX';
    final paragraph = bidi.BidiString.fromLogical(text).paragraphs.single;
    final visual = String.fromCharCodes(paragraph.bidiText);
    expect(paragraph.indices[visual.indexOf('X')], 3);
    expect(paragraph.n.lengths.reduce((a, b) => a + b), text.length);
  });

  test('ordinary Arabic words do not lose source offsets', () {
    const input = 'مرحباX';
    final paragraph = bidi.BidiString.fromLogical(input).paragraphs.single;
    final visual = String.fromCharCodes(paragraph.bidiText);
    expect(paragraph.indices[visual.indexOf('X')], input.length - 1);
  });
}
