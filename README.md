# A1 Mini Modular Painting Station

Parametric OpenSCAD modules for a mini-figure painting station, sized to
actually fit the Bambu A1 mini's 180×180×180mm bed — the plate-size gap most
existing "modular art station" designs on MakerWorld/Printables don't
account for. Six connector-compatible modules (bottle row, water reservoir,
wet holder, scrubber insert, marker holders, handle dock) join through one
shared dovetail edge profile, so pieces printed separately, on separate
plates, still assemble into one continuous bench setup.

See [`docs/PROJECT-SPEC.md`](docs/PROJECT-SPEC.md) for the full design and
[`docs/PUBLISH-CHECKLIST.md`](docs/PUBLISH-CHECKLIST.md) for what has to be
true before any module ships publicly.

## License

MIT for the shared connector library and parameter template (`lib/`,
`config.scad`). CC BY-NC-SA 4.0 for the module designs (`modules/`). See
[`LICENSE`](LICENSE) and [`LICENSE-MODULES.md`](LICENSE-MODULES.md).
