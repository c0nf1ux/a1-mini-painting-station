# A1 Mini Modular Painting Station — Project Spec

## Why this exists

The Bambu A1 mini's 180×180×180mm bed makes most "modular art supply station"
designs on MakerWorld/Printables unprintable as published — they're sized for
full-size A1/P1/X1 plates. The fix isn't a new design philosophy, it's smaller
modules on more plates, joined by one shared connector so the finished set
still reads as a single continuous bench setup. Reference layout: Polvak3D's
"Z-Desk Paint Master" (https://makerworld.com/en/models/1625421), redesigned
here as six independent single-purpose modules.

**Course-correction note (2026-09-11):** Modules 1-4's first pass drifted
into generic, plain geometry (flat single-row bottle rack, plain
rectangular basin) that didn't carry over the reference design's actual
functional bones — a stepped/tiered bottle layout, a combined scrub+water
unit, dense hole-grid tool holders. Scope is the reference's *functional*
layout only, not its ornamental engraving or two-tone color scheme (no
AMS/4-color feeder here, and that's the one part of the reference that's
actually copyright-sensitive — useful-article functional features aren't
protected, ornamental expression is). Module 1 was the first module
corrected; see its entry below and the 2026-09-11 spec/plan docs.

## Repo & file structure

```
a1-mini-painting-station/
├── lib/
│   └── connector.scad      # shared edge profile + base plinth, used by every module
├── config.scad              # real measurements — see "Parameters" below
├── modules/
│   ├── bottle_row.scad
│   ├── water_reservoir.scad
│   ├── wet_holder.scad
│   ├── scrubber_insert.scad
│   ├── marker_holders.scad
│   └── handle_dock.scad
└── docs/
    ├── PROJECT-SPEC.md      # this file
    └── sources.md            # third-party sourced models (Chuck V2), license per model
```

Each module file renders/slices to exactly one plate — matches the verified
`openscad -o preview.png --render model.scad` and OrcaSlicer CLI workflow
(see local tooling notes). This mirrors the sizing-rig/skins split used in
`versus-chess`: shared parametric code lives in `lib/` and `config.scad`,
per-piece geometry lives in `modules/`.

## Shared connector spec (design and validate first)

- **Type:** dovetail, printed in the XY plane (no supports on any orientation).
  Chosen over a plain rectangular tab-and-slot because the wedge shape
  mechanically resists being pulled straight apart once seated — better
  lateral-wobble resistance without glue, at no print-orientation cost since
  both types print flat either way.
- **Tab width:** 8-10mm, tab depth 3-4mm.
- **Clearance:** 0.15-0.2mm per side for a snap fit. Add a glue-relief chamfer
  if a permanent joint is wanted instead.
- **Placement:** centered on each module's long edges, so modules can be
  arranged in any left-right order along the bench.
- **Base plinth height:** 8mm, standardized across all six modules so bottle
  rows, the reservoir, the handle dock, and marker holders sit flush despite
  differing upper geometry.
- **Validation step:** print two stub blocks with just the connector profile
  before committing it into any module file. Every hour spent here saves
  rework across all six modules.

## Parameters (`config.scad`)

Every physical dimension below is tagged with where it came from. Only
`MEASURED` values are trusted as final; `SOURCE` values are a working default
from a comparable product and should be re-verified with calipers before a
module's first print; `MEASURE` means no real value exists yet and the
module is blocked until one is supplied.

| Parameter | Value | Status | Note |
|---|---|---|---|
| `bottle_diameter` | 26mm | SOURCE | **2026-09-11, finalized (still SOURCE, verify with calipers on a real bottle before final print):** LITKO Game Accessories (a company that manufactures paint racks) publishes a fit table — Vallejo 17-18ml, Army Painter Warpaints/Fanatic/Speedpaint, AK Interactive 3rd Gen, Scale75, Reaper MSP, and Two Thin Coats all fit the same 26mm hole ("bottles about 25mm across"). Replaces the earlier 28mm single-listing (Vallejo 20ml) proxy — a manufacturer's tolerance-inclusive number beats one retail listing. Scope is the dropper-bottle family only; Citadel's flip-top pots are a genuinely different shape (30-34mm wide, 32-45mm tall depending on line — Base/Layer ~32mm, Dry/Technical ~35mm, Contrast ~45mm) and are deferred to a future brand-specific module rather than forcing one well to fit both shapes. Source: https://litko.net/pages/paint-racks and https://cypaint.com/article/what-are-the-dimensions-of-citadel-paint-pot (both fetched via Firecrawl after a plain-fetch 403). |
| `well_clearance` | 0.75mm | SOURCE | **Added 2026-09-11.** Community guidance range 0.5-1mm per side for a bottle pulled in/out by hand, distinct from `tab_clearance` (0.15-0.2mm, tuned for the connector's printed-in-place snap fit). `bottle_row.scad` wells use this now instead of reusing `tab_clearance`. |
| `handle_width` | 10mm | MEASURED | User's brush set, thickest handle point |
| `brush_length` | 220mm | MEASURED | User's brush set, sizes Module 3's footprint |
| `marker_diameter` | — | MEASURE | No marker product selected yet — Module 5 is blocked on this |
| `base_plinth_height` | 8mm | DECIDED | Shared connector spec |
| `tab_width` / `tab_depth` | 8-10mm / 3-4mm | DECIDED | Shared connector spec |

## Modules

### Module 1 — Bottle Row (×8 bottles per module, 2 rows of 4)
- **Redesigned 2026-09-11** from a flat single row into a 2-row "stadium"
  layout — back row's collar taller than the front row's (25mm / 45mm) so
  both rows' labels stay visible from the front, matching the reference
  design's actual functional layout instead of a generic flat row. See
  `docs/superpowers/specs/2026-09-11-tiered-bottle-rack-design.md` for the
  full design and `docs/superpowers/plans/2026-09-11-tiered-bottle-rack.md`
  for the implementation. No angled step face needed between the two
  collar heights — two straight vertical prisms of different heights don't
  overhang.
- Footprint: 135 × 76mm (widened in Y from the original 45mm single-row
  footprint to fit both rows), well under the 180mm bed edge.
- Wells sized to `bottle_diameter` + `well_clearance`, angled back 8° for
  label visibility (both rows share the same tilt).
- Print as many copies as needed for the full paint collection — highest
  reprint frequency of any module.
- **Sent to printer 2026-09-11, physical fit-test pending** — real dropper
  bottles needed to confirm `row_step` (20mm, DECIDED not measured) and
  `well_clearance` feel right.
- Scoped to the dropper-bottle family only (Vallejo/Army Painter/AK
  Interactive/Scale75/Reaper/Two Thin Coats). Citadel pots are a separate
  future module (different bottle shape, not just a size variant) — build
  it once real Citadel pots are on hand to measure, per the user's own
  per-brand-module plan.

### Module 2 — Water Reservoir
- **2026-09-11: current implementation is a throwaway alpha**, kept for
  what it taught about the plinth/connector mechanics, not as the final
  design. It shipped as a plain rectangular basin + separate scrubber
  insert; the reference design's actual bones are a *combined* scrub-box +
  water-trough as one printed unit with a ridged interior, which is planned
  as a future redesign spec once Module 1's fit-test is done. Do not treat
  the description below as final.
- Footprint: 60-100mm on the long side.
- Single open well, rounded interior corners for cleaning, 2.5-3mm minimum
  wall thickness for water tightness, slight interior taper so debris settles
  rather than clinging to vertical walls.
- 4+ walls on the slicer profile specifically for this module — the only one
  holding standing liquid.
- **Known bug, fixed 2026-09-11:** the connector slot cut (`edge_slot()`,
  3.7mm deep) overlapped the well cavity's 1mm plinth bite, tunneling
  straight through the connector-side wall — visible as a hole in the
  printed part exactly at the connector. Fixed by pushing the well's inner
  wall back to 4.5mm on the slot side only. **Any future module with a
  cavity within ~5mm of a connector edge must re-run this check** — verify
  with `trimesh` point-containment (watertight checks alone do NOT catch
  this; a tunnel is still a closed manifold), not just by eye.

### Module 3 — Brush Flat-Lay Wet Holder
- Footprint: sized off `brush_length` (220mm) and `handle_width` (10mm).
- Grooved rest channels sloped toward the reservoir side so bristles drain
  away from the handle end. Groove width fits `handle_width`.

### Module 4 — Brush Cleaner/Scrubber Insert
- Small insert that drops into Module 2's reservoir footprint.
- Ribbed/bristled interior surface for working paint out of ferrules against
  a submerged surface. Needs a small tab/lip so it doesn't float once the
  reservoir has water in it.

### Module 5 — Marker Holders (8-12 at a time)
- Two staggered rows of 6 (not one row of 12) to keep the footprint square
  (~100×80mm) and inside the bed on both axes.
- Staggered so caps don't collide when markers are fully seated. Wells taper
  slightly for one-handed removal.
- Blocked on `marker_diameter` (see Parameters table) — build order places
  this last for that reason too.

### Module 6 — Handle Dock (for "The Chuck V2" painting handle)
- Sourced model: MakerWorld "Miniature painting handle: 'The Chuck V2'" by
  Ashwood (https://makerworld.com/en/models/708184) — 27,981 downloads,
  6,898 likes, 20,994 prints as of 2026-09-09; checked against the next-best
  alternative by download count ("Print-in-Place 3-Jaw Chuck for Painting
  Miniatures," 6,476 downloads) and confirmed as the stronger pick, not just
  the first one found. License: MakerWorld "Standard Digital File License"
  — personal printing is fine, but the file is **not bundled into this repo**;
  see `docs/sources.md` for the link-only reference.
- Design: open-top U-cradle sized to a generous tolerance range rather than a
  snug socket — MakerWorld doesn't publish a bounding box for the handle, and
  a loose cradle plus a small retaining lip avoids needing an exact diameter.
- Connector-compatible on its long edges like every other module.

## Build order

1. Connector profile (validate first, reuse everywhere)
2. Bottle Row — highest-value piece, print several copies early
3. Water Reservoir — pairs with Module 4, working wet-palette setup fast
4. Brush Flat-Lay Wet Holder
5. Brush Cleaner/Scrubber Insert
6. Handle Dock — new module, not blocked on any missing measurement
7. Marker Holders — blocked on `marker_diameter`, lowest priority

## Print settings (starting point)

- 0.2mm layer height, PLA, no supports (all geometry, including the
  connector, is designed to be support-free).
- Water Reservoir gets 4+ walls given it's the only module holding standing
  liquid; every other module uses the standard profile.

## Licensing & publishing

MIT for `lib/` and `config.scad` (the reusable parametric tooling); CC
BY-NC-SA 4.0 for `modules/` (the original module designs) — see `LICENSE`
and `LICENSE-MODULES.md` for the full split and the reasoning behind it.
Every module goes through `docs/PUBLISH-CHECKLIST.md` before it's listed
anywhere public.
