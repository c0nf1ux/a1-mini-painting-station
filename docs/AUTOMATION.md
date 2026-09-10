# Print pipeline automation

Why this exists: running OrcaSlicer's GUI alongside VS Code on this machine
makes both crawl. The goal is to get a sliced file onto the A1 mini and
printing without ever opening the OrcaSlicer window, so slicing/iteration
can happen entirely from the CLI/editor side.

## Setup (one-time)

Create `scripts/printer_config.local.json` (gitignored — never commit real
credentials to this public repo):

```json
{
  "ip": "192.168.0.54",
  "access_code": "XXXXXXXX",
  "ftp_port": 990,
  "mqtt_port": 8883,
  "serial": "XXXXXXXXXXXXXXX"
}
```

- **IP**: printer's Settings -> Network screen.
- **Access Code**: same screen, requires **Developer Mode** enabled in
  Settings -> General first (newer Bambu firmware hides it otherwise; this
  does not disable cloud/Handy, they run in parallel with LAN access).

## Stage 1 — done (2026-09-10): send-only

`scripts/send_to_printer.py` uploads a sliced `.3mf`/`.gcode` straight to
the printer's onboard storage over **implicit FTPS** (port 990, user
`bblp`, password = Access Code) — the same mechanism OrcaSlicer's own
"Send" button uses under the hood (confirmed by inspecting its FTP URL in
the app's debug log). No GUI involved.

```
python scripts/send_to_printer.py path/to/file.3mf   # upload
python scripts/send_to_printer.py --list              # list files on printer, no upload
```

After upload, pick the file from **Print Files** on the printer's own
touchscreen and start it manually.

Cert verification is intentionally disabled for this one connection —
Bambu printers use a self-signed cert locally with no real CA, and the
Access Code (not cert trust) is the actual auth boundary. See the comment
in `send_to_printer.py` before copying this pattern anywhere else.

## Stage 2 — planned, not yet built: auto-start

Bambu printers accept a `project_file` command over MQTTS (port 8883, same
`bblp`/Access Code auth) that starts a print from a file already on the
printer's storage — this is the exact command OrcaSlicer sent, captured
directly from its debug log on 2026-09-10:

```json
{"print": {"command": "project_file", "file": "connector_stubs.gcode.3mf",
"param": "Metadata/plate_1.gcode", "url": "ftp://connector_stubs.gcode.3mf",
"use_ams": false, ...}}
```

Once Stage 1's reliability is confirmed across a few real uploads, extend
`send_to_printer.py` (or add `start_print.py`) to publish this over MQTT
right after upload — fully hands-off, no touchscreen step either.

## Known gotcha this automation sidesteps

**Closing OrcaSlicer while a print is running via its own "Send" flow
aborts the print** — confirmed directly (2026-09-10: closed the app at 31%
complete, print stopped on the printer, 5g filament used). This doesn't
apply to prints started from the touchscreen or, once Stage 2 lands, prints
started via the MQTT command directly — neither depends on any app staying
open on the PC. See project memory for the full incident writeup.

## Slicing (CLI, no GUI)

Use the wrapper:

```bash
./print-profiles/slice.sh print-ready/bottle_row.stl
```

It flattens the stock Bambu presets (the CLI does not resolve their
`inherits` chains — it silently substitutes program defaults), applies
this project's corrections from `print-profiles/overrides.json`, and
slices with the nozzle-specific machine preset (`Bambu Lab A1 mini 0.4
nozzle.json`, not the bare model file, which errors on `--load-settings`).

**Why this replaced the raw CLI recipe:** bottle_row test print #1
(2026-09-10) failed — the raw recipe's slice ran the bed at 35 °C on a
plate that needs 65 °C and added no brim, so a 135 mm PLA slab peeled off
at ~6 mm and spaghetti'd. Full post-mortem and the corrected settings:
`print-profiles/README.md`.
