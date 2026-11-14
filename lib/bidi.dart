/// Implementation of the Bidi algorithm, as described in http://www.unicode.org/reports/tr9/tr9-17.html.
///
/// Converts *logical* strings to their equivalent *visual* representation. Persian, Hebrew and Arabic languages (and any other RTL language) are supported.
library bidi;

import 'dart:core';
import 'dart:math';
import 'dart:collection';
import 'dart:convert';

part 'src/bidi.dart';
part 'src/ascii_bidi_types.dart';
part 'src/character_type.dart';
part 'src/supplementary_bidi_types.dart';
part 'src/direction_override.dart';
part 'src/shape_joining_type.dart';
part 'src/decomposition_type.dart';
part 'src/letter_form.dart';
part 'src/canonical_class.dart';
part 'src/character_category.dart';
part 'src/paragraph.dart';
part 'src/paired_brackets.dart';
part 'src/stack.dart';
part 'src/character_mirror.dart';
part 'src/bidi_characters.dart';
part 'src/shaping_resolver.dart';
part 'src/unicode_character_resolver.dart';
