"""Export authored keyframes to Roblox KeyframeSequences and generate asset-ID modules.

Outputs:
  build/AnimSources.rbxmx   -> ServerStorage.AnimSources (publish these in Studio; see docs/ASSETS.md)
  src/shared/AnimIds.luau   <- data/animations.json (generated; do not hand-edit)
  src/shared/Assets.luau    <- data/assets.json     (generated; do not hand-edit)
"""
import json
import math
import re
import shutil
import subprocess
import sys
from pathlib import Path
from xml.sax.saxutils import escape

from generate_content import lua

ROOT = Path(__file__).resolve().parents[1]
PRIORITY = {"Idle": 0, "Movement": 1, "Action": 2}
# PoseEasingStyle: Linear 0, Constant 1, Elastic 2, Cubic 3, Bounce 4. PoseEasingDirection: In 0, Out 1, InOut 2.
EASING = {"linear": (0, 0), "in": (3, 0), "out": (3, 1), "inout": (3, 2)}
PARENT = {
    "Root": ("HumanoidRootPart", "LowerTorso"), "Waist": ("LowerTorso", "UpperTorso"), "Neck": ("UpperTorso", "Head"),
    "RightShoulder": ("UpperTorso", "RightUpperArm"), "RightElbow": ("RightUpperArm", "RightLowerArm"), "RightWrist": ("RightLowerArm", "RightHand"),
    "LeftShoulder": ("UpperTorso", "LeftUpperArm"), "LeftElbow": ("LeftUpperArm", "LeftLowerArm"), "LeftWrist": ("LeftLowerArm", "LeftHand"),
    "RightHip": ("LowerTorso", "RightUpperLeg"), "RightKnee": ("RightUpperLeg", "RightLowerLeg"), "RightAnkle": ("RightLowerLeg", "RightFoot"),
    "LeftHip": ("LowerTorso", "LeftUpperLeg"), "LeftKnee": ("LeftUpperLeg", "LeftLowerLeg"), "LeftAnkle": ("LeftLowerLeg", "LeftFoot"),
}
PART_JOINT = {part: joint for joint, (_, part) in PARENT.items()}


def luau_binary():
    suffix = ".exe" if sys.platform == "win32" else ""
    local = ROOT / ".tools" / "luau" / ("luau" + suffix)
    found = str(local) if local.exists() else shutil.which("luau")
    if not found:
        raise RuntimeError("Missing luau; run scripts/bootstrap.ps1 or see docs/SETUP.md")
    return found


def load_sets():
    out = subprocess.run([luau_binary(), "scripts/dump_animdata.luau"], cwd=ROOT, capture_output=True, text=True, encoding="utf-8", check=True)
    return json.loads(out.stdout)


def matrix(v):
    """CFrame.new(px,py,pz) * CFrame.Angles(rx,ry,rz): R = Rx * Ry * Rz (radians)."""
    rx, ry, rz = (math.radians(a) for a in (v + [0, 0, 0])[:3])
    px, py, pz = (v + [0, 0, 0, 0, 0, 0])[3:6]
    cx, sx, cy, sy, cz, sz = math.cos(rx), math.sin(rx), math.cos(ry), math.sin(ry), math.cos(rz), math.sin(rz)
    r = [
        [cy * cz, -cy * sz, sy],
        [cx * sz + sx * sy * cz, cx * cz - sx * sy * sz, -sx * cy],
        [sx * sz - cx * sy * cz, sx * cz + cx * sy * sz, cx * cy],
    ]
    return px, py, pz, r


def cframe(v):
    px, py, pz, r = matrix(v)
    cells = "".join(f"<R{i}{j}>{r[i][j]:.6f}</R{i}{j}>" for i in range(3) for j in range(3))
    return f'<CoordinateFrame name="CFrame"><X>{px:.4f}</X><Y>{py:.4f}</Y><Z>{pz:.4f}</Z>{cells}</CoordinateFrame>'


def pose_tree(pose, easing):
    """Nest Poses along the R15 hierarchy so every animated joint's Part1 hangs under its Part0."""
    children = {}
    needed = set()
    for joint in pose:
        part = PARENT[joint][1]
        while part != "HumanoidRootPart":
            needed.add(part)
            part = PARENT[PART_JOINT[part]][0]
    for part in needed:
        children.setdefault(PARENT[PART_JOINT[part]][0], []).append(part)
    style, direction = EASING[easing]

    def node(part):
        joint = PART_JOINT.get(part)
        value = pose.get(joint, [0, 0, 0]) if joint else [0, 0, 0]
        weight = 1 if joint in pose or part == "HumanoidRootPart" else 0
        inner = "".join(node(c) for c in sorted(children.get(part, [])))
        return (f'<Item class="Pose"><Properties><string name="Name">{part}</string>{cframe(value)}'
                f'<token name="EasingStyle">{style}</token><token name="EasingDirection">{direction}</token>'
                f'<float name="Weight">{weight}</float></Properties>{inner}</Item>')
    return node("HumanoidRootPart")


def sequence(name, anim):
    frames = anim["keyframes"]
    items = []
    for i, key in enumerate(frames):
        # Roblox eases from a keyframe toward the next one; our data stores easing on the destination keyframe.
        easing = frames[i + 1]["easing"] if i + 1 < len(frames) else "linear"
        items.append(f'<Item class="Keyframe"><Properties><string name="Name">Keyframe</string><float name="Time">{key["t"]}</float></Properties>{pose_tree(key["pose"], easing)}</Item>')
    for marker, time in sorted(anim.get("markers", {}).items()):
        items.append(f'<Item class="Keyframe"><Properties><string name="Name">{marker}</string><float name="Time">{time}</float></Properties>'
                     f'<Item class="KeyframeMarker"><Properties><string name="Name">{marker}</string><string name="Value"></string></Properties></Item></Item>')
    loop = "true" if anim.get("loop") else "false"
    return (f'<Item class="KeyframeSequence"><Properties><string name="Name">{escape(name)}</string><bool name="Loop">{loop}</bool>'
            f'<token name="Priority">{PRIORITY[anim["priority"]]}</token></Properties>{"".join(items)}</Item>')


def build():
    sets = load_sets()
    animations = json.loads((ROOT / "data/animations.json").read_text(encoding="utf-8"))
    assets = json.loads((ROOT / "data/assets.json").read_text(encoding="utf-8"))
    for name, anims in sets.items():
        assert set(animations.get(name, {})) == set(anims), f"data/animations.json ids differ from AnimData for {name}"
    for ids in animations.values():
        assert all(re.fullmatch(r"\d*", v) for v in ids.values()), "animation IDs must be digits or empty"
    for character in assets.values():
        for key in ("shirt", "pants", "face"):
            assert re.fullmatch(r"\d*", character[key]), f"{key} asset ID must be digits or empty"
        assert all(re.fullmatch(r"\d+", a) for a in character["accessories"]), "accessory IDs must be digits"
    folders = "".join(f'<Item class="Folder"><Properties><string name="Name">{n}</string></Properties>{"".join(sequence(i, a) for i, a in sorted(anims.items()))}</Item>'
                      for n, anims in sorted(sets.items()))
    xml = ('<roblox version="4"><Item class="Folder"><Properties><string name="Name">AnimSources</string></Properties>'
           + folders + "</Item></roblox>")
    (ROOT / "build").mkdir(exist_ok=True)
    (ROOT / "build/AnimSources.rbxmx").write_text(xml, encoding="utf-8")
    header = "-- Generated by scripts/build_keyframes.py; edit data/{}.\nreturn "
    (ROOT / "src/shared/AnimIds.luau").write_text(header.format("animations.json") + lua(animations) + "\n", encoding="utf-8")
    (ROOT / "src/shared/Assets.luau").write_text(header.format("assets.json") + lua(assets) + "\n", encoding="utf-8")
    count = sum(len(a) for a in sets.values())
    published = sum(bool(v) for ids in animations.values() for v in ids.values())
    print(f"PASS exported {count} KeyframeSequences ({published} published IDs) and asset modules")


if __name__ == "__main__":
    build()
