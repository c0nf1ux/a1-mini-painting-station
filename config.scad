// config.scad — single source of truth for every physical dimension
// used across modules/. Status tags match docs/PROJECT-SPEC.md's
// Parameters table: MEASURED (trust it), SOURCE (verify with calipers
// before printing), MEASURE (blocked, no real value exists yet).

// Connector geometry — DECIDED, shared across all modules
tab_width           = 9;     // mm, spec range 8-10mm
tab_depth           = 3.5;   // mm, spec range 3-4mm
tab_clearance       = 0.175; // mm per side, spec range 0.15-0.2mm
base_plinth_height  = 8;     // mm, shared plinth height across all modules

// Physical measurements
bottle_diameter = 28;    // mm — SOURCE: Vallejo 20ml listing, proxy for Smallbudi 20ml bottles
handle_width    = 10;    // mm — MEASURED: user's brush set
brush_length    = 220;   // mm — MEASURED: user's brush set
marker_diameter = undef; // MEASURE: no marker product selected yet — blocks modules/marker_holders.scad
