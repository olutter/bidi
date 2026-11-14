import 'package:bidi/bidi.dart' as bidi;

void main() {
  final cases = <String, String>{
    'neutral-heavy mixed Hebrew/English':
        List<String>.filled(80, 'שלום: ABC, Windows. (PDF) 2026; ').join(),
    'many neutral runs': List<String>.filled(200, 'א, ABC; 123: ').join(),
    'long neutral sequences': 'אב${List<String>.filled(700, ' .,:;').join()}ג',
    'pointed Hebrew (control)':
        List<String>.filled(90, 'בְּרֵאשִׁית בָּרָא').join(' '),
  };

  const iterations = 150;
  for (final entry in cases.entries) {
    final text = entry.value;
    var checksum = 0;
    for (var i = 0; i < 50; ++i) {
      checksum += bidi.logicalToVisual(text).length;
    }
    final watch = Stopwatch()..start();
    for (var i = 0; i < iterations; ++i) {
      checksum += bidi.logicalToVisual(text).length;
    }
    watch.stop();
    print('${entry.key}: '
        '${(watch.elapsedMicroseconds / iterations).toStringAsFixed(1)} us/op, '
        'checksum=$checksum');
  }
}
