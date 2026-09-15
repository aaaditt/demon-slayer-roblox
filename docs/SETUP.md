# Build and play

## Quick start on this machine

1. Run `python scripts/check.py` from the repository root.
2. In Roblox Studio, open `build/WisteriaChronicles.rbxlx`.
3. Press **Play** (F5). The environment is created when the server starts; the edit viewport is empty before play.
4. The Journey menu opens automatically. Use **Characters** to select a fighter, **Techniques** to equip four moves, or **Play Story** to begin.
5. Press **M** to close/open the menu. Two training constructs stand in the courtyard.

## Fresh machine

Install Python 3.11+, Git and Roblox Studio. Clone the repository, run `python scripts/bootstrap.py`, then `python scripts/check.py`. The bootstrap downloads checksum-verified Rojo 7.7.0 and Luau 0.738 to the ignored `.tools` directory. PowerShell users can also use `scripts/bootstrap.ps1`.

On other platforms, install those versions manually and put `rojo`, `luau`, and `luau-compile` on PATH. The check script supports local tools or PATH tools. Roblox Studio runtime tests require Windows or macOS with Studio installed.

## Controls

| Action | Keyboard / mouse | Controller | Touch |
|---|---|---|---|
| Move / jump | WASD / Space | Left stick / A | Roblox thumbstick / jump |
| Basic attack | Left mouse | Right trigger | Attack button |
| Techniques 1–4 | 1, 2, 3, 4 | X, Y, B, left bumper | Four technique cards |
| Guard / parry | Hold F | Hold left trigger | Hold Guard |
| Dodge | Q | Right bumper | Dodge button |
| Menu | M | D-pad up | Menu button |

Aim with the mouse on desktop; touch/controller techniques follow camera facing. Dodge follows movement when moving. Character and loadout changes require the hub. Return to the hub via Journey after five seconds without combat.

## Multiplayer

Use Studio's **Server & Clients** test with at least two players. Each client joins PvP through Journey. Both must opt in before a round starts. Campaign missions are private, single-player encounter rooms within the same server. They are not yet cooperative campaign instances.

For people on different computers, the owner must publish the place to their Roblox experience and configure its visibility/permissions. This repository does not contain a Roblox universe/place ID or deployment credentials. GitHub publication does not publish a Roblox experience.

## Saving

Studio uses session-only progression by default (`Config.StudioPersistence = false`). In a published experience the game uses DataStore `WisteriaChronicles_v1`, validates loaded data, and claims a renewable per-player session lease. If loading fails or another live session owns the save, play continues with temporary progression and writes are disabled. Test against an isolated experience before enabling Studio API access or real save testing.

## Automated checks

`python scripts/check.py` validates catalog references and constraints, regenerates data/docs, compiles Luau, executes pure core tests, and builds the place. GitHub Actions repeats these checks on Linux and uploads the built place as an artifact.

Optional Studio engine smoke test, with [run-in-roblox 0.3.0](https://github.com/rojo-rbx/run-in-roblox/releases/tag/v0.3.0) installed under `.tools/run-in-roblox`:

```powershell
.tools/run-in-roblox/run-in-roblox.exe --place build/WisteriaChronicles.rbxlx --script tests/studio.spec.luau
```

Two-client integration suite:

```powershell
python scripts/prepare_studio_test.py
.tools/run-in-roblox/run-in-roblox.exe --place build/WisteriaChronicles.rbxlx --script build/run-multiplayer.luau
```

The runner temporarily injects server/client tests into its test copy. No test remotes or test hooks are included in the shipping Rojo tree. The legacy runner also loads its plugin in child Studio DataModels; the generated wrapper holds those copies idle so only the edit instance launches or terminates the suite.

Tests verify mechanics, not finished art, balance, complete lore fidelity, or physical device usability. See STATUS.md for actual executed results.
