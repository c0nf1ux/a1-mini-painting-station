# Tiered bottle rack — design spec

## Context

The original vision for this project (see `README.md` / project memory) was
to segment Polvak3D's "Z-Desk Paint Master" — a modular painting-station
design built for full-size print beds — into pieces small enough for the
A1 mini's 180×180×180mm bed, joined by a shared connector. What got built
in Tasks 4–5 (`bottle_row.scad`, `water_reservoir.scad`,
`scrubber_insert.scad`) instead ended up as new, plain, single-row/
single-basin geometry that doesn't carry over the reference's actual
functional bones: a stepped/tiered bottle layout so every row's label is
visible, a combined scrub+water unit, dense hole-grid tool holders.

This spec covers the **first corrected module**: a tiered bottle rack,
replacing `modules/bottle_row.scad` in place. Scope is explicitly the
*functional* layout (stepped rows, real bottle-fit dimensions) — not
Polvak3D's ornamental surface engraving or two-tone color scheme, which
the user has said they don't want copied (no AMS/4-color feeder anyway,
and copying specific ornamental expression is the one part of that
reference that's actually copyright-sensitive; the functional layout
itself is not — useful-article features aren't protected).

The water reservoir + scrubber insert printed today are being kept as a
throwaway alpha (already fixed, printing, and useful for what they taught
about the plinth/connector) — they get redesigned as a combined
scrub+trough unit in a later spec, not this one.

## Goals

- Replace the flat single row of 4 wells with a 2-row "stadium" layout:
  back row's collar taller than the front row's, so both rows' bottle
  labels are visible from the front.
- Use real, sourced bottle dimensions for the dropper-bottle family
  (Vallejo, Army Painter, AK Interactive, Scale75, Reaper, Two Thin
  Coats) rather than a single-brand proxy.
- Fix a known open TODO while touching this file: wells currently reuse
  `tab_clearance` (0.175mm, tuned for the connector snap-fit) as their
  bottle-fit clearance. A bottle pulled in/out by hand needs real
  clearance, same fix already applied to `scrubber_insert.scad`'s
  `insert_clearance`.
- Stay within the A1 mini's bed — no cross-plate splitting needed for
  this module.

## Non-goals

- Citadel-pot compatibility. Citadel's 30-34mm-wide flip-top pots are a
  genuinely different bottle shape (short and wide vs. tall and narrow)
  from the dropper-bottle family; forcing one well to fit both would
  compromise the fit for whichever shape didn't drive the design. This
  becomes its own future module once real Citadel pots are on hand to
  measure (see docs/sources.md entry below).
- Ornamental surface engraving / two-tone color scheme — explicitly
  descoped by the user.
- Redesigning the water reservoir / scrubber insert — separate spec.

## Sourced dimensions

**Dropper-bottle family (Vallejo, Army Painter, AK Interactive, Scale75,
Reaper MSP, Two Thin Coats)** — LITKO Game Accessories (a company that
manufactures paint racks) publishes a fit table: these all fit the same
**26mm** hole, bottles measuring "about 25mm across." This is a stronger
source than a single retail listing — it's a manufacturer's actual
tolerance-inclusive number, and it lands inside the 24.5–26.5mm range
already found in this project's earlier cross-referencing of 6+
MakerWorld/retail designs (`docs/PROJECT-SPEC.md`).
Source: https://litko.net/pages/paint-racks (fetched via Firecrawl
2026-09-11 after a 403 on a plain fetch).

**Citadel pots (for the future module, not used here):** ~30mm diameter
across all lines (LITKO cites a 34mm rack hole for these); height varies
by line — Base/Layer ≈32mm, Dry/Technical ≈35mm, Contrast is a real
outlier at ≈45mm.
Source: https://cypaint.com/article/what-are-the-dimensions-of-citadel-paint-pot
(fetched via Firecrawl 2026-09-11 after a 403 on a plain fetch; this
corrects an earlier bad AI-summarized claim that Contrast pots were the
same height as Base pots).

## config.scad changes

- `bottle_diameter`: `28` → `26`, tag changes from a single-listing
  SOURCE proxy to the LITKO manufacturer citation above.
- New `well_clearance = 0.75` (SOURCE: community guidance range is
  0.5–1mm for a hand-inserted bottle, same reasoning already used for
  `scrubber_insert.scad`'s `insert_clearance`; 0.75mm is the midpoint).
  Wells use this instead of `tab_clearance` going forward.

## Module geometry (`modules/bottle_row.scad`, updated in place)

Two rows of 4 wells each (8 bottles total), reusing `lib/connector.scad`
unmodified — the tab/slot edges don't change.

**Correction from the approach discussion:** no angled/sloped step face
is actually needed for printability. A step between two flat-topped
rectangular collars is just two straight vertical prisms of different
heights sitting side by side — every surface is either vertical (fully
supported from below) or a horizontal ledge resting on solid material.
The 8° well tilt (unchanged, still applies per-well for the
label-forward lean) was the thing that needed angling in the original
file; the row-height step itself doesn't.

Derived values (computed from primaries, not hardcoded):
- `well_dia = bottle_diameter + 2*well_clearance` = 27.5mm
- `footprint_x = 135` (unchanged — already bed-fit-validated for 4
  wells at `well_spacing = 31`, which now leaves a slightly more
  generous 3.5mm divider than before since `well_dia` shrank from
  28.35mm to 27.5mm)
- `row_divider = 3.5` (matches the per-column divider thickness above,
  for consistency)
- `row_margin = (footprint_y - 2*well_dia - row_divider) / 2` — front
  and back edge margin, solved from a target `footprint_y = 76`, giving
  ≈8.75mm (close to the original single-row design's 8.325mm edge
  margin)
- `front_collar_height = 25` (unchanged — this is the one number
  that's already physically fit-tested, from the first bottle_row
  print)
- `row_step = 20` (**DECIDED, not measured** — enough that a back-row
  bottle's label clears a front-row bottle's shoulder/cap; same
  provenance convention as `collar_height` itself. Adjust after a
  physical fit-test, don't treat as final.)
- `back_collar_height = front_collar_height + row_step` = 45mm
- `total_height = base_plinth_height + back_collar_height` = 53mm

Resulting footprint: 135 × 76 × 53mm — comfortably inside the 180mm bed
on every axis, no scaffolding or cross-plate splitting required.

Wells keep the existing 8° `well_angle` backward tilt per row (both
rows use the same angle; only the collar height differs between rows).

## Testing / verification plan

Same pipeline already proven on this project:
1. `openscad --render` + `scripts/check_module.py --watertight` on the
   new geometry.
2. Render PNGs from multiple angles, visually confirm: no merged wells,
   real well depth, no repeat of the connector/well-overlap bug just
   fixed in `water_reservoir.scad` (this module's wells sit far from
   the slot edge, same as the current file, so that specific bug class
   doesn't apply here — but re-check with the same overlap math as a
   sanity pass since this is a geometry change).
3. `check_module.py --bed-fit` against 135×76×53mm.
4. Slice via `print-profiles/slice.sh`, `check_slice.py`, send to
   printer.
5. Physical fit-test once printed: real dropper bottles in both rows,
   confirm labels are visible on the back row, confirm `row_step` and
   `well_clearance` feel right — adjust and reprint if not, same as the
   original bottle_row's `collar_height`/`tab_clearance` tuning.

## Open items carried forward (not blocking this module)

- Citadel-pot module: needs real Citadel pots in hand to measure before
  design, per the user's own stated plan (buy bottles per brand, send
  fit photos, then build brand-specific modules).
- Water reservoir / scrubber insert redesign as a combined scrub+trough
  unit: separate spec, after this module's fit-test.
- Brush holder (hole grid) and marker/pen holder (hole grid): later
  modules in the same "commodity organizer bones" direction, not
  started yet.
