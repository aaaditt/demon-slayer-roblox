# Optional uploaded assets (owner steps)

The game runs without any of these: every empty ID falls back to part-built looks and code-driven animation. Filling them in upgrades Tanjiro to uploaded clothing, a real hair accessory and published Roblox animations.

## 1. Clothing (Shirt / Pants)

1. Run `python scripts/check.py` (or `python scripts/generate_clothing.py`). It writes `assets/clothing/tanjiro_shirt.png` and `tanjiro_pants.png` (585×559 classic templates).
2. Upload each in Creator Hub → Creations → Avatar Items → Shirts / Pants (or Studio → Avatar → Create classic clothing). Uploading clothing may charge a small Robux fee.
3. Copy each item's numeric ID into `data/assets.json` → `characters.tanjiro.shirt` / `characters.tanjiro.pants`.

## 2. Hair, earrings, scar

Pick from the Creator Store (free items, R15-compatible):
- Hair: short, spiky, dark red-black (Tanjiro's hair is black fading to dark red at the tips).
- Earrings: hanafuda (white card with a red rising sun) if one exists; otherwise leave empty (the fallback adds part earrings).
- Face: a face decal with the forehead scar, or leave empty.

Put accessory IDs in `characters.tanjiro.accessories` and the face in `characters.tanjiro.face`; record each item's URL under `provenance`.

## 3. Combat sounds

Roblox ships no sword sounds, so hits currently use pitched built-in sounds. Put Creator Store sound IDs (sword swing, flesh cut, heavy impact, metal block, blade clash, unsheathe) into `data/assets.json` → `sounds` to replace them.

## 4. Animations

1. Run `python scripts/check.py`; open `build/WisteriaChronicles.rbxlx` in Studio.
2. In Explorer, `ServerStorage → AnimSources → Tanjiro` has one KeyframeSequence per animation (`m1_1`, `draw`, `dash_f`, …).
3. For each: select it → right-click → **Save to Roblox** (or open the Animation Editor on an R15 rig, import it and **Publish to Roblox**). Publish under the account/group that owns the experience; animations owned by someone else will not play.
4. Paste each numeric ID into `data/animations.json` under the same name and run `python scripts/check.py` again.

Clients play a published animation when its ID is present, and the code keyframe player otherwise. Hit timing always comes from the server's copy of the keyframe markers, so publishing never changes gameplay.

## Checking

`python scripts/check.py` rejects non-numeric IDs and fails if `data/animations.json` names differ from the authored animation set.
