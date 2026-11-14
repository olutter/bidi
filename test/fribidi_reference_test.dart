import 'package:bidi/bidi.dart' as bidi;
import 'package:test/test.dart';

/// Visual output and index mapping generated independently by the system
/// FriBidi `fribidi_log2vis` function with automatic first-strong base
/// paragraph direction. These fixtures intentionally contain only Hebrew,
/// Latin, numbers and punctuation, excluding Arabic glyph shaping.
void main() {
  const fixtures = <_Fixture>[
    _Fixture('abc אבג', 'abc גבא', [0, 1, 2, 3, 6, 5, 4]),
    _Fixture('אבג abc', 'abc גבא', [4, 5, 6, 3, 2, 1, 0]),
    _Fixture('אבג 2026', '2026 גבא', [4, 5, 6, 7, 3, 2, 1, 0]),
    _Fixture(
        'abc 2026 אבג', 'abc 2026 גבא', [0, 1, 2, 3, 4, 5, 6, 7, 8, 11, 10, 9]),
    _Fixture('אבג (abc)', '(abc) גבא', [8, 5, 6, 7, 4, 3, 2, 1, 0]),
    _Fixture('abc (אבג) def', 'abc (גבא) def',
        [0, 1, 2, 3, 4, 7, 6, 5, 8, 9, 10, 11, 12]),
    _Fixture('אבג (123)', '(123) גבא', [8, 5, 6, 7, 4, 3, 2, 1, 0]),
    _Fixture('אבג [abc]', '[abc] גבא', [8, 5, 6, 7, 4, 3, 2, 1, 0]),
    _Fixture('abc [אבג] def', 'abc [גבא] def',
        [0, 1, 2, 3, 4, 7, 6, 5, 8, 9, 10, 11, 12]),
    _Fixture('אבג {abc}', '{abc} גבא', [8, 5, 6, 7, 4, 3, 2, 1, 0]),
    _Fixture('אבג <abc>', '<abc> גבא', [8, 5, 6, 7, 4, 3, 2, 1, 0]),
    _Fixture(
        'ABC שלום 123', 'ABC 123 םולש', [0, 1, 2, 3, 9, 10, 11, 8, 7, 6, 5, 4]),
    _Fixture('שלום ABC עולם', 'םלוע ABC םולש',
        [12, 11, 10, 9, 8, 5, 6, 7, 4, 3, 2, 1, 0]),
    _Fixture('שנה 2026 (PDF)', '(PDF) 2026 הנש',
        [13, 10, 11, 12, 9, 8, 4, 5, 6, 7, 3, 2, 1, 0]),
    _Fixture('abc (אבג DEF) xyz', 'abc (גבא DEF) xyz',
        [0, 1, 2, 3, 4, 7, 6, 5, 8, 9, 10, 11, 12, 13, 14, 15, 16]),
    _Fixture('שלום (abc אבג) עולם', 'םלוע (גבא abc) םולש',
        [18, 17, 16, 15, 14, 13, 12, 11, 10, 9, 6, 7, 8, 5, 4, 3, 2, 1, 0]),
    _Fixture('abc (אבג [DEF]) xyz', 'abc (גבא [DEF]) xyz',
        [0, 1, 2, 3, 4, 7, 6, 5, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18]),
    _Fixture('אבג (A) דהו', 'והד (A) גבא', [10, 9, 8, 7, 6, 5, 4, 3, 2, 1, 0]),
    _Fixture('abc [אבג] 123', 'abc [גבא] 123',
        [0, 1, 2, 3, 4, 7, 6, 5, 8, 9, 10, 11, 12]),
  ];

  for (final fixture in fixtures) {
    test('matches independent FriBidi reference: ${fixture.logical}', () {
      final paragraph =
          bidi.BidiString.fromLogical(fixture.logical).paragraphs.single;
      expect(String.fromCharCodes(paragraph.bidiText), fixture.visual);
      expect(paragraph.indices, fixture.mapping);
    });
  }
}

class _Fixture {
  const _Fixture(this.logical, this.visual, this.mapping);

  final String logical;
  final String visual;
  final List<int> mapping;
}
