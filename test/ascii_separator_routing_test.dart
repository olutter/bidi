import 'package:bidi/bidi.dart' as bidi;
import 'package:test/test.dart';

void main() {
  test(
      'all ASCII boundary classes match the Unicode type table in both scanners',
      () {
    for (var character = 0; character < 128; ++character) {
      final source = 'A${String.fromCharCode(character)}B';
      final separator =
          bidi.getCharacterType(character) == bidi.CharacterType.separator;
      final paragraphs = bidi.BidiString.fromLogical(source).paragraphs;
      // ignore: deprecated_member_use_from_same_package
      final legacy = bidi.splitStringToParagraphs(source);
      expect(paragraphs.length, separator ? 2 : 1, reason: 'ASCII $character');
      expect(
          legacy.map((p) => p.separator), paragraphs.map((p) => p.separator));
      expect([for (final p in paragraphs) ...p.bidiText], source.codeUnits);
    }
  });

  test('CRLF and consecutive boundaries retain separate paragraph positions',
      () {
    const source = 'one\r\ntwo\n\nthree\rfour\u001cfive';
    final paragraphs = bidi.BidiString.fromLogical(source).paragraphs;
    expect(paragraphs.length, 7);
    expect(String.fromCharCodes(bidi.logicalToVisual(source)), source);
    expect(
        paragraphs.map((p) => p.separator).take(6), [13, 10, 10, 10, 13, 28]);
  });

  test('Unicode boundaries and UTF-16 offsets retain the general path', () {
    for (final character in [0x85, 0x2028, 0x2029]) {
      final source = 'A${String.fromCharCode(character)}B';
      final expected =
          bidi.getCharacterType(character) == bidi.CharacterType.separator;
      final paragraphs = bidi.BidiString.fromLogical(source).paragraphs;
      // ignore: deprecated_member_use_from_same_package
      expect(bidi.splitStringToParagraphs(source).length, expected ? 2 : 1);
      expect(paragraphs.length, expected ? 2 : 1);
    }
    final p = bidi.BidiString.fromLogical('A😀B').paragraphs.single;
    expect(String.fromCharCodes(p.bidiText), 'A😀B');
    expect(p.indices.last, 3);
  });
}
