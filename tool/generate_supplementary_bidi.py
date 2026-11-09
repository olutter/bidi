#!/usr/bin/env python3
"""Regenerate supplementary bidi class ranges from Python's Unicode database.

Run using a Python interpreter with unicodedata.unidata_version == '15.1.0'.
The output is base64 for lib/src/supplementary_bidi_types.dart. The table
stores only classes that differ from Unicode's default L property.
"""

import base64
import unicodedata

CLASS_TO_INDEX = {
    "L": 0, "R": 4, "AL": 5, "EN": 12, "AN": 15,
    "NSM": 17, "ON": 22, "ET": 14, "BN": 18,
    "ES": 13, "CS": 16, "WS": 21, "S": 20, "B": 19,
}


def main():
    if unicodedata.unidata_version != "15.1.0":
        raise SystemExit(
            "Expected Unicode 15.1.0, found " + unicodedata.unidata_version
        )

    ranges = []
    previous = None
    for code_point in range(0x10000, 0x110000):
        bidi_class = unicodedata.bidirectional(chr(code_point)) or "L"
        if bidi_class != previous:
            if previous is not None and previous != "L":
                ranges.append((start, code_point - 1, previous))
            start = code_point
            previous = bidi_class
    if previous != "L":
        ranges.append((start, 0x10FFFF, previous))

    records = bytearray()
    for start, end, bidi_class in ranges:
        records.extend(start.to_bytes(3, "big"))
        records.extend(end.to_bytes(3, "big"))
        records.append(CLASS_TO_INDEX[bidi_class])
    encoded = base64.b64encode(records).decode("ascii")
    print(f"Unicode 15.1.0, {len(ranges)} ranges")
    for offset in range(0, len(encoded), 120):
        print("    '" + encoded[offset:offset + 120] + "'")


if __name__ == "__main__":
    main()
