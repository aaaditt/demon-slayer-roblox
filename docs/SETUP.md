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

The development build has been uploaded to a [new private Roblox experience](https://www.roblox.com/games/139004028759819). Its universe/place IDs and update instructions are in [DEPLOYMENT.md](DEPLOYMENT.md) and `deploy/roblox.json`. Access settings and live multiplayer QA remain pending. The repository contains no deployment credentials; pushing to GitHub does not update the Roblox place automatically.

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

For focused W+Q replication diagnostics, prepare with `--dash-only`. It runs the client bootstrap/movement/profile checks, three real held-W+Q attempts, and a forged-position rejection check, recording timestamped client frame displacement and server ownership/position samples. It keeps the normal distance and frame-jump thresholds; a focused pass does not qualify the full suite or sustained lag.

Add `--selection-only` to `prepare_studio_test.py` to run only the two Final Selection/exit checks while debugging that chapter. This is an isolated diagnostic that seeds temporary chapter access; it does not replace the full suite or modify the production build.

Use `--swamp-only` instead for the two northwest-town/exit checks. It seeds chapter-four access in the temporary test copy. The default suite runs every staged chapter and the existing movement/PvP checks.

Use `--asakusa-only` for the two chapter-five route/exit checks. This seeds temporary chapter-five access and includes the civilian's Focus remote and client-observed acting. Both focused checks passed on October 4; consult QA.md for full regression results and limits.

Add `--visual` to the preparation command for a 60-second opening review pause, or `--visual-sagiri` for two 45-second house/waterfall review pauses after the suite. Add `--virtual-input` only to investigate the currently failing synthetic menu-click diagnostic; it is not part of the passing baseline. Actual desktop mouse navigation is documented separately in QA.md.

If Studio updates and run-in-roblox fails to find an executable, inspect the Windows `HKCU\Software\Roblox\RobloxStudio\ContentFolder` value. The legacy runner reads that path; on this machine the updater left it pointing at a deleted version. Repair it only to the verified, currently installed Studio content directory. Keep Rojo disconnected from unrelated servers when reviewing or publishing the built place.

Tests verify mechanics, not finished art, balance, complete lore fidelity, or physical device usability. See STATUS.md for actual executed results.

## Opening story revision

Choose Journey -> 01 A Trail in the Snow to play the Kamado prologue, even if an earlier save has already unlocked later chapters. After it, 02 The Mountain Trial continues through the temple, mountain training and the boulder test; 03 Final Selection continues through the trial and homecoming; 04 Beneath the Town covers the first mission. The local 0.6.0 build adds tested 05 Lights of Asakusa, with visual review pending. Chapters 6-22 say Encounter Preview. In the prologue, Tanjiro has no breathing skills or Nichirin sword; follow objective markers and interact with E / controller X / tap. Dialogue uses E / controller A / Continue. Y / controller Y / Skip Scene skips the current scene only. M -> Return to Hub safely leaves a cinematic.

Training permits basic strikes and guard only during fighting lessons. Breathing practice uses E / controller X / the Breathe button while stationary near the marker during the gold window. Complete route markers in order; defeat or timeout restarts the lesson. Scene Skip cannot bypass exercises. The axe and practice sword are provided by the story, with breathing forms and manual weapon toggling locked throughout both staged chapters.

Outside those chapters, R / D-pad right / Sword toggles single-blade sword drawing. Attacking while sheathed first draws the blade. Q / right bumper / Dodge follows movement, including held WASD. The directional dash uses bounded motion with collision checks, not a position teleport.

Final Selection equips a temporary Water-form kit during encounters (1–4 / the normal controller technique keys / touch cards). Sword drawing is available between scenes. Guard and dodge the Hand Demon's marked attacks; attack while the HUD says its neck is exposed. Follow patrol markers in order and defeat each demon. Scene skipping does not finish combat or the patrol. Defeat/timeout retries the current encounter; leaving still discards chapter progress. Your saved fighter and loadout return in the hub.

Chapter four uses the same combat controls with Water forms 1/2/6/8. Investigate the street markers and rescue house, then watch the pools. Evade each marked claw reach and attack while EXPOSED appears. Land three hits and survive the ambush timer; defeat the two bodies below and the last one above. Nezuko joins the scenes and final encounter without exposing an extra player command. Follow the keepsake/farewell objectives to complete the chapter. The town and swamp are separate generated spaces, not an underwater swimming simulation.

Chapter five's civilian rescue uses E / controller X / the Brace button in the gold timing window. Stay still within the marked area; sword attacks and drawing are disabled there. At the clinic, Water forms 1/2/4/8 return for the two encounters. Defeat Yahaba, then land at least three hits and hold Susamaru's attention for 20 seconds before Tamayo intervenes. Automated Studio checks pass; manual visual review and physical-device qualification remain pending.
