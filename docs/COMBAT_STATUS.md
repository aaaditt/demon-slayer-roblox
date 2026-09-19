# Combat slice status (branch `combat/tanjiro`)

Updated: 2026-09-19. Spec: `superpowers/specs/2026-09-19-tanjiro-combat-design.md`. Plan: `superpowers/plans/2026-09-19-tanjiro-combat.md`.

This file exists so the branch does not conflict with the owner's uncommitted edits to STATUS.md, WORKLOG.md, QA.md, README.md and RESEARCH.md on `main`. Fold its sections into those files when merging.

## What is implemented

- **R15 Tanjiro** (hub and arena only): `CharacterBody` builds a standard R15 body from a HumanoidDescription. Optional uploaded Shirt/Pants/hair/face IDs are used when set; otherwise part-built fallbacks add the checkered haori, hair, hanafuda earrings and forehead scar. Roblox's own R15 walk/run/jump animations drive locomotion. Staged story chapters still spawn the R6 rig because Story/Training rely on R6 part names; converting them is follow-up work after merging the owner's story changes.
- **Canonical swords** (`Swords`, `SwordBuilder`): Urokodaki's steel sword (chapters 1–3), Tanjiro's black Nichirin blade with the black wagon-wheel tsuba (4–14), and Yoriichi's restored blade with 滅 engraving and Rengoku's flame tsuba (15+). Saya on the left hip; the draw moves the grip to the right hand at the animation's `Grip` marker.
- **Authored animations** (`src/shared/Anims/Tanjiro.luau`, 18 clips): iai-style draw, chiburi sheathe, four-cut M1 string (kesa-giri, gyaku-kesa, yoko-giri, stepping overhead finisher), four dashes, flinches, knockback, get-up, block, clash recoil. Played by `KeyframePlayer` on clients; exported to `ServerStorage.AnimSources` as KeyframeSequences for publishing (docs/ASSETS.md).
- **Melee** (server-authoritative): 4-hit chain (0.5 s chain window, 0.9 s end lag), box hitboxes at the `Hit` marker, 0.45 s hitstun that interrupts the target's actions, finisher knockback 25 studs with a ragdoll-lite fall and get-up, M1-only block (techniques pass through), parry in the first 0.18 s of a block, finisher guard-break (1 s stun), directional dashes on separate cooldowns with no invulnerability (side dashes circle a locked target), technique clashes within 0.25 s (equal tier cancels; higher tier wins at 50% damage).
- **Hit feedback**: white Highlight flash, 60/120 ms hit-stop, camera shake for the people involved, slash sparks, block sparks, clash ring, sounds (pitched built-ins; optional sound IDs in `data/assets.json`).

## Controls

LMB attack (M1 string, draws first if sheathed) · F hold block · Q + WASD dash (Q alone = front dash) · R draw/sheathe · 1–4 techniques.

## Verification (exact results)

- `python scripts/check.py`: passes (17 portable core tests, 34 Luau files compiled, place built, 18 KeyframeSequences exported).
- `tests/studio.spec.luau` via run-in-roblox: **18 passed / 0 failed**. Covers R15 build, saya on the left hip, draw to the right hand, wagon-wheel and flame tsuba, fallback look, four-cut damage totals, hitstun, forced finisher knockback motion, misses behind, block/guard-break, techniques through block, dash motion/cooldowns/no i-frames, technique clash cancel. Edit-mode runs do not simulate physics, so movement is asserted from the server motion record.
- Two-client multiplayer suite: **14 passed / 0 failed** in several runs, including R15 locomotion, the WASD+Q dash, sword draw/sheathe replication and the white hit flash on both clients after a real PvP M1. **The dash test is flaky under load; see known issue below.**
- Visual: one Studio client frame showed R15 Tanjiro (checkered haori fallback, nameplate) at a distance in the arena. The dedicated close-up staging (`prepare_studio_test.py --visual-combat`) ran, but its frames were not captured. **No close-up visual review of the sword, draw or swing poses has been done.** Pose quality, timing and feel still need a human playthrough.

## Known issue: dash snap for the dashing player (pre-existing, needs a decision)

The multiplayer dash test measures the dashing player's own client frame by frame. Instrumented runs showed:

- The server runs the dash (`Combat:move`) and takes network ownership; the owning client sees it through a few replication snapshots, 2 frames of about 6–12 studs each, rather than smooth motion.
- **The unmodified R6 dodge shows the same behaviour** (7.3 and 13.1 stud frames in two runs), so this predates the sword kit. R15 samples ranged 6.1–12.2 studs (16.7 under screen-capture load, and one loaded run where the client saw only 6 studs of travel).
- Two fixes were tried and rejected by measurement: slowing the R15 dash to the R6 speed envelope (no change) and removing a server CFrame write after the dash started (no change).

The likely proper fix is a **client-predicted dash**: the server admits the dash (cooldown, stun), the owning client applies the motion locally so it is smooth, and the existing server speed check (80 studs/s) bounds cheating. This changes the network-authority model for every character, so it is left for the owner's decision.

## Owner steps

1. Upload `assets/clothing/tanjiro_shirt.png` / `tanjiro_pants.png`, pick hair/earring accessories, optionally sounds; paste IDs into `data/assets.json` (docs/ASSETS.md).
2. Publish the 18 KeyframeSequences from `ServerStorage.AnimSources.Tanjiro` and paste IDs into `data/animations.json`.
3. Play Tanjiro in Studio (hub dummy, arena) and review the draw, swings, dashes, block and hit feel; tune `Config.Melee` and the keyframes.
4. Decide on the client-predicted dash.

## Canon notes (fold into RESEARCH.md)

- Tanjiro's Nichirin blade turned black when he first drew it; the blue in the anime is the Water Breathing effect, not the blade colour. Tsuba: black wagon-wheel. Handle wrap: black over red diamonds (from replica sellers; verify against anime screenshots).
- The Swordsmith Village blade is Yoriichi's ~300-year-old sword restored by Haganezuka and delivered fitted with Rengoku's flame tsuba (one sword, not two). The 滅 engraving on it still needs verification.
- The Corps kanji 滅 on the uniform back is covered by Tanjiro's haori, so the generated shirt does not show it.
