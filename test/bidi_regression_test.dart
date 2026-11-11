import 'package:bidi/bidi.dart' as bidi;
import 'package:test/test.dart';

void main() {
  test('LTR text preserves both content and logical indices', () {
    final paragraph = bidi.BidiString.fromLogical('abc 123').paragraphs.single;
    expect(String.fromCharCodes(paragraph.bidiText), 'abc 123');
    expect(paragraph.indices, List<int>.generate(7, (index) => index));
  });

  test('RTL letters reorder with their original indices', () {
    final paragraph = bidi.BidiString.fromLogical('אבג').paragraphs.single;
    expect(String.fromCharCodes(paragraph.bidiText), 'גבא');
    expect(paragraph.indices, [2, 1, 0]);
  });

  test('interleaved direction marks preserve surviving source indices', () {
    final paragraph = bidi.BidiString.fromLogical(
      '\u200Eab\u200Ec\u200E',
    ).paragraphs.single;
    expect(String.fromCharCodes(paragraph.bidiText), 'abc');
    expect(paragraph.indices, [1, 2, 4]);
  });

  test('paragraph separators are preserved', () {
    expect(
      String.fromCharCodes(bidi.logicalToVisual('abc\ndef')),
      'abc\ndef',
    );
  });

  test('formatting markers are removed without shifting source indices', () {
    final prefix = List<String>.filled(500, '\u200E').join();
    final suffix = List<String>.filled(500, '\u200E').join();
    final paragraph = bidi.BidiString.fromLogical(
      '${prefix}abc$suffix',
    ).paragraphs.single;

    expect(String.fromCharCodes(paragraph.bidiText), 'abc');
    expect(paragraph.indices, [500, 501, 502]);
  });

  test('compaction removes explicit overrides as well as direction marks', () {
    const input = 'abc\u202A\u202C\u200E\u200F\u202B\u202E\u202D';
    final paragraph = bidi.BidiString.fromLogical(input).paragraphs.single;
    final output = String.fromCharCodes(paragraph.bidiText);
    for (final marker in [
      0x200E,
      0x200F,
      0x202A,
      0x202B,
      0x202C,
      0x202D,
      0x202E
    ]) {
      expect(output.contains(String.fromCharCode(marker)), isFalse);
    }
    expect(paragraph.indices.length, paragraph.bidiText.length);
  });
}
