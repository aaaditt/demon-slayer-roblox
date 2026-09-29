# Character animation production

Updated: 2026-09-29. This is the working plan and tracker for character motion, the sword model and sword handling. The base rig performs every action first; characters then specialize it through data (`motionProfiles`, `swordPresets`), not forked code.

## Owner decisions (2026-09-29)

- **Authoring format:** Roblox Animation Editor `KeyframeSequence` clips. They are stored in the repo as `.rbxmx` and played offline by the in-game sampler, so basic play never depends on uploaded assets (see AGENTS.md). Uploading a clip and recording its ID in `animationAssets` is optional.
- **Rig:** blocky R15 with elbows, wrists, knees, ankles and a waist. The silhouette and 5-stud height stay the same.
- **Dashes:** directional. The character keeps facing forward and dashes front 16, side 12 or back 10 studs. Energy cost and cooldown are unchanged.
- **Sheathing:** three styles. A chiburi flick followed by a slow noto sheathe, a fast combat re-sheathe, and an automatic sheathe 8 s after the last damage dealt or taken.

## Progress

| Phase | Scope | State |
|---|---|---|
| 1 | Blocky R15 rig and caller/test migration | **Done.** Engine 16/16, two-client 18/18 |
| 2 | Nichirin katana model, scabbard and data-driven presets | **Done.** Engine 17/17, two-client 18/18 |
| 3 | Clip pipeline: JSON → KeyframeSequence `.rbxmx`, hash-protected, validated | Planned |
| 4 | Runtime sampler (`Motion.luau`), `MotionMath` with tests, layers, markers, time-warp | Planned |
| 5 | Locomotion clips | Planned |
| 6 | Directional dashes (server and clips) | Planned |
| 7 | Draw/sheathe state machine, three sheathe styles, auto-sheathe | Planned |
| 8 | Sword attack, combo, guard/parry and reaction clips | Planned |
| 9 | Per-character motion profiles; Tanjiro as the first specialization | Planned |
| 10 | Studio authoring workflow (this document) | Planned |

Automated tests prove wiring, not appearance. No visual quality is claimed until a human reviews the motion in Studio.

## Rig (phase 1)

Offsets are in the classic frame (origin at the old torso centre). The floor sits at y = −3.

| Joint | Parent → child | Pivot (classic y) |
|---|---|---|
| Root | HumanoidRootPart → LowerTorso | −0.7 |
| Waist | LowerTorso → UpperTorso | −0.4 |
| Neck | UpperTorso → Head | 1.0 |
| Right/LeftShoulder | UpperTorso → UpperArm | 0.6 (x ±1.5) |
| Right/LeftElbow | UpperArm → LowerArm | 0.0 |
| Right/LeftWrist | LowerArm → Hand (skin) | −0.65 |
| Right/LeftHip | LowerTorso → UpperLeg | −1.1 (x ±0.5) |
| Right/LeftKnee | UpperLeg → LowerLeg | −2.0 |
| Right/LeftAnkle | LowerLeg → Foot (0.2 toe extension) | −2.8 |

- **Humanoid:** `RigType = R15`, `HipHeight = 2`, `AutomaticScalingEnabled = false`. An engine test requires every playable character's soles to sit within 0.02 studs of the floor.
- **Accessory offsets:** `Rig.torsoFrame(model, classicOffset)` returns the covering torso part and the converted offset. Parts below the waist line attach to LowerTorso. Held items attach to `RightHand`/`LeftHand`.
- **Interim animation:** the old procedural animator still drives the new joint names (constant elbow bend, knee follow-through) until phase 4 replaces it.

## Sword (phase 2)

Base preset `nichirin_base`. Implemented as `Rig.buildSword`/`Rig.swordSpec`. Sword pieces use classic `Weld` joints, because `WeldConstraint` re-captures offsets when the joints move the tsuka and desyncs the blade (found by an engine diagnostic). The saya covers the blade plus the kissaki; an engine test proves containment for all 19 sword users. Sourced overrides: Tanjiro, Giyu, Rengoku and Kanao (see RESEARCH.md). Characters override it through `characters[id].sword`, but only with details sourced in RESEARCH.md; anything unsourced uses the base.

| Piece | Build |
|---|---|
| Kashira | 0.27×0.27×0.1 dark metal pommel cap |
| Tsuka | 0.22×0.26×0.95 core, 5 diamond ito-wrap plates, 2 gold menuki |
| Fuchi | collar |
| Tsuba | shape enum: `round`, `square`, `hex`, `flame`, `flower`, `bar`; about 0.62 wide, 0.08 thick |
| Habaki | small gold collar |
| Blade | 3 segments with about 0.03 rad of curve (sori) each. Spine in the nichirin colour (Metal, Reflectance 0.15) with a lighter hamon edge strip. About 3.2 long, with a wedge kissaki tip |
| Saya | 3 lacquered segments following the curve, koiguchi mouth ring, kojiri end cap, kurikata knob and sageo cord. Worn on the left hip, angled about 30° down and back |
| Trail | Attachments at the habaki and the tip, coloured by nichirin colour, toggled by clip markers |

- **Motors:** two Motor6Ds on the tsuka: `SwordHip` (LowerTorso) and `SwordHand` (RightHand). Exactly one is enabled at a time.
- **Sheathed blade:** it sits inside the saya. It is no longer hidden with transparency.

## Clip pipeline (phases 3–4)

- **Source files:** `data/animations/<set>/<clip>.json` → `scripts/generate_animations.py` → `assets/animations/<set>/<clip>.rbxmx`, mapped by Rojo to `ReplicatedStorage.Animations`.
- **Edit protection:** a file whose `GeneratedHash` no longer matches has been refined in Studio. It is never regenerated.
- **Sampler:** it writes `Motor6D.Transform` in three layers:
  - locomotion, speed-blended
  - action, with a joint mask
  - an additive procedural overlay for turn lean, breathing and landing
- **Markers:** `Hit`, `End`, `Grip`, `Release`, `TrailOn`, `TrailOff`, `Click`.
- **Server timing stays authoritative:** attack clips are time-warped so `Hit` lands on the move's `windup` and `End` lands on `windup + recovery`.

## Clip catalogue

**Locomotion.** Stride-matched: playback rate = speed ÷ the authored speed (22 for the run).

| Clip | Beats |
|---|---|
| idle_sheathed | 2.4 s breathing loop. Weight on the back leg, left hand resting on the saya, slight head scan. |
| idle_drawn | Chudan-no-kamae with a two-handed grip, tip at throat height, knees 15°, left foot back, ±2° waist sway. |
| walk_sheathed | 1.0 s cycle: contact, down, pass, up. Heel-to-toe roll, left hand steadying the saya. |
| run_sheathed | 0.62 s cycle. Torso pitched 12°, knee lift up to 70°, arms driving at 90° elbows. |
| run_drawn | Run legs; blade held low and trailing about 40° back. |
| jump_start / fall / land_light / land_heavy | Tuck on the rise, legs extending on the fall, 0.18 s absorb, 0.35 s crouch after a fall of more than 25 studs. |

**Dashes.**

| Clip | Beats |
|---|---|
| dash_front | 0.05 s load, lunge with the torso pitched 35°, arms swept back (hand on the hilt if sheathed), plant. |
| dash_left / dash_right | Outside-leg push, crossing slide, torso rolled 15° away from travel, eyes forward. |
| dash_back | Front-foot push and an upright hop back, blade raised in guard if drawn. |

**Draw and sheathe.**

| Clip | Beats and markers |
|---|---|
| draw 0.45 s | Thumb pushes the tsuba (koiguchi-o-kiru). `Grip` at 0.1. The blade slides out along the saya axis while the waist twists, then arcs into chudan. |
| draw_iai 0.35 s | A draw that flows straight into the first cut. |
| sheathe_noto 1.4 s | Chiburi flick, blade brought across the body, left hand forms the koiguchi, tip finds the mouth, slow slide in. `Release` at 1.25, `Click` at 1.3. |
| sheathe_fast 0.3 s | Tip straight into the saya; `Release` at 0.24. |

**Sword attacks.**

| Clip | Beats |
|---|---|
| combo_1/2/3 | Kesa-giri (diagonal down), gyaku-kesa (rising), tsuki (lunge thrust). |
| slash | Wide horizontal yoko-giri. |
| thrust | Long lunge. |
| dash_strike | Passing cut. |
| spin | 360° spin cut. |
| barrage | Loop of 4 X-cuts. |
| burst | Overhead charge, then a downward cut into the ground. |
| projectile | Wide rising slash that releases a wave. |
| guard / guard_hold / parry | Vertical block; parry is a 0.18 s snap. |
| evade | Sidestep with a counter-cut. |
| trap | Blade swept in a circle on the ground. |
| heal | Blade point down, breathing stance. |
| summon | Blade raised overhead. |
| hit_light / hit_heavy / stun | Hit reactions. |

**Story poses.** kneel, embrace, kick, emerge and carry move to the same player.

## Remaining beyond this plan

- Clip sets for the non-katana weapons: dual, whip, claws, fans, flail, staff, fists and instruments.
- Character-specific technique choreography.
- Authored likeness models.
