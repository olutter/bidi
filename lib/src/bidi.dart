part of '../bidi.dart';

/// Bidi String.
class BidiString {
  BidiString._(this.paragraphs);

  /// Implementation of the BIDI algorithm, as described in http://www.unicode.org/reports/tr9/tr9-17.html
  /// [text] is the original logical-ordered string. Returns the visual representation of the string.
  factory BidiString.fromLogical(String text) {
    final paragraphs = <Paragraph>[];
    final codeUnits = text.codeUnits;
    // Iterate Unicode scalar values, never individual UTF-16 surrogate
    // halves. Reordering the halves separately corrupts supplementary text.
    var next = <int>[];

    var asciiOnly = true;
    for (var i = 0; i < codeUnits.length; ++i) {
      final char = codeUnits[i];
      if (char > 0x7F) {
        asciiOnly = false;
      }
      final type = getCharacterType(char);
      if (type == CharacterType.separator) {
        final paragraph =
            asciiOnly ? Paragraph._ascii(next, char) : Paragraph._(next, char);
        paragraphs.add(paragraph);
        next = [];
        asciiOnly = true;
      } else {
        next.add(char);
      }
    }

    if (next.isNotEmpty) // string ended without a paragraph separator
    {
      paragraphs.add(asciiOnly
          ? Paragraph._ascii(next, _BidiChars.notAChar)
          : Paragraph._(next, _BidiChars.notAChar));
    }

    return BidiString._(paragraphs);
  }

  /// Paragraphs.
  final List<Paragraph> paragraphs;
}

/// Implementation of the BIDI algorithm, as described in http://www.unicode.org/reports/tr9/tr9-17.html
/// [logicalString] is the original logical-ordered string. Returns the visual representation of the string.
List<int> logicalToVisual(String logicalString) {
  final paragraphs = BidiString.fromLogical(logicalString).paragraphs;
  final sb = <int>[];
  for (final p in paragraphs) {
    sb.addAll(p.bidiText);
  }

  return sb;
}

/// Implementation of the BIDI algorithm, as described in http://www.unicode.org/reports/tr9/tr9-17.html
/// [logicalString] is the original logical-ordered string.
/// [indexes] Implies where the original characters are.
/// [lengths] Implies how many characters each original character occupies.
/// Returns the visual representation of the string.
String logicalToVisual2(
  String logicalString,
  List<int> indexes,
  List<int> lengths,
) {
  //Section 3:
  //1. seperate text into paragraphs
  //2. resulate each paragraph to its embeding levels of text
  //2.1 find the first character of type L, AL, or R.
  //3. reorder text elements

  //Section 3.3: Resolving Embedding Levels:
  //(1) determining the paragraph level.
  //(2) determining explicit embedding levels and directions.
  //(3) resolving weak types.
  //(4) resolving neutral types.
  //(5) resolving implicit embedding levels.

  final paragraphs = BidiString.fromLogical(logicalString).paragraphs;

  final sb = <int>[];
  for (final p in paragraphs) {
    sb.addAll(p.bidiText);
    indexes.addAll(p.indices);
  }

  return String.fromCharCodes(sb);
}

/// Split the text into separate paragraphs.
///
/// A paragraph separator is kept with the previous paragraph.
/// Within each paragraph, apply all the other rules of this algorithm.
///
/// 3.3.1.P1.
@Deprecated('Please use BidiString.fromLogical')
List<Paragraph> splitStringToParagraphs(String logicalString) {
  return BidiString.fromLogical(logicalString).paragraphs;
}

// ASCII has five paragraph separators; other scalars retain the Unicode lookup.
bool _isParagraphSeparator(int character) => character < 0x80
    ? character == 0x0A ||
        character == 0x0D ||
        (character >= 0x1C && character <= 0x1E)
    : getCharacterType(character) == CharacterType.separator;
