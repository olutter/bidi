// Prints timings without imposing machine-dependent thresholds.
import 'package:bidi/bidi.dart' as bidi;

void main() {
  final cases = <String, String>{
    'mixed Hebrew/Latin':
        'זהו טקסט עברי עם PDF, Windows, מספרים 1234, וסימני פיסוק.',
    'vowelled Hebrew':
        'בְּרֵאשִׁית בָּרָא אֱלֹקִים אֵת הַשָּׁמַיִם וְאֵת הָאָרֶץ.',
    'marker-heavy': '${List<String>.filled(200, '\u200E').join()}Hello שלום',
    'long paragraph': List<String>.filled(100, 'שלום, World 2026;').join(' '),
  };

  const warmup = 50;
  const iterations = 300;
  for (final entry in cases.entries) {
    var checksum = 0;
    for (var i = 0; i < warmup; ++i) {
      checksum += bidi.logicalToVisual(entry.value).length;
    }
    final watch = Stopwatch()..start();
    for (var i = 0; i < iterations; ++i) {
      checksum += bidi.logicalToVisual(entry.value).length;
    }
    watch.stop();
    final micros = watch.elapsedMicroseconds / iterations;
    print(
        '${entry.key}: ${micros.toStringAsFixed(1)} us/op (checksum=$checksum)');
  }
}
