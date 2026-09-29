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
| 3 | Clip pipeline: JSON → KeyframeSequence `.rbxmx`, hash-protected, validated | **Done.** Two proof clips: idle_sheathed, idle_drawn |
| 4 | Runtime sampler (`Motion.luau`), `MotionMath` with tests, layers, markers, time-warp | **Done.** Core 16/16, engine 18/18, two-client 18/18. Asset-ID playback deferred |
| 5 | Locomotion clips | **Done.** walk, run (drawn/sheathed), jump, fall, light/heavy landings |
| 6 | Directional dashes (server and clips) | **Done.** Camera-relative; engine 20/20, two-client 19/19 |
| 7 | Draw/sheathe state machine, three sheathe styles, auto-sheathe | **Done.** Procedural sword path; engine 22/22, two-client 20/20 |
| 8 | Sword attack, combo, guard/parry and reaction clips | **Done.** 21 clips; Click sound deferred |
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

## How clips work now (phases 3–4)

**Authoring a clip.**
1. Write `data/animations/<set>/<clip>.json` with:
   - `category`: `locomotion`, `action`, `attack` or `story`
   - `priority`
   - `loop`
   - `speed` (the authored ground speed for locomotion)
   - `ease`: default `Style/Direction`
   - `keyframes`: `{t, pose: {Joint: [rx, ry, rz] degrees | {r, p, ease}}}`
   - `markers`: `{t, name}`
2. Alternatively, write `{"mirrorOf": "<clip>"}` to reflect a clip left to right.
3. Run `python scripts/check.py`. It validates the clip and writes:
   - `assets/animations/<set>/<clip>.rbxmx`, which Rojo maps to `ReplicatedStorage.Animations`
   - `src/shared/AnimationIndex.luau`, the metadata that `.rbxmx` cannot carry without binary attributes
   - `assets/animation-manifest.json`, the hashes

   CI fails if any of these are stale.

**Joint conventions.** Degrees are applied as `CFrame.Angles(rx, ry, rz)` on the joint:
- +X swings arms and legs forward.
- Knees bend at −X; elbows bend at +X.
- +X on the Waist or Neck leans back.
- +Z on the right shoulder raises the right arm outward; the left side mirrors this.
- Ankle +X lifts the toes.

Structural parent poses carry Weight 0, following the Animation Editor's convention, so a clip affects only the joints it keys. An upper-body draw therefore leaves the legs to locomotion.

**Refining in Studio.**
1. Open the built place.
2. In the command bar, run `require(game.ServerScriptService.Server.Rig).create(workspace, Vector3.new(0, 5, 0), require(game.ReplicatedStorage.Shared.Content).characters.tanjiro)` to spawn a rig.
3. Open the clip in the Animation Editor from `ReplicatedStorage.Animations` and edit it.
4. Right-click the KeyframeSequence, choose **Save to File**, and save over `assets/animations/<set>/<clip>.rbxmx`.

The generator then reports `KEPT` and never overwrites that file. The JSON still supplies category, speed and loop, and `check.py` validates the saved file's pose names and markers.

**Runtime (`src/client/Animator.luau` + `Motion.luau`).**
- Every client animates every rig into `Motor6D.Transform` in `PreSimulation`. `C0` stays at rest.
- **Base layer:** cross-fades (0.15 s) between the locomotion state's clip and the legacy procedural pose when no clip exists. States are `idle`, `run`, `jump`, `fall` and `land`, with drawn and sheathed variants.
- **Action layer:** a fading stack (0.08 s in, 0.12 s out). Each server `Pose` plays `base/<pose>` (or `base/<pose>_<PoseVariant>`) if authored, otherwise the legacy pose.
- **Timing:** attack clips are time-warped from `PoseWindup` and `PoseDuration`.
- **Markers:** `Grip`/`Release` swap the sword joints locally, and `TrailOn`/`TrailOff` drive the trail.
- **Overlay:** a turn-lean roll is added on top.
- **Diagnostics:** `MotionClip` and `MotionState` attributes. They are client-local and never trusted.

**Deviations from the plan, recorded honestly.**
- **Uploaded asset-ID playback (`animationAssets`) is not implemented.** No IDs exist to test it, and the offline sampler plays everything. Add it only together with a real uploaded clip to test against.
- **The drawn stance uses a right-hand grip with the left hand guarding the chest.** The blocky rig's 3-stud shoulder span puts the body's centreline beyond arm reach (1.43 studs from the shoulder pivot), so a true two-handed chudan grip is geometrically impossible without changing proportions.
- **Pose easing:** legacy `Cubic`, `Elastic` and `Bounce` are assumed to reverse In/Out, as Roblox documents for `Cubic`. Generated clips use `CubicV2`/`Linear` only. If a Studio-edited clip using the legacy styles previews differently in game, check this first.
- **The two proof clips have not been visually reviewed.**

## Locomotion and dashes as built (phases 5–6)

**Locomotion states.** The base layer picks the most specific authored clip: `<state>_drawn`, then `<state>_sheathed`, then `<state>`.

| State | Condition | Clip | Notes |
|---|---|---|---|
| idle | speed < 1.76 | `idle_drawn` / `idle_sheathed` | |
| walk | speed < 12 | `walk_sheathed` | Also used when drawn; authored at 8 studs/s |
| run | otherwise | `run_drawn` / `run_sheathed` | Authored at 22 studs/s |
| jump | rising | `jump` | |
| fall | falling | `fall` | |
| land_light | after a normal fall | `land_light` (0.18 s) | |
| land_heavy | after a fall of more than 25 studs | `land_heavy` (0.35 s) | Fall height is the peak root height minus the landing height |

- **Stride matching:** cycle playback rate = speed ÷ authored speed, clamped to 0.4–1.6.
- **One-shot clips** (jump and landings) restart whenever they become current again.
- **Stride cycles:** contact keys ease `CubicV2/In` into the pass and pass keys ease `CubicV2/Out`, so joint velocity is continuous. The root bob eases InOut.
- **Soles on the floor:** root offsets follow leg height = 0.9·cos(hip) + 1.0·cos(hip+knee) against 1.9 at rest.
- **Run feet slide:** WalkSpeed 22 is far longer than the stride of a 5-stud body, as in most Roblox games.

**Directional dashes (camera-relative).**
- **Why camera-relative:** default controls turn the character toward its movement (AutoRotate), so classifying against the body would make A+Q a front dash. With movement input, the client sends `{direction, facing = camera look}`. A bare Q sends no facing and dashes along the character's own look.
- **Server validation:** the facing is only planar-validated and chooses which way the dasher faces. Players already control their own facing, and distance, timing and collision stay server-owned.
- **Classification:** the server classifies with `MotionMath.dashDirection`:

  | Kind | Reach | I-frames | Facing |
  |---|---|---|---|
  | `front` | 16 studs | 0.28 s | Turns to the travel direction |
  | `left` / `right` | 12 studs | 0.24 s | Faces `facing` throughout (`Combat:move(..., keepFacing)`) |
  | `back` | 10 studs | 0.26 s | Faces `facing` throughout |

  Energy cost, cooldown and the 0.32 s duration are unchanged. The server sets `Pose = dash_<kind>`.
- **Clips:** `dash_front`, `dash_left`, `dash_right` (generated by `mirrorOf dash_left`) and `dash_back`.
- **Drawn sword:** `drawnMask: "lower"` on the front and side dashes means that while the sword is drawn only the legs and root play, and the upper body keeps the base layer's sword pose. `dash_back` keeps its guard arms either way.
- **Walk while drawn:** there is no `walk_drawn` yet, so walking with the sword drawn uses `walk_sheathed` arms.

## Drawing, sheathing and attacks as built (phases 7–8)

**Server state machine (`Combat:weapon(actor, drawn, style)`).**
- **Timing source:** all timing comes from `AnimationIndex`: clip length plus the `Seat`/`Release` markers.
- **State attributes:**
  - `WeaponDrawn` changes immediately; it is the gameplay state.
  - `WeaponState` moves through `drawing`, `drawn`, `sheathing` and `sheathed`.
  - The sword joints swap through `Rig.swapSword` and `SwordInHand` only when the clip reaches that point.
  - `WeaponChanged` is the token that cancels a superseded delayed swap.

| Clip | Duration | Busy until | Joint swap |
|---|---|---|---|
| `draw` | 0.45 s | end of clip | at the end of the clip |
| `draw_iai` | 0.35 s | end of clip | at the end of the clip |
| `sheathe_noto` | 1.4 s | `Seat` (0.35 s) | at `Release` (1.25 s) |
| `sheathe_fast` | 0.3 s | `Seat` | at `Release` (0.24 s) |

- **Choosing the draw:** a sheathed attack draws with `draw_iai` and then casts (it previously waited a fixed 0.46 s).
- **Cancelling:** attacking or drawing after the noto's chiburi cancels its Release.
- **Choosing the sheathe:** **R** uses `sheathe_fast` within 3 s (`FastSheatheWindow`) of dealing or taking damage, otherwise `sheathe_noto`.
- **Auto-sheathe:** in `Combat:tick`, after `AutoSheatheSeconds` (8 s) without dealing or taking damage since the later of the last combat and the last draw. It never fires while blocking, dashing, busy, stunned, in cutscenes or under a story weapon lock.
- **Instant changes:** story setup and spawning use `Rig.draw`, which changes state instantly.

**Procedural sword path (client, `Animator.luau`).**
- **Why it exists:** the blocky right hand reaches 1.43 studs from the shoulder, but the tsuka at the left hip is about 2.9 studs away, so the hand cannot carry the sword out of the saya.
- **Draw:**
  - At the draw clip's `Grip` marker, the client records the tsuka frame and enables the hand joint locally.
  - The sword slides out along its own blade axis over `SwordDrawLength` (a Rig attribute: blade + kissaki − mouth + margin).
  - After `Clear`, it is swept into the hand.
- **Sheathe:** from `Seat`, the sword is carried from the hand onto the saya line (first half), then slid in and seated (second half). `Release` returns it to the hip joint locally.
- **Implementation:** `SwordHand.Transform = (hand·C0)⁻¹ · desired · C1`.
- **Superseded or finished paths:** when a path is superseded (for example by a dash) or finishes, the client holds its target state for up to 0.8 s until the server swap replicates, then follows `SwordInHand`.
- **Measured on a second client at about 15 FPS:** the blade slid 2.59 studs out along the axis, travelled 9.39 studs in total with a largest single-frame step of 3.03, and finished 0.27 studs from the hand.
- **Review note:** 9.4 studs of travel in 0.37 s may read as a wide swoop. Tune `draw.json`'s `Clear` time and the path easing after viewing it.

**Attack clips.**
- **Timing:** each attack clip starts and ends on the `idle_drawn` guard and carries `Hit`, `End`, `TrailOn` and `TrailOff`. The client time-warps `Hit` onto the server `PoseWindup` and `End` onto `PoseDuration`.
- **Combo clips:** basic attacks set `PoseVariant = combo_1`, `combo_2` or `combo_3`, and techniques clear it.

| Clip | Beats |
|---|---|
| `combo_1` | Kesa-giri |
| `combo_2` | Gyaku-kesa |
| `combo_3` | Tsuki |
| `slash` | Yoko-giri |
| `thrust` | Lunge |
| `dash` | Low sprint with the blade trailing, then a passing cut. Damage applies after travel, so `Hit` marks the start of the sprint |
| `spin` | Root turn in keys of at most 110°, so interpolation keeps the direction |
| `barrage` | X-cuts |
| `burst` | Jodan (overhead), then a ground cut |
| `projectile` | Rising release |
| `trap` | Low sweep |
| `summon` | Blade overhead |

**Defensive and reaction clips.**
- `guard`, `evade` and `heal` are non-damaging actions.
- `guard_hold` loops while **F** is held. It is upper body only, so the legs walk at guard speed.
- `parry` plays when a parry or counter succeeds.
- **Hit reactions (`Combat:react`):**
  - `hit_light` (0.3 s) plays only on a target that is not attacking, and never replaces a running pose.
  - `hit_heavy` plays for control statuses (stun, sleep, root), which interrupt anyway.
- **Scope:** these clips play for every character. Non-katana wielders use the same arm choreography until weapon-specific sets exist.

**Deferred or not done.**
- **`Click` sheathe sound:** the marker exists, but no audio asset is bundled yet.
- **Weapon-specific clip sets:** dual, whip, claws and the other non-katana weapons still need their own clips.
- **Visual review:** none has taken place. The poses come from joint arithmetic only.

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
