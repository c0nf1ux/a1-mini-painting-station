# Tiered Bottle Rack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace `modules/bottle_row.scad`'s flat single row of 4 bottle wells with a 2-row "stadium" layout (back row's collar taller than the front row's) using real, manufacturer-sourced dropper-bottle dimensions, so both rows' labels stay visible — the first module in this project's course-correction back toward its original "segment a real modular painting-station design" vision.

**Architecture:** Two flat-topped rectangular collar blocks of different heights, side by side in Y, built on the existing shared `base_plinth`/connector system from `lib/connector.scad` (unmodified). No new connector geometry, no angled/sloped faces — a step between two straight vertical prisms needs neither. `config.scad` gains one corrected constant (`bottle_diameter`) and one new constant (`well_clearance`).

**Tech Stack:** OpenSCAD 2021.01 (`openscad` wrapper on PATH), Python 3.12 + `trimesh` for STL verification, OrcaSlicer 2.4.2 via this repo's `print-profiles/slice.sh` wrapper, `scripts/send_to_printer.py` for direct FTPS upload.

**Spec:** `docs/superpowers/specs/2026-09-11-tiered-bottle-rack-design.md`

## Global Constraints

- Bed limit: every axis of the rendered STL must be ≤180mm (A1 mini bed) — checked automatically by `scripts/check_module.py` on every run, not an opt-in flag.
- `bottle_diameter` = 26mm (LITKO manufacturer fit table, covers Vallejo/Army Painter/AK Interactive/Scale75/Reaper/Two Thin Coats dropper bottles) — do not reuse the old 28mm single-listing proxy.
- Wells use a new `well_clearance` = 0.75mm constant, never `tab_clearance` (0.175mm is tuned for the connector's printed-in-place snap-fit, not a bottle pulled in/out by hand).
- `front_collar_height` stays 25mm (already physically fit-tested from the original single-row print) — do not change it as part of this work.
- `row_step` = 20mm is DECIDED, not measured — implement it as written, but the comment in code must say so, and the physical fit-test at the end of this plan is the point where it gets corrected if wrong.
- No angled/sloped step face between the two collar heights — two straight vertical prisms of different heights need no draft angle. Do not add one.
- Final module footprint must be 135 × 76 × 53mm exactly (per the spec's derivation) — if your numbers land anywhere else, the arithmetic is wrong; stop and recheck against the spec before proceeding.

---

## Task 1: Update `config.scad` with the corrected bottle diameter and new well clearance constant

**Files:**
- Modify: `config.scad:12-16`
- Modify: `config_test.scad:9` (add assertion for the new constant)

**Interfaces:**
- Produces: `bottle_diameter` (existing name, corrected value 26), `well_clearance` (new constant, 0.75) — both consumed by Task 2's `modules/bottle_row.scad`.

- [ ] **Step 1: Update `bottle_diameter` and add `well_clearance` in `config.scad`**

Replace the "Physical measurements" section (currently lines 12-16) with:

```openscad
// Physical measurements
bottle_diameter = 26;    // mm — SOURCE: LITKO Game Accessories manufacturer
                          // fit table (litko.net/pages/paint-racks) — 26mm
                          // hole fits Vallejo 17-18ml, Army Painter
                          // Warpaints/Fanatic/Speedpaint, AK Interactive 3rd
                          // Gen, Scale75, Reaper MSP, Two Thin Coats
                          // (bottles "about 25mm across"). Replaces an
                          // earlier 28mm single-listing (Vallejo 20ml) proxy.
well_clearance  = 0.75;  // mm per side — SOURCE: community guidance range
                          // 0.5-1mm for a bottle pulled in/out by hand, vs.
                          // tab_clearance's 0.15-0.2mm which is tuned for a
                          // printed-in-place snap connector. Wells use this,
                          // never tab_clearance.
handle_width    = 10;    // mm — MEASURED: user's brush set
brush_length    = 220;   // mm — MEASURED: user's brush set
marker_diameter = undef; // MEASURE: no marker product selected yet — blocks modules/marker_holders.scad
```

- [ ] **Step 2: Add the new constant's assertion to `config_test.scad`**

In `config_test.scad`, after the existing `assert(is_num(bottle_diameter));` line, add:

```openscad
assert(is_num(well_clearance));
```

- [ ] **Step 3: Run the config test to verify it still parses and passes**

Run: `openscad -o /tmp/a1mps-check/config_test.stl --render config_test.scad`
Expected output includes `ECHO: "config.scad OK"` and no `ERROR`/`assertion failed` lines. Exit code 0.

- [ ] **Step 4: Commit**

```bash
git add config.scad config_test.scad
git commit -m "$(cat <<'EOF'
Correct bottle_diameter to sourced 26mm, add well_clearance constant

LITKO's manufacturer fit table (a company that actually makes paint
racks) covers Vallejo/Army Painter/AK Interactive/Scale75/Reaper/Two
Thin Coats at 26mm - a stronger source than the old single-listing
28mm proxy. well_clearance (0.75mm) replaces tab_clearance for wells:
a hand-inserted bottle needs real clearance, not a snap-fit tolerance.

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01L569pvLm68Jp9P34qvsfgf
EOF
)"
```

---

## Task 2: Rewrite `modules/bottle_row.scad` as a 2-row tiered rack

**Files:**
- Modify: `modules/bottle_row.scad` (full rewrite)

**Interfaces:**
- Consumes: `bottle_diameter`, `well_clearance` from Task 1's `config.scad`; `tab_width`, `tab_depth`, `tab_clearance`, `base_plinth_height` from `config.scad` (unchanged); `base_plinth()`, `edge_tab()`, `edge_slot()` from `lib/connector.scad` (unchanged, do not modify that file).
- Produces: `modules/bottle_row.scad`'s rendered geometry — footprint 135×76×53mm, connector edges at the same positions as before (slot at x=0, tab at x=footprint_x), consumed by nothing else in this plan but must stay compatible with `lib/connector.scad`'s tab/slot geometry for future modules to mate against.

- [ ] **Step 1: Replace the full contents of `modules/bottle_row.scad`**

```openscad
// modules/bottle_row.scad — 2-row "stadium" tiered bottle rack: back
// row's collar is taller than the front row's so both rows' labels
// stay visible from the front, matching the functional layout of
// commodity tiered paint racks (see docs/superpowers/specs/2026-09-11-
// tiered-bottle-rack-design.md) rather than a flat single row.
//
// The shared base_plinth is just the connector-alignment floor (per
// docs/PROJECT-SPEC.md: modules share a flush plinth while having
// "differing upper geometry") — wells are cut into two separate collar
// blocks built on top of it, not into the thin plinth itself.
//
// The step between the two collar heights needs NO angled/sloped face:
// two flat-topped rectangular blocks of different heights sitting side
// by side are both just straight vertical prisms — every surface is
// either vertical (backed by solid material) or a horizontal ledge
// resting on solid material below it. Nothing overhangs.
include <../config.scad>
use <../lib/connector.scad>

footprint_x     = 135;  // unchanged from the single-row design — still
                         // fits 4 wells per row at well_spacing below,
                         // still far under the 180mm bed edge.
footprint_y     = 76;   // DECIDED: fits front margin + front well +
                         // row divider + back well + back margin (see
                         // row_margin below) for both rows' depth.
                         // Solved so row_margin lands close to the
                         // original single-row design's ~8.3mm edge
                         // margin.
well_spacing    = 31;   // mm between well centers within a row — must
                         // exceed well_dia (27.5mm at current
                         // bottle_diameter + well_clearance) or
                         // adjacent wells merge into one trough, same
                         // constraint as the original single-row file.
row_divider     = 3.5;  // mm of solid wall between the front and back
                         // well rows — matches the within-row divider
                         // thickness (well_spacing - well_dia) for a
                         // consistent wall thickness throughout.
front_collar_height = 25;  // unchanged — the one number that's already
                             // physically fit-tested, from the original
                             // single-row bottle_row print.
row_step        = 20;   // mm — DECIDED, NOT measured. How much taller
                         // the back row's collar is than the front
                         // row's, so a back-row bottle's label clears a
                         // front-row bottle's shoulder/cap. Adjust
                         // after a physical fit-test, same provenance
                         // convention as front_collar_height itself.
back_collar_height  = front_collar_height + row_step;
well_angle      = 8;    // degrees, both rows tilted back the same
                         // amount — unchanged from the single-row file.
well_dia        = bottle_diameter + 2*well_clearance;
row_margin      = (footprint_y - 2*well_dia - row_divider) / 2;
front_row_y     = row_margin + well_dia/2;
back_row_y      = row_margin + well_dia + row_divider + well_dia/2;
row_split_y     = row_margin + well_dia + row_divider/2;  // where the
                         // front and back collar blocks meet — splits
                         // the divider wall evenly between them.
total_height    = base_plinth_height + back_collar_height;

module bottle_well(x, y, collar_h) {
    // Starts 1mm below the plinth top (clean CSG fusion, same overcut
    // convention as lib/connector.scad) and punches generously past
    // this row's own collar top so the well is genuinely open, not a
    // sealed pocket — the 8deg tilt eats a little of the nominal
    // height, this margin absorbs that rather than computing the exact
    // cosine.
    translate([x, y, base_plinth_height])
        rotate([well_angle, 0, 0])
            translate([0, 0, -1])
                cylinder(h=collar_h + 5, d=well_dia, $fn=48);
}

difference() {
    union() {
        base_plinth(footprint_x, footprint_y, base_plinth_height);
        translate([footprint_x, 0, 0])
            edge_tab(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height);
        translate([0, 0, base_plinth_height])
            cube([footprint_x, row_split_y, front_collar_height]);
        translate([0, row_split_y, base_plinth_height])
            cube([footprint_x, footprint_y - row_split_y, back_collar_height]);
    }
    edge_slot(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height, clearance=tab_clearance);
    for (i = [0:3]) {
        bottle_well(20 + i * well_spacing, front_row_y, front_collar_height);
        bottle_well(20 + i * well_spacing, back_row_y, back_collar_height);
    }
}
```

- [ ] **Step 2: Render to STL and check watertightness + bed-fit**

```bash
mkdir -p /tmp/a1mps-check
openscad -o /tmp/a1mps-check/bottle_row.stl --render modules/bottle_row.scad
python scripts/check_module.py /tmp/a1mps-check/bottle_row.stl --watertight
```

Expected: `bounding box 135.0 x 76.0 x 53.0 mm`, `OK: watertight`, no `FAIL` lines. If the bounding box doesn't read exactly `135.0 x 76.0 x 53.0`, the arithmetic in Step 1 is wrong (edge_tab adds a small amount to the X extent beyond footprint_x — that's expected and already true of the original single-row module; only the Y and Z extents need to match 76.0/53.0 exactly).

- [ ] **Step 3: Point-containment sanity check — confirm the connector slot never touches a well cavity**

This project has twice shipped a module where two CSG cuts overlapped and connected a cavity to the outside (an early bottle_row well-spacing bug, and the water_reservoir connector-slot/well-cavity tunnel fixed 2026-09-11). `check_module.py`'s watertight check does NOT catch this class of bug — a tunnel is still a closed manifold. Run this explicit check every time a module's connector edge and a cavity are anywhere near each other.

`edge_slot()` is centered on the whole edge it's given — here that's `edge_slot(footprint_y, ...)`, so its Y-center is `footprint_y/2 = 38.0`, NOT either row's Y-center. Its cut box spans roughly X:[-0.2, 3.7] (tab_depth + connector.scad's fixed 0.2mm overcut), Y:[33.325, 42.675] (half of `tip_w = tab_width + 2*tab_clearance = 9.35` either side of 38.0), Z:[-0.2, 8.4]. The nearest well is column `i=0` at x=20 in both rows (radius `well_dia/2 = 13.75`); the closest point in the slot's box to that well's center is the box corner (3.7, 33.325) for the front well and (3.7, 42.675) for the back well — both roughly 19.6mm from their well center, comfortably outside the 13.75mm well radius (~5.8mm of solid material between them). Sample a point in that gap:

```bash
python - <<'EOF'
import trimesh
m = trimesh.load("/tmp/a1mps-check/bottle_row.stl")
pts = {
    "between slot and front well, in the connector z-band (should be SOLID)": (4.0, 34.0, 7.5),
    "between slot and back well, in the connector z-band (should be SOLID)":  (4.0, 42.0, 7.5),
    "front well interior (should be void)": (20.0, 22.5, 15.0),
    "back well interior (should be void)":  (20.0, 53.5, 30.0),
}
res = m.contains([list(v) for v in pts.values()])
for (label, pt), inside in zip(pts.items(), res):
    print(f"{label:65s} {pt}: {'SOLID' if inside else 'void/air'}")
EOF
```

Expected: both "between slot and well" points read `SOLID`, both "well interior" points read `void/air`. If any "between" point reads `void/air`, stop — there's a tunnel, don't proceed to slicing. (If you change `well_spacing`, `footprint_y`, `row_divider`, or `tab_depth` from the values in this plan, recompute the slot box and nearest-well distance above before trusting these exact coordinates.)

- [ ] **Step 4: Render PNGs from multiple angles and visually inspect**

```bash
openscad -o /tmp/a1mps-check/bottle_row_iso.png --imgsize=1400,1000 --camera=0,40,20,60,0,25,300 --render modules/bottle_row.scad
openscad -o /tmp/a1mps-check/bottle_row_side.png --imgsize=1400,1000 --camera=-300,38,20,60,38,20 --projection=ortho --render modules/bottle_row.scad
```

Read both PNGs (via the Read tool, resolving the Windows path with `cygpath -w`). Confirm: 8 distinct wells (4 front, 4 back), no merged/overlapping wells, a visible step between the front and back collar heights, no unexpected gaps or holes in the walls.

- [ ] **Step 5: Commit**

```bash
git add modules/bottle_row.scad
git commit -m "$(cat <<'EOF'
Redesign bottle_row.scad as a 2-row tiered stadium rack

Replaces the flat single row of 4 wells with front/back rows at
different collar heights (25mm / 45mm) so both rows' labels stay
visible, matching the functional layout this project's reference
design actually uses. No angled step face needed - two straight
vertical prisms of different heights don't overhang. Uses the
corrected bottle_diameter (26mm) and new well_clearance (0.75mm)
from config.scad.

Verified: watertight, single fused volume, bed-fit 135x76x53mm,
point-containment check confirms no connector-slot/well-cavity
overlap (the bug class just fixed in water_reservoir.scad).

Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01L569pvLm68Jp9P34qvsfgf
EOF
)"
```

---

## Task 3: Slice, run pre-send checks, and send to the printer

**Files:**
- Create: `print-ready/bottle_row.stl` (export target, gitignored)
- Create: `print-ready/bottle_row.gcode.3mf` (slice output, gitignored)

**Interfaces:**
- Consumes: `modules/bottle_row.scad` from Task 2.
- Produces: nothing further code depends on — this task's deliverable is the physical print sent to the printer, and this plan's terminal state.

- [ ] **Step 1: Export the verified STL to `print-ready/`**

```bash
openscad -o print-ready/bottle_row.stl --render modules/bottle_row.scad
```

- [ ] **Step 2: Slice with the corrected print profile**

```bash
./print-profiles/slice.sh print-ready/bottle_row.stl
```

Expected output includes `curr_bed_type = Textured PEI Plate`, `nozzle_temperature = 220`, `M190 S65` (bed temp), and a brim setting. Do not hand-roll a raw `orca-slicer.exe` call — `slice.sh` resolves the preset `inherits` chain that the bare CLI silently drops (this repo's `print-profiles/README.md` has the full post-mortem on why that matters).

- [ ] **Step 3: Run the pre-send sanity check**

```bash
python print-profiles/check_slice.py print-ready/bottle_row.gcode.3mf
```

Expected: every line reads `[ok]`, final line `PASS: print-ready/bottle_row.gcode.3mf`. If any line reads `[FAIL]`, stop — do not send to the printer. Fix the profile issue (see `print-profiles/README.md`) and re-slice.

- [ ] **Step 4: Send to the printer**

```bash
python scripts/send_to_printer.py print-ready/bottle_row.gcode.3mf
```

Expected: `Upload verified. Select it from Print Files on the printer's touchscreen.`

- [ ] **Step 5: STOP — physical fit-test checkpoint, user-in-the-loop**

This is the end of this plan. Do not attempt to automate or self-verify the remaining step: the user needs to physically start the print, let it finish, and fit-test it with real dropper bottles (Vallejo/Army Painter/AK Interactive/Scale75/Reaper-style, ~26mm across) to judge:
- Whether `row_step` (20mm, DECIDED not measured) actually clears a front-row bottle's shoulder/cap so the back row's label is visible.
- Whether `well_clearance` (0.75mm) feels right for a bottle pulled in and out by hand — not too loose, not too tight.

If either needs adjustment, that's a follow-up change to `config.scad` / `modules/bottle_row.scad` and a reprint, same tuning loop already used for `front_collar_height` and `tab_clearance` on the original single-row module. Do not mark this module "done" until that physical fit-test has actually happened.
