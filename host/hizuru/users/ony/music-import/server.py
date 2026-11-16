"""Takes song uploads from index.html and hands them to beets (see ../beets.nix).

Uploads are staged in STAGING and PENDING starts beets-import. Beets moves
what it imports, so a file still staged after a run was left out, and the
import log says why.
"""

import json
import os
import subprocess
import tempfile
from http import HTTPStatus
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.parse import unquote, urlsplit

PORT = int(os.environ["PORT"])
PAGE = Path(os.environ["PAGE"]).read_bytes()
STAGING = Path(os.environ["STAGING"])
PENDING = Path(os.environ["PENDING"])
IMPORT_LOG = Path(os.environ["IMPORT_LOG"])

AUDIO = {
    ".flac",
    ".mp3",
    ".m4a",
    ".ogg",
    ".opus",
    ".wav",
    ".aif",
    ".aiff",
    ".wv",
    ".ape",
}
MAX_SIZE = 2 << 30
CHUNK = 1 << 20


def import_state() -> str:
    """running while beets has work queued or underway, else failed or idle."""
    unit = subprocess.run(
        ["systemctl", "show", "--property=ActiveState", "--value", "beets-import"],
        check=False,
        capture_output=True,
        text=True,
    ).stdout.strip()
    if PENDING.exists() or unit in ("active", "activating"):
        return "running"
    return "failed" if unit == "failed" else "idle"


def staged() -> dict[str, str | None]:
    """Staged file names, each with beets' last verdict on it (e.g. "duplicate-skip")."""
    names = [p.name for p in STAGING.glob("[!.]*")] if STAGING.is_dir() else []
    verdicts: dict[str, str] = {}
    if names and IMPORT_LOG.exists():
        # Lines look like "<action> <path>".
        for line in IMPORT_LOG.read_text(errors="replace").splitlines():
            action, _, path = line.partition(" ")
            if path.startswith(f"{STAGING}/"):
                verdicts[path.removeprefix(f"{STAGING}/")] = action
    return {name: verdicts.get(name) for name in sorted(names)}


class Handler(BaseHTTPRequestHandler):
    server_version = "music-import"

    def reply(
        self,
        status: HTTPStatus,
        body: object = None,
        content_type: str = "application/json",
    ) -> None:
        data = body if isinstance(body, bytes) else json.dumps(body or {}).encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def fail(self, status: HTTPStatus, message: str) -> None:
        self.reply(status, {"error": message})

    def song_name(self) -> str | None:
        """The file name in /upload/<name>, if it's one we'd stage."""
        path = urlsplit(self.path).path
        if not path.startswith("/upload/"):
            return None
        name = unquote(path.removeprefix("/upload/"))
        if not name or name.startswith(".") or "/" in name or "\0" in name:
            return None
        return name

    def do_GET(self) -> None:
        path = urlsplit(self.path).path
        if path == "/":
            self.reply(HTTPStatus.OK, PAGE, "text/html; charset=utf-8")
        elif path == "/status":
            self.reply(HTTPStatus.OK, {"import": import_state(), "staged": staged()})
        else:
            self.fail(HTTPStatus.NOT_FOUND, "Not found.")

    def do_PUT(self) -> None:
        name = self.song_name()
        if name is None:
            return self.fail(HTTPStatus.BAD_REQUEST, "Invalid file name.")
        if Path(name).suffix.lower() not in AUDIO:
            return self.fail(
                HTTPStatus.UNSUPPORTED_MEDIA_TYPE, "Only audio files can be imported."
            )
        length = self.headers.get("Content-Length", "")
        if not length.isdigit():
            return self.fail(HTTPStatus.LENGTH_REQUIRED, "Missing Content-Length.")
        size = int(length)
        if size == 0:
            return self.fail(HTTPStatus.BAD_REQUEST, "The file is empty.")
        if size > MAX_SIZE:
            return self.fail(
                HTTPStatus.REQUEST_ENTITY_TOO_LARGE, "Files over 2 GB aren't accepted."
            )

        STAGING.mkdir(parents=True, exist_ok=True)
        # Dot-prefixed so beets ignores it until it's complete.
        fd, tmp = tempfile.mkstemp(dir=STAGING, prefix=".", suffix=".part")
        try:
            os.fchmod(fd, 0o644)
            with os.fdopen(fd, "wb") as f:
                left = size
                while left:
                    chunk = self.rfile.read(min(left, CHUNK))
                    if not chunk:
                        raise ConnectionAbortedError
                    f.write(chunk)
                    left -= len(chunk)
            os.replace(tmp, STAGING / name)
        except ConnectionError:
            Path(tmp).unlink(missing_ok=True)
            self.close_connection = True
            return None
        except OSError as e:
            Path(tmp).unlink(missing_ok=True)
            return self.fail(
                HTTPStatus.INSUFFICIENT_STORAGE,
                f"Couldn't save it on hizuru: {e.strerror}.",
            )

        PENDING.touch()
        self.reply(HTTPStatus.CREATED)

    def do_DELETE(self) -> None:
        """Drops a staged file that beets left out."""
        name = self.song_name()
        if name is None:
            return self.fail(HTTPStatus.BAD_REQUEST, "Invalid file name.")
        try:
            (STAGING / name).unlink()
        except FileNotFoundError:
            return self.fail(HTTPStatus.NOT_FOUND, "It's no longer on hizuru.")
        self.reply(HTTPStatus.OK)


if __name__ == "__main__":
    # Leftovers from uploads cut short by a restart.
    for part in STAGING.glob(".*.part"):
        part.unlink(missing_ok=True)
    ThreadingHTTPServer(("127.0.0.1", PORT), Handler).serve_forever()
