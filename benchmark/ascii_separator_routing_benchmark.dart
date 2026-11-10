import 'package:bidi/bidi.dart' as bidi;

void main() {
  final cases = <String, String>{
    'ASCII text': List<String>.filled(
            200, 'Chapter 12 (Draft): a longer English paragraph.')
        .join(' '),
    'mixed Hebrew/Latin':
        List<String>.filled(160, 'בראשית, Otzaria 2026 text: פרק ראשון.')
            .join(' '),
    'ASCII paragraph separators':
        List<String>.filled(150, 'abc 123\r\ndef 456\nlast!').join(),
  };
  for (final entry in cases.entries) {
    final text = entry.value;
    for (var i = 0; i < 75; ++i) {
      bidi.BidiString.fromLogical(text);
    }
    const iterations = 300;
    var checksum = 0;
    final timer = Stopwatch()..start();
    for (var i = 0; i < iterations; ++i) {
      final paragraphs = bidi.BidiString.fromLogical(text).paragraphs;
      checksum += paragraphs.length;
    }
    timer.stop();
    print('${entry.key}: '
        '${(timer.elapsedMicroseconds / iterations).toStringAsFixed(2)} us/op '
        '(checksum=$checksum)');
  }
}
