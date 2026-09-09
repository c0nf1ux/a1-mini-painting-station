# A1 Mini Modular Painting Station — Project Spec

## Why this exists

The Bambu A1 mini's 180×180×180mm bed makes most "modular art supply station"
designs on MakerWorld/Printables unprintable as published — they're sized for
full-size A1/P1/X1 plates. The fix isn't a new design philosophy, it's smaller
modules on more plates, joined by one shared connector so the finished set
still reads as a single continuous bench setup. Reference layout: Polvak3D's
"Z-Desk Paint Master" (https://makerworld.com/en/models/1625421), redesigned
here as six independent single-purpose modules.

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
| `bottle_diameter` | 28mm | SOURCE | Vallejo 20ml dropper-bottle listing, used as a proxy for the user's Smallbudi 20ml bottles (same volume class, same dropper format) |
| `handle_width` | 10mm | MEASURED | User's brush set, thickest handle point |
| `brush_length` | 220mm | MEASURED | User's brush set, sizes Module 3's footprint |
| `marker_diameter` | — | MEASURE | No marker product selected yet — Module 5 is blocked on this |
| `base_plinth_height` | 8mm | DECIDED | Shared connector spec |
| `tab_width` / `tab_depth` | 8-10mm / 3-4mm | DECIDED | Shared connector spec |

## Modules

### Module 1 — Bottle Row (×4 bottles per module)
- Footprint: ~110-130mm × 40-50mm, well under the 180mm bed edge.
- Wells sized to `bottle_diameter`, angled back 5-10° for label visibility.
- Print as many copies as needed for the full paint collection — highest
  reprint frequency of any module.

### Module 2 — Water Reservoir
- Footprint: 60-100mm on the long side.
- Single open well, rounded interior corners for cleaning, 2.5-3mm minimum
  wall thickness for water tightness, slight interior taper so debris settles
  rather than clinging to vertical walls.
- 4+ walls on the slicer profile specifically for this module — the only one
  holding standing liquid.

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
