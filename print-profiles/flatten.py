#!/usr/bin/env python
"""Flatten an OrcaSlicer preset + its full `inherits` chain into one
standalone JSON with every key resolved and no `inherits` link.

Why this exists: the OrcaSlicer 2.4.2 CLI does NOT reliably resolve a
preset's inheritance chain when you pass a bundled system preset to
`--load-settings` / `--load-filaments`. It silently falls back to bare
program defaults for any key the top-level file doesn't state outright.

Real failure this caused (2026-09-10, bottle_row test print #1):
  - `Generic PLA @BBL A1M` states fan + textured-plate temps only, and
    inherits nozzle_temperature (220) + bed defaults from `Generic PLA
    @base`. The CLI didn't follow that link, so the slice baked
    nozzle_temperature=200 (program default) and curr_bed_type="Cool
    Plate" @ 35C (program default) instead of 220C / textured PEI.
  - On the textured PEI plate actually in use, 35C is far too cold to
    hold a 135mm-long PLA slab. The part peeled off at ~6mm and the
    nozzle dragged it into a bird's nest.

Usage:
  python flatten.py process  "0.20mm Standard @BBL A1M"  out/process.json
  python flatten.py filament "Generic PLA @BBL A1M"      out/filament.json

Overrides for this project's real conditions are applied from
overrides.json (same directory) keyed by kind.

Machine is NOT flattened: the stock nozzle-suffixed machine preset
(`Bambu Lab A1 mini 0.4 nozzle.json`) DOES resolve correctly through the
CLI on its own (verified), and a flattened machine file makes the CLI
exit with a bare "found error" (some key in the merged fdm_machine_common
set is rejected). Pass the stock machine file directly. The one machine
setting we change, `curr_bed_type`, is carried in the process override
instead, which the slicer honours from there.
"""
import json
import os
import sys
import glob

PROFILE_ROOT = r"C:\Program Files\OrcaSlicer\resources\profiles"
BBL = os.path.join(PROFILE_ROOT, "BBL")

# Meta keys that describe the preset itself, not print settings. Dropped
# from the flattened output so the CLI treats it as a plain settings blob.
META_KEYS = {
    "inherits", "from", "setting_id", "filament_id", "instantiation",
    "is_custom_defined", "version", "name",
}


def find_preset(kind, name):
    """kind in {machine, process, filament}. Search BBL first, then the
    whole profile tree, for <name>.json under a matching category dir."""
    for base in (BBL, PROFILE_ROOT):
        hits = glob.glob(os.path.join(base, "**", kind, name + ".json"),
                         recursive=True)
        if hits:
            return hits[0]
    raise FileNotFoundError(f"{kind} preset not found: {name}")


def resolve(kind, name, _seen=None):
    """Return the merged dict for `name` with its full inherits chain
    applied (parent first, child overrides)."""
    _seen = _seen or set()
    if name in _seen:
        raise RuntimeError(f"inherits cycle at {name}")
    _seen.add(name)

    data = json.load(open(find_preset(kind, name), encoding="utf-8"))
    parent = data.get("inherits")
    merged = resolve(kind, parent, _seen) if parent else {}
    for k, v in data.items():
        if k not in META_KEYS:
            merged[k] = v
    return merged


def main():
    kind, name, out_path = sys.argv[1], sys.argv[2], sys.argv[3]
    if kind == "machine":
        sys.exit("machine presets are not flattened - see module docstring; "
                 "pass the stock 'Bambu Lab A1 mini 0.4 nozzle.json' directly")
    flat = resolve(kind, name)
    flat["type"] = kind
    # OrcaSlicer's CLI rejects a settings file with no `from` ("... 's
    # from unsupported"). A flattened, project-owned preset is a user
    # preset by definition.
    flat["from"] = "User"
    flat["name"] = f"{name} (flattened)"

    ov_file = os.path.join(os.path.dirname(__file__), "overrides.json")
    if os.path.exists(ov_file):
        overrides = json.load(open(ov_file, encoding="utf-8")).get(kind, {})
        for k, v in overrides.items():
            flat[k] = v
        if overrides:
            print(f"  applied {len(overrides)} override(s): "
                  f"{', '.join(overrides)}")

    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    json.dump(flat, open(out_path, "w", encoding="utf-8"),
              indent="\t", ensure_ascii=False)
    print(f"  wrote {out_path} ({len(flat)} keys)")


if __name__ == "__main__":
    main()
