import 'package:bidi/bidi.dart' as bidi;
import 'package:test/test.dart';

void main() {
  test('Hebrew niqqud stays after its base when RTL text is reordered', () {
    const input = 'א\u05B0ב\u05B1ג';
    final paragraph = bidi.BidiString.fromLogical(input).paragraphs.single;
    expect(String.fromCharCodes(paragraph.bidiText), 'גב\u05B1א\u05B0');
    expect(paragraph.indices, [4, 2, 3, 0, 1]);
  });

  test('multiple niqqud marks remain in their original cluster order', () {
    const input = 'ש\u05B8\u05C1לו\u05B9ם';
    final paragraph = bidi.BidiString.fromLogical(input).paragraphs.single;
    expect(
      String.fromCharCodes(paragraph.bidiText),
      'םו\u05B9לש\u05B8\u05C1',
    );
    expect(paragraph.indices, [6, 4, 5, 3, 0, 1, 2]);
  });

  test('RTL combining marks inside a Latin paragraph remain attached', () {
    const input = 'abc א\u05B0ב def';
    final paragraph = bidi.BidiString.fromLogical(input).paragraphs.single;
    expect(
      String.fromCharCodes(paragraph.bidiText),
      'abc בא\u05B0 def',
    );
    expect(paragraph.indices, [0, 1, 2, 3, 6, 4, 5, 7, 8, 9, 10]);
  });

  test('left-to-right accent marks are not moved', () {
    const input = 'e\u0301cole';
    final paragraph = bidi.BidiString.fromLogical(input).paragraphs.single;
    // Canonical normalization may compose the first accent.
    expect(String.fromCharCodes(paragraph.bidiText), 'école');
    expect(paragraph.indices, hasLength(5));
  });
}
