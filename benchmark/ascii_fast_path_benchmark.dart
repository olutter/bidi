import 'package:bidi/bidi.dart' as bidi;

void main() {
  final samples = <String, String>{
    'short ASCII': 'English text 2026: 123.45 (3/4) plus @test!',
    'long ASCII': List<String>.filled(100, 'Title 2026: abc 123.').join(' '),
    'ASCII with separators':
        List<String>.filled(20, 'abc 123\ndef 456').join('\n'),
  };

  const iterations = 250;
  for (final sample in samples.entries) {
    final input = sample.value;
    final optimized = bidi.BidiString.fromLogical(input);
    final optimizedText = [
      for (final paragraph in optimized.paragraphs) ...paragraph.bidiText,
    ];
    if (String.fromCharCodes(optimizedText) != input) {
      throw StateError('ASCII output diverged from its logical input');
    }

    double time(void Function() run) {
      for (var i = 0; i < 80; ++i) {
        run();
      }
      final stopwatch = Stopwatch()..start();
      for (var i = 0; i < iterations; ++i) {
        run();
      }
      stopwatch.stop();
      return stopwatch.elapsedMicroseconds / iterations;
    }

    final fastMicros = time(() => bidi.BidiString.fromLogical(input));
    print('${sample.key}: ${fastMicros.toStringAsFixed(1)} us/op');
  }
}
