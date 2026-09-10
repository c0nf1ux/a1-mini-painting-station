# Publish Checklist

Run through this before any module goes up on MakerWorld/Printables/GitHub.
Written for this repo, but generic enough to reuse verbatim on the next
pain-point project — copy it forward rather than re-deriving it each time.

## Before publishing a module

- [ ] **Upload includes a sliced `.3mf`, not just the raw STL/CAD file.**
  Confirmed by hitting this directly (2026-09-09): an STL/CAD-only upload has
  no attached print profile, so MakerWorld can't generate a Handy print
  preview for it ("please print it with Bambu Studio on your computer").
  Slice locally first (OrcaSlicer or Bambu Studio — same workflow, OrcaSlicer
  is already installed), then either attach the resulting `.3mf` to the
  MakerWorld upload, or skip MakerWorld/Handy for your own prints entirely
  and send straight from the slicer to the printer over network/cloud.
- [ ] **Printed, not just rendered.** No module goes up on the strength of an
  OpenSCAD `--render` preview alone. Print it on the actual A1 mini first.
- [ ] **Connector validated against at least one sibling module**, not just
  the standalone stub blocks — confirms the shared interface actually holds
  across two independently-printed parts, not just in theory.
- [ ] **Every dimension in the listing is real.** Print time and filament
  usage come from the exported `.3mf`'s `Metadata/plate_1.gcode` header
  (`; model printing time:`, `; filament used [cm3] =`) — not
  `slice_info.config`, which is known to report garbage/zero values in CLI
  mode (see local tooling notes). If a number wasn't measured, it doesn't go
  in the listing.
- [ ] **`config.scad` parameters used for this print are noted in the
  listing description** (e.g. "sized for 28mm bottles, 10mm brush handles")
  so downloaders know what to re-measure for their own supplies, not just
  copy your numbers blind.
- [ ] **`docs/sources.md` is current** — any third-party sourced model this
  module docks or depends on is logged with URL, author, license, and
  repo-eligibility, re-checked at publish time (licenses/download counts do
  change).
- [ ] **License selected on the platform matches the repo license** for that
  file — CC BY-NC-SA 4.0 for anything under `modules/`, matching
  `LICENSE-MODULES.md`. Don't let the platform default (often a more
  permissive or more restrictive built-in option) silently override it.
- [ ] **Reference/inspiration credited** where the design draws from an
  existing layout (e.g. Polvak3D's "Z-Desk Paint Master" for the overall
  station concept) — link it in the listing even when the geometry itself is
  original.
- [ ] **Cover photo is the actual print**, not a render — a real photo of
  your printed part on your A1 mini, ideally showing it connected to at
  least one other module.
- [ ] **Liquid-holding parts (Water Reservoir) are leak-tested**, not just
  wall-count-verified — fill it, wait, check for seepage, before claiming
  water-tightness in the listing.

## Platform setup (one-time, done once for this repo)

- [ ] MakerWorld Maker Rewards program opted into, so downloads/prints on
  published modules actually generate payout, not just visibility.
- [ ] GitHub repo description and README point to the MakerWorld listing(s)
  once published, and vice versa — the two should cross-link.
- [x] **Decided against Bambuddy (2026-09-10):** rather than run a
  self-hosted service (more background load on a machine that already
  chokes running OrcaSlicer's GUI alongside VS Code), built lightweight
  on-demand scripts instead — direct FTPS/MQTT to the printer, no persistent
  process. See `docs/AUTOMATION.md`. This covers "get a file onto the
  printer and print it" headlessly; it doesn't touch the MakerWorld
  publish-form flow above, which is still manual.

## After publishing

- [ ] Note the real download/like/print numbers somewhere trackable (repo
  README or a running log) after a few weeks — this is the signal that
  decides whether the next move is a paid customizer, more free modules for
  portfolio/reputation, or moving on to hunt the next plate-size-broken gap.
