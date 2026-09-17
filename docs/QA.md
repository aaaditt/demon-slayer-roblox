# Validation evidence

## 2026-09-15 local validation

### Portable checks

`python scripts/check.py` passed catalog referential integrity, nine-Hashira coverage, character-specific move restrictions, balance bounds, generation, Luau compilation (17 source/test files at this checkpoint), all eight core tests, and the Rojo place build.

Core coverage: malformed/NaN/infinite input, atomic cooldown/resource admission, token-bucket limits, hub safety and private mission isolation, hit geometry, guard/parry/dodge, corrupted profiles, and exclusive save-lease transitions. An initial lease-release test failed and was fixed; the regression test remains.

### Roblox engine smoke test

Executed `tests/studio.spec.luau` in Roblox Studio through run-in-roblox. **7 passed / 0 failed**:

- All 44 playable character rigs have expected R6 joints and humanoids.
- All 19 location themes build valid bounded rooms.
- An in-range enemy receives damage and a cooldown replay is rejected.
- Hub players and other private instances reject damage.
- Walls block line-of-sight attacks and server-driven dashes.
- Guard, poison application, and healing execute in the engine.
- All 12 shared move patterns execute.

These tests construct engine objects in the runner's Studio environment. They do not by themselves prove player movement, client UI, or multiplayer behavior.

### Real two-client Studio integration

Executed `StudioTestService:ExecuteMultiplayerTestAsync(2, ...)` with injected test-only client and server scripts. **8 passed / 0 failed**:

1. Both clients loaded the GUI, attached cameras to their characters, and stood at valid ground height.
2. The custom rig moved more than five studs under client movement input.
3. Real remote requests selected Giyu, changed a loadout, and rejected a foreign move.
4. Completing a chapter advanced progression, awarded XP, and removed its mission enemy.
5. A forged request to start a locked chapter was rejected.
6. Two opt-in players started a round and a real client basic-attack request damaged the opponent.
7. Elimination scoring, respawn and a five-point round win updated correctly.
8. Client UI remained present after mission/arena respawns.

Test limits: the reward test sets the NPC's health to zero to exercise progression plumbing. The scoring test accelerates eliminations and the score threshold. These checks do not establish combat difficulty, long-session fairness, physical input ergonomics, visual polish, or live DataStore persistence.

The first multiplayer attempt exposed a **test-runner** issue: run-in-roblox's plugin also loaded in server/client DataModels and launched the edit-only test API again. The isolated wrapper now holds child copies idle. The corrected suite completed successfully. No production test hooks or test remotes ship in the place.

## 2026-09-15/16 visual review and publishing follow-up

- Added a ninth, experimental VirtualInput menu check. The expanded multiplayer run reported **8 passed / 1 failed**: synthetic clicks did not open Characters. Another attempt timed out while launching two clients; the startup allowance is now 100 seconds.
- Investigated the click in the actual game: a Windows desktop mouse event opened Characters correctly. Additional desktop mouse clicks opened Techniques, Codex, Settings, Journey, and Characters; client assertions found each corresponding heading. These five navigation checks passed. They were driven by local UI automation, not a human playthrough.
- Instrumenting VirtualInput showed a button receiving `InputBegan` without its `Activated` callback firing. This does not prove all virtual-input edge cases are understood. The failing diagnostic is retained behind `python scripts/prepare_studio_test.py --virtual-input`; it is **not counted as a passing check** or silently discarded.
- Visually inspected the desktop Journey and Characters panels, skill bar, rig, and generated hub. These are procedural development visuals; full map/art review and small-screen checks remain open.
- Studio updated from 0.738 to 0.739 during the work. An existing Rojo connection initially replaced the contents of a manually opened review window with another local project. Disconnected it, discarded that window, opened a fresh build, verified the Wisteria catalog, and repeated the manual review before publication. The wrong project was never published to this experience.
- The update left the `ContentFolder` registry value pointing at the removed Studio version, breaking the legacy test runner. Corrected it to the installed Studio content directory; no credentials or global security settings were changed.
- Re-ran the engine suite after that repair in Studio 0.739: **7 passed / 0 failed** on 2026-09-16.
- Re-ran the full eight-check two-client baseline in Studio 0.739 on 2026-09-16: **8 passed / 0 failed**, with `RUNTIME_JSON.failures = 0`. The optional VirtualInput diagnostic was not enabled in this run.
- `python scripts/check.py` passed on 2026-09-16: 17 Luau files, eight core tests, valid generated content, and the place build. The four basic audio cues reference bundled Roblox sound files, with bounded lifetimes and a mute control. Authored audio and listening/balance review remain open.
- Studio confirmed **Successfully published** and **Private** for the new experience. Roblox's unauthenticated playability endpoint reported `ContextualPlayabilityUnrated`, `isPlayable: false`. Opening Creator Dashboard reached the browser login page. This is publication evidence, **not public-play or live-persistence evidence**.

## Remaining release checks

- Human playthrough of every chapter and loadout; difficulty/balance tuning.
- Visual inspection at desktop, phone portrait/landscape, and tablet resolutions.
- Physical controller and touch interaction; focus navigation and screen safe-area layout.
- Real published DataStore save/load, disconnect, throttle, lease conflict, crash recovery, and shutdown tests.
- Adversarial remote/movement tests; lag and packet-loss behavior; maximum-room/player performance.
- Per-move visual/choreography verification against lawful primary scene references.
- Long-running arena join/leave, timeout/tie, disconnect and late-join tests.
- Public Roblox publishing and cross-computer play.

## 2026-09-17 story and movement revision

- Portable checks passed: catalog and story target/shot/source references, 20 Luau compilations, eight core tests and a fresh Rojo build.
- Expanded engine suite: **10 passed / 0 failed**. Added an open-house doorway block cast and all prologue anchor bounds, non-teleporting dash admission/constraint cleanup, and server sword/story combat restrictions. The wall test now checks the swept-motion destination clearance instead of merely observing the unchanged starting position of an asynchronous dash.
- Final two-client integration: **12 passed / 0 failed**, with `RUNTIME_JSON.failures = 0`. New client checks observe changing leg joints, jump/fall/land poses, held W + Q keyboard events, replicated drawn/sheath blade visibility, Scriptable cinematic cameras and Custom camera restoration. E keyboard input advanced the opening dialogue.
- The campaign test executes every prologue line and stage, rejects other-player/unknown/distant interactions, blocks pre-training skills, verifies exactly one completion reward, restores the selected Giyu hub fighter and checks room/NPC cleanup. It repositions the player to objectives and calls the server interaction method; it does not establish that a human walked the entire route or activated every physical proximity prompt.
- Two intermediate expanded runs were **11 passed / 1 failed** on the dash-distance check. A first retry passed a weaker displacement-only check; this was not accepted as sufficient evidence, because ordinary walking could meet the threshold. Strengthened the test to require server dash motion too and use a clear starting area away from the second player's spawn.
- Diagnostics then showed roughly 16 studs of server motion but only 9.30 studs on the early client sample, and 10.68 in another settled sample. Added a 0.15-second server-ownership release delay so the final physics transform can replicate before giving control back. The final run measured **16.8068 studs server**, **16.9917 studs client**; largest rendered-frame displacement was **10.6692 studs** under the four-Studio test load. That passes the current no-full-distance-jump threshold, but sustained low-FPS and network-lag smoothness still need dedicated qualification. Do not infer perfect motion at all frame rates from this run.
- Reviewed window screenshots of the actual opening, house, family placement, green Tanjiro outfit, subtitle card and letterbox. Removed overlapping story nameplates/health bars and moved a lantern out of the establishing shot. Screenshots remain ignored local review artifacts. A desktop-helper attempt ran past the 60-second review window and could not finish its interaction walkthrough; no successful physical mouse/proximity walkthrough is claimed.
- The optional pre-existing VirtualInput mouse-menu diagnostic remains unresolved and was not included in this passing baseline. Current dialogue keyboard input passed separately. Physical controller/touch, phone layouts, live saves, authored animation assets, full campaign pacing and final art remain open.
