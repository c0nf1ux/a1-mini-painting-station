# A1 Mini Painting Station Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build six connector-compatible OpenSCAD modules (bottle row, water reservoir, scrubber insert, wet holder, handle dock, marker holders) that each fit on the Bambu A1 mini's 180×180×180mm bed and join through one shared dovetail edge profile.

**Architecture:** A shared `lib/connector.scad` provides the dovetail tab/slot geometry and base plinth, consumed via `use <../lib/connector.scad>` by each standalone file in `modules/`. All physical dimensions live in one `config.scad`, included via `include <../config.scad>`, so a single source of truth drives every module. Each module file renders to exactly one STL/plate, matching the verified `openscad --render` → OrcaSlicer CLI pipeline.

**Tech Stack:** OpenSCAD 2021.01 (CLI), Python 3.12 + trimesh (mesh verification), OrcaSlicer 2.4.2 CLI (slicing, not covered by this plan — see `docs/PUBLISH-CHECKLIST.md`).

## Global Constraints

- Bed size: 180×180×180mm (Bambu A1 mini) — every module's bounding box must fit under this on all three axes.
- Base plinth height: 8mm, identical across every module (`base_plinth_height` in `config.scad`).
- Connector: dovetail, tab width 9mm / depth 3.5mm / clearance 0.175mm per side (midpoints of the spec's 8-10mm / 3-4mm / 0.15-0.2mm ranges) — see `docs/PROJECT-SPEC.md`.
- No supports on any module — all geometry must print flat/support-free.
- No fabricated dimensions: every constant in `config.scad` is tagged `MEASURED`, `SOURCE`, or `MEASURE` per `docs/PROJECT-SPEC.md`'s Parameters table, and that tagging must be preserved as comments in the code.
- Physical print/measurement steps in this plan (connector fit-check, water-tightness) cannot be performed by an agent — they're called out explicitly as **MANUAL CHECKPOINT** and are the user's responsibility between tasks.

---

## Assembly note (why this connector works without gluing)

The dovetail tab is a trapezoid in the XY plane — narrow where it meets the parent module's edge, wide at the tip — extruded straight up through the full 8mm plinth height. Because the cross-section never changes along Z, two modules assemble by **setting one down from above** so the tab drops straight into the mating slot (zero collision at any height, by construction). Once seated, the wide tip is trapped behind the slot's narrower mouth, so the modules can't be pulled apart *sideways* (racking/wobble on the bench) without lifting one back up first. This is why the spec's "snap-fit or glue-relief" note works either way: the geometry already provides the mechanical lock; glue is only for permanence, not for holding the joint together day to day.

## File Structure

```
a1-mini-painting-station/
├── lib/
│   └── connector.scad
├── config.scad
├── scripts/
│   └── check_module.py
├── modules/
│   ├── bottle_row.scad
│   ├── water_reservoir.scad
│   ├── scrubber_insert.scad
│   ├── wet_holder.scad
│   ├── handle_dock.scad
│   └── marker_holders.scad
└── docs/
    ├── PROJECT-SPEC.md
    ├── sources.md
    └── PUBLISH-CHECKLIST.md
```

---

### Task 1: Bed-fit / watertight verification script

**Files:**
- Create: `scripts/check_module.py`
- Test: manual invocation against two throwaway OpenSCAD renders (no separate test file — this task's own two runs in Steps 2 and 4 are the test)

**Interfaces:**
- Produces: `scripts/check_module.py <path.stl> [--watertight]` — CLI tool, exit code 0 on pass / 1 on fail / 2 on bad args. Every later task's verification step shells out to this.

- [ ] **Step 1: Write the script**

```python
#!/usr/bin/env python3
"""Verify a rendered module STL fits the A1 mini bed and (optionally) is watertight."""
import sys
import trimesh

BED_MM = 180.0


def check(stl_path, require_watertight=False):
    mesh = trimesh.load(stl_path)
    x, y, z = mesh.bounding_box.extents
    print(f"{stl_path}: bounding box {x:.1f} x {y:.1f} x {z:.1f} mm")
    ok = True
    for label, dim in (("X", x), ("Y", y), ("Z", z)):
        if dim > BED_MM:
            print(f"FAIL: {label} extent {dim:.1f}mm exceeds {BED_MM}mm bed edge")
            ok = False
    if require_watertight:
        if mesh.is_watertight:
            print("OK: watertight")
        else:
            print("FAIL: not watertight")
            ok = False
    return ok


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: check_module.py <path.stl> [--watertight]")
        sys.exit(2)
    require_watertight = "--watertight" in sys.argv
    sys.exit(0 if check(sys.argv[1], require_watertight) else 1)
```

- [ ] **Step 2: Verify it catches an oversized part**

```bash
mkdir -p /tmp/a1mps-check
echo 'cube([200, 50, 8]);' > /tmp/a1mps-check/too_big.scad
openscad -o /tmp/a1mps-check/too_big.stl --render /tmp/a1mps-check/too_big.scad
python scripts/check_module.py /tmp/a1mps-check/too_big.stl
```

Expected: prints a bounding box line, then `FAIL: X extent 200.0mm exceeds 180.0mm bed edge`, exits 1 (`echo $?` → `1`).

- [ ] **Step 3: Verify it passes a part that fits**

```bash
echo 'cube([50, 50, 8]);' > /tmp/a1mps-check/fits.scad
openscad -o /tmp/a1mps-check/fits.stl --render /tmp/a1mps-check/fits.scad
python scripts/check_module.py /tmp/a1mps-check/fits.stl --watertight
```

Expected: bounding box line, `OK: watertight`, exits 0 (`echo $?` → `0`).

- [ ] **Step 4: Commit**

```bash
git add scripts/check_module.py
git commit -m "Add STL bed-fit/watertight verification script"
```

---

### Task 2: Shared connector library

**Files:**
- Create: `lib/connector.scad`
- Create: `lib/connector_test.scad`

**Interfaces:**
- Produces: `dovetail_tab(width, depth, height)`, `dovetail_slot(width, depth, height, clearance)`, `edge_tab(edge_length, width, depth, height)`, `edge_slot(edge_length, width, depth, height, clearance)`, `base_plinth(footprint_x, footprint_y, height)` — every module task below uses these exact names and parameter orders.

- [ ] **Step 1: Write the connector library**

```openscad
// lib/connector.scad — shared dovetail edge profile + base plinth.
// Extruded along Z with a constant XY cross-section, so two modules
// assemble by setting one down from above (tab drops into slot with
// zero collision at any height); once seated, the flare traps the tab
// against sideways separation. See docs/PROJECT-SPEC.md for the
// connector spec this implements.

module dovetail_tab(width=9, depth=3.5, height=8) {
    neck_w = width * 0.6;
    linear_extrude(height=height)
        polygon(points=[
            [0, -neck_w/2],
            [0, neck_w/2],
            [depth, width/2],
            [depth, -width/2]
        ]);
}

module dovetail_slot(width=9, depth=3.5, height=8, clearance=0.175) {
    neck_w = width * 0.6 + 2*clearance;
    tip_w  = width + 2*clearance;
    translate([0, 0, -0.2])
        linear_extrude(height=height + 0.4)
            polygon(points=[
                [-0.2, -neck_w/2],
                [-0.2, neck_w/2],
                [depth + 0.2, tip_w/2],
                [depth + 0.2, -tip_w/2]
            ]);
}

// Places a tab centered on a Y-running edge of the given length,
// protruding in +X from x=0. Call with translate() to position at the
// actual edge of your module's footprint.
module edge_tab(edge_length, width=9, depth=3.5, height=8) {
    translate([0, edge_length/2, 0])
        dovetail_tab(width=width, depth=depth, height=height);
}

module edge_slot(edge_length, width=9, depth=3.5, height=8, clearance=0.175) {
    translate([0, edge_length/2, 0])
        dovetail_slot(width=width, depth=depth, height=height, clearance=clearance);
}

module base_plinth(footprint_x, footprint_y, height=8) {
    cube([footprint_x, footprint_y, height]);
}
```

- [ ] **Step 2: Write the stub-block test file**

```openscad
// lib/connector_test.scad — two small stub blocks for validating the
// connector fit before it's committed into every module. Render each
// object separately (see Step 3) and print both — MANUAL CHECKPOINT
// below confirms the physical fit before Task 4 starts.
include <../config.scad>
use <connector.scad>

module tab_stub() {
    difference() {
        base_plinth(30, 20, base_plinth_height);
        // nothing subtracted from the stub body itself
    }
    translate([30, 0, 0])
        edge_tab(20, width=tab_width, depth=tab_depth, height=base_plinth_height);
}

module slot_stub() {
    difference() {
        base_plinth(30, 20, base_plinth_height);
        edge_slot(20, width=tab_width, depth=tab_depth, height=base_plinth_height, clearance=tab_clearance);
    }
}

if (STUB == "tab") {
    tab_stub();
} else if (STUB == "slot") {
    slot_stub();
} else {
    echo("Set -D STUB=\"tab\" or -D STUB=\"slot\" when rendering this file");
}
```

- [ ] **Step 3: Render both stubs and check them**

```bash
mkdir -p /tmp/a1mps-check
openscad -o /tmp/a1mps-check/tab_stub.stl --render -D 'STUB="tab"' lib/connector_test.scad
openscad -o /tmp/a1mps-check/slot_stub.stl --render -D 'STUB="slot"' lib/connector_test.scad
python scripts/check_module.py /tmp/a1mps-check/tab_stub.stl --watertight
python scripts/check_module.py /tmp/a1mps-check/slot_stub.stl --watertight
openscad -o /tmp/a1mps-check/tab_stub.png --imgsize=800,600 --render -D 'STUB="tab"' lib/connector_test.scad
openscad -o /tmp/a1mps-check/slot_stub.png --imgsize=800,600 --render -D 'STUB="slot"' lib/connector_test.scad
```

Expected: both `check_module.py` calls print `OK: watertight` and exit 0. Read both PNGs and confirm visually: the tab stub shows a trapezoid (narrow-to-wide) block protruding from one edge; the slot stub shows a matching trapezoid cavity cut into one edge.

- [ ] **Step 4: MANUAL CHECKPOINT — print and test fit**

Slice and print both stubs on the A1 mini (PLA, 0.2mm layer, no supports). Set the tab stub down onto the slot stub as described in the Assembly note above. Confirm: (a) the tab seats fully without forcing, (b) the two stubs resist being slid apart sideways without lifting. If either fails, adjust `tab_clearance` in `config.scad` (looser fit → increase; too loose/wobbly → decrease) and re-render before proceeding to Task 3. **Do not start Task 4 until this physically checks out** — every module depends on this connector.

- [ ] **Step 5: Commit**

```bash
git add lib/connector.scad lib/connector_test.scad
git commit -m "Add shared dovetail connector library and stub-block test"
```

---

### Task 3: Shared parameters (`config.scad`)

**Files:**
- Create: `config.scad`
- Create: `config_test.scad`

**Interfaces:**
- Produces: `tab_width`, `tab_depth`, `tab_clearance`, `base_plinth_height`, `bottle_diameter`, `handle_width`, `brush_length`, `marker_diameter` (undef) — every module task below `include`s this file and uses these exact names.

- [ ] **Step 1: Write config.scad**

```openscad
// config.scad — single source of truth for every physical dimension
// used across modules/. Status tags match docs/PROJECT-SPEC.md's
// Parameters table: MEASURED (trust it), SOURCE (verify with calipers
// before printing), MEASURE (blocked, no real value exists yet).

// Connector geometry — DECIDED, shared across all modules
tab_width           = 9;     // mm, spec range 8-10mm
tab_depth           = 3.5;   // mm, spec range 3-4mm
tab_clearance       = 0.175; // mm per side, spec range 0.15-0.2mm
base_plinth_height  = 8;     // mm, shared plinth height across all modules

// Physical measurements
bottle_diameter = 28;    // mm — SOURCE: Vallejo 20ml listing, proxy for Smallbudi 20ml bottles
handle_width    = 10;    // mm — MEASURED: user's brush set
brush_length    = 220;   // mm — MEASURED: user's brush set
marker_diameter = undef; // MEASURE: no marker product selected yet — blocks modules/marker_holders.scad
```

- [ ] **Step 2: Write config_test.scad to catch syntax/definition errors**

```openscad
// config_test.scad — renders nothing, just proves config.scad parses
// and every constant this plan depends on is actually defined.
include <config.scad>

assert(is_num(tab_width));
assert(is_num(tab_depth));
assert(is_num(tab_clearance));
assert(is_num(base_plinth_height));
assert(is_num(bottle_diameter));
assert(is_num(handle_width));
assert(is_num(brush_length));
assert(is_undef(marker_diameter), "marker_diameter should still be undef until markers are measured");

echo("config.scad OK");
cube([1, 1, 1]);
```

- [ ] **Step 3: Run it**

```bash
openscad -o /tmp/a1mps-check/config_test.stl --render config_test.scad
```

Expected: console output includes `ECHO: "config.scad OK"`, no assertion errors, exits 0.

- [ ] **Step 4: Commit**

```bash
git add config.scad config_test.scad
git commit -m "Add shared config.scad with tagged parameter provenance"
```

---

### Task 4: Module 1 — Bottle Row

**Files:**
- Create: `modules/bottle_row.scad`

**Interfaces:**
- Consumes: `base_plinth(x, y, h)`, `edge_tab(len, w, d, h)`, `edge_slot(len, w, d, h, c)` from Task 2; `bottle_diameter`, `tab_width`, `tab_depth`, `tab_clearance`, `base_plinth_height` from Task 3.

- [ ] **Step 1: Write the module**

```openscad
// modules/bottle_row.scad — 4-bottle row, angled 8 deg back for label
// visibility. Footprint 120x45mm (spec estimate: 110-130 x 40-50mm).
include <../config.scad>
use <../lib/connector.scad>

footprint_x = 120;
footprint_y = 45;
well_depth  = 25;
well_angle  = 8; // degrees, tilted back

module bottle_well(x, y) {
    translate([x, y, base_plinth_height])
        rotate([well_angle, 0, 0])
            translate([0, 0, -1])
                cylinder(h=well_depth + 1, d=bottle_diameter + 2*tab_clearance, $fn=48);
}

difference() {
    union() {
        base_plinth(footprint_x, footprint_y, base_plinth_height);
        translate([footprint_x, 0, 0])
            edge_tab(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height);
    }
    edge_slot(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height, clearance=tab_clearance);
    for (i = [0:3])
        bottle_well(20 + i * 27, footprint_y/2);
}
```

- [ ] **Step 2: Render, check, and visually inspect**

```bash
openscad -o /tmp/a1mps-check/bottle_row.stl --render modules/bottle_row.scad
python scripts/check_module.py /tmp/a1mps-check/bottle_row.stl --watertight
openscad -o /tmp/a1mps-check/bottle_row.png --imgsize=1000,700 --render modules/bottle_row.scad
```

Expected: `check_module.py` prints a bounding box under 180mm on every axis and `OK: watertight`, exits 0. Read the PNG and confirm 4 evenly spaced, back-angled wells and a tab on the right edge / slot on the left edge.

- [ ] **Step 3: Commit**

```bash
git add modules/bottle_row.scad
git commit -m "Add Module 1: bottle row"
```

---

### Task 5: Module 2 — Water Reservoir and Module 4 — Scrubber Insert

**Files:**
- Create: `modules/water_reservoir.scad`
- Create: `modules/scrubber_insert.scad`

**Interfaces:**
- Consumes: same as Task 4.

- [ ] **Step 1: Write the water reservoir**

```openscad
// modules/water_reservoir.scad — single open well, rounded interior
// corners, 3mm minimum wall thickness. Footprint 80x60mm (spec
// estimate: 60-100mm on the long side).
include <../config.scad>
use <../lib/connector.scad>

footprint_x  = 80;
footprint_y  = 60;
wall         = 3;
well_depth   = 20;
corner_r     = 8;

module rounded_well(x, y, w, h, r, depth) {
    translate([x, y, base_plinth_height - depth])
        linear_extrude(height=depth + 1)
            hull() {
                translate([r, r]) circle(r=r, $fn=32);
                translate([w - r, r]) circle(r=r, $fn=32);
                translate([r, h - r]) circle(r=r, $fn=32);
                translate([w - r, h - r]) circle(r=r, $fn=32);
            }
}

difference() {
    union() {
        base_plinth(footprint_x, footprint_y, base_plinth_height);
        translate([footprint_x, 0, 0])
            edge_tab(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height);
    }
    edge_slot(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height, clearance=tab_clearance);
    rounded_well(wall, wall, footprint_x - 2*wall, footprint_y - 2*wall, corner_r, well_depth);
}
```

- [ ] **Step 2: Write the scrubber insert**

```openscad
// modules/scrubber_insert.scad — ribbed insert that drops into
// Module 2's well footprint. Small lip so it doesn't float once the
// reservoir has water in it. No connector edges — this isn't a
// standalone bench module, it's an insert for water_reservoir.scad.
include <../config.scad>

insert_x    = 74; // fits inside water_reservoir's 74x54 interior well
insert_y    = 54;
insert_h    = 15;
lip_h       = 3;
rib_count   = 8;
rib_width   = 2;

difference() {
    union() {
        cube([insert_x, insert_y, insert_h]);
        translate([-2, -2, insert_h - lip_h])
            cube([insert_x + 4, insert_y + 4, lip_h]);
    }
    for (i = [0:rib_count-1])
        translate([i * (insert_x/rib_count), 0, insert_h - 4])
            cube([rib_width, insert_y, 5]);
}
```

- [ ] **Step 3: Render, check, and visually inspect both**

```bash
openscad -o /tmp/a1mps-check/water_reservoir.stl --render modules/water_reservoir.scad
python scripts/check_module.py /tmp/a1mps-check/water_reservoir.stl --watertight
openscad -o /tmp/a1mps-check/water_reservoir.png --imgsize=1000,700 --render modules/water_reservoir.scad

openscad -o /tmp/a1mps-check/scrubber_insert.stl --render modules/scrubber_insert.scad
python scripts/check_module.py /tmp/a1mps-check/scrubber_insert.stl --watertight
openscad -o /tmp/a1mps-check/scrubber_insert.png --imgsize=1000,700 --render modules/scrubber_insert.scad
```

Expected: both pass `check_module.py` (bed fit + watertight), both PNGs show the expected geometry (rounded-corner well with 3mm walls; ribbed insert with a lip).

- [ ] **Step 4: MANUAL CHECKPOINT — leak test**

Print `water_reservoir.scad`, fill with water, let it sit 15+ minutes, check for seepage at the walls/floor before this module is considered print-verified. `check_module.py --watertight` only confirms the *mesh* has no holes — it says nothing about actual liquid tightness through PLA infill/walls, which is a physical property this plan cannot verify for you.

- [ ] **Step 5: Commit**

```bash
git add modules/water_reservoir.scad modules/scrubber_insert.scad
git commit -m "Add Module 2 (water reservoir) and Module 4 (scrubber insert)"
```

---

### Task 6: Module 3 — Brush Flat-Lay Wet Holder

**Files:**
- Create: `modules/wet_holder.scad`

**Interfaces:**
- Consumes: same as Task 4, plus `handle_width` and `brush_length` from Task 3.

- [ ] **Step 1: Write the module**

Note: `brush_length` (220mm) exceeds the 180mm bed edge on its own, and the spec's own footprint estimate for this module tops out at 150mm — it was never meant to lay the full brush flat. The channel cradles the ferrule/bristle end and the first ~140mm of handle (brushes angle up and out, they aren't laid perfectly flat their whole length). This is a deliberate scope decision, not an oversight — `check_module.py` would catch it as a bed-fit failure if it weren't handled here.

```openscad
// modules/wet_holder.scad — grooved rest channels sloped toward the
// reservoir side. Channel length is capped at 140mm (spec estimate:
// 100-150mm) even though brush_length is 220mm — brushes rest at an
// angle, they aren't laid flat their full length. Groove width fits
// handle_width.
include <../config.scad>
use <../lib/connector.scad>

footprint_x   = 140;
footprint_y   = 100;
groove_count  = 5;
groove_depth  = 8;
slope_deg     = 4; // toward y=0, the reservoir-facing edge

module groove(x) {
    translate([x, -1, base_plinth_height])
        rotate([slope_deg, 0, 0])
            translate([0, 0, -groove_depth])
                cube([handle_width + 2*tab_clearance, footprint_y + 2, groove_depth + 5]);
}

difference() {
    union() {
        base_plinth(footprint_x, footprint_y, base_plinth_height);
        translate([footprint_x, 0, 0])
            edge_tab(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height);
    }
    edge_slot(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height, clearance=tab_clearance);
    for (i = [0:groove_count-1])
        groove(15 + i * ((footprint_x - 30) / (groove_count - 1)));
}
```

- [ ] **Step 2: Render, check, and visually inspect**

```bash
openscad -o /tmp/a1mps-check/wet_holder.stl --render modules/wet_holder.scad
python scripts/check_module.py /tmp/a1mps-check/wet_holder.stl --watertight
openscad -o /tmp/a1mps-check/wet_holder.png --imgsize=1000,700 --render modules/wet_holder.scad
```

Expected: passes bed-fit (140×100mm, well under 180mm) and watertight, PNG shows 5 sloped grooves sized to `handle_width`.

- [ ] **Step 3: Commit**

```bash
git add modules/wet_holder.scad
git commit -m "Add Module 3: brush flat-lay wet holder"
```

---

### Task 7: Module 6 — Handle Dock

**Files:**
- Create: `modules/handle_dock.scad`

**Interfaces:**
- Consumes: same as Task 4.

- [ ] **Step 1: Write the module**

```openscad
// modules/handle_dock.scad — open-top U-cradle for "The Chuck V2"
// painting handle (see docs/sources.md). Sized to a generous
// tolerance range rather than a snug socket, since no bounding box is
// published for the handle — a loose cradle plus a retaining lip
// avoids needing an exact diameter.
include <../config.scad>
use <../lib/connector.scad>

footprint_x  = 60;
footprint_y  = 50;
cradle_d     = 40; // generous — typical painting-handle barrel range
lip_h        = 4;

difference() {
    union() {
        base_plinth(footprint_x, footprint_y, base_plinth_height);
        translate([footprint_x, 0, 0])
            edge_tab(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height);
    }
    edge_slot(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height, clearance=tab_clearance);
    translate([footprint_x/2, footprint_y/2, base_plinth_height - lip_h + 0.1])
        cylinder(h=lip_h + 1, d=cradle_d, $fn=64);
    translate([footprint_x/2, -1, base_plinth_height - lip_h + 0.1])
        cube([cradle_d, footprint_y/2 + 1, lip_h + 1], center=false);
}
```

- [ ] **Step 2: Render, check, and visually inspect**

```bash
openscad -o /tmp/a1mps-check/handle_dock.stl --render modules/handle_dock.scad
python scripts/check_module.py /tmp/a1mps-check/handle_dock.stl --watertight
openscad -o /tmp/a1mps-check/handle_dock.png --imgsize=1000,700 --render modules/handle_dock.scad
```

Expected: passes bed-fit and watertight, PNG shows an open U-shaped cradle with a shallow retaining lip.

- [ ] **Step 3: Commit**

```bash
git add modules/handle_dock.scad
git commit -m "Add Module 6: handle dock for The Chuck V2"
```

---

### Task 8: Module 5 — Marker Holders (blocked on measurement)

**Files:**
- Create: `modules/marker_holders.scad`

**Interfaces:**
- Consumes: same as Task 4, plus `marker_diameter` from Task 3 (currently `undef` by design).

- [ ] **Step 1: Write the module with an explicit blocking assertion**

```openscad
// modules/marker_holders.scad — two staggered rows of 6 (not one row
// of 12, which risks 180-220mm and crowds the bed). Blocked until
// marker_diameter is measured — this file intentionally fails to
// render rather than guessing a diameter.
include <../config.scad>
use <../lib/connector.scad>

assert(!is_undef(marker_diameter),
    "marker_diameter is undef — measure your markers and set it in config.scad before rendering this module");

footprint_x  = 100;
footprint_y  = 80;
row_spacing  = 40;
well_depth   = 30;
taper_deg    = 3;

module marker_well(x, y) {
    translate([x, y, base_plinth_height])
        rotate([0, taper_deg, 0])
            translate([0, 0, -1])
                cylinder(h=well_depth + 1, d1=marker_diameter + 2*tab_clearance + 1,
                         d2=marker_diameter + 2*tab_clearance, $fn=32);
}

difference() {
    union() {
        base_plinth(footprint_x, footprint_y, base_plinth_height);
        translate([footprint_x, 0, 0])
            edge_tab(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height);
    }
    edge_slot(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height, clearance=tab_clearance);
    for (i = [0:5]) {
        marker_well(15 + i * 15, footprint_y/2 - row_spacing/2);
        marker_well(22 + i * 15, footprint_y/2 + row_spacing/2);
    }
}
```

- [ ] **Step 2: Confirm it currently fails loudly (expected — this is the blocked state)**

```bash
openscad -o /tmp/a1mps-check/marker_holders.stl --render modules/marker_holders.scad
```

Expected: FAILS with `ERROR: Assertion 'marker_diameter is undef...' failed`. This is correct and expected — do not weaken or remove the assertion to force a render.

- [ ] **Step 3: Commit the blocked module**

```bash
git add modules/marker_holders.scad
git commit -m "Add Module 5: marker holders (blocked on marker_diameter measurement)"
```

- [ ] **Step 4: Unblock later (not part of this plan's completion)**

Once a marker product is picked and measured: set `marker_diameter` in `config.scad` to a real `MEASURED` value (not another `SOURCE` proxy, since caps vary more than bottle bases), re-run Step 2 above expecting success this time, then run the same render/check/inspect/commit sequence used in Tasks 4-7.

---

## Self-Review Notes

**Spec coverage:** Connector (Task 2), config/parameter provenance (Task 3), Modules 1-6 (Tasks 4, 5, 5, 6, 7, 8) — all six modules and the shared connector from `docs/PROJECT-SPEC.md` have a task. Publishing itself is intentionally out of scope for this plan — `docs/PUBLISH-CHECKLIST.md` governs that once modules are print-verified.

**Placeholder scan:** No TBD/TODO markers. Module 5 is the one deliberately incomplete piece, and it's incomplete via a real, testable `assert()` rather than a comment.

**Type/interface consistency:** `edge_tab`/`edge_slot`/`base_plinth` signatures defined in Task 2 are called identically (same parameter order: length, width, depth, height[, clearance]) in Tasks 4 through 8. `config.scad` variable names defined in Task 3 (`tab_width`, `tab_depth`, `tab_clearance`, `base_plinth_height`, `bottle_diameter`, `handle_width`, `brush_length`, `marker_diameter`) match every module's `include` usage exactly.
