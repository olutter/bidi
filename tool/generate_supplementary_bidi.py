#!/usr/bin/env python3
"""Generate supplementary classes from Unicode 15.1 DerivedBidiClass.txt."""

import base64
from pathlib import Path
import sys

CLASS_TO_INDEX = {
    "L": 0, "R": 4, "AL": 5, "EN": 12, "AN": 15,
    "NSM": 17, "ON": 22, "ET": 14, "BN": 18,
    "ES": 13, "CS": 16, "WS": 21, "S": 20, "B": 19,
}
DEFAULT_CLASSES = {
    "Left_To_Right": "L", "Right_To_Left": "R",
    "Arabic_Letter": "AL", "European_Terminator": "ET",
}


def main():
    if len(sys.argv) != 2:
        raise SystemExit("Usage: generate_supplementary_bidi.py DerivedBidiClass.txt")
    data = Path(sys.argv[1]).read_text(encoding="utf-8")
    if not data.startswith("# DerivedBidiClass-15.1.0.txt"):
        raise SystemExit("Expected Unicode 15.1.0 DerivedBidiClass.txt")
    classes = ["L"] * 0x110000

    # @missing rules apply before explicit records, including unassigned scalars.
    for defaults in (True, False):
        for line in data.splitlines():
            if defaults:
                if not line.startswith("# @missing:"):
                    continue
                line = line.split(":", 1)[1]
            else:
                line = line.split("#", 1)[0].strip()
                if not line:
                    continue
            code_range, bidi_class = (part.strip() for part in line.split(";"))
            bidi_class = DEFAULT_CLASSES.get(bidi_class, bidi_class)
            bounds = code_range.split("..")
            start, end = int(bounds[0], 16), int(bounds[-1], 16)
            classes[start:end + 1] = [bidi_class] * (end - start + 1)

    records = bytearray()
    start = 0x10000
    for limit in range(start + 1, 0x110001):
        if limit != 0x110000 and classes[limit] == classes[start]:
            continue
        if classes[start] != "L":
            records.extend(start.to_bytes(3, "big"))
            records.extend((limit - 1).to_bytes(3, "big"))
            records.append(CLASS_TO_INDEX[classes[start]])
        start = limit
    encoded = base64.b64encode(records).decode("ascii")
    print(f"Unicode 15.1.0, {len(records) // 7} ranges")
    for offset in range(0, len(encoded), 120):
        print("    '" + encoded[offset:offset + 120] + "'")


if __name__ == "__main__":
    main()
