import 'package:bidi/bidi.dart' as bidi;
import 'package:test/test.dart';

void main() {
  test('unpointed Hebrew stays unchanged by normalization', () {
    const input = 'בראשית ברא אלהים את השמים ואת הארץ';
    final paragraph = bidi.BidiString.fromLogical(input).paragraphs.single;
    expect(paragraph.n.text, input.codeUnits);
    expect(paragraph.n.lengths, List<int>.filled(input.length, 1));
    expect(paragraph.n.hasNonspacingMark, isFalse);
    expect(paragraph.n.hasPersian, isFalse);
  });

  test('mixed Hebrew and ASCII retains visual and logical index mapping', () {
    final paragraph = bidi.BidiString.fromLogical('abc אבג').paragraphs.single;
    expect(String.fromCharCodes(paragraph.bidiText), 'abc גבא');
    expect(paragraph.indices, [0, 1, 2, 3, 6, 5, 4]);
  });

  test('Hebrew-only input preserves RTL visual reordering', () {
    final paragraph = bidi.BidiString.fromLogical('אבג').paragraphs.single;
    expect(String.fromCharCodes(paragraph.bidiText), 'גבא');
    expect(paragraph.indices, [2, 1, 0]);
  });

  test('pointed Hebrew continues through the full normalization path', () {
    final paragraph =
        bidi.BidiString.fromLogical('א\u05B0ב\u05B1').paragraphs.single;
    expect(paragraph.n.hasNonspacingMark, isTrue);
    expect(paragraph.indices.length, paragraph.bidiText.length);
  });

  test('Arabic presentation forms are unchanged by this fast path', () {
    expect(String.fromCharCodes(bidi.logicalToVisual('أ')), 'ﺃ');
    expect(String.fromCharCodes(bidi.logicalToVisual('خطأ')), 'ﺄﻄﺧ');
  });
}
