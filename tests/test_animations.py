"""Authoring regression tests: run without Studio, writing only inside temporary directories."""
import contextlib
import io
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
from xml.etree import ElementTree as ET

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "scripts"))
import generate_animations as animations
from import_animation import import_clip
from check import validate_motion_profiles


class AnimationAuthoringTests(unittest.TestCase):
    def setUp(self):
        self.stack = contextlib.ExitStack()
        self.addCleanup(self.stack.close)
        self.stack.enter_context(contextlib.redirect_stdout(io.StringIO()))
        self.root = Path(self.stack.enter_context(tempfile.TemporaryDirectory()))
        source = self.root / "data/animations"
        (source / "base").mkdir(parents=True)
        for name in ("combo_1", "idle_drawn", "draw"):
            original = animations.SOURCE / "base" / (name + ".json")
            (source / "base" / original.name).write_bytes(original.read_bytes())
        (self.root / "src/shared").mkdir(parents=True)
        for key, value in {"ROOT": self.root, "SOURCE": source, "TARGET": self.root / "assets/animations",
                           "MANIFEST": self.root / "assets/animation-manifest.json", "INDEX": self.root / "src/shared/AnimationIndex.luau"}.items():
            self.stack.enter_context(patch.object(animations, key, value))
        animations.generate()

    def export(self, name="combo_1"):
        return ET.parse(animations.TARGET / "base" / (name + ".rbxmx"))

    def save(self, tree):
        path = self.root / "Studio export.rbxmx"
        tree.write(path, encoding="utf-8", xml_declaration=True)
        return path

    def test_import_preserves_edits_backup_and_actual_timing(self):
        target = animations.TARGET / "base/combo_1.rbxmx"
        original = target.read_text(encoding="utf-8")
        manifest = animations.MANIFEST.read_bytes()
        tree = self.export()
        for time in tree.findall(".//float[@name='Time']"):
            time.text = str(float(time.text) * 1.5)
        source = self.save(tree)
        backup = import_clip("base/combo_1", source)
        self.assertEqual(backup.read_text(encoding="utf-8"), original)
        self.assertEqual(target.read_text(encoding="utf-8"), source.read_text(encoding="utf-8"))
        index = animations.generate()
        self.assertEqual(target.read_text(encoding="utf-8"), source.read_text(encoding="utf-8"))
        self.assertEqual(animations.MANIFEST.read_bytes(), manifest)
        self.assertAlmostEqual(index["base/combo_1"]["length"], 0.75)
        self.assertAlmostEqual(index["base/combo_1"]["hit"], 0.27)

    def test_preview_and_rejected_import_leave_assets_untouched(self):
        before = {p: p.read_bytes() for p in animations.TARGET.rglob("*.rbxmx")}
        source = self.save(self.export())
        import_clip("base/combo_1", source, check_only=True)
        tree = self.export()
        for frame in tree.findall(".//Item[@class='Keyframe']"):
            for marker in frame.findall("Item[@class='KeyframeMarker']"):
                if marker.find("Properties/string[@name='Name']").text == "Hit":
                    frame.remove(marker)
        with self.assertRaisesRegex(AssertionError, "Hit < End"):
            import_clip("base/combo_1", self.save(tree))
        self.assertFalse((self.root / "build/animation-backups").exists())
        self.assertTrue(all(p.read_bytes() == data for p, data in before.items()))

    def test_export_rejects_duplicate_gates_nonfinite_poses_and_scripts(self):
        for kind in ("duplicate", "nonfinite", "script", "weight", "joint", "time"):
            with self.subTest(kind=kind):
                tree = self.export()
                if kind == "duplicate":
                    for frame in tree.findall(".//Item[@class='Keyframe']"):
                        marker = frame.find("Item[@class='KeyframeMarker']/Properties/string[@name='Name']")
                        if marker is not None:
                            marker.text = "Hit"
                elif kind == "nonfinite":
                    tree.find(".//CoordinateFrame/X").text = "nan"
                elif kind == "script":
                    ET.SubElement(tree.getroot().find("Item"), "Item", {"class": "Script"})
                elif kind == "weight":
                    tree.find(".//float[@name='Weight']").text = "0.5"
                elif kind == "joint":
                    tree.find(".//Item[@class='Pose']/Properties/string[@name='Name']").text = "Torso"
                else:
                    tree.find(".//float[@name='Time']").text = "inf"
                with self.assertRaises(AssertionError):
                    import_clip("base/combo_1", self.save(tree))

    def test_draw_gates_validate_against_target_name_not_export_filename(self):
        tree = self.export("draw")
        for marker in tree.findall(".//Item[@class='KeyframeMarker']/Properties/string[@name='Name']"):
            if marker.text == "Clear":
                marker.text = "Step"
        with self.assertRaisesRegex(AssertionError, "Grip < Clear"):
            import_clip("base/draw", self.save(tree))

    def test_loop_metadata_and_closed_tracks_required(self):
        tree = self.export("idle_drawn")
        tree.find(".//bool[@name='Loop']").text = "false"
        with self.assertRaisesRegex(AssertionError, "Loop"):
            import_clip("base/idle_drawn", self.save(tree))
        tree = self.export("idle_drawn")
        frames = tree.findall(".//Item[@class='Keyframe']")
        poses = frames[-1].findall(".//Item[@class='Pose']")
        for pose in poses:
            if pose.find("Properties/float[@name='Weight']").text == "1":
                pose.find("Properties/CoordinateFrame/X").text = "0.2"
                break
        with self.assertRaisesRegex(AssertionError, "loop does not close"):
            import_clip("base/idle_drawn", self.save(tree))

    def test_profile_rejects_unknown_targets_and_incompatible_override(self):
        index = animations.generate()
        data = {"characters": {"tanjiro": {"motionProfile": "tanjiro"}}, "motionProfiles": {
            "base": {"clips": {}, "design": "shared"},
            "tanjiro": {"clips": {"combo_1": "base/combo_1"}, "design": "test"}}}
        validate_motion_profiles(data, index)
        for target in ("missing/combo_1", "base/idle_drawn"):
            data["motionProfiles"]["tanjiro"]["clips"]["combo_1"] = target
            with self.assertRaises(AssertionError):
                validate_motion_profiles(data, index)


if __name__ == "__main__":
    unittest.main()
