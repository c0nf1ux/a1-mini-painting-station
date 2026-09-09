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
