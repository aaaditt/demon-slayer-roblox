# Tanjiro Combat Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tanjiro plays as an R15 battlegrounds-style swordsman: canonical sword on the left hip with a draw, authored keyframe animations, 4-hit M1 string with finisher, directional dashes, M1-only block/guard-break, technique clashes and white-flash hit feedback.

**Architecture:** Pure, Roblox-free rules and data (`MeleeRules`, `Swords`, `AnimData/Tanjiro`) are unit-tested by plain `luau`. Server modules (`CharacterBody`, `SwordBuilder`, `Melee`) build and drive the R15 fighter; `Combat` delegates M1/guard/dodge to `Melee` when the actor is R15. The server announces animations through model attributes (`Anim`, `AnimStart`) exactly like the existing `Pose` attributes; the client `KeyframePlayer` (or a published Animation, when an ID exists) renders them and `HitFeedback` renders hit events.

**Tech Stack:** Luau, Rojo 7.7, plain `luau` test runner (`tests/core.spec.luau`), run-in-roblox for the Studio spec, Python 3.11 + Pillow for clothing textures and KeyframeSequence generation.

**Spec:** `docs/superpowers/specs/2026-09-19-tanjiro-combat-design.md`

## Global Constraints

- Work only in worktree `C:\Aadit\Personal\code-ide\antigravity\demon-slayer-combat`, branch `combat/tanjiro`.
- Do not hand-edit generated files (`src/shared/Content.luau`, `src/shared/AnimIds.luau`); edit `data/*.json` and regenerate.
- Server is authoritative: clients send intent only (`Basic`, `Guard`, `Dodge`, `Weapon`, `Skill`); hit timing comes from shared AnimData on the server.
- No external asset **required** for basic play: every asset ID may be empty and the game must still work.
- Every effect has a bounded lifetime; reuse one `Highlight` per model.
- Only Tanjiro changes rig. All other characters keep `Rig.create` R6 rigs and existing behaviour.
- Run `python scripts/check.py` after each task; it must pass before commit.
- Commit each task; push the branch at the end of each task. Commit trailer:
  `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>` and `Claude-Session: https://claude.ai/code/session_01PHw2HVU13wFX3H3nozyqff`.

## File Structure

| File | Kind | Responsibility |
|---|---|---|
| `src/shared/MeleeRules.luau` | new, pure | chain step, hitbox inclusion, block outcome, clash outcome, technique tier, dash selection |
| `src/shared/Config.luau` | modify | add `Melee` table of tunables |
| `src/shared/Swords.luau` | new, pure | sword definitions + `variantFor(chapter)` |
| `src/shared/AnimData/Tanjiro.luau` | new, pure | keyframe tables (degrees) + markers |
| `src/shared/AnimData/init.luau` | new, pure | `get(set, id)`, `marker(set, id, name)`, R15 joint list |
| `data/animations.json` → `src/shared/AnimIds.luau` | new data / generated | published animation asset IDs (empty by default) |
| `data/assets.json` | new data | Tanjiro appearance asset IDs + provenance (empty by default) |
| `src/server/CharacterBody.luau` | new | R15 build from HumanoidDescription, appearance + part fallback, returns `model, humanoid, root` or nil |
| `src/server/SwordBuilder.luau` | new | build sword parts on R15, `setDrawn(model, drawn)` moves grip between LowerTorso and RightHand |
| `src/server/Melee.luau` | new | M1 chain, hitbox query, block/guard-break, knockback, dashes, anim attributes |
| `src/server/Combat.luau` | modify | delegate `basic/guard/weapon/dodge` for R15 actors; clash check in `cast`; `activeCast` bookkeeping |
| `src/server/Game.luau` | modify | `spawn` uses `CharacterBody` for Tanjiro; passes `swordVariant` |
| `src/client/KeyframePlayer.luau` | new | plays AnimData on Motor6D.Transform (or published track), hit-stop pause |
| `src/client/HitFeedback.luau` | new | white Highlight flash, camera shake, sparks, sounds, hit-stop trigger |
| `src/client/Bootstrap.client.luau` | modify | start KeyframePlayer; route events to HitFeedback; dash direction from WASD |
| `scripts/generate_clothing.py` | new | Tanjiro Shirt/Pants PNGs (585×559) into `assets/clothing/` |
| `scripts/build_keyframes.py` | new | AnimData → `build/AnimSources.rbxmx` KeyframeSequences; `data/animations.json` → `AnimIds.luau` |
| `scripts/check.py` | modify | validate new data, run new generators |
| `tests/core.spec.luau` | modify | tests for MeleeRules, Swords, AnimData |
| `tests/studio.spec.luau` | modify | R15 Tanjiro spawn, sword mount, draw to RightHand, M1 hit in engine |
| `docs/ASSETS.md`, `AGENTS.md`, `docs/STATUS.md`, `docs/WORKLOG.md`, `docs/QA.md` | docs | upload/publish steps, rule change, status |

---

### Task 1: Pure melee rules + config

**Files:** Create `src/shared/MeleeRules.luau`; Modify `src/shared/Config.luau`; Test `tests/core.spec.luau`.

**Interfaces (Produces):**
- `MeleeRules.nextChain(state, now, cfg) -> step:number|nil` — `state = {step, lastEnd, busyUntil}`; returns 1–4 or nil if still busy. Continues if `now - state.lastEnd <= cfg.ChainWindow` and `state.step < 4`; after step 4, requires `now >= state.lastEnd + cfg.EndLag`.
- `MeleeRules.inHitbox(forward, side, up, box) -> boolean` — local-space offset of target from attacker; `box = {length, width, height, forwardOffset, tolerance}`; accepts `0 <= forward <= forwardOffset + length/2 + tolerance`, `|side| <= width/2`, `|up| <= height/2`.
- `MeleeRules.blockOutcome(isBlocking, frontalDot, sinceBlockStart, isFinisher, isTechnique, cfg) -> "hit"|"parry"|"block"|"guardbreak"`.
- `MeleeRules.tier(move) -> 1|2|3` — `move.tier` if present else damage `<20→1`, `<35→2`, else 3.
- `MeleeRules.clash(aActiveAt, bActiveAt, aTier, bTier, window) -> nil|"cancel"|"a"|"b"`.
- `MeleeRules.dashKind(localX, localZ) -> "front"|"back"|"left"|"right"` — from the dash direction in the actor's local space (`-Z` forward).
- `Config.Melee = {ChainWindow=0.5, EndLag=0.9, Damage=9, FinisherDamage=14, Hitstun=0.45, KnockbackDistance=25, Knockdown=0.8, GuardBreakStun=1.0, ParryStagger=0.6, BlockFrontDot=0.3, SwingSpeedScale=0.5, StunSpeedScale=0.3, ClashWindow=0.25, ClashPush=10, ClashLoserScale=0.5, Dash={front={distance=20,cooldown=2.5}, back={distance=12,cooldown=1.5}, left={distance=14,cooldown=1.5}, right={distance=14,cooldown=1.5}}, DashDuration=0.28, TargetLockRange=20}`.

- [ ] **Step 1: Write failing tests** (append to `tests/core.spec.luau`, requiring `../src/shared/MeleeRules` and `../src/shared/Config`):

```luau
test("m1 chain continues inside window, restarts outside, end lag after finisher", function()
    local cfg = Config.Melee
    local s = {step = 0, lastEnd = 0, busyUntil = 0}
    assert(MeleeRules.nextChain(s, 1, cfg) == 1)
    s.step = 1; s.lastEnd = 1.3; s.busyUntil = 1.3
    assert(MeleeRules.nextChain(s, 1.2, cfg) == nil)          -- still swinging
    assert(MeleeRules.nextChain(s, 1.5, cfg) == 2)            -- inside window
    assert(MeleeRules.nextChain(s, 2.0, cfg) == 1)            -- window expired
    s.step = 4; s.lastEnd = 5; s.busyUntil = 5
    assert(MeleeRules.nextChain(s, 5.5, cfg) == nil)          -- end lag
    assert(MeleeRules.nextChain(s, 5.95, cfg) == 1)
end)

test("sword hitbox accepts front targets only within reach and tolerance", function()
    local box = {length = 8, width = 7, height = 6, forwardOffset = 4, tolerance = 1.5}
    assert(MeleeRules.inHitbox(5, 0, 0, box))
    assert(MeleeRules.inHitbox(9.4, 3, 2, box))
    assert(not MeleeRules.inHitbox(9.6, 0, 0, box))
    assert(not MeleeRules.inHitbox(-1, 0, 0, box))
    assert(not MeleeRules.inHitbox(4, 3.6, 0, box))
    assert(not MeleeRules.inHitbox(4, 0, 3.1, box))
end)

test("block stops frontal m1s, not techniques; finisher breaks guard; early block parries", function()
    local cfg = Config.Melee
    assert(MeleeRules.blockOutcome(false, 1, 1, false, false, cfg) == "hit")
    assert(MeleeRules.blockOutcome(true, 1, 1, false, false, cfg) == "block")
    assert(MeleeRules.blockOutcome(true, -1, 1, false, false, cfg) == "hit")
    assert(MeleeRules.blockOutcome(true, 1, 1, false, true, cfg) == "hit")
    assert(MeleeRules.blockOutcome(true, 1, 1, true, false, cfg) == "guardbreak")
    assert(MeleeRules.blockOutcome(true, 1, 0.1, true, false, cfg) == "parry")
end)

test("technique tiers and clash resolution", function()
    assert(MeleeRules.tier({damage = 12}) == 1 and MeleeRules.tier({damage = 24}) == 2 and MeleeRules.tier({damage = 40}) == 3)
    assert(MeleeRules.tier({damage = 40, tier = 1}) == 1)
    assert(MeleeRules.clash(1, 1.3, 2, 2, 0.25) == nil)
    assert(MeleeRules.clash(1, 1.2, 2, 2, 0.25) == "cancel")
    assert(MeleeRules.clash(1, 1.1, 3, 1, 0.25) == "a")
    assert(MeleeRules.clash(1, 1.1, 1, 2, 0.25) == "b")
end)

test("dash kind from local direction", function()
    assert(MeleeRules.dashKind(0, -1) == "front" and MeleeRules.dashKind(0, 1) == "back")
    assert(MeleeRules.dashKind(-1, 0) == "left" and MeleeRules.dashKind(1, 0.2) == "right")
    assert(MeleeRules.dashKind(0, 0) == "front")
end)
```

- [ ] **Step 2:** `.tools/luau/luau tests/core.spec.luau` → FAIL (module missing).
- [ ] **Step 3:** Implement `MeleeRules.luau` (pure; no Roblox globals) and `Config.Melee` exactly per the interfaces above. Parry = blocking, frontal, `sinceBlockStart <= Config.ParryWindow`, not technique. Finisher on non-parry frontal block = `guardbreak`.
- [ ] **Step 4:** tests PASS; `python scripts/check.py` PASS.
- [ ] **Step 5:** commit `Add pure melee rules and tunables`.

### Task 2: Sword definitions

**Files:** Create `src/shared/Swords.luau`; Test `tests/core.spec.luau`.

**Interfaces (Produces):**
- `Swords.definitions[id] = {id, blade={length, width, thickness, color={r,g,b}, edge={r,g,b}, engraving=string|nil}, tsuba={shape="round"|"wheel"|"flame", color, accent}, tsuka={length, wrap, diamond}, saya={color, length}}` (colors are `{r,g,b}` 0–255 arrays).
- `Swords.variantFor(characterId, chapter) -> id|nil` — tanjiro: chapter ≤ 3 → `urokodaki_steel` (Final Selection uses Urokodaki's sword), 4–14 → `tanjiro_black`, ≥ 15 → `tanjiro_yoriichi` (Swordsmith Village is chapters 13–14; its blade comes with Rengoku's tsuba); other characters → nil. Thresholds: `Swords.TanjiroThresholds = {black = 4, yoriichi = 15}`.

- [ ] **Step 1: failing test**

```luau
test("tanjiro sword variants follow story progress and are fully defined", function()
    assert(Swords.variantFor("tanjiro", 1) == "urokodaki_steel")
    assert(Swords.variantFor("tanjiro", 3) == "urokodaki_steel")
    assert(Swords.variantFor("tanjiro", 4) == "tanjiro_black")
    assert(Swords.variantFor("tanjiro", 15) == "tanjiro_yoriichi")
    assert(Swords.variantFor("zenitsu", 5) == nil)
    for _, id in ipairs({"urokodaki_steel", "tanjiro_black", "tanjiro_yoriichi"}) do
        local d = Swords.definitions[id]
        assert(d and d.blade.length > 2 and #d.blade.color == 3 and d.tsuba.shape and d.saya.length > d.blade.length, id)
    end
    assert(Swords.definitions.tanjiro_black.tsuba.shape == "wheel")
    assert(Swords.definitions.tanjiro_yoriichi.tsuba.shape == "flame")
    assert(Swords.definitions.tanjiro_yoriichi.blade.engraving == "滅")
end)
```

- [ ] **Step 2:** FAIL. **Step 3:** implement; before fixing thresholds, print `Content.chapters[i].name` for i=1..22 and pick indices of Swordsmith Village and the chapter after Mugen Train; record them in the constants with a comment naming the chapters. **Step 4:** PASS + check. **Step 5:** commit `Define Tanjiro sword variants`.

### Task 3: Animation data

> Layout amended during execution: data lives in `src/shared/Anims/Tanjiro.luau` (no requires, so plain `luau` and Roblox both load it); `src/shared/AnimData.luau` helpers take the set table (`AnimData.get(set, id)`, `AnimData.prepare(set)` fills `anim.joints`); a Roblox-only `src/shared/AnimSets.luau` maps set names to data.

**Files:** Create `src/shared/AnimData/init.luau`, `src/shared/AnimData/Tanjiro.luau`; Test `tests/core.spec.luau`.

**Interfaces (Produces):**
- Pose format (pure numbers): `pose[jointName] = {rx, ry, rz}` degrees, optional `{rx, ry, rz, px, py, pz}` studs offset. Joint names = R15 Motor6D names: `Root, Waist, Neck, RightShoulder, RightElbow, RightWrist, LeftShoulder, LeftElbow, LeftWrist, RightHip, RightKnee, RightAnkle, LeftHip, LeftKnee, LeftAnkle`.
- Animation: `{id, duration, loop=bool, priority="Idle"|"Movement"|"Action", keyframes={{t, pose, easing="linear"|"out"|"inout"}}, markers={Name=time}, hitbox={length,width,height,forwardOffset,tolerance}|nil, swing="left"|"right"|"down"|nil}`.
- `AnimData.JOINTS` (array), `AnimData.get(set, id)`, `AnimData.marker(set, id, name) -> number|nil`, `AnimData.sample(anim, t) -> {joint={rx,ry,rz,px,py,pz}}` (eased linear interpolation between surrounding keyframes; loops wrap).
- Required ids: `idle_sheathed, idle_drawn, draw, sheathe, m1_1, m1_2, m1_3, m1_4, dash_f, dash_b, dash_l, dash_r, hit_l, hit_r, knockback, getup, block, clash_recoil`. Required markers: `draw: Grip`, `sheathe: Release`, `m1_*: Hit, CanChain, End`; `m1_*` have `hitbox`; `m1_4` has `finisher = true`.

- [ ] **Step 1: failing test**

```luau
test("tanjiro animation data is complete, ordered and samples within bounds", function()
    local required = {"idle_sheathed","idle_drawn","draw","sheathe","m1_1","m1_2","m1_3","m1_4","dash_f","dash_b","dash_l","dash_r","hit_l","hit_r","knockback","getup","block","clash_recoil"}
    local joints = {}
    for _, j in ipairs(AnimData.JOINTS) do joints[j] = true end
    for _, id in ipairs(required) do
        local a = AnimData.get("Tanjiro", id)
        assert(a and a.duration > 0 and #a.keyframes >= 2, id)
        local last = -1
        for _, k in ipairs(a.keyframes) do
            assert(k.t > last and k.t <= a.duration, id .. " keyframe order")
            last = k.t
            for joint, v in pairs(k.pose) do assert(joints[joint] and (#v == 3 or #v == 6), id .. " " .. joint) end
        end
        for name, t in pairs(a.markers) do assert(t >= 0 and t <= a.duration, id .. " " .. name) end
    end
    for i = 1, 4 do
        local a = AnimData.get("Tanjiro", "m1_" .. i)
        assert(a.hitbox and a.markers.Hit < a.markers.CanChain and a.markers.CanChain <= a.markers.End, "m1_" .. i)
    end
    assert(AnimData.get("Tanjiro", "m1_4").finisher)
    assert(AnimData.marker("Tanjiro", "draw", "Grip") and AnimData.marker("Tanjiro", "sheathe", "Release"))
    local mid = AnimData.sample(AnimData.get("Tanjiro", "m1_1"), 0.1)
    assert(mid.RightShoulder and #mid.RightShoulder == 6)
end)
```

- [ ] **Step 2:** FAIL. **Step 3:** author the keyframes (choreography per spec §3: kesa-giri R-shoulder→L-hip; gyaku kesa rising L→R; yoko-giri horizontal with Waist turn; m1_4 step-in overhead with Root forward offset; draw = left hand at hip, right hand crosses to hilt at ~0.12 s (`Grip` 0.14), draws forward/up into chūdan by 0.35 s). Durations: m1_1–3 0.42 s (Hit 0.16, CanChain 0.28, End 0.42), m1_4 0.6 s (Hit 0.26, CanChain 0.6, End 0.6), draw 0.35 s, sheathe 0.5 s (Release 0.38), dashes 0.28 s, hit_l/r 0.3 s, knockback 0.8 s, getup 0.5 s, clash_recoil 0.45 s; idles loop 2 s; block loop 1 s. **Step 4:** PASS + check. **Step 5:** commit `Author Tanjiro keyframe animation data`.

### Task 4: Asset data, clothing textures, keyframe export

**Files:** Create `data/assets.json`, `data/animations.json`, `scripts/generate_clothing.py`, `scripts/build_keyframes.py`, `docs/ASSETS.md`; Modify `scripts/check.py`, `default.project.json`, `.gitignore` (only if `assets/` must be tracked — it must be tracked).

**Interfaces (Produces):**
- `data/assets.json`: `{"tanjiro": {"shirt": "", "pants": "", "face": "", "accessories": [], "bodyColors": {"skin": [235,197,171]}, "provenance": {}}}`; IDs are strings of digits or empty.
- `data/animations.json`: `{"Tanjiro": {"m1_1": "", ...}}` for all 18 ids; generated to `src/shared/AnimIds.luau` (`return {Tanjiro = {m1_1 = "", ...}}`), plus assets.json generated to `src/shared/Assets.luau`.
- `build/AnimSources.rbxmx`: Folder `AnimSources` → Folder `Tanjiro` → one `KeyframeSequence` per id (Keyframes + nested Poses along the R15 hierarchy `HumanoidRootPart>LowerTorso>UpperTorso>…`, CFrame from degrees, `KeyframeMarker` children for markers, `Loop` and `Priority` set). Mapped in `default.project.json` to `ServerStorage.AnimSources`.
- `assets/clothing/tanjiro_shirt.png`, `assets/clothing/tanjiro_pants.png` — 585×559 classic templates.

- [ ] **Step 1:** add to `check.py` `validate()`: every asset ID matches `^\d*$`; animations.json keys equal the ids exported from AnimData (the Python exporter parses `Tanjiro.luau` via `luau` running a tiny dump script that prints JSON — use `.tools/luau/luau scripts/dump_animdata.luau`), and fail if any required id is missing. Run check → FAIL (files missing).
- [ ] **Step 2:** write `scripts/dump_animdata.luau` (requires `../src/shared/AnimData`, prints JSON of the Tanjiro set via a tiny serializer), `build_keyframes.py` (runs dump, writes rbxmx + AnimIds.luau + Assets.luau), `generate_clothing.py` (Pillow; uniform black `#1c1c24`, haori ichimatsu green `#2b7958` / black `#141414` checks on torso front/back/arms regions of the classic template, white belt line, 滅 drawn on back with a CJK font if available else omitted with a printed warning; pants black with white wraps below knee). Call both generators from `check.py main()` before rojo build.
- [ ] **Step 3:** `python scripts/check.py` PASS; open `build/AnimSources.rbxmx` and confirm 18 KeyframeSequences; view the PNGs with the Read tool.
- [ ] **Step 4:** write `docs/ASSETS.md`: how to upload the two PNGs as Shirt/Pants (Creator Hub → Avatar items or Studio "Import 3D/2D"), where to paste IDs, how to pick a hair accessory from Creator Store (criteria: dark spiky short hair, free, R15-compatible), how to publish the AnimSources in Studio (right-click KeyframeSequence → Save to Roblox / Animation Editor → Publish), and to paste IDs into `data/animations.json`.
- [ ] **Step 5:** commit `Generate Tanjiro clothing and exportable keyframes`.

### Task 5: R15 body and sword on the server

**Files:** Create `src/server/CharacterBody.luau`, `src/server/SwordBuilder.luau`; Modify `src/server/Game.luau` (`spawn`); Test `tests/studio.spec.luau`.

**Interfaces:**
- Consumes: `Swords.definitions`, `Swords.variantFor`, `Assets`, `Content.characters`.
- Produces: `CharacterBody.create(parent, position, definition, actorName, options) -> model, humanoid, root | nil` (nil when `definition.id ~= "tanjiro"` or R15 creation fails; caller falls back to `Rig.create`). Sets attributes `RigKind="R15"`, `CharacterId`, `HasSheath=true`, `WeaponDrawn=false`, `SwordVariant`, `AnimSet="Tanjiro"`. Applies Shirt/Pants/face/accessories when IDs non-empty; otherwise adds part fallback: checker panels welded to UpperTorso front/back and upper arms, hair block on Head, hanafuda earrings, scar decal-less red part on forehead.
- `SwordBuilder.build(model, swordId) -> sword Model` named `Sword` with parts `Blade, Edge, Habaki, Tsuba*, Tsuka, Diamond*, Saya`; `Motor6D "SwordGrip"` (Part0 LowerTorso, Part1 Tsuka) with sheathed C0 on left hip; `Saya` welded to LowerTorso; blade attachments + `SwordTrail`.
- `SwordBuilder.setDrawn(model, drawn)` — switches `SwordGrip.Part0` between `LowerTorso` (hip C0) and `RightHand` (grip C0), toggles `Blade/Edge` transparency when sheathed (hidden inside saya), and calls `Rig.draw(model, drawn)` to keep existing attributes consistent.
- `Game:spawn` — `local variant = Swords.variantFor(characterId, p.chapter)`; try `CharacterBody.create(..., {swordVariant = variant})`, else `Rig.create`.

- [ ] **Step 1:** add Studio checks:

```luau
check("tanjiro spawns as R15 with sword on left hip and draws to right hand",function()
    local CharacterBody=require(ServerScriptService.Server.CharacterBody)
    local SwordBuilder=require(ServerScriptService.Server.SwordBuilder)
    local model,humanoid,root=CharacterBody.create(World.Actors,Vector3.new(0,6,0),Content.characters.tanjiro,"TanjiroTest",{swordVariant="tanjiro_black"})
    assert(model and humanoid.RigType==Enum.HumanoidRigType.R15 and model.PrimaryPart==root)
    assert(model:GetAttribute("RigKind")=="R15" and model:GetAttribute("HasSheath"))
    local grip=model:FindFirstChild("SwordGrip",true)
    assert(grip and grip.Part0==model.LowerTorso)
    local saya=model.Sword.Saya
    assert(model.LowerTorso.CFrame:PointToObjectSpace(saya.Position).X<0,"saya on left hip")
    SwordBuilder.setDrawn(model,true)
    assert(grip.Part0==model.RightHand and model:GetAttribute("WeaponDrawn"))
    assert(CharacterBody.create(World.Actors,Vector3.zero,Content.characters.zenitsu,"Z",{})==nil)
    model:Destroy()
end)
```

- [ ] **Step 2:** build + run `run-in-roblox --place build/WisteriaChronicles.rbxlx --script tests/studio.spec.luau` → FAIL.
- [ ] **Step 3:** implement both modules and the `Game:spawn` change. `CharacterBody` uses `Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)` in `pcall`; sets `BreakJointsOnDeath=false`, `DisplayDistanceType=None`, adds overhead HP bar like `Rig.create` (reuse by extracting `Rig.healthBar(model, head, humanoid)` into `Rig.luau`).
- [ ] **Step 4:** Studio spec PASS (record output); `check.py` PASS.
- [ ] **Step 5:** commit `Spawn Tanjiro as R15 with canonical sword`.

### Task 6: Server melee (M1, block, dashes, knockback) and clash

**Files:** Create `src/server/Melee.luau`; Modify `src/server/Combat.luau`; Test `tests/studio.spec.luau`.

**Interfaces:**
- Consumes: `MeleeRules`, `Config.Melee`, `AnimData`, `SwordBuilder.setDrawn`, `Combat:move`, `Combat:damage`, `Combat:emit`.
- Produces:
  - `Melee.play(actor, animId, now)` — sets attributes `Anim`, `AnimStart`, `AnimSet`.
  - `Melee.basic(combat, actor, direction) -> ok, reason` — draws first if sheathed (plays `draw`, then swings when `Grip` marker elapses); uses `nextChain`; faces `direction`; sets `busyUntil = now + anim.markers.End`, `actor.chain = {step, lastEnd, busyUntil}`; at `Hit` marker runs `workspace:GetPartBoundsInBox` (OverlapParams include `World.Actors`), maps parts to actors via `combat.actors[part.Parent]`, filters `Rules.canDamage`, once per target, re-checks `MeleeRules.inHitbox` in attacker local space with the anim's hitbox; resolves `blockOutcome`; applies damage via `combat:damage` with `{source="m1", finisher, swing}`; hitstun (`stunUntil`, `Anim=hit_l|hit_r`), finisher knockback (`combat:move(target, dir, KnockbackDistance, 0.3)` + upward `AssemblyLinearVelocity`, `Anim=knockback`, then `getup` after `Knockdown`); guardbreak → target `stunUntil += GuardBreakStun`; parry → attacker stunned `ParryStagger`.
  - `Melee.guard(combat, actor, enabled)` — sets `blocking/blockStarted`, `Anim=block` or clears.
  - `Melee.weapon(combat, actor, drawn)` — plays `draw`/`sheathe`, calls `SwordBuilder.setDrawn` at `Grip`/`Release` marker time (task.delay guarded by `castToken`).
  - `Melee.dash(combat, actor, direction)` — `dashKind` in actor space; per-kind cooldown in `actor.cooldowns["dash_"..kind]`; side dash with a target within `TargetLockRange` curves: direction = tangent around target (perpendicular of target offset, sign by kind); no `invulnerableUntil`; plays `dash_f|b|l|r`; emits `dodge` event with `dash=kind`.
- `Combat:damage(actor, target, amount, status, info)` — new optional `info` table; when `info.source=="m1"` the block path uses `MeleeRules.blockOutcome` instead of `Rules.resolveDamage`; techniques (no info) against an R15 blocker pass through (`frontal=false` for block purposes) — implement via `if target.model:GetAttribute("RigKind")=="R15" and not info then` treat as unblocked. Emitted `hit` event gains `result`, `finisher`, `swing`, `attacker` (model), `contact` (Vector3 midpoint).
- `Combat:basic/guard/weapon/dodge` — first line: `if actor.model:GetAttribute("RigKind")=="R15" then return Melee.x(self, actor, ...) end`.
- Clash in `Combat:cast`: after `Rules.spend` succeeds, set `actor.activeCast = {token, activeAt = now + move.windup, move, origin, direction}`; scan other actors with `activeCast` whose token is current, `Rules.canDamage(actor, other)`, and each within the other's shape (`Rules.inShape` in the other's frame, range+dash); `MeleeRules.clash(actor.activeAt, other.activeAt, tier(a), tier(b), ClashWindow)`; on result: bump both `castToken` (cancels both casts), push both apart `ClashPush` (loser only when not "cancel"), winner deals `ClashLoserScale * move.damage` to loser, set `Anim=clash_recoil` on R15 participants, emit `clash` event at midpoint. Clear `activeCast` after the cast's hit loop.

- [ ] **Step 1:** Studio checks: (a) R15 Tanjiro vs dummy actor (Hub mode, dummy kind) in front at 5 studs: four `Melee.basic` calls spaced by each anim's `End` → dummy health drops by `3*9+14`, dummy displaced ≥ 15 studs after finisher; (b) dummy behind attacker takes no damage; (c) blocking R15 target facing attacker takes 0 from m1_1 and is stunned after a finisher (guardbreak); (d) `Melee.dash` front moves ~20 studs and sets `cooldowns.dash_front`; immediate second front dash rejected, left dash accepted; (e) two actors casting `water_1` at each other within 0.1 s → both castTokens bumped and neither takes technique damage (equal tier). Use accelerated waits by calling internals with explicit `now` where possible; otherwise `task.wait` the real marker times.
- [ ] **Step 2:** FAIL. **Step 3:** implement. **Step 4:** Studio spec PASS + `check.py` PASS; `core.spec` unchanged PASS. **Step 5:** commit `Add R15 melee string, block, dashes and technique clashes`.

### Task 7: Client animation playback and hit feedback

**Files:** Create `src/client/KeyframePlayer.luau`, `src/client/HitFeedback.luau`; Modify `src/client/Bootstrap.client.luau`, `src/client/Effects.luau` (skip old floating hit number for flashes? keep number, add nothing else).

**Interfaces:**
- `KeyframePlayer.start()` — watches `workspace.Actors` models with `RigKind=="R15"`; each `PreSimulation` (after Roblox's Animator stepped the default Animate tracks) computes the active clip from `Anim`/`AnimStart` (server time) — or idle (`idle_drawn` if `WeaponDrawn` else no override so Roblox locomotion shows) — samples `AnimData.sample`, and writes `motor.Transform = CFrame.new(px,py,pz) * CFrame.Angles(rad(rx),rad(ry),rad(rz))` blended by weight (fade in 0.06 s, out 0.1 s) with the existing Transform (`existing:Lerp(target, w)`). Clips with `priority=="Action"` override all joints; `idle_drawn` overrides only arm/waist joints so legs keep walking. If `AnimIds[set][id] ~= ""` it instead plays a loaded `AnimationTrack` (cached per model) at matching TimePosition and skips Transform writing for that clip.
- `KeyframePlayer.freeze(model, seconds)` — hit-stop: clip time stops advancing for that model.
- `SwordTrail.Enabled` on during `m1_*` between `AnimStart` and `Hit + 0.08`.
- `HitFeedback.play(event)` for `hit` and `clash`:
  - `hit` with `amount > 0`: Highlight (one per model, `DepthMode=Occluded`, FillColor white, `FillTransparency` tween 0.25→1 over 0.12 s, OutlineTransparency 1), `KeyframePlayer.freeze(attacker & target, finisher and 0.12 or 0.06)`, camera shake if local player is attacker or target (0.15 s, 0.25 studs; finisher 0.5), spark burst at `contact` (6 thin neon shards along swing direction, 0.15 s life), sound `rbxasset://sounds/swordslash.wav` (hit) or `swordlunge.wav` (finisher).
  - `result=="block"`: blue-white shards, `rbxasset://sounds/metal.ogg` fallback to `action_jump_land.mp3`, no Highlight.
  - `clash`: ring of 12 white shards + Highlight on both, shake for participants.
  - All parts bounded lifetime; respect `Effects.reduced` and `Effects.muted`.
- `Bootstrap`: require and start `KeyframePlayer`; `effectRemote.OnClientEvent` → `Effects.play(e)` then `HitFeedback.play(e)`; rename dodge button title to "Dash".

- [ ] **Step 1:** add a Studio multiplayer client assertion only if cheap; otherwise verify by the manual Studio pass in Task 8 (the Transform path cannot be exercised by plain luau). Record which in QA.md.
- [ ] **Step 2:** implement; `check.py` PASS (compile).
- [ ] **Step 3:** run the existing multiplayer suite (`python scripts/prepare_studio_test.py` then run-in-roblox on `build/run-multiplayer.luau`) to confirm no regressions for the R6 path; record results.
- [ ] **Step 4:** commit `Play Tanjiro animations on clients with white-flash hit feedback`.

### Task 8: Docs, rule change, verification, push

**Files:** Modify `AGENTS.md` (asset rule → "no external asset required for basic play; optional asset IDs live in data/assets.json and data/animations.json"), `docs/STATUS.md`, `docs/WORKLOG.md`, `docs/QA.md`, `README.md` (controls: Q+WASD dash).

- [ ] **Step 1:** `python scripts/check.py`; Studio spec; multiplayer suite. Capture exact pass counts.
- [ ] **Step 2:** attempt a Studio visual capture of Tanjiro (existing `.tools/capture_studio.py`); if no visible window is obtained, say so in QA.md — do not claim visual review.
- [ ] **Step 3:** update docs with exact results and the owner's remaining manual steps (upload clothing, choose hair, publish animations, play-feel review).
- [ ] **Step 4:** commit `Document Tanjiro combat slice status` and `git push`.

---

## Self-review notes

- Spec coverage: §1 → T4/T5; §2 → T2/T5; §3 → T3/T4/T7; §4 M1/hitbox/dash/block → T1/T6, clash → T1/T6; §5 → T7; out-of-scope docs already committed; testing → each task + T8; merge note → Global Constraints (only thin seams in Combat/Game).
- Deviation from spec, deliberate: technique `tier` is derived from damage with an optional catalog override instead of adding `tier` to all 210 techniques now (same behaviour, no mass data edit). Hair/earrings Creator Store IDs are left empty with selection criteria in ASSETS.md; IDs are not invented.
