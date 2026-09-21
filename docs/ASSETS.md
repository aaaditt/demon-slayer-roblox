# Optional uploaded assets (owner steps)

**The game is complete without any upload.** Outfits are drawn onto the body with SurfaceGui patterns in code, animations fall back to the code keyframe player, and sounds fall back to built-in Roblox audio. Fill these in only if you want to.

## What costs Robux, and what does not

| Asset | Cost | Verified |
|---|---|---|
| Studio, local 2-player tests, publishing your place | **Free** | Standard Roblox behaviour |
| Publishing animations (Animation Editor → Publish to Roblox) | **Free** (no fee documented) | [Animation editor docs](https://create.roblox.com/docs/animation/editor) |
| Audio uploads | **Free**, 100 per 30 days (2,000 if ID-verified), ≤7 min and ≤20 MB each | [Audio assets docs](https://create.roblox.com/docs/audio/assets) |
| Images / decals | No fee documented; the upload page shows a price if one applies | [Decal upload](https://create.roblox.com/dashboard/creations/upload?assetType=Decal) |
| Free Creator Store models and accessories (hair, props) | **Free** | Creator Store |
| **Classic Shirt / Pants uploads** | **80 Robux per upload** since 14 July 2026 (was 10) | [Fee change](https://www.ugcraft.ai/posts/roblox-2d-clothing-update-2026) |
| UGC 3D accessories | Paid, plus marketplace access requirements | Roblox marketplace docs |

**We do not use classic clothing.** Tanjiro's uniform, checkered haori, obi, leg wraps and scar are drawn in `src/server/CharacterBody.luau` with SurfaceGui panels, which cost nothing and work for every character.

## 1. Hair and accessories (free, optional)

Take free items from the Creator Store: short spiky dark red-black hair, and hanafuda earrings if any exist. Put their IDs in `data/assets.json` → `characters.tanjiro.accessories`, and record the item URLs under `provenance`. With none set, the code-built hair and earrings are used.

## 2. Combat sounds (free, optional)

Roblox ships no sword sounds, so hits currently use pitched built-in sounds. Upload your own audio (free, see limits above) or take free Creator Store sounds, then put the IDs in `data/assets.json` → `sounds` (`swing`, `hit`, `finisher`, `block`, `clash`, `draw`).

## 3. Animations (free, optional, improves smoothness)

1. Run `python scripts/check.py`, open `build/WisteriaChronicles.rbxlx` in Studio.
2. `ServerStorage → AnimSources → Tanjiro` holds one KeyframeSequence per animation (`m1_1`, `draw`, `dash_f`, …).
3. For each: right-click → **Save to Roblox**, or load it in the Animation Editor and **Publish to Roblox**. Publish under the account or group that owns the experience; animations owned by someone else will not play.
4. Paste each numeric ID into `data/animations.json` and run `python scripts/check.py` again.

Clients play a published animation when its ID is present and the code keyframe player otherwise. Hit timing always comes from the server's copy of the keyframe markers, so publishing never changes gameplay.

## 4. Clothing textures (only if you ever choose to pay)

`python scripts/generate_clothing.py` still writes `assets/clothing/tanjiro_shirt.png` and `tanjiro_pants.png` (585×559 classic templates). Uploading them as Shirt/Pants costs 80 Robux each. If you do, put the IDs in `data/assets.json` → `characters.tanjiro.shirt` / `.pants`; the code-drawn outfit then steps aside automatically.

A free alternative worth testing: upload the PNGs as **Decals** (free) and try setting the shirt template to that image ID. Roblox has historically accepted image assets there. If it works, you get true clothing for nothing; if it is rejected, the code-drawn outfit is unaffected.

## Checking

`python scripts/check.py` rejects non-numeric IDs and fails if `data/animations.json` names differ from the authored animation set.
