// modules/scrubber_insert.scad — ribbed insert that drops into
// Module 2's well footprint. A lip rests on the reservoir's rim so it
// doesn't float once the reservoir has water in it. No connector
// edges — this isn't a standalone bench module, it's an insert for
// water_reservoir.scad, so its dimensions are hardcoded against that
// module's interior well (74x54, from footprint 80x60 minus 2x the
// 3mm wall) rather than `use`-importing it, which would pull in that
// file's own top-level footprint_x/wall/etc and collide with this
// file's names.
include <../config.scad>

well_interior_x  = 74; // water_reservoir.scad: footprint_x(80) - 2*wall(3)
well_interior_y  = 54; // water_reservoir.scad: footprint_y(60) - 2*wall(3)

// Same fit-clearance reasoning as the bottle wells (see
// docs/PROJECT-SPEC.md): a part pulled in/out by hand needs real
// clearance, not the 0.175mm tuned for a printed-in-place snap
// connector. 0.5mm/side is the low end of that guidance.
insert_clearance = 0.5;
insert_x    = well_interior_x - 2*insert_clearance;
insert_y    = well_interior_y - 2*insert_clearance;
insert_h    = 15;      // shorter than the reservoir's 20mm well_depth
lip_h       = 3;
lip_overhang = 2;      // mm the lip extends past the opening on each
                        // side, resting on the reservoir's 3mm rim
                        // wall with 1mm margin from the outer edge
rib_count   = 8;
rib_width   = 2;

difference() {
    union() {
        cube([insert_x, insert_y, insert_h]);
        translate([-lip_overhang, -lip_overhang, insert_h - lip_h])
            cube([insert_x + 2*lip_overhang, insert_y + 2*lip_overhang, lip_h]);
    }
    for (i = [0:rib_count-1])
        translate([i * (insert_x/rib_count), 0, insert_h - 4])
            cube([rib_width, insert_y, 5]);
}
