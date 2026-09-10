# Print profiles

Corrected OrcaSlicer settings for slicing this project's modules from the
CLI. Exists because of a real failed print — read the post-mortem below
before touching `overrides.json`.

## Use it

```bash
./print-profiles/slice.sh print-ready/bottle_row.stl
```

Regenerates the flattened presets from `overrides.json`, slices with the
stock A1 mini machine preset, writes `<name>.gcode.3mf` next to the STL,
and prints the real time / filament / bed temp from the gcode header.

Then send it:

```bash
python scripts/send_to_printer.py print-ready/bottle_row.gcode.3mf
```

## Files

| File | Tracked | Purpose |
|---|---|---|
| `flatten.py` | yes | Resolves an OrcaSlicer preset's full `inherits` chain into one flat JSON, then applies `overrides.json`. |
| `overrides.json` | yes | Every deliberate deviation from resolved-stock Bambu settings, with a reason in the table below. **This is the source of truth.** |
| `slice.sh` | yes | One-command flatten + slice wrapper. |
| `flat/` | no (gitignored) | Regenerated every run. Never hand-edit. |

## Why flattening is needed

The OrcaSlicer 2.4.2 CLI does **not** reliably follow a bundled system
preset's `inherits` chain when the preset is passed to `--load-settings` /
`--load-filaments`. It keeps only the keys stated outright in the
top-level file and fills everything else from bare program defaults.

`Generic PLA @BBL A1M` states fan speeds and textured-plate temps and
inherits the rest from `Generic PLA @base`. `0.20mm Standard @BBL A1M`
inherits nearly everything from `fdm_process_single_0.20`. Passed raw to
the CLI, both collapsed to defaults.

The **machine** preset (`Bambu Lab A1 mini 0.4 nozzle.json`) is the
exception — it resolves fine on its own. A *flattened* machine file makes
the CLI exit with a bare "found error" (a key in the merged
`fdm_machine_common` set is rejected), so `slice.sh` passes the stock
machine file and carries the one machine setting we change,
`curr_bed_type`, in the process override instead.

## Post-mortem: bottle_row test print #1 (2026-09-10)

**Symptom:** print detached from the textured PEI plate at ~6 mm / ~30
layers, nozzle dragged it around, ~5 h of filament went into a bird's
nest before it was caught.

**Root cause:** the CLI slice silently used program defaults instead of
the Generic PLA / 0.20mm Standard values:

| Setting | Bad slice (defaults) | Should have been | Effect |
|---|---|---|---|
| `curr_bed_type` | Cool Plate | Textured PEI Plate | picked the wrong per-plate bed temp |
| bed temp (first layer) | 35 °C | 65 °C | far too cold to hold a 135 mm PLA slab; it peeled and popped off |
| `nozzle_temperature` | 200 °C | 220 °C | weak first-layer weld |
| `brim_type` / width | auto_brim / 0 | outer_only / 5 mm | no brim on a long flat part = nothing resisting the peel |
| wall / infill speeds | generic-slow | A1 mini tuned | not a failure cause, but why the bad slice estimated 7 h 49 m vs the corrected 3 h 03 m |

**Not the cause:** the model. `bottle_row.stl` is a watertight single
solid, flat-bottomed, no overhangs or bridges, no support needed. The
whole-part detachment (vs. a local sag) is an adhesion signature, not a
geometry one.

**Fix:** everything in `overrides.json` below, plus wash the plate with
dish soap + warm water occasionally (IPA alone leaves a PLA-release film
over time).

## Current overrides

| Key | Value | Reason |
|---|---|---|
| `curr_bed_type` | `Textured PEI Plate` | The plate actually on the printer. Nothing in the stock chain sets this, so the CLI defaulted it to Cool Plate. |
| `brim_type` | `outer_only` | Force a brim. `auto_brim` added none to a 135×45 footprint; the part still peeled. Snaps off the plinth edge cleanly. |
| `brim_width` | `5` | Enough bite for a part this long without wasting plate. |
| `brim_object_gap` | `0.1` | Tight enough to hold, loose enough to release. |

Nozzle 220 °C and bed 65 °C are **not** overridden — they are the correct
resolved values from `Generic PLA @base`, which `flatten.py` now restores
by following the chain the CLI skipped.

## Filament note

Spool in use is generic SUNLU white PLA 1 kg (label range ~190–220 °C),
no Bambu-calibrated profile. `Generic PLA @BBL A1M` at 220 °C is within
range. If surface finish ever matters, run Bambu's flow-rate + temp
calibration for this spool and fold the results in here as a
`filament` override block.
