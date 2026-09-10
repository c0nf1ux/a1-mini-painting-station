#!/usr/bin/env bash
# Slice a print-ready STL to a printer-loadable .3mf using this project's
# corrected profiles. Regenerates the flattened presets every run so an
# edit to overrides.json always takes effect.
#
#   ./print-profiles/slice.sh print-ready/bottle_row.stl
#
# Output lands next to the STL as <name>.gcode.3mf. Real print time and
# filament weight are printed from the sliced gcode header at the end.
set -euo pipefail

STL_IN="${1:?usage: slice.sh <path-to-stl>}"
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORCA="/c/Program Files/OrcaSlicer/orca-slicer.exe"
BBL='C:\Program Files\OrcaSlicer\resources\profiles\BBL'
FLAT="$REPO/print-profiles/flat"

name="$(basename "$STL_IN" .stl)"
out_win="$(cygpath -w "$(dirname "$STL_IN")/$name.gcode.3mf")"

python "$REPO/print-profiles/flatten.py" process  "0.20mm Standard @BBL A1M" "$FLAT/process.json"
python "$REPO/print-profiles/flatten.py" filament "Generic PLA @BBL A1M"     "$FLAT/filament.json"

# Machine preset stays stock — it resolves correctly on its own and a
# flattened one breaks the CLI (see flatten.py docstring).
"$ORCA" "$(cygpath -w "$STL_IN")" \
  --slice 0 \
  --load-settings "$BBL\machine\Bambu Lab A1 mini 0.4 nozzle.json;$(cygpath -w "$FLAT/process.json")" \
  --load-filaments "$(cygpath -w "$FLAT/filament.json")" \
  --export-3mf "$out_win"

echo
echo "sliced -> $out_win"
unzip -p "$out_win" Metadata/plate_1.gcode | grep -E \
  "^; (model printing time|total layer number|filament used \[g\]|nozzle_temperature|curr_bed_type|brim_type) =|^; model printing time|^M190 S" \
  | head -10
