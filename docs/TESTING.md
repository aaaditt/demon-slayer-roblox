# How to test the combat (all free, no Robux)

Nothing here costs Robux. Roblox Studio, local multi-player tests and publishing your place are free.

## 1. Build and open

```powershell
python scripts/check.py      # validates, runs tests, writes build/WisteriaChronicles.rbxlx
```

Open `build/WisteriaChronicles.rbxlx` in Studio and press **Play** (F5). The world is built at runtime; you spawn in the hub courtyard as Tanjiro.

## 2. The training range (Studio only)

Press **F4** to teleport to it, or walk south from spawn. It never exists in a published server.

| Target | What it is for |
|---|---|
| **STILL TARGET** | 400 HP, never moves. Damage, the 4-hit combo, hit flash, knockback. |
| **BLOCKING TARGET** | R15 Tanjiro holding a permanent block. Blocked M1s, guard break with the finisher, techniques passing through a block. |
| **SPARRING PARTNER** | Giyu, fights back at half damage. Getting hit, hitstun, your own block, dashing away, technique clashes. |

All three heal back to full 5 seconds after combat, so you can repeat a test immediately.

### Test keys (Studio only)

| Key | Effect |
|---|---|
| **F1** | Next sword: Urokodaki's steel → black Nichirin → Yoriichi blade with Rengoku's flame guard |
| **F2** | Heal to full, refill energy, clear cooldowns and stun |
| **F3** | Pause or re-engage the sparring partner |
| **F4** | Teleport to the training range |

### The readout panel

The panel in the top-left shows, live: rig kind, sword variant, sheathed/drawn, the animation playing and how long ago it started, your combo step, whether you are blocking, HP/energy, all four dash cooldowns, the last hit (damage, result, whether it was a finisher) and the nearest target's health.

Use it to confirm what the combat system thinks is happening, not just what it looks like.

## 3. Controls

**LMB** attack (draws the sword first if sheathed) · **F** hold to block · **Q + WASD** dash (Q alone dashes forward) · **R** draw/sheathe · **1–4** techniques · **M** menu.

## 4. What to check

**Sword and character**
- [ ] The saya sits on his left hip and the blade is hidden inside it while sheathed.
- [ ] R (or the first attack) plays the draw and the sword ends up in his right hand.
- [ ] F1 changes the blade and guard: plain steel, black wagon-wheel, flame guard.
- [ ] The haori checkers, obi, leg wraps and scar look right from the front, back and sides.

**The combo**
- [ ] Four different cuts in order: diagonal down, rising diagonal, horizontal, overhead finisher.
- [ ] Attacking again within half a second continues the combo; waiting restarts at cut 1.
- [ ] Cuts 1–3 stun the target briefly; the 4th knocks it back and it gets up.
- [ ] After the finisher there is a pause before you can swing again.
- [ ] A target behind you is not hit.

**Feel**
- [ ] The white flash, freeze on impact, shake, sparks and sound land together with the hit.
- [ ] The finisher feels heavier than a normal hit.

**Block and dash** (use the sparring partner)
- [ ] Holding F stops its normal attacks from the front, but not its techniques.
- [ ] Your finisher breaks the blocking target's guard and stuns it.
- [ ] Q + each direction gives a different dash animation, and side dashes curve around a locked target.
- [ ] Dashes do not make you invincible, and each direction has its own cooldown.
- [ ] **Watch for the known dash snap**: your character sometimes jumps ahead instead of gliding (see COMBAT_STATUS.md).

**Techniques**
- [ ] 1–4 cast, cost energy and go on cooldown.
- [ ] If you and the sparring partner cast at nearly the same moment, both cancel with a clash spark.
- [ ] Technique effects still look like plain shapes. That is the next piece of work (VFX_STANDARD.md).

## 5. Two-player testing (free)

Studio → **Test** tab → Clients and Servers → set 2 players → **Start**. Two client windows plus a server window open. Use one window to attack the other: PvP damage, the hit flash on both screens and sword replication all work there. Close with **Cleanup**.

## 6. Automated tests (free)

```powershell
python scripts/check.py                                   # data, 18 unit tests, compile, build
.tools/run-in-roblox/run-in-roblox.exe --place build/WisteriaChronicles.rbxlx --script tests/studio.spec.luau
python scripts/prepare_studio_test.py
.tools/run-in-roblox/run-in-roblox.exe --place build/WisteriaChronicles.rbxlx --script build/run-multiplayer.luau
```

The training range is skipped automatically during these runs.

## 7. Telling me what to change

The numbers live in `src/shared/Config.luau` under `Melee` (damage, hitstun, knockback, cooldowns, chain window) and the poses in `src/shared/Anims/Tanjiro.luau`. Saying "the finisher is too slow" or "the combo drops too easily" is enough; each is a one-line change.
