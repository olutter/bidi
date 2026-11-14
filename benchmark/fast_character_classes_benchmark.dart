import 'package:bidi/bidi.dart' as bidi;

void main() {
  final cases = <String, List<int>>{
    'Hebrew letter classifications':
        List<int>.generate(5400, (index) => 0x05D0 + index % 27),
    'ASCII classifications': List<int>.generate(6400, (index) => index % 128),
    'mixed-printing classifications': List<int>.generate(4800,
        (index) => index % 5 == 0 ? 0x05D0 + index % 27 : 32 + index % 95),
  };
  for (final entry in cases.entries) {
    final chars = entry.value;
    var checksum = 0;
    for (var j = 0; j < 15; ++j) {
      for (final ch in chars) {
        checksum += bidi.getCharacterType(ch).index;
      }
    }
    const iterations = 200;
    final timer = Stopwatch()..start();
    for (var j = 0; j < iterations; ++j) {
      for (final ch in chars) {
        checksum += bidi.getCharacterType(ch).index;
      }
    }
    timer.stop();
    print('${entry.key}: '
        '${(timer.elapsedMicroseconds / iterations).toStringAsFixed(1)} us/op, '
        'checksum=$checksum');
  }

  final paragraph =
      List<String>.filled(100, 'בראשית ברא אלהים, English, 2026.').join(' ');
  for (var i = 0; i < 50; i++) {
    bidi.BidiString.fromLogical(paragraph);
  }
  const runs = 200;
  final stopwatch = Stopwatch()..start();
  for (var i = 0; i < runs; ++i) {
    bidi.BidiString.fromLogical(paragraph);
  }
  stopwatch.stop();
  print('mixed Hebrew paragraph: '
      '${(stopwatch.elapsedMicroseconds / runs).toStringAsFixed(1)} us/op');
}
