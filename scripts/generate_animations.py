"""Generate Animation Editor KeyframeSequence clips (.rbxmx) and a runtime index from data/animations.

Clips are authored as JSON (joint name -> Euler degrees / stud offsets). The output is a real
KeyframeSequence that opens in Studio's Animation Editor. A clip refined in Studio and saved back over
its .rbxmx no longer matches the recorded hash, so it is never regenerated; its JSON only supplies
metadata (category, loop, speed) from then on.
"""
import hashlib
import json
import math
import sys
from pathlib import Path
from xml.etree import ElementTree

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "data/animations"
TARGET = ROOT / "assets/animations"
MANIFEST = ROOT / "assets/animation-manifest.json"
INDEX = ROOT / "src/shared/AnimationIndex.luau"

# Joint (Motor6D) name -> (Part1 name, parent part name). Pose trees follow Part1 names.
JOINTS = {
    "Root": ("LowerTorso", "HumanoidRootPart"),
    "Waist": ("UpperTorso", "LowerTorso"),
    "Neck": ("Head", "UpperTorso"),
}
for _side in ("Right", "Left"):
    JOINTS[_side + "Shoulder"] = (_side + "UpperArm", "UpperTorso")
    JOINTS[_side + "Elbow"] = (_side + "LowerArm", _side + "UpperArm")
    JOINTS[_side + "Wrist"] = (_side + "Hand", _side + "LowerArm")
    JOINTS[_side + "Hip"] = (_side + "UpperLeg", "LowerTorso")
    JOINTS[_side + "Knee"] = (_side + "LowerLeg", _side + "UpperLeg")
    JOINTS[_side + "Ankle"] = (_side + "Foot", _side + "LowerLeg")
PARTS = {"HumanoidRootPart"} | {part for part, _ in JOINTS.values()}
PRIORITY = {"Idle": 0, "Movement": 1, "Action": 2, "Action2": 3, "Action3": 4, "Action4": 5, "Core": 1000}
STYLES = {"Linear": 0, "Constant": 1, "Elastic": 2, "Cubic": 3, "Bounce": 4, "CubicV2": 5}
DIRECTIONS = {"In": 0, "Out": 1, "InOut": 2}
CATEGORIES = {"locomotion", "action", "attack", "story"}
MARKERS = {"Hit", "End", "Grip", "Release", "TrailOn", "TrailOff", "Click", "Step"}


def rotation(rx, ry, rz):
    """Row-major matrix of CFrame.Angles(rx, ry, rz) = Rx * Ry * Rz (radians)."""
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    x = [[1, 0, 0], [0, cx, -sx], [0, sx, cx]]
    y = [[cy, 0, sy], [0, 1, 0], [-sy, 0, cy]]
    z = [[cz, -sz, 0], [sz, cz, 0], [0, 0, 1]]
    mul = lambda a, b: [[sum(a[i][k] * b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
    return mul(mul(x, y), z)


def mirror_name(joint):
    if joint.startswith("Right"):
        return "Left" + joint[5:]
    if joint.startswith("Left"):
        return "Right" + joint[4:]
    return joint


def normalise(value, default_ease):
    """A joint value is [rx, ry, rz] in degrees or {"r": [...], "p": [...], "ease": "Style/Direction"}."""
    if isinstance(value, list):
        value = {"r": value}
    ease = value.get("ease", default_ease)
    return {"r": list(value.get("r", [0, 0, 0])), "p": list(value.get("p", [0, 0, 0])), "ease": ease}


def mirrored(clip):
    """Reflect across the character's X plane: swap sides, negate Y/Z rotation and X offset."""
    out = dict(clip)
    out["keyframes"] = []
    for frame in clip["keyframes"]:
        pose = {}
        for joint, value in frame["pose"].items():
            v = normalise(value, frame.get("ease", clip.get("ease", "CubicV2/InOut")))
            pose[mirror_name(joint)] = {"r": [v["r"][0], -v["r"][1], -v["r"][2]], "p": [-v["p"][0], v["p"][1], v["p"][2]], "ease": v["ease"]}
        out["keyframes"].append({**frame, "pose": pose})
    return out


def load_clips():
    raw = {}
    for path in sorted(SOURCE.rglob("*.json")):
        name = path.relative_to(SOURCE).with_suffix("").as_posix()
        raw[name] = json.loads(path.read_text(encoding="utf-8"))
    clips = {}
    for name, clip in raw.items():
        if "mirrorOf" in clip:
            base = raw[clip["mirrorOf"]]
            assert "mirrorOf" not in base, name + ": mirrors cannot chain"
            clip = {**mirrored(base), **{k: v for k, v in clip.items() if k != "mirrorOf"}}
        clips[name] = clip
    return clips


def validate_clip(name, clip):
    assert clip.get("category") in CATEGORIES, name + ": category"
    assert clip.get("priority", "Action") in PRIORITY, name + ": priority"
    frames = clip["keyframes"]
    assert frames and frames[0]["t"] == 0, name + ": first keyframe must be at t=0"
    times = [f["t"] for f in frames]
    assert all(b > a for a, b in zip(times, times[1:])), name + ": keyframe times must increase"
    length = times[-1]
    assert 0 < length <= 30, name + ": length"
    for frame in frames:
        for joint, value in frame["pose"].items():
            assert joint in JOINTS, f"{name}: unknown joint {joint}"
            v = normalise(value, frame.get("ease", clip.get("ease", "CubicV2/InOut")))
            style, _, direction = v["ease"].partition("/")
            assert style in STYLES and direction in DIRECTIONS, f"{name}: easing {v['ease']}"
            assert len(v["r"]) == 3 and len(v["p"]) == 3 and all(abs(n) <= 360 for n in v["r"]) and all(abs(n) <= 4 for n in v["p"]), f"{name}: {joint} range"
    for marker in clip.get("markers", []):
        assert marker["name"] in MARKERS and 0 <= marker["t"] <= length, f"{name}: marker {marker}"
    if clip.get("loop"):
        first, last = frames[0]["pose"], frames[-1]["pose"]
        norm = lambda pose: {j: (normalise(v, "")["r"], normalise(v, "")["p"]) for j, v in pose.items()}
        assert norm(first) == norm(last), name + ": looping clips must end on their first pose"
    if clip["category"] == "attack":
        marks = {m["name"]: m["t"] for m in clip.get("markers", [])}
        assert "Hit" in marks and "End" in marks and 0 < marks["Hit"] < marks["End"] <= length, name + ": attack clips need Hit < End"
    if clip["category"] == "locomotion":
        assert clip.get("speed", 0) >= 0, name + ": speed"
    # "lower": while the sword is drawn only the legs and root play, so the upper body keeps its stance.
    assert clip.get("drawnMask") in (None, "lower"), name + ": drawnMask"


class Writer:
    def __init__(self):
        self.next = 0

    def item(self, parent, cls, props):
        item = ElementTree.SubElement(parent, "Item", {"class": cls, "referent": f"RBX{self.next}"})
        self.next += 1
        properties = ElementTree.SubElement(item, "Properties")
        for kind, key, value in props:
            element = ElementTree.SubElement(properties, kind, {"name": key})
            if kind == "CoordinateFrame":
                for axis, number in value.items():
                    ElementTree.SubElement(element, axis).text = fmt(number)
            else:
                element.text = value if isinstance(value, str) else fmt(value) if not isinstance(value, bool) else ("true" if value else "false")
        return item


def fmt(number):
    text = f"{number:.6f}".rstrip("0").rstrip(".")
    return "0" if text in ("-0", "") else text


def cframe(rot_deg, pos):
    m = rotation(*(math.radians(a) for a in rot_deg))
    frame = {"X": pos[0], "Y": pos[1], "Z": pos[2]}
    for i in range(3):
        for j in range(3):
            frame[f"R{i}{j}"] = m[i][j]
    return frame


def build_xml(name, clip):
    writer = Writer()
    root = ElementTree.Element("roblox", {"xmlns:xmime": "http://www.w3.org/2005/05/xmlmime", "xmlns:xsi": "http://www.w3.org/2001/XMLSchema-instance", "xsi:noNamespaceSchemaLocation": "http://www.roblox.com/roblox.xsd", "version": "4"})
    sequence = writer.item(root, "KeyframeSequence", [("string", "Name", name.split("/")[-1]), ("bool", "Loop", bool(clip.get("loop"))), ("token", "Priority", str(PRIORITY[clip.get("priority", "Action")]))])
    default_ease = clip.get("ease", "CubicV2/InOut")
    marker_times = {m["t"] for m in clip.get("markers", [])}
    frames = {f["t"]: f for f in clip["keyframes"]}
    for t in sorted(set(frames) | marker_times):
        keyframe = writer.item(sequence, "Keyframe", [("string", "Name", "Keyframe"), ("float", "Time", t)])
        frame = frames.get(t)
        if frame:
            keyed = {JOINTS[j][0]: normalise(v, frame.get("ease", default_ease)) for j, v in frame["pose"].items()}
            # Structural ancestors carry Weight 0, the Animation Editor's convention for unkeyed hierarchy poses.
            needed = set()
            for part in keyed:
                while part != "HumanoidRootPart":
                    needed.add(part)
                    part = next(parent for p, parent in JOINTS.values() if p == part)
            parent_of = {p: parent for p, parent in JOINTS.values()}

            def emit(parent_element, part):
                value = keyed.get(part)
                style, _, direction = (value["ease"] if value else "Linear/In").partition("/")
                pose = writer.item(parent_element, "Pose", [
                    ("string", "Name", part),
                    ("CoordinateFrame", "CFrame", cframe(value["r"], value["p"]) if value else cframe([0, 0, 0], [0, 0, 0])),
                    ("token", "EasingDirection", str(DIRECTIONS[direction])),
                    ("token", "EasingStyle", str(STYLES[style])),
                    ("float", "Weight", 1 if value else 0),
                ])
                for child in sorted(p for p in needed if parent_of[p] == part):
                    emit(pose, child)
            emit(keyframe, "HumanoidRootPart")
        for marker in clip.get("markers", []):
            if marker["t"] == t:
                writer.item(keyframe, "KeyframeMarker", [("string", "Name", marker["name"]), ("string", "Value", marker.get("value", ""))])
    ElementTree.indent(root, "  ")
    return ElementTree.tostring(root, encoding="unicode") + "\n"


def read_rbxmx(path):
    """Parse a KeyframeSequence file (generated or saved by Studio) into times, pose names and markers."""
    tree = ElementTree.parse(path)
    sequence = tree.getroot().find("Item[@class='KeyframeSequence']")
    assert sequence is not None, f"{path}: no KeyframeSequence"
    def prop(item, query):
        found = item.find("Properties/" + query)
        assert found is not None and found.text is not None, f"{path}: missing {query}"
        return found.text

    frames = []
    for keyframe in sequence.findall("Item[@class='Keyframe']"):
        time = float(prop(keyframe, "float[@name='Time']"))
        poses = [prop(p, "string[@name='Name']") for p in keyframe.iter("Item") if p.get("class") == "Pose"]
        markers = [prop(m, "string[@name='Name']") for m in keyframe.findall("Item[@class='KeyframeMarker']")]
        frames.append((time, poses, markers))
    return sorted(frames, key=lambda f: f[0])


def digest(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def generate(check_only=False):
    clips = load_clips()
    for name, clip in clips.items():
        validate_clip(name, clip)
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8")) if MANIFEST.exists() else {}
    written, kept = 0, []
    for name, clip in clips.items():
        target = TARGET / (name + ".rbxmx")
        text = build_xml(name, clip)
        if target.exists():
            current = digest(target.read_text(encoding="utf-8"))
            if manifest.get(name) and current != manifest[name]:
                kept.append(name)  # Refined in Studio: never overwrite.
                continue
            if current == digest(text):
                manifest[name] = current
                continue
        if not check_only:
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(text, encoding="utf-8")
            manifest[name] = digest(text)
            written += 1
    for path in sorted(TARGET.rglob("*.rbxmx")):
        name = path.relative_to(TARGET).with_suffix("").as_posix()
        assert name in clips, f"{path}: clip has no JSON source for its metadata"
        frames = read_rbxmx(path)
        assert frames and frames[0][0] == 0, f"{path}: first keyframe must be at 0"
        for _, poses, markers in frames:
            assert all(p in PARTS for p in poses), f"{path}: pose names must be rig parts"
            assert all(m in MARKERS for m in markers), f"{path}: unknown marker"
        clips[name]["length"] = frames[-1][0]
        clips[name]["markerTimes"] = {m: t for t, _, ms in frames for m in ms}
    index = {}
    for name, clip in clips.items():
        entry = {"category": clip["category"], "loop": bool(clip.get("loop")), "length": clip.get("length", clip["keyframes"][-1]["t"]), "speed": clip.get("speed", 0)}
        marks = clip.get("markerTimes") or {m["name"]: m["t"] for m in clip.get("markers", [])}
        if clip.get("drawnMask"):
            entry["drawnMask"] = clip["drawnMask"]
        if "Hit" in marks:
            entry["hit"], entry["finish"] = marks["Hit"], marks["End"]
        index[name] = entry
    if not check_only:
        MANIFEST.parent.mkdir(parents=True, exist_ok=True)
        MANIFEST.write_text(json.dumps(manifest, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        from generate_content import lua
        INDEX.write_text("-- Generated by scripts/generate_animations.py; edit data/animations.\nreturn " + lua(dict(sorted(index.items()))) + "\n", encoding="utf-8")
    for name in kept:
        print(f"KEPT {name}: edited in Studio, not regenerated")
    print(f"PASS {len(clips)} animation clips ({written} written, {len(kept)} Studio-edited)")
    return index


if __name__ == "__main__":
    generate(check_only="--check" in sys.argv)
