// modules/water_reservoir.scad — single open well, rounded interior
// corners, 3mm minimum wall thickness. Footprint 80x60mm (spec estimate:
// 60-100mm on the long side).
//
// Same plinth-height bug bottle_row.scad hit (see its header comment):
// base_plinth_height is only the connector-alignment floor (8mm), not
// the module's full body. The plan's original Task 5 draft cut a 20mm
// well straight into that 8mm plinth, which is geometrically impossible
// and would have rendered a hole tunneling out the bottom/side of the
// part instead of a vessel. Fix: a separate rim wall unioned on top of
// the plinth, well cut into the rim (plus a shallow 1mm bite into the
// plinth top for a clean CSG fusion, same convention bottle_row uses)
// — the remaining ~7mm of plinth below the well becomes the reservoir's
// actual floor, which is also what makes it capable of holding water at
// all.
include <../config.scad>
use <../lib/connector.scad>

footprint_x  = 80;
footprint_y  = 60;
wall         = 3;
well_depth   = 20;
corner_r     = 8;
total_height = base_plinth_height + well_depth;

module rounded_well(x, y, w, h, r, depth) {
    // Starts 1mm into the plinth top (clean CSG fusion, same overcut
    // convention as bottle_row.scad) and punches 2mm past the rim's
    // actual top so the well is genuinely open, not a sealed pocket.
    translate([x, y, base_plinth_height - 1])
        linear_extrude(height=depth + 3)
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
        translate([0, 0, base_plinth_height])
            cube([footprint_x, footprint_y, well_depth]);
    }
    edge_slot(footprint_y, width=tab_width, depth=tab_depth, height=base_plinth_height, clearance=tab_clearance);
    rounded_well(wall, wall, footprint_x - 2*wall, footprint_y - 2*wall, corner_r, well_depth);
}
