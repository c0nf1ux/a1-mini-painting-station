"""Upload a sliced .3mf/.gcode file directly to the Bambu A1 mini over LAN
FTPS, bypassing OrcaSlicer's GUI. Stage 1 of the print-automation pipeline:
this gets the file onto the printer; you still pick it from the touchscreen's
Print Files menu and hit start. See docs/AUTOMATION.md.

Credentials come from scripts/printer_config.local.json (gitignored — never
commit real IP/Access Code to this public repo). Get the Access Code from
the printer's Settings -> Network screen (Developer Mode must be on).

Usage:
    python scripts/send_to_printer.py <path-to-file.3mf>
    python scripts/send_to_printer.py --list   # just list files on the printer, no upload
"""

import argparse
import ftplib
import json
import ssl
import sys
from pathlib import Path

CONFIG_PATH = Path(__file__).parent / "printer_config.local.json"


class ImplicitFTP_TLS(ftplib.FTP_TLS):
    """ftplib.FTP_TLS only speaks explicit FTPS (AUTH TLS on port 21).
    Bambu printers use implicit FTPS (TLS handshake immediately on connect,
    port 990) — this subclass wraps the socket in TLS as soon as it's set,
    which is the standard workaround for implicit-mode FTPS in Python."""

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self._sock = None

    @property
    def sock(self):
        return self._sock

    @sock.setter
    def sock(self, value):
        if value is not None and not isinstance(value, ssl.SSLSocket):
            value = self.context.wrap_socket(value)
        self._sock = value


def load_config():
    if not CONFIG_PATH.exists():
        sys.exit(
            f"Missing {CONFIG_PATH}. Create it with your printer's IP and "
            "Access Code (Settings -> Network on the printer screen)."
        )
    return json.loads(CONFIG_PATH.read_text())


def connect(config):
    # Bambu printers serve a self-signed cert on their local FTPS server (no
    # real CA — this is how Bambu Studio/OrcaSlicer connect locally too).
    # The Access Code is the actual auth boundary here, not cert trust. This
    # is a narrow exception for this one LAN device — don't copy this
    # cert-verification skip into code that talks to anything else.
    ctx = ssl.create_default_context()
    ctx.check_hostname = False
    ctx.verify_mode = ssl.CERT_NONE

    ftp = ImplicitFTP_TLS(context=ctx)
    ftp.connect(host=config["ip"], port=config.get("ftp_port", 990), timeout=15)
    ftp.login(user="bblp", passwd=config["access_code"])
    ftp.prot_p()
    return ftp


def list_files(ftp):
    lines = []
    ftp.retrlines("LIST", lines.append)
    return lines


def upload(ftp, local_path: Path):
    with open(local_path, "rb") as f:
        ftp.storbinary(f"STOR {local_path.name}", f)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("file", nargs="?", help="Local .3mf/.gcode file to upload")
    parser.add_argument("--list", action="store_true", help="List files on the printer and exit")
    args = parser.parse_args()

    if not args.file and not args.list:
        parser.error("Provide a file to upload, or pass --list")

    config = load_config()
    print(f"Connecting to {config['ip']}:{config.get('ftp_port', 990)} (implicit FTPS)...")
    ftp = connect(config)
    print("Connected and authenticated.")

    if args.list:
        for line in list_files(ftp):
            print(line)
        ftp.quit()
        return

    local_path = Path(args.file)
    if not local_path.exists():
        sys.exit(f"File not found: {local_path}")

    print(f"Uploading {local_path.name} ({local_path.stat().st_size} bytes)...")
    upload(ftp, local_path)
    print("Upload complete. Select it from Print Files on the printer's touchscreen.")
    ftp.quit()


if __name__ == "__main__":
    main()
