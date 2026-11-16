"""Takes song uploads from index.html and hands them to beets (see ../beets.nix)."""

import json
import os
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote

PORT = int(os.environ["PORT"])
PAGE = Path(os.environ["PAGE"]).read_bytes()
STAGING = Path(os.environ["STAGING"])
PENDING = Path(os.environ["PENDING"])
AUDIO = {".flac", ".mp3", ".m4a", ".ogg", ".opus", ".wav", ".aif", ".aiff", ".wv", ".ape"}


def importing():
    state = subprocess.run(
        ["systemctl", "show", "-P", "ActiveState", "beets-import"],
        capture_output=True, text=True,
    ).stdout.strip()
    return PENDING.exists() or state in ("active", "activating")


class Handler(BaseHTTPRequestHandler):
    def send(self, code, body, kind="application/json"):
        self.send_response(code)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/":
            self.send(200, PAGE, "text/html; charset=utf-8")
        elif self.path == "/status":
            # Beets moves imported files out, so whatever is still here hasn't
            # been imported (yet, or at all when nothing is running).
            waiting = sorted(p.name for p in STAGING.glob("[!.]*")) if STAGING.exists() else []
            self.send(200, json.dumps({"importing": importing(), "waiting": waiting}).encode())
        else:
            self.send(404, b"{}")

    def do_PUT(self):
        name = Path(unquote(self.path.removeprefix("/upload/"))).name
        if not self.path.startswith("/upload/") or name.startswith(".") or Path(name).suffix.lower() not in AUDIO:
            return self.send(400, b'{"error":"not a song"}')

        STAGING.mkdir(parents=True, exist_ok=True)
        # Dotfiles are ignored by beets, so a run mid-upload skips this one.
        part = STAGING / f".{name}.part"
        left = int(self.headers["Content-Length"])
        with part.open("wb") as f:
            while left:
                chunk = self.rfile.read(min(left, 1 << 20))
                if not chunk:
                    part.unlink()
                    return self.send(400, b'{"error":"upload cut short"}')
                f.write(chunk)
                left -= len(chunk)
        part.rename(STAGING / name)
        PENDING.touch()
        self.send(200, b"{}")


ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
