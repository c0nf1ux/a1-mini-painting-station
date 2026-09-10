// modules/bottle_row.scad — 4-bottle row, angled 8 deg back for label
// visibility. The shared base_plinth is just the connector-alignment
// floor (per docs/PROJECT-SPEC.md: modules share a flush plinth while
// having "differing upper geometry") — wells are cut into a separate
// collar built on top of it, not into the thin plinth itself. An
// earlier draft of this file cut wells straight into the 8mm plinth,
// which can't hold a bottle upright at any well_depth value — caught by
// rendering and visually inspecting before committing.
include <../config.scad>
use <../lib/connector.scad>

footprint_x   = 135;  // widened from an earlier 120mm draft — 4 wells at
                       // this diameter need more room than that fit (see
                       // well_spacing below). Spec range was 110-130mm;
                       // this is a deliberate 5mm overshoot for real
                       // divider walls between bottles, still far under
                       // the 180mm bed edge.
footprint_y   = 45;
collar_height = 25;   // DECIDED, not measured — first-pass estimate for
                       // enough collar to grip a bottle's lower body for
                       // lateral stability without fully enclosing it.
                       // Adjust after the physical fit-test with a real
                       // bottle, same as tab_clearance was tuned earlier.
well_angle    = 8;    // degrees, tilted back
well_spacing  = 31;   // mm between well centers — must exceed well
                       // diameter (28.35mm at current bottle_diameter +
                       // tab_clearance) or adjacent wells merge into one
                       // trough with no divider, which is what an
                       // earlier 27mm-spacing draft did.
total_height  = base_plinth_height + collar_height;

module bottle_well(x, y) {
    // Starts 1mm below the plinth top (clean CSG fusion, same overcut
    // convention as lib/connector.scad) and punches generously past the
    // collar's actual top so the well is genuinely open, not a sealed
    // pocket — the 8deg tilt eats a little of the nominal height, this
    // margin absorbs that rather than computing the exact cosine.
    translate([x, y, base_plinth_height])
        rotate([well_angle, 0, 0])
            translate([0, 0, -1])
                cylinder(h=collar_height + 5, d=bottle_diameter + 2*tab_clearance, $fn=48);
}

difference() {
    union() {
        base_plinth(footprint_x, footprint_y, base_plinth_height);
        translate([footprint_x, 0, 0])
            edge_tab(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height);
        translate([0, 0, base_plinth_height])
            cube([footprint_x, footprint_y, collar_height]);
    }
    edge_slot(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height, clearance=tab_clearance);
    for (i = [0:3])
        bottle_well(20 + i * well_spacing, footprint_y/2);
}
