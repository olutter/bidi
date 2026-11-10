import 'package:bidi/bidi.dart' as bidi;
import 'package:test/test.dart';

void main() {
  test('supplementary Unicode scalar is not split while reordering Hebrew', () {
    const input = 'אב😀ג';
    final paragraph = bidi.BidiString.fromLogical(input).paragraphs.single;
    expect(String.fromCharCodes(paragraph.bidiText), 'ג😀בא');
    // Indices are offsets into the original UTF-16 String, not rune numbers.
    expect(paragraph.indices, [4, 2, 1, 0]);
  });

  test('supplementary character occupies two source code units', () {
    final paragraph = bidi.BidiString.fromLogical('A😀B').paragraphs.single;
    expect(String.fromCharCodes(paragraph.bidiText), 'A😀B');
    expect(paragraph.indices, [0, 1, 3]);
  });

  test('leading neutral emoji does not force a Hebrew paragraph to LTR', () {
    final paragraph = bidi.BidiString.fromLogical('😀אבג').paragraphs.single;
    expect(String.fromCharCodes(paragraph.bidiText), 'גבא😀');
    expect(paragraph.indices, [4, 3, 2, 0]);
  });

  test('Unicode 15.1 supplementary bidi classes', () {
    expect(bidi.getCharacterType(0x1F600), bidi.CharacterType.otherNeutrals);
    expect(bidi.getCharacterType(0x1E900), bidi.CharacterType.rtl);
    expect(bidi.getCharacterType(0x10D00), bidi.CharacterType.al);
    expect(bidi.getCharacterType(0x1D7CE), bidi.CharacterType.en);
    expect(bidi.getCharacterType(0x1DA00), bidi.CharacterType.nonspacingMark);
    expect(bidi.getCharacterType(0x10400), bidi.CharacterType.ltr);
  });

  test('Unicode 15.1 defaults include unassigned RTL and ignorable scalars',
      () {
    expect(bidi.getCharacterType(0x10806), bidi.CharacterType.rtl);
    expect(bidi.getCharacterType(0x10D28), bidi.CharacterType.al);
    expect(bidi.getCharacterType(0x1EF00), bidi.CharacterType.rtl);
    expect(bidi.getCharacterType(0xE0000), bidi.CharacterType.bn);
    expect(bidi.getCharacterType(0x10FFFF), bidi.CharacterType.bn);
  });
}
