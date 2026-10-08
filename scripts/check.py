"""Validate content, compile all Luau, execute pure rules tests, and build a place."""
import json
import math
import shutil
import subprocess
import sys
from pathlib import Path
from generate_content import generate
import generate_animations

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
    sword_fields = {"bladeColor", "edgeColor", "tsuba", "tsubaColor", "wrapColor", "sayaColor", "fittingColor", "cordColor", "length", "curve", "bladeDepth", "source", "preset"}
    def sword_spec(name, spec):
        assert set(spec) <= sword_fields, name
        for key, value in spec.items():
            if key.endswith("Color"):
                assert len(value) == 3 and all(isinstance(n, int) and 0 <= n <= 255 for n in value), name
        assert spec.get("tsuba", "round") in {"round", "square", "hex", "flame", "flower", "wheel", "bar"}, name
        assert 2.4 <= spec.get("length", 3.2) <= 4 and 0 <= spec.get("curve", 0) <= 0.12 and 0.08 <= spec.get("bladeDepth", 0.22) <= 0.3, name
        assert spec.get("source", "original") == "original" or spec["source"] in d["sources"], name
        assert spec.get("preset", "nichirin_base") in d["swordPresets"], name
    assert "nichirin_base" in d["swordPresets"] and set(d["swordPresets"]["nichirin_base"]) == sword_fields - {"preset"}
    for name, spec in d["swordPresets"].items():
        sword_spec(name, spec)
    for cid, c in d["characters"].items():
        if "sword" in c:
            assert c["weapon"] in {"katana", "needle", "serpent"}, cid
            sword_spec(cid, c["sword"])
    assert len({c["id"] for c in d["chapters"]}) == len(d["chapters"])
    for n, chapter in enumerate(d["chapters"], 1):
        assert chapter["index"] == n and chapter["location"] in d["locations"]
        assert (chapter["enemies"] or chapter.get("story")) and all(e in d["characters"] for e in chapter["enemies"])
        assert chapter["mentor"] in d["characters"]
        if story := chapter.get("story"):
            assert story["character"] in d["characters"] and all(s in d["sources"] for s in story["sources"])
            assert story.get("map") in {None, "sagiri", "selection", "town", "swamp", "asakusa", "clinic", "tsuzumi"}
            if loadout := story.get("loadout"):
                assert len(loadout) == len(set(loadout)) == 4
                assert all(move in d["characters"][story["character"]]["moves"] for move in loadout)
            assert len({s["id"] for s in story["steps"]}) == len(story["steps"])
            actors = {a["id"] for a in story["actors"]}
            assert len(actors) == len(story["actors"])
            assert all(vector(a["position"]) and (not a.get("template") or a["template"] in d["characters"]) for a in story["actors"])
            assert all(isinstance(a.get("unarmed", False), bool) for a in story["actors"])
            assert all(vector(pos) for pos in story["targets"].values())
            assert all(vector(shot["from"]) and vector(shot["to"]) and shot["from"] != shot["to"] for shot in story["shots"].values())
            for step in story["steps"]:
                assert step.get("automatic") or step["target"] in story["targets"]
                assert step["scene"] and 0 <= step["clock"] <= 24
                assert all(line["shot"] in story["shots"] and line["text"] for line in step["scene"] + step.get("outro", []))
                assert 0 <= step.get("resultClock", step["clock"]) <= 24
                for field in ("carryAfter", "carryOnScene"):
                    assert step.get(field, "none") in {"none", "charcoal", "nezuko", "box", "box_open"}
                assert step.get("map") in {None, "sagiri", "selection", "town", "swamp", "asakusa", "clinic", "tsuzumi"}
                assert not step.get("map") or vector(step["playerPosition"])
                assert not step.get("map") or step.get("automatic"), "map transitions begin with a scene"
                assert step.get("weaponOnScene") in {None, "none", "borrowed", "black"}
                assert step.get("collectOnScene") in {None, "LostKeepsake", "NezukoTravelBox"}
                assert step.get("revealOnScene") in {None, "NezukoTravelBox"}
                assert all(a in actors for a in step.get("hideChallengeActors", []))
                for line in step["scene"] + step.get("outro", []):
                    if effect := line.get("effect"):
                        assert effect["at"] in actors and effect["pattern"] in {"heal", "burst"}
                        assert 1 <= effect["range"] <= 12 and len(effect["color"]) == 3
                        assert all(isinstance(n, int) and 0 <= n <= 255 for n in effect["color"])
                    for aid, state in line.get("actors", {}).items():
                        assert aid in actors
                        assert "position" not in state or vector(state["position"])
                        assert "moveTo" not in state or (vector(state["moveTo"]) and 0.1 <= state.get("duration", 0) <= 3)
                for field in ("actors", "resultActors"):
                    for aid, state in step.get(field, {}).items():
                        assert aid in actors
                        assert "position" not in state or vector(state["position"])
                        assert "rotation" not in state or vector(state["rotation"])
                        assert "visible" not in state or isinstance(state["visible"], bool)
                if challenge := step.get("challenge"):
                    kind = challenge["kind"]
                    assert kind in {"route", "survive", "strikes", "spar", "breath", "cut", "battle", "hand_boss", "vigil", "swamp", "restrain", "hold", "drums"}
                    assert vector(challenge["start"]) and 0 < challenge["limit"] <= chapter["timeLimit"]
                    assert 0 < challenge["radius"] <= 60 and step.get("outro")
                    assert challenge.get("weapon") in {None, "axe", "practice"}
                    if kind in {"survive", "strikes", "spar", "cut"}:
                        assert challenge["enemy"] in d["characters"] and vector(challenge["spawn"])
                        assert challenge["weapon"] in {"axe", "practice"}
                        assert 0 < challenge.get("damageScale", 0.45) <= 1
                        assert 1 <= challenge.get("hits", 1) <= 20
                    if kind in {"survive", "vigil", "hold"}:
                        assert 0 < challenge["duration"] < challenge["limit"]
                    if kind in {"route", "vigil"}:
                        assert challenge["checkpoints"] and all(c in story["targets"] for c in challenge["checkpoints"])
                    if kind in {"breath", "cut", "restrain"}:
                        assert 0 < challenge["period"] <= 10
                        assert 0 <= challenge["window"][0] < challenge["window"][1] < challenge["period"]
                        assert 1 <= challenge.get("cycles", 1) <= 10
                    if kind in {"battle", "hand_boss", "vigil", "swamp", "hold", "drums"}:
                        assert story.get("loadout") and 1 <= challenge["health"] <= 1000
                    if kind in {"battle", "hold"}:
                        assert 1 <= len(challenge["enemies"]) <= 6
                        assert all(e["id"] in d["characters"] and vector(e["position"]) for e in challenge["enemies"])
                        assert isinstance(challenge.get("techniques", False), bool)
                    if kind == "hold":
                        assert 1 <= challenge["hits"] <= 20 and challenge.get("ally") in actors
                    if kind == "restrain":
                        assert challenge["victim"] in actors and challenge["radius"] <= 5 and step.get("weaponOnScene")=="none"
                    if kind == "hand_boss":
                        assert vector(challenge["spawn"]) and 0 < challenge["damage"] <= 40
                        assert 0.6 <= challenge["windup"] <= 3 and 1 <= challenge["recovery"] <= 6
                        assert 0 < challenge["width"] < challenge["reach"] <= 40 and 0 < challenge["sweep"] <= 20
                    if kind == "drums":
                        assert story["map"] == "tsuzumi" and challenge["enemy"] == "kyogai"
                        assert 0.5 <= challenge["turnTime"] <= 2 and 0.8 <= challenge["windup"] <= 3
                        assert 1 <= challenge["recovery"] <= 6 and 0 < challenge["damage"] <= 30
                        assert 0 < challenge["width"] < challenge["laneGap"] < challenge["reach"] <= 40
                    if kind == "swamp":
                        assert challenge["mode"] in {"ambush", "depths", "last"}
                        assert challenge["bodyCount"] == len(challenge["pools"]) == {"ambush":3,"depths":2,"last":1}[challenge["mode"]]
                        assert all(vector(p) for p in challenge["pools"])
                        assert 0.8 <= challenge["windup"] <= 3 and 1 <= challenge["recovery"] <= 6
                        assert 0 < challenge["damage"] <= 30 and 0 < challenge["width"] < challenge["reach"] <= 30
                        assert 0 <= challenge["duration"] < challenge["limit"] and 0 <= challenge["hits"] <= 10
            for hazard in story.get("hazards", []):
                assert vector(hazard["position"]) and vector(hazard["size"]) and all(n > 0 for n in hazard["size"])
                assert 0 < hazard["windup"] < hazard["windup"] + hazard["active"] < hazard["period"]
                assert 0 <= hazard["offset"] < hazard["period"] and 0 < hazard["damage"] <= 20
    assert sum(c["group"] == "Hashira" for c in d["characters"].values()) == 9
    assert "thunder_2" not in d["characters"]["zenitsu"]["moves"]
    assert "thunder_1" not in d["characters"]["kaigaku"]["moves"]
    assert "water_11" not in d["characters"]["tanjiro"]["moves"]
    print("PASS catalog references, coverage, balance bounds and character restrictions")

def validate_motion_profiles(data, index):
    profiles = data["motionProfiles"]
    assert "base" in profiles and profiles["base"]["clips"] == {}, "base profile must use shared clips"
    # New stance-specific locomotion slots need not exist in base (e.g. Tanjiro's drawn walk).
    slots = {name.removeprefix("base/") for name in index if name.startswith("base/")}
    states = {"idle", "walk", "run", "jump", "fall", "land_light", "land_heavy"}
    locomotion_slots = states | {s + suffix for s in states for suffix in ("_drawn", "_sheathed")}
    for name, profile in profiles.items():
        assert set(profile) == {"clips", "design"} and profile["design"], name
        for slot, target in profile["clips"].items():
            assert slot in slots | locomotion_slots and target in index, f"{name}: unknown slot or clip {slot} -> {target}"
            entry = index[target]
            if slot in locomotion_slots:
                assert entry["category"] == "locomotion", f"{name}: {slot} needs locomotion"
            if baseline := index.get("base/" + slot):
                for field in ("category", "loop", "drawnMask"):
                    assert entry.get(field) == baseline.get(field), f"{name}: {slot} incompatible {field}"
                assert set(baseline.get("markers", {})) <= set(entry.get("markers", {})), f"{name}: {slot} missing timing markers"
            generate_animations.validate_timing(slot, entry["category"], entry["length"],
                [{"name": m, "t": t} for m, t in entry.get("markers", {}).items()])
    for cid, character in data["characters"].items():
        assert character.get("motionProfile", "base") in profiles, f"{cid}: unknown motion profile"
    print(f"PASS {len(profiles)} motion profiles and character assignments")


def main():
    validate()
    generate()
    index = generate_animations.generate()
    validate_motion_profiles(json.loads((ROOT / "data/catalog.json").read_text(encoding="utf-8")), index)
    run([sys.executable, "-m", "unittest", "discover", "-s", "tests", "-p", "test_animations.py"])
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
