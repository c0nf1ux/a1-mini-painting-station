// lib/connector_test.scad — two small stub blocks for validating the
// connector fit before it's committed into every module. Render each
// object separately (see docs/superpowers/plans/2026-09-09-a1-mini-painting-station.md
// Task 2) and print both — MANUAL CHECKPOINT confirms the physical fit
// before Task 4 starts.
include <../config.scad>
use <connector.scad>

module tab_stub() {
    base_plinth(30, 20, base_plinth_height);
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
