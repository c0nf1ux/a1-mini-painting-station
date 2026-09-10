#!/usr/bin/env python
"""Sanity-check a sliced .3mf's gcode header before sending it to the
printer. Catches the exact class of failure that wrecked bottle_row test
print #1 (wrong bed type / cold bed / no brim from unresolved presets).

  python print-profiles/check_slice.py print-ready/bottle_row.gcode.3mf

Exit 0 = all checks pass. Exit 1 = something is off, don't print it.
"""
import sys
import zipfile

# (regex-free) substring -> (predicate, human description) checks against
# the CONFIG_BLOCK comment lines in the plate gcode.
EXPECT = {
    "curr_bed_type": (lambda v: v == "Textured PEI Plate",
                      "must be 'Textured PEI Plate' (the plate in use)"),
    "nozzle_temperature": (lambda v: 200 <= int(v.split(",")[0]) <= 230,
                           "PLA nozzle temp should be 200-230 C"),
    "brim_type": (lambda v: v in ("outer_only", "outer_and_inner"),
                  "a brim must be forced on (long flat footprint)"),
    "brim_width": (lambda v: float(v) >= 3,
                   "brim width should be >= 3 mm"),
}


def main():
    path = sys.argv[1]
    with zipfile.ZipFile(path) as z:
        gcode = z.read("Metadata/plate_1.gcode").decode("utf-8", "replace")

    cfg = {}
    bed_wait = None
    for line in gcode.splitlines():
        if line.startswith("; ") and " = " in line:
            k, v = line[2:].split(" = ", 1)
            cfg[k.strip()] = v.strip()
        elif line.startswith("M190 S") and bed_wait is None:
            bed_wait = int(line[6:].split(";")[0].split()[0])

    ok = True
    for key, (pred, desc) in EXPECT.items():
        val = cfg.get(key, "<missing>")
        try:
            passed = val != "<missing>" and pred(val)
        except (ValueError, IndexError):
            passed = False
        print(f"  [{'ok' if passed else 'FAIL'}] {key} = {val}  ({desc})")
        ok &= passed

    bed_ok = bed_wait is not None and bed_wait >= 55
    print(f"  [{'ok' if bed_ok else 'FAIL'}] first M190 = {bed_wait} C  "
          f"(textured PEI + PLA needs >= 55 C to hold)")
    ok &= bed_ok

    print(f"\n{'PASS' if ok else 'FAIL'}: {path}")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
