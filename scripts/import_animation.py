"""Validate a Studio XML export, back up the bundled clip, then adopt the edit without regeneration."""
import argparse
import json
from pathlib import Path
import generate_animations as animations


def import_clip(name, source, check_only=False):
    clips = animations.load_clips()
    assert name in clips, "Unknown clip: create its data/animations JSON metadata first"
    source = Path(source)
    assert source.suffix.lower() == ".rbxmx", "Export XML Model (.rbxmx), not binary .rbxm"
    assert source.stat().st_size <= 10 * 1024 * 1024, "Animation export exceeds 10 MiB"
    animations.validate_clip(name, clips[name])
    frames = animations.read_rbxmx(source, clips[name], name)
    print(f"PASS {name}: {len(frames)} keyframes, {frames[-1][0]:g} seconds")
    if check_only:
        return None
    target = animations.TARGET / (name + ".rbxmx")
    manifest = json.loads(animations.MANIFEST.read_text(encoding="utf-8"))
    assert target.exists() and name in manifest, "Run python scripts/check.py once to establish the generated baseline"
    text = source.read_text(encoding="utf-8")
    previous = target.read_text(encoding="utf-8")
    backup = animations.ROOT / "build/animation-backups" / name / (animations.digest(previous) + ".rbxmx")
    backup.parent.mkdir(parents=True, exist_ok=True)
    backup.write_text(previous, encoding="utf-8")
    # Preserve the last generated hash; the generator recognizes the new bytes as an authored edit.
    target.write_text(text, encoding="utf-8")
    animations.generate()
    print(f"IMPORTED {name}; previous file: {backup}")
    return backup


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("clip", help="Catalog clip name, e.g. tanjiro/combo_1")
    parser.add_argument("export", type=Path, help="Studio KeyframeSequence saved as XML Model (.rbxmx)")
    parser.add_argument("--check-only", action="store_true", help="Validate without changing files")
    args = parser.parse_args()
    import_clip(args.clip, args.export, args.check_only)
