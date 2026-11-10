import 'package:bidi/bidi.dart' as bidi;
import 'package:test/test.dart';

void main() {
  test('global UTF-16 positions include paragraph separators', () {
    final indexes = <int>[];
    final lengths = <int>[];
    final visual = bidi.logicalToVisual2('abc\nאבג', indexes, lengths);

    expect(visual, 'abc\nגבא');
    expect(indexes, [0, 1, 2, 3, 6, 5, 4]);
    expect(lengths, [1, 1, 1, 1, 1, 1, 1]);
  });

  test('multiple paragraph separators each have an index and span', () {
    final indexes = <int>[];
    final lengths = <int>[];
    const source = 'a\r\nb\nc';
    expect(bidi.logicalToVisual2(source, indexes, lengths), source);
    expect(indexes, [0, 1, 2, 3, 4, 5]);
    expect(lengths, [1, 1, 1, 1, 1, 1]);
  });

  test('formatting marks are omitted but source positions remain correct', () {
    final indexes = <int>[];
    final lengths = <int>[];
    const source = 'a\u200Eb\u200Fc';
    expect(bidi.logicalToVisual2(source, indexes, lengths), 'abc');
    expect(indexes, [0, 2, 4]);
    expect(lengths, [1, 1, 1]);
  });

  test('canonical composition records the span of both source code units', () {
    final indexes = <int>[];
    final lengths = <int>[];
    expect(bidi.logicalToVisual2('e\u0301', indexes, lengths), 'é');
    expect(indexes, [0]);
    expect(lengths, [2]);
  });

  test('existing caller output entries are preserved and appended to', () {
    final indexes = <int>[-1];
    final lengths = <int>[-1];
    expect(bidi.logicalToVisual2('abc', indexes, lengths), 'abc');
    expect(indexes, [-1, 0, 1, 2]);
    expect(lengths, [-1, 1, 1, 1]);
  });

  test('source-span alignment agrees with each paragraph visual character', () {
    for (final source in [
      'abc123',
      'אבג',
      '1:23 אבג',
      'אבג (2026)',
      'אבג\ndef',
      'e\u0301 א\u05B0',
    ]) {
      final indexes = <int>[];
      final lengths = <int>[];
      final visual = bidi.logicalToVisual2(source, indexes, lengths);
      expect(indexes.length, visual.runes.length, reason: source);
      expect(lengths.length, indexes.length, reason: source);
      for (var i = 0; i < indexes.length; i++) {
        expect(indexes[i], inInclusiveRange(0, source.length - 1));
        expect(lengths[i], greaterThanOrEqualTo(0));
        expect(indexes[i] + lengths[i], lessThanOrEqualTo(source.length));
      }
    }
  });
}
