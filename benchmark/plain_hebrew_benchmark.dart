import 'package:bidi/bidi.dart' as bidi;

void main() {
  final cases = <String, String>{
    'unpointed Hebrew 100 words':
        List<String>.filled(100, 'שלום עליכם בראשית').join(' '),
    'unpointed mixed Hebrew Latin':
        List<String>.filled(100, 'ספר Otzaria 2026').join(' '),
    'pointed Hebrew (control)':
        List<String>.filled(100, 'שָׁלוֹם בָּרוּךְ').join(' '),
    'ASCII (control)':
        List<String>.filled(100, 'English Windows 2026').join(' '),
  };

  const warmup = 25;
  const iterations = 100;
  for (final entry in cases.entries) {
    var checksum = 0;
    for (var i = 0; i < warmup; i++) {
      checksum += bidi.logicalToVisual(entry.value).length;
    }
    final watch = Stopwatch()..start();
    for (var i = 0; i < iterations; i++) {
      checksum += bidi.logicalToVisual(entry.value).length;
    }
    watch.stop();
    print('${entry.key}: '
        '${(watch.elapsedMicroseconds / iterations).toStringAsFixed(1)} us/op '
        '(checksum=$checksum)');
  }
}
