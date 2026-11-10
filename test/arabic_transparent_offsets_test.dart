import 'package:bidi/bidi.dart' as bidi;
import 'package:test/test.dart';

void main() {
  test('lam-alef source spans preserve intervening transparent marks', () {
    for (final alef in ['\u0627', '\u0622', '\u0623', '\u0625']) {
      for (final marks in ['\u064e', '\u064e\u0650']) {
        final input = '\u0644$marks${alef}X';
        final p = bidi.BidiString.fromLogical(input).paragraphs.single;
        final ligature = p.indices.indexOf(0);
        expect(p.sourceLengths[ligature], 2 + marks.length, reason: input);
        for (var i = 0; i < marks.length; ++i) {
          final position = p.bidiText.indexOf(marks.codeUnitAt(i));
          expect(p.indices[position], 1 + i, reason: input);
          expect(p.sourceLengths[position], 1, reason: input);
        }
        expect(p.indices[p.bidiText.indexOf(88)], input.length - 1);
        expect(p.n.lengths.reduce((a, b) => a + b), input.length);
      }
    }
  });
}
