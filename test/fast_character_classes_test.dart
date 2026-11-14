import 'package:bidi/bidi.dart' as bidi;
import 'package:test/test.dart';

void main() {
  test('all BMP codepoints retain their existing BiDi classes', () {
    for (var character = 0; character <= 0xFFFF; ++character) {
      final original = bidi.characterTypes[character] ?? bidi.CharacterType.ltr;
      expect(bidi.getCharacterType(character), original,
          reason: 'U+${character.toRadixString(16)}');
    }
  });

  test('classification boundaries and out-of-range fallback stay unchanged',
      () {
    for (final character in [
      -0x8000000000000000,
      -1,
      0,
      0x7f,
      0x80,
      0x05cf,
      0x05d0,
      0x05ea,
      0x05eb,
      0xffff,
      0x10000,
      0x1f600,
      0x10ffff,
      0x110000,
      0x7fffffffffffffff,
    ]) {
      expect(bidi.getCharacterType(character),
          bidi.characterTypes[character] ?? bidi.CharacterType.ltr,
          reason: character.toRadixString(16));
    }
  });

  test('mixed Hebrew and Latin retain visual order and source indices', () {
    final paragraph = bidi.BidiString.fromLogical('abc אבג').paragraphs.single;
    expect(String.fromCharCodes(paragraph.bidiText), 'abc גבא');
    expect(paragraph.indices, [0, 1, 2, 3, 6, 5, 4]);
  });
}
