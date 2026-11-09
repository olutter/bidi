import 'package:bidi/bidi.dart' as bidi;

void main() {
  final paragraphs = <String, String>{
    'short ASCII': 'English text 2026: 123.45 (3/4) plus @test!',
    'long ASCII': List<String>.filled(100, 'Title 2026: abc 123.').join(' '),
    'ASCII with separators': List<String>.filled(20, 'abc 123\ndef 456').join('\n'),
  };
  for (final caseEntry in paragraphs.entries) {
    final text = caseEntry.value;
    for (var i = 0; i < 100; i++) {
      bidi.logicalToVisual(text);
    }
    final watch = Stopwatch()..start();
    var total = 0;
    for (var i = 0; i < 500; i++) {
      total += bidi.logicalToVisual(text).length;
    }
    watch.stop();
    print('${caseEntry.key}: ${(watch.elapsedMicroseconds / 500).toStringAsFixed(1)} us/op (checksum=$total)');
  }
}
