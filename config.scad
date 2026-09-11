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
bottle_diameter = 26;    // mm — SOURCE: LITKO Game Accessories manufacturer
                          // fit table (litko.net/pages/paint-racks) — 26mm
                          // hole fits Vallejo 17-18ml, Army Painter
                          // Warpaints/Fanatic/Speedpaint, AK Interactive 3rd
                          // Gen, Scale75, Reaper MSP, Two Thin Coats
                          // (bottles "about 25mm across"). Replaces an
                          // earlier 28mm single-listing (Vallejo 20ml) proxy.
well_clearance  = 0.75;  // mm per side — SOURCE: community guidance range
                          // 0.5-1mm for a bottle pulled in/out by hand, vs.
                          // tab_clearance's 0.15-0.2mm which is tuned for a
                          // printed-in-place snap connector. Wells use this,
                          // never tab_clearance.
handle_width    = 10;    // mm — MEASURED: user's brush set
brush_length    = 220;   // mm — MEASURED: user's brush set
marker_diameter = undef; // MEASURE: no marker product selected yet — blocks modules/marker_holders.scad
