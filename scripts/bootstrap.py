"""Install checksum-pinned local Rojo/Luau tools on Windows or Linux x86_64."""
import hashlib
import os
import platform
import urllib.request
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SYSTEM = platform.system()
if SYSTEM not in {"Windows", "Linux"} or platform.machine().lower() not in {"amd64", "x86_64"}:
    raise SystemExit("Use manual Rojo/Luau installation for this platform; see docs/SETUP.md")
TOOLS = [
    ("rojo-rbx/rojo", "v7.7.0", "rojo", "rojo-7.7.0-windows-x86_64.zip" if SYSTEM == "Windows" else "rojo-7.7.0-linux-x86_64.zip",
     "2179c44862a10ecbd725bdfeb4abc64e16dc4aad9b6c8f3e1a7c46a87280b949" if SYSTEM == "Windows" else "22503e5839864f9d7c2171c48b536fc229f2cc4d8774c9cc149f60941d864073"),
    ("luau-lang/luau", "0.738", "luau", "luau-windows.zip" if SYSTEM == "Windows" else "luau-ubuntu.zip",
     "1d465aa225dff00ed589f32dd79f6e766b54c4de57e3b8652410ccbd4d491695" if SYSTEM == "Windows" else "e967efb6c2a74e691637a82b0fd54de9ae43a2ec9f7be895eee51c1efb84363a"),
]
for repo, tag, folder, filename, expected in TOOLS:
    archive = ROOT / ".tools" / filename
    archive.parent.mkdir(exist_ok=True)
    if not archive.exists():
        request = urllib.request.Request(f"https://github.com/{repo}/releases/download/{tag}/{filename}", headers={"User-Agent": "Wisteria-build"})
        with urllib.request.urlopen(request, timeout=60) as response:
            archive.write_bytes(response.read())
    actual = hashlib.sha256(archive.read_bytes()).hexdigest()
    if actual != expected:
        raise RuntimeError(f"Checksum mismatch: {filename}")
    target = archive.parent / folder
    target.mkdir(exist_ok=True)
    with zipfile.ZipFile(archive) as zipped:
        for member in zipped.infolist():
            resolved = (target / member.filename).resolve()
            if not resolved.is_relative_to(target.resolve()):
                raise RuntimeError("Unsafe path in tool archive")
        zipped.extractall(target)
    if SYSTEM == "Linux":
        for binary in target.iterdir():
            if binary.is_file():
                binary.chmod(binary.stat().st_mode | 0o111)
    print(f"Verified and installed {folder} {tag}")
