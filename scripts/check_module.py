#!/usr/bin/env python3
"""Verify a rendered module STL fits the A1 mini bed and (optionally) is watertight."""
import sys
import trimesh

BED_MM = 180.0


def check(stl_path, require_watertight=False):
    mesh = trimesh.load(stl_path)
    x, y, z = mesh.bounding_box.extents
    print(f"{stl_path}: bounding box {x:.1f} x {y:.1f} x {z:.1f} mm")
    ok = True
    for label, dim in (("X", x), ("Y", y), ("Z", z)):
        if dim > BED_MM:
            print(f"FAIL: {label} extent {dim:.1f}mm exceeds {BED_MM}mm bed edge")
            ok = False
    if require_watertight:
        if mesh.is_watertight:
            print("OK: watertight")
        else:
            print("FAIL: not watertight")
            ok = False
    return ok


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("usage: check_module.py <path.stl> [--watertight]")
        sys.exit(2)
    require_watertight = "--watertight" in sys.argv
    sys.exit(0 if check(sys.argv[1], require_watertight) else 1)
