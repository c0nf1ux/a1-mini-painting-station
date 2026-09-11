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
