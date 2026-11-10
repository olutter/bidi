part of '../bidi.dart';

/// Represents a paragraph in text.
class Paragraph {
  /// Constructor.
  Paragraph._(List<int> text, this._separator)
      : n = Normalization.decompose(text) {
    _originalText.clear();

    if (text.isNotEmpty) {
      _originalText.addAll(text);
    }

    n._compose();

    final embeddingLevel = _calculateEmbeddingLevel(n);
    _recalculateCharactersEmbeddingLevels(n, embeddingLevel);

    _removeBidiMarkers();
  }

  final int _separator;
  final List<int> _originalText = [];
  final List<int> _bidiText = [];

  /// N
  final Normalization n;

  final List<int> _indices = [];
  final List<int> _sourceLengths = [];

  /// Original text.
  List<int> get text {
    return _originalText;
  }

  /// Bidi text.
  List<int> get bidiText {
    var ret = _bidiText.toList();

    if (_separator != _BidiChars.notAChar) {
      ret.add(_separator);
    }
    return ret;
  }

  /// Bidi indexes.
  @Deprecated('Please use indices')
  List<int> get bidiIndexes {
    return _indices;
  }

  /// Indices of the bidi text.
  List<int> get indices {
    return _indices;
  }

  /// UTF-16 source span of each visual character, in the same order as
  /// [indices], not including the optional paragraph separator.
  List<int> get sourceLengths => _sourceLengths;

  /// The paragraph separatpr.
  int get separator => _separator;

  /// The paragraph separatpr.
  @Deprecated('Please use separator')
  int get paragraphSeparator => _separator;

  /// Removes Bidi markers from text.
  void _removeBidiMarkers() {
    final controlChars = [
      0x200F,
      0x202B,
      0x202E,
      0x200E,
      0x202A,
      0x202D,
      0x202C,
    ];

    final sb = _bidiText.toList();

    int i = 0;
    while (i < sb.length) {
      if (controlChars.contains(sb[i])) {
        sb.removeAt(i);
        _indices.removeAt(i);
        _sourceLengths.removeAt(i);
      } else {
        ++i;
      }
    }

    _bidiText.clear();
    _bidiText.addAll(sb);
  }

  // 3.3.2 Explicit Levels and Directions
  void _recalculateCharactersEmbeddingLevels(Normalization n, int el) {
    // This method is implemented in such a way it handles the string in logical order,
    // rather than visual order, so it is easier to handle complex layouts. That is why
    // it is placed BEFORE ReorderString rather than AFTER it, as its number suggests.
    final sourceIndices = <int>[];
    var sourceOffset = 0;
    for (final length in n.lengths) {
      sourceIndices.add(sourceOffset);
      sourceOffset += length;
    }
    final sourceLengths = n.lengths.toList();
    if (n.hasPersian) {
      final shaped = n._performShaping(sourceIndices, sourceLengths);
      n.text.clear();
      n.text.addAll(shaped);
    }
    int embeddingLevel = el;
    final text = n.text;

    final textData =
        List<_CharData>.generate(n.text.length, (index) => _CharData());

    // X1
    var dos = DirectionOverride.neutral;
    final dosStack = _Stack<DirectionOverride>();
    _Stack<int> elStack = _Stack<int>();

    for (int i = 0; i < text.length; ++i) {
      bool x9Char = false;
      final c = text[i];
      textData[i].type = getCharacterType(c);
      textData[i].char = c;
      textData[i].index = sourceIndices[i];
      textData[i].sourceLength = sourceLengths[i];

      // X2. With each RLE, compute the least greater odd embedding level.
      // X4. With each RLO, compute the least greater odd embedding level.
      if (c == _BidiChars.RLE || c == _BidiChars.RLO) {
        x9Char = true;
        if (embeddingLevel < 60) {
          elStack.push(embeddingLevel);
          dosStack.push(dos);

          ++embeddingLevel;
          embeddingLevel |= 1;

          if (c == _BidiChars.RLE) {
            dos = DirectionOverride.neutral;
          } else {
            dos = DirectionOverride.rtl;
          }
        }
      }
      // X3. With each LRE, compute the least greater even embedding level.
      // X5. With each LRO, compute the least greater even embedding level.
      else if (c == _BidiChars.LRE || c == _BidiChars.LRO) {
        x9Char = true;
        if (embeddingLevel < 59) {
          elStack.push(embeddingLevel);
          dosStack.push(dos);

          embeddingLevel |= 1;
          ++embeddingLevel;

          if (c == _BidiChars.LRE) {
            dos = DirectionOverride.neutral;
          } else {
            dos = DirectionOverride.ltr;
          }
        }
      }

      // X6. For all types besides RLE, LRE, RLO, LRO, and PDF: (...)
      else if (c != _BidiChars.PDF) {
        // a. Set the level of the current character to the current embedding level.
        textData[i].embeddingLevel = embeddingLevel;

        //b. Whenever the directional override status is not neutral,
        //reset the current character type to the directional override status.
        if (dos == DirectionOverride.ltr) {
          textData[i].type = CharacterType.ltr;
        } else if (dos == DirectionOverride.rtl) {
          textData[i].type = CharacterType.rtl;
        }
      }

      //Terminating Embeddings and Overrides
      // X7. With each PDF, determine the matching embedding or override code.
      // If there was a valid matching code, restore (pop) the last remembered (pushed)
      // embedding level and directional override.
      else if (c == _BidiChars.PDF) {
        x9Char = true;
        if (elStack.length > 0) {
          embeddingLevel = elStack.pop();
          dos = dosStack.pop();
        }
      }

      // X8. All explicit directional embeddings and overrides are completely
      // terminated at the end of each paragraph. Paragraph separators are not
      // included in the embedding.

      if (x9Char || textData[i].type == CharacterType.bn) {
        textData[i].embeddingLevel = embeddingLevel;
      }
    }

    // X10. The remaining rules are applied to each run of characters at the same level.
    int prevLevel = embeddingLevel;
    int start = 0;
    while (start < text.length) {
      final level = textData[start].embeddingLevel;
      final sor = _typeForLevel(max(prevLevel, level));

      int limit = start + 1;
      while (limit < text.length && textData[limit].embeddingLevel == level) {
        ++limit;
      }

      final nextLevel =
          limit < text.length ? textData[limit].embeddingLevel : embeddingLevel;
      final eor = _typeForLevel(max(nextLevel, level));

      _resolveWeakTypes(
          textData, start, limit, sor, eor, n.hasPersian, n.hasNonspacingMark);
      _resolveNeutralTypes(textData, start, limit, sor, eor, level);
      _resolveImplicitTypes(textData, start, limit, level);

      prevLevel = level;
      start = limit;
    }

    _reorderString(textData, el);
    _fixMirroredCharacters(textData);

    List<int> indexes = [];

    final List<int> sb = [];
    for (final cd in textData) {
      sb.add(cd.char);
      indexes.add(cd.index);
    }

    _bidiText.clear();
    _bidiText.addAll(sb);

    _indices.clear();
    _indices.addAll(indexes);

    _sourceLengths.clear();
    for (final cd in textData) {
      _sourceLengths.add(cd.sourceLength);
    }
  }
}

class _CharData {
  late int char;
  late int embeddingLevel; // 0-62 => 6
  late CharacterType type; // 0-18 => 5
  late int index;
  late int sourceLength;
}

/// Return the strong type (L or R) corresponding to the embedding level.
///
/// [level] The embedding level to check.
CharacterType _typeForLevel(int level) {
  return ((level & 1) == 0) ? CharacterType.ltr : CharacterType.rtl;
}

/// Contains a set of functions for bidi text
/// normalization (decomposition and composition).
class Normalization {
  /// Decomposition.
  const Normalization._(
    this.text,
    this.lengths,
    this.hasPersian,
    this.hasNonspacingMark,
  );

  /// Calculates the internal decomposition of the input text.
  factory Normalization.decompose(List<int> characters) {
    final List<int> text = [];
    final List<int> lengths = [];

    var hasPersian = false;
    var hasNSMs = false;

    for (int i = 0; i < characters.length; ++i) {
      final ct = getCharacterType(characters[i]);
      hasPersian |= ((ct == CharacterType.al) || (ct == CharacterType.an));
      hasNSMs |= (ct == CharacterType.nonspacingMark);

      final buffer = <int>[];
      _getRecursiveDecomposition(false, characters[i], buffer);
      lengths.add(1 - buffer.length);
      // add all of the characters in the decomposition.
      // (may be just the original character, if there was
      // no decomposition mapping)

      for (int j = 0; j < buffer.length; ++j) {
        final character = buffer[j];
        final chClass = _getCanonicalClass(character);
        int k = text.length; // insertion point
        if (chClass != _CanonicalClass.notReordered) {
          // bubble-sort combining marks as necessary
          int ch2;
          for (; k > 0; --k) {
            ch2 = text[k - 1];
            if (_getCanonicalClass(ch2).value <= chClass.value) break;
          }
        }

        text.insert(k, character);
      }
    }

    return Normalization._(text, lengths, hasPersian, hasNSMs);
  }

  /// Compose.
  void _compose() {
    if (text.isEmpty) {
      return;
    }

    int starterPos = 0;
    int compPos = 1;
    var starterCh = text[0];

    lengths[starterPos] = lengths[starterPos] + 1;

    var lastClass = _getCanonicalClass(starterCh);

    if (lastClass != _CanonicalClass.notReordered) {
      lastClass = _CanonicalClass.fromValue(
        256,
      ); // fix for strings staring with a combining mark
    }

    int oldLen = text.length;

    // Loop on the decomposed characters, combining where possible
    int ch;
    for (int decompPos = compPos; decompPos < text.length; ++decompPos) {
      ch = text[decompPos];
      final chClass = _getCanonicalClass(ch);
      final isShaddaPair = chClass.isShaddaPair;
      final composite = _getPairwiseComposition(starterCh, ch);
      final composeType = getDecompositionType(composite);

      if ((composeType == null || (isShaddaPair)) &&
          composite != _BidiChars.notAChar &&
          (lastClass.value < chClass.value ||
              lastClass == _CanonicalClass.notReordered)) {
        text[starterPos] = composite;
        lengths[starterPos] = lengths[starterPos] + 1;
        // we know that we will only be replacing non-supplementaries by non-supplementaries
        // so we don't have to adjust the decompPos
        starterCh = composite;
      } else {
        if (chClass == _CanonicalClass.notReordered || (isShaddaPair)) {
          starterPos = compPos;
          starterCh = ch;
        }
        lastClass = chClass;
        text[compPos] = ch;
        //char_lengths[compPos] = char_lengths[compPos] + 1;
        int chkPos = compPos;
        if (lengths[chkPos] < 0) {
          while (lengths[chkPos] < 0) {
            lengths[chkPos] = lengths[chkPos] + 1;
            lengths.insert(compPos, 0);
            chkPos++;
          }
        } else {
          lengths[chkPos] = lengths[chkPos] + 1;
        }

        if (text.length != oldLen) // MAY HAVE TO ADJUST!
        {
          decompPos += text.length - oldLen;
          oldLen = text.length;
        }
        ++compPos;
      }
    }
    text.length = compPos;

    final taken = lengths.take(compPos).toList();

    lengths.clear();
    lengths.addAll(taken);
  }

  /// 3.5 Shaping
  /// Implements rules R1-R7 and rules L1-L3 of section 8.2 (Persian) of the Unicode standard.
  // TODO - this code is very special-cased.
  List<int> _performShaping(List<int> sourceIndices, List<int> sourceLengths) {
    var lastJt = ShapeJoiningType.nonJoining;
    var lastForm = LetterForm.isolated;
    int lastPos = 0;
    var lastChar = _BidiChars.notAChar;
    final letterForms =
        List<LetterForm>.filled(text.length, LetterForm.initial);

    for (int i = 0; i < text.length; ++i) {
      var ch = text[i];
      //string chStr = (ch).toString("X4");

      final jt = getShapeJoiningType(ch);

      if ((jt == ShapeJoiningType.right ||
              jt == ShapeJoiningType.dual ||
              jt == ShapeJoiningType.causing) &&
          (lastJt == ShapeJoiningType.left ||
              lastJt == ShapeJoiningType.dual ||
              lastJt == ShapeJoiningType.causing)) {
        if (lastForm == LetterForm.isolated &&
            (lastJt == ShapeJoiningType.dual ||
                lastJt == ShapeJoiningType.left)) {
          letterForms[lastPos] = LetterForm.initial;
        } else if (lastForm == LetterForm.finalForm &&
            lastJt == ShapeJoiningType.dual) {
          letterForms[lastPos] = LetterForm.medial;
        }
        letterForms[i] = LetterForm.finalForm;
        lastForm = LetterForm.finalForm;
        lastJt = jt;
        lastPos = i;
        lastChar = ch;
      } else if (jt != ShapeJoiningType.transparent) {
        letterForms[i] = LetterForm.isolated;
        lastForm = LetterForm.isolated;
        lastJt = jt;
        lastPos = i;
        lastChar = ch;
      } else {
        letterForms[i] = LetterForm.isolated;
      }
    }

    lastChar = _BidiChars.notAChar;
    lastPos = 0;
    int insertPos = 0;

    final sb = <int>[];

    // Source spans may overlap when a ligature spans transparent marks.
    void finishLamAlef() {
      final alefPos = sb.length;
      sourceLengths[insertPos] = sourceIndices[alefPos] +
          sourceLengths[alefPos] -
          sourceIndices[insertPos];
      sourceIndices.removeAt(alefPos);
      sourceLengths.removeAt(alefPos);
      lengths[insertPos] += lengths.removeAt(alefPos);
      lastChar = _BidiChars.notAChar;
    }

    for (int i = 0; i < text.length; ++i) {
      var ch = text[i];
      //string chStr = (ch).toString("X4");
      final jt = getShapeJoiningType(ch);

      if (lastChar == _BidiChars.ARABIC_LAM &&
          ch != _BidiChars.ARABIC_ALEF &&
          ch != _BidiChars.ARABIC_ALEF_MADDA_ABOVE &&
          ch != _BidiChars.ARABIC_ALEF_HAMZA_ABOVE &&
          ch != _BidiChars.ARABIC_ALEF_HAMZA_BELOW &&
          jt != ShapeJoiningType.transparent) {
        lastChar = _BidiChars.notAChar;
      } else if (ch == _BidiChars.ARABIC_LAM) {
        lastChar = ch;
        lastPos = i;
        insertPos = sb.length;
      }

      if (lastChar == _BidiChars.ARABIC_LAM) {
        if (letterForms[lastPos] == LetterForm.medial) {
          switch (ch) {
            case _BidiChars.ARABIC_ALEF:
              sb[insertPos] = _BidiChars.ARABIC_LAM_ALEF_FINAL;
              finishLamAlef();
              continue;

            case _BidiChars.ARABIC_ALEF_MADDA_ABOVE:
              sb[insertPos] = _BidiChars.ARABIC_LAM_ALEF_MADDA_ABOVE_FINAL;
              finishLamAlef();
              continue;

            case _BidiChars.ARABIC_ALEF_HAMZA_ABOVE:
              sb[insertPos] = _BidiChars.ARABIC_LAM_ALEF_HAMZA_ABOVE_FINAL;
              finishLamAlef();
              continue;

            case _BidiChars.ARABIC_ALEF_HAMZA_BELOW:
              sb[insertPos] = _BidiChars.ARABIC_LAM_ALEF_HAMZA_BELOW_FINAL;
              finishLamAlef();
              continue;
          }
        } else if (letterForms[lastPos] == LetterForm.initial) {
          switch (ch) {
            case _BidiChars.ARABIC_ALEF:
              sb[insertPos] = _BidiChars.ARABIC_LAM_ALEF_ISOLATED;
              finishLamAlef();
              continue;

            case _BidiChars.ARABIC_ALEF_MADDA_ABOVE:
              sb[insertPos] = _BidiChars.ARABIC_LAM_ALEF_MADDA_ABOVE_ISOLATED;
              finishLamAlef();
              continue;

            case _BidiChars.ARABIC_ALEF_HAMZA_ABOVE:
              sb[insertPos] = _BidiChars.ARABIC_LAM_ALEF_HAMZA_ABOVE_ISOLATED;
              finishLamAlef();
              continue;

            case _BidiChars.ARABIC_ALEF_HAMZA_BELOW:
              sb[insertPos] = _BidiChars.ARABIC_LAM_ALEF_HAMZA_BELOW_ISOLATED;
              finishLamAlef();
              continue;
          }
        }
      }

      sb.add(_getCharacterByLetterForm(ch, letterForms[i]));
    }

    return sb;
  }

  /// Target.
  final List<int> text;

  /// Lengths.
  final List<int> lengths;

  /// Has Persian Characters.
  final bool hasPersian;

  /// Has Nonspacing Mark.
  final bool hasNonspacingMark;
}

int _getPairwiseComposition(int first, int second) {
  if (first < 0 || first > 0xFFFF || second < 0 || second > 0xFFFF) {
    return _BidiChars.notAChar;
  }

  return compose(String.fromCharCodes([first, second]));
}

// 3.3.1 The Paragraph Level
// P2 - In each paragraph, find the first character of type L, AL, or R.
// P3 - If a character is found in P2 and it is of type AL or R, then
// set the paragraph embedding level to one; otherwise, set it to zero.
int _calculateEmbeddingLevel(Normalization n) {
  int embeddingLevel = 0;
  for (var c in n.text) {
    final cType = getCharacterType(c);
    if (cType == CharacterType.rtl || cType == CharacterType.al) {
      embeddingLevel = 1;
      break;
    } else if (cType == CharacterType.ltr) {
      break;
    }
  }

  return embeddingLevel;
}

/// 3.3.3 Resolving Weak Types
void _resolveWeakTypes(
  List<_CharData> textData,
  int start,
  int limit,
  CharacterType sor,
  CharacterType eor,
  bool hasPersian,
  bool hasNSMs,
) {
  // TODO - all these repeating runs seems somewhat unefficient...
  // TODO - rules 2 and 7 are the same, except for minor parameter changes...

  // W1. Examine each nonspacing mark (NSM) in the level run, and change the type of the NSM to the type of the previous character. If the NSM is at the start of the level run, it will get the type of sor.
  if (hasNSMs) {
    CharacterType preceedingCharacterType = sor;
    for (int i = start; i < limit; ++i) {
      CharacterType t = textData[i].type;
      if (t == CharacterType.nonspacingMark) {
        textData[i].type = preceedingCharacterType;
      } else {
        preceedingCharacterType = t;
      }
    }
  }

  // W2. Search backward from each instance of a European number until the first strong type (R, L, AL, or sor) is found. If an AL is found, change the type of the European number to Persian number.

  var tW2 = CharacterType.en;
  for (int i = start; i < limit; ++i) {
    if (textData[i].type == CharacterType.ltr ||
        textData[i].type == CharacterType.rtl) {
      tW2 = CharacterType.en;
    } else if (textData[i].type == CharacterType.al) {
      tW2 = CharacterType.an;
    } else if (textData[i].type == CharacterType.en) {
      textData[i].type = tW2;
    }
  }

  // W3. Change all ALs to R.
  if (hasPersian) {
    for (int i = start; i < limit; ++i) {
      if (textData[i].type == CharacterType.al) {
        textData[i].type = CharacterType.rtl;
      }
    }
  }

  // W4. A single European separator between two European numbers changes to a European number. A single common separator between two numbers of the same type changes to that type.

  // Since there must be values on both sides for this rule to have an
  // effect, the scan skips the first and last value.
  //
  // Although the scan proceeds left to right, and changes the type values
  // in a way that would appear to affect the computations later in the scan,
  // there is actually no problem.  A change in the current value can only
  // affect the value to its immediate right, and only affect it if it is
  // ES or CS.  But the current value can only change if the value to its
  // right is not ES or CS.  Thus either the current value will not change,
  // or its change will have no effect on the remainder of the analysis.

  for (int i = start + 1; i < limit - 1; ++i) {
    if (textData[i].type == CharacterType.es ||
        textData[i].type == CharacterType.commonNumberSeparator) {
      CharacterType prevSepType = textData[i - 1].type;
      CharacterType succSepType = textData[i + 1].type;
      if (prevSepType == CharacterType.en && succSepType == CharacterType.en) {
        textData[i].type = CharacterType.en;
      } else if (textData[i].type == CharacterType.commonNumberSeparator &&
          prevSepType == CharacterType.an &&
          succSepType == CharacterType.an) {
        textData[i].type = CharacterType.an;
      }
    }
  }

  // W5. A sequence of European terminators adjacent to European numbers changes to all European numbers.
  for (int i = start; i < limit; ++i) {
    if (textData[i].type == CharacterType.et) {
      // locate end of sequence
      int runstart = i;
      int runlimit =
          _findRunLimit(textData, runstart, limit, [CharacterType.et]);

      // check values at ends of sequence
      CharacterType t = runstart == start ? sor : textData[runstart - 1].type;

      if (t != CharacterType.en) {
        t = runlimit == limit ? eor : textData[runlimit].type;
      }

      if (t == CharacterType.en) {
        _setTypes(textData, runstart, runlimit, CharacterType.en);
      }

      // continue at end of sequence
      i = runlimit;
    }
  }

  // W6. Otherwise, separators and terminators change to Other Neutral.
  for (int i = start; i < limit; ++i) {
    CharacterType t = textData[i].type;
    if (t == CharacterType.es ||
        t == CharacterType.et ||
        t == CharacterType.commonNumberSeparator) {
      textData[i].type = CharacterType.otherNeutrals;
    }
  }

  // W7. Search backward from each instance of a European number until the first strong type (R, L, or sor) is found.
  //     If an L is found, then change the type of the European number to L.

  CharacterType tW7 =
      sor == CharacterType.ltr ? CharacterType.ltr : CharacterType.en;
  for (int i = start; i < limit; ++i) {
    if (textData[i].type == CharacterType.rtl) {
      tW7 = CharacterType.en;
    } else if (textData[i].type == CharacterType.ltr) {
      tW7 = CharacterType.ltr;
    } else if (textData[i].type == CharacterType.en) {
      textData[i].type = tW7;
    }
  }
}

/// 3.3.4 Resolving Neutral Types
void _resolveNeutralTypes(
  List<_CharData> textData,
  int start,
  int limit,
  CharacterType sor,
  CharacterType eor,
  int level,
) {
  // N1. A sequence of neutrals takes the direction of the surrounding strong text if the text on both sides has the same direction.
  //     European and Persian numbers act as if they were R in terms of their influence on neutrals.
  //     Start-of-level-run (sor) and end-of-level-run (eor) are used at level run boundaries.
  // N2. Any remaining neutrals take the embedding direction.

  for (int i = start; i < limit; ++i) {
    CharacterType t = textData[i].type;
    if (t == CharacterType.whitespace ||
        t == CharacterType.otherNeutrals ||
        t == CharacterType.separator ||
        t == CharacterType.segmentSeparator) {
      // find bounds of run of neutrals
      int runstart = i;
      int runlimit = _findRunLimit(
        textData,
        runstart,
        limit,
        [
          CharacterType.separator,
          CharacterType.segmentSeparator,
          CharacterType.whitespace,
          CharacterType.otherNeutrals
        ],
      );

      // determine effective types at ends of run
      CharacterType leadingType;
      CharacterType trailingType;

      if (runstart == start) {
        leadingType = sor;
      } else {
        leadingType = textData[runstart - 1].type;
        if (leadingType == CharacterType.an ||
            leadingType == CharacterType.en) {
          leadingType = CharacterType.rtl;
        }
      }

      if (runlimit == limit) {
        trailingType = eor;
      } else {
        trailingType = textData[runlimit].type;
        if (trailingType == CharacterType.an ||
            trailingType == CharacterType.en) {
          trailingType = CharacterType.rtl;
        }
      }

      CharacterType resolvedType;
      if (leadingType == trailingType) {
        // Rule N1.
        resolvedType = leadingType;
      } else {
        // Rule N2.
        // Notice the embedding level of the run is used, not
        // the paragraph embedding level.
        resolvedType = _typeForLevel(level);
      }

      _setTypes(textData, runstart, runlimit, resolvedType);

      // skip over run of (former) neutrals
      i = runlimit;
    }
  }
}

/// 3.3.5 Resolving Implicit Levels
void _resolveImplicitTypes(
  List<_CharData> textData,
  int start,
  int limit,
  int level,
) {
  // I1. For all characters with an even (left-to-right) embedding direction, those of type R go up one level and those of type AN or EN go up two levels.
  // I2. For all characters with an odd (right-to-left) embedding direction, those of type L, EN or AN go up one level.

  if ((level & 1) == 0) // even level
  {
    for (int i = start; i < limit; ++i) {
      CharacterType t = textData[i].type;
      // Rule I1.
      if (t == CharacterType.rtl) {
        textData[i].embeddingLevel += 1;
      } else if (t == CharacterType.an || t == CharacterType.en) {
        textData[i].embeddingLevel += 2;
      }
    }
  } else // odd level
  {
    for (int i = start; i < limit; ++i) {
      CharacterType t = textData[i].type;
      // Rule I2.
      if (t == CharacterType.ltr ||
          t == CharacterType.an ||
          t == CharacterType.en) {
        textData[i].embeddingLevel += 1;
      }
    }
  }
}

/// 3.4 Reordering Resolved Levels
void _reorderString(List<_CharData> textData, int embeddingLevel) {
  //L1. On each line, reset the embedding level of the following characters to the paragraph embedding level:
  //    1. Segment separators,
  //    2. Paragraph separators,
  //    3. Any sequence of whitespace characters preceding a segment separator or paragraph separator, and
  //    4. Any sequence of white space characters at the end of the line.

  int l1Start = 0;
  for (int i = 0; i < textData.length; ++i) {
    if (textData[i].type == CharacterType.segmentSeparator ||
        textData[i].type == CharacterType.separator) {
      for (int j = l1Start; j <= i; ++j) {
        textData[j].embeddingLevel = embeddingLevel;
      }
    }

    if (textData[i].type != CharacterType.whitespace) {
      l1Start = i + 1;
    }
  }
  for (int j = l1Start; j < textData.length; ++j) {
    textData[j].embeddingLevel = embeddingLevel;
  }

  // L2. From the highest level found in the text to the lowest odd level on each
  //     line, including intermediate levels not actually present in the text,
  //     reverse any contiguous sequence of characters that are at that level or
  //     higher.
  int highest = 0;
  int lowestOdd = 63;
  for (_CharData cd in textData) {
    if (cd.embeddingLevel > highest) highest = cd.embeddingLevel;
    if ((cd.embeddingLevel & 1) == 1 && cd.embeddingLevel < lowestOdd) {
      lowestOdd = cd.embeddingLevel;
    }
  }

  for (var el = highest; el >= lowestOdd; --el) {
    for (int i = 0; i < textData.length; ++i) {
      if (textData[i].embeddingLevel >= el) {
        // find range of text at or above this level
        int l2Start = i;
        int limit = i + 1;
        while (
            limit < textData.length && textData[limit].embeddingLevel >= el) {
          ++limit;
        }

        // reverse run
        for (int j = l2Start, k = limit - 1; j < k; ++j, --k) {
          _CharData tempCd = textData[j];
          textData[j] = textData[k];
          textData[k] = tempCd;
        }

        // skip to end of level run
        i = limit;
      }
    }
  }

  // TODO - L3. Combining marks applied to a right-to-left base character will at this point precede their base
  // character. If the rendering engine expects them to follow the base characters in the final display process,
  // then the ordering of the marks and the base character must be reversed.
}

/// L4. A character is depicted by a mirrored glyph if and only if (a) the resolved directionality of that character is R, and (b) the Bidi_Mirrored property value of that character is true.
void _fixMirroredCharacters(List<_CharData> textData) {
  for (int i = 0; i < textData.length; ++i) {
    if ((textData[i].embeddingLevel & 1) == 1) {
      textData[i].char = _getCharacterMirror(textData[i].char);
    }
  }
}

/// Return the limit of the run, starting at index, that includes only resultTypes in [validSet].
/// This checks the value at index, and will return index if that value is not in [validSet].
int _findRunLimit(
  List<_CharData> textData,
  int index,
  int limit,
  List<CharacterType> validSet,
) {
  --index;
  bool found = false;
  while (++index < limit) {
    final t = textData[index].type;
    found = false;
    for (int i = 0; i < validSet.length && !found; ++i) {
      if (t == validSet[i]) found = true;
    }

    if (!found) return index; // didn't find a match in validSet
  }
  return limit;
}

/// Set resultTypes from start up to (but not including) limit to newType.
void _setTypes(
  List<_CharData> textData,
  int start,
  int limit,
  CharacterType newType,
) {
  for (int i = start; i < limit; ++i) {
    textData[i].type = newType;
  }
}
