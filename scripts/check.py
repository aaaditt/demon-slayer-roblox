"""Validate content, compile all Luau, execute pure rules tests, and build a place."""
import json
import math
import shutil
import subprocess
import sys
from pathlib import Path
from generate_content import generate
from build_keyframes import build as build_keyframes
from generate_clothing import generate as generate_clothing

ROOT = Path(__file__).resolve().parents[1]

def tool(folder, name):
    suffix = ".exe" if sys.platform == "win32" else ""
    local = ROOT / ".tools" / folder / (name + suffix)
    found = str(local) if local.exists() else shutil.which(name)
    if not found:
        raise RuntimeError(f"Missing {name}; run scripts/bootstrap.ps1 on Windows, or install pinned tools from docs/SETUP.md")
    return found

def run(args, quiet=False):
    result = subprocess.run(args, cwd=ROOT, text=True, encoding="utf-8", capture_output=quiet)
    if result.returncode:
        if quiet:
            print(result.stdout, result.stderr)
        raise RuntimeError(f"Command failed: {args[0]}")

def validate():
    d = json.loads((ROOT / "data/catalog.json").read_text(encoding="utf-8"))
    def vector(value):
        return len(value) == 3 and all(isinstance(n, (int, float)) and math.isfinite(n) for n in value)
    for mid, m in d["moves"].items():
        assert mid == m["id"] and m["style"] in d["styles"] and m["source"] in d["sources"], mid
        assert m["pattern"] in {"slash", "thrust", "dash", "spin", "barrage", "projectile", "burst", "guard", "evade", "heal", "trap", "summon"}, mid
        assert m["status"] in {"none", "poison", "burn", "chill", "shock", "sleep", "root", "cleanse"}, mid
        assert 0 <= m["damage"] <= 60 and 1 <= m["cost"] <= 100 and 0 < m["cooldown"] <= 60, mid
        assert 0 <= m["dash"] <= 30 and 0 <= m["range"] <= 80 and 1 <= m["hits"] <= 8, mid
        assert m["windup"] > 0 and m["recovery"] > 0, mid
    for cid, c in d["characters"].items():
        assert cid == c["id"] and all(m in d["moves"] for m in c["moves"]), cid
        assert len(set(c["moves"])) == len(c["moves"]), cid
        if c["playable"]:
            assert len(c["loadout"]) == 4 and len(set(c["loadout"])) == 4, cid
            assert all(m in c["moves"] for m in c["loadout"]), cid
    assert len({c["id"] for c in d["chapters"]}) == len(d["chapters"])
    for n, chapter in enumerate(d["chapters"], 1):
        assert chapter["index"] == n and chapter["location"] in d["locations"]
        assert (chapter["enemies"] or chapter.get("story")) and all(e in d["characters"] for e in chapter["enemies"])
        assert chapter["mentor"] in d["characters"]
        if story := chapter.get("story"):
            assert story["character"] in d["characters"] and all(s in d["sources"] for s in story["sources"])
            assert len({s["id"] for s in story["steps"]}) == len(story["steps"])
            actors = {a["id"] for a in story["actors"]}
            assert len(actors) == len(story["actors"])
            assert all(vector(a["position"]) and (not a.get("template") or a["template"] in d["characters"]) for a in story["actors"])
            assert all(vector(pos) for pos in story["targets"].values())
            assert all(vector(shot["from"]) and vector(shot["to"]) and shot["from"] != shot["to"] for shot in story["shots"].values())
            for step in story["steps"]:
                assert step.get("automatic") or step["target"] in story["targets"]
                assert step["scene"] and 0 <= step["clock"] <= 24
                assert all(line["shot"] in story["shots"] and line["text"] for line in step["scene"] + step.get("outro", []))
                assert 0 <= step.get("resultClock", step["clock"]) <= 24
                for field in ("carryAfter", "carryOnScene"):
                    assert step.get(field, "none") in {"none", "charcoal", "nezuko"}
                for field in ("actors", "resultActors"):
                    for aid, state in step.get(field, {}).items():
                        assert aid in actors
                        assert "position" not in state or vector(state["position"])
                        assert "rotation" not in state or vector(state["rotation"])
                        assert "visible" not in state or isinstance(state["visible"], bool)
                if challenge := step.get("challenge"):
                    kind = challenge["kind"]
                    assert kind in {"route", "survive", "strikes", "spar", "breath", "cut"}
                    assert vector(challenge["start"]) and 0 < challenge["limit"] <= chapter["timeLimit"]
                    assert 0 < challenge["radius"] <= 40 and step.get("outro")
                    assert challenge.get("weapon") in {None, "axe", "practice"}
                    if kind in {"survive", "strikes", "spar", "cut"}:
                        assert challenge["enemy"] in d["characters"] and vector(challenge["spawn"])
                        assert challenge["weapon"] in {"axe", "practice"}
                        assert 0 < challenge.get("damageScale", 0.45) <= 1
                        assert 1 <= challenge.get("hits", 1) <= 20
                    if kind == "survive":
                        assert 0 < challenge["duration"] < challenge["limit"]
                    if kind == "route":
                        assert challenge["checkpoints"] and all(c in story["targets"] for c in challenge["checkpoints"])
                    if kind in {"breath", "cut"}:
                        assert 0 < challenge["period"] <= 10
                        assert 0 <= challenge["window"][0] < challenge["window"][1] < challenge["period"]
                        assert 1 <= challenge.get("cycles", 1) <= 10
            for hazard in story.get("hazards", []):
                assert vector(hazard["position"]) and vector(hazard["size"]) and all(n > 0 for n in hazard["size"])
                assert 0 < hazard["windup"] < hazard["windup"] + hazard["active"] < hazard["period"]
                assert 0 <= hazard["offset"] < hazard["period"] and 0 < hazard["damage"] <= 20
    assert sum(c["group"] == "Hashira" for c in d["characters"].values()) == 9
    assert "thunder_2" not in d["characters"]["zenitsu"]["moves"]
    assert "thunder_1" not in d["characters"]["kaigaku"]["moves"]
    assert "water_11" not in d["characters"]["tanjiro"]["moves"]
    print("PASS catalog references, coverage, balance bounds and character restrictions")

def main():
    validate()
    generate()
    generate_clothing()
    build_keyframes()
    compiler = tool("luau", "luau-compile")
    files = sorted(ROOT.glob("src/**/*.luau")) + sorted(ROOT.glob("tests/*.luau"))
    for path in files:
        run([compiler, "--null", str(path)], quiet=True)
    print(f"PASS compiled {len(files)} Luau files")
    run([tool("luau", "luau"), "tests/core.spec.luau"])
    (ROOT / "build").mkdir(exist_ok=True)
    run([tool("rojo", "rojo"), "build", "default.project.json", "-o", "build/WisteriaChronicles.rbxlx"])
    print("PASS build/WisteriaChronicles.rbxlx")

if __name__ == "__main__":
    main()
