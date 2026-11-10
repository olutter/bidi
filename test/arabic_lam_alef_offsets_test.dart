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

  test('ordinary Arabic words do not lose source offsets', () {
    const input = 'مرحباX';
    final paragraph = bidi.BidiString.fromLogical(input).paragraphs.single;
    final visual = String.fromCharCodes(paragraph.bidiText);
    expect(paragraph.indices[visual.indexOf('X')], input.length - 1);
  });
}
