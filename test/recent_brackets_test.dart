import 'package:bidi/bidi.dart' as bidi;
import 'package:test/test.dart';

void main() {
  for (var opening = 0x2E55; opening <= 0x2E5B; opening += 2) {
    final left = String.fromCharCode(opening);
    final right = String.fromCharCode(opening + 1);
    test('recent bracket pair ${opening.toRadixString(16)} stays neutral', () {
      expect(bidi.getCharacterType(opening), bidi.CharacterType.otherNeutrals);
      expect(
          bidi.getCharacterType(opening + 1), bidi.CharacterType.otherNeutrals);
      expect(
          String.fromCharCodes(bidi.logicalToVisual('abc $leftאבג$right 123')),
          'abc $leftגבא$right 123');
      expect(String.fromCharCodes(bidi.logicalToVisual('אבג ${left}abc$right')),
          '${left}abc$right גבא');
    });
  }
}
