// lib/connector.scad — shared dovetail edge profile + base plinth.
// Extruded along Z with a constant XY cross-section, so two modules
// assemble by setting one down from above (tab drops into slot with
// zero collision at any height); once seated, the flare traps the tab
// against sideways separation. See docs/PROJECT-SPEC.md for the
// connector spec this implements.

module dovetail_tab(width=9, depth=3.5, height=8) {
    // Root extends 0.3mm behind x=0 so the tab always has real
    // volumetric overlap with whatever it's unioned onto, rather than
    // touching at a single coincident face (which CGAL can render as
    // two disjoint volumes instead of one fused solid).
    neck_w = width * 0.6;
    linear_extrude(height=height)
        polygon(points=[
            [-0.3, -neck_w/2],
            [-0.3, neck_w/2],
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
