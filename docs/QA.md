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

## 2026-09-18 Sagiri training chapter

- Portable checks passed: expanded target/actor/shot/challenge/hazard validation, 22 Luau compilations, ten core tests and the place build. New pure tests cover early/late/repeated breathing windows and damage clamping at the nonlethal floor.
- Engine suite: **12 passed / 0 failed**. Added temple/house doorway clearance, walkable surfaces at every Sagiri objective, trap/boulder construction, axe/practice-sword replacement, allowed basic attacks, rejected breathing forms and nonlethal sparring damage callbacks.
- Two expanded two-client runs: **14 passed / 0 failed** each, with `RUNTIME_JSON.failures = 0`. Every Sagiri stage and all eight exercises completed. A real client Basic request landed an axe hit. Client checks confirmed training HUD/camera state and replicated axe/wooden sword props. The final run also sent actual virtual E-key events through the client binding to the server Focus action in both breathing lessons.
- Training assertions reject another player, scene-skip attempts during exercises, premature/repeated breaths, an unfocused boulder strike and a wrong-order course marker. A controlled active trap damages once per immunity interval; reaching one health restarts and heals the current lesson. Survival requires both hits and elapsed time. Chapter completion opens the boulder, grants 130 XP once, unlocks chapter three and restores the selected hub fighter. Leaving active training removes its enemy, room and nonlethal/combat permissions.
- These are automated integration checks. The harness repositions the player, pins actors for deterministic attack/focus tests, accelerates survival/breathing clocks and uses the actual server damage function for most required hits. It does not prove manual route traversal, prompt ergonomics, difficulty, NPC combat pacing, animation quality or small-screen layout. Engine doorway/floor casts verify geometry independently of those repositioned state tests.
- Final movement regression measured **16.3889 studs server**, **14.8963 studs client**, largest client-frame step **6.8543 studs**. Held W + Q and locomotion/sword replication passed. Lag/low-FPS qualification remains open.
- Added optional `--visual-sagiri` house/waterfall review pauses. Both review stages ran, but the window capture helper returned `No visible window for requested test process`; later attempts also outlived the review. No Sagiri screenshots were obtained and no visual inspection or manual playthrough is claimed. The earlier optional mouse-menu diagnostic remains disabled and unresolved; physical controller/touch and live DataStores are still unverified.

## 2026-09-19 Final Selection

- Portable checks: **11 core tests passed**, 24 Luau files compiled and a fresh place built. Validation covers the chapter Water kit, map transitions, battle/patrol targets and bounded boss timings. The pure permission test rejects foreign forms before, during and after story combat.
- Studio engine checks: **14 passed / 0 failed**, repeated after the final recovery change. New checks sweep every main forest path for obstacles and find floors beneath objective anchors. Boss checks verify guarded damage rejection, no premature windup damage, reach/sweep geometry, exposed damage, recovery closure, planted recovery, local retry and cleanup.
- First expanded full two-client run was **15 passed / 1 failed** on immediate encounter completion. The harness now waits for deferred NPC death events rather than assuming a synchronous Died callback. The second full run was **15/16**, failing a real client Basic against the exposed boss.
- A focused **1/2** run recorded the failed hit as admitted, damage multiplier 1, more than two seconds remaining in recovery, but `sight=false`. Stationary story rigs could regain humanoid body collision despite initial `CanCollide=false`. Disabling their state-machine evaluation and queries/collision removed the obstruction; a focused **2/2** run then completed all thirteen stages and asserted all cinematic parts stay non-colliding. Combatants retain humanoid simulation. Additional observed boss drift during recovery was fixed by retaining its anchor through that phase and restoring server physics ownership for pursuit.
- Selection coverage includes real remote Water/basic strikes, extra-arm joint motion observed on a client, private-boss isolation, prevention of scene-skip/foreign-form bypass, ordered patrols and minimum duration, removal of the old map, black sword/crow/uniform/box replication, hidden boxed Nezuko, preserved saved kit, 150 XP once per completed attempt, chapter-four unlock and exit during windup. Most defeats/timers are accelerated on the test server, and actors are repositioned for deterministic geometry. These checks are not a manual playthrough, NPC difficulty assessment or final-art review.
- Added `--selection-only` for the two focused chapter/exit checks; it seeds access only inside the injected test copy. No test remotes or access shortcuts ship in the production place.
- Final full two-client regression: **16 passed / 0 failed**, runner exit 0. The boss strike diagnostic recorded `phase=exposed`, `distance=7`, `multiplier=1`, `sight=true`, health reduced to 200 and 2.1363 seconds of recovery remaining. The earlier prologue, Sagiri, locomotion, sword and PvP checks also passed. Held W + Q measured **16.0197 studs server**, **16.6963 studs client**, largest client-frame displacement **9.7917 studs**. This passes the current test threshold; dedicated low-FPS/lag smoothness review remains open.
- Another window-capture attempt returned `No visible window for requested test process`; no Selection screenshot review is claimed. Existing optional virtual mouse-menu diagnostic, physical touch/controller, small-screen visual review, live saves and lag/performance qualification remain open.

## 2026-09-29 northwest town

- Catalog validation, 26 Luau compilations, all eleven portable tests and the production place build passed. Added map-transition, scene-motion, three-body challenge and box-state validation.
- Studio auto-updated to 0.740 during the initial launch. The first runner timed out; a second could not find the executable. The updater left `ContentFolder` pointing to the removed version. Verified the new executable/content directory and corrected that registry pointer before the environment changed to restricted writes. Only the orphaned test-place process was targeted for cleanup. A subsequent engine run executed; no new visual review is claimed.
- First expanded engine run: **15 passed / 1 failed**. Town lanes, rescue doorway and objective floors passed. The swamp test reached submersion/rise/strike/recovery/retry checks but failed its final death-completion assertion. A second diagnostic run was also 15/16: lethal health was -905, `alive=true`, humanoid state Running and `RunService:IsRunning()=false`. This plugin suite is in edit mode, where death simulation is stopped. The test now checks lethal health there and retains real death progression assertions in the running two-client suite. Final engine run: **16 passed / 0 failed**, runner exit 0.
- Focused two-client town/exit suite: **2 passed / 0 failed**, `RUNTIME_JSON.failures=0`. Completed all thirteen stages, checked remote Water damage against exposed bodies and rejected submerged/other-player damage. Client assertions observed Nezuko's hip-joint motion, black sword/uniform/box and combat HUD. Map transitions hid the correct actors, cleaned the old room and restored the survivors; completion awarded 170 XP once, unlocked chapter five and restored the hub fighter/loadout. Exit during a marked attack removed pools/actors/permissions.
- Final full two-client regression: **18 passed / 0 failed**, `RUNTIME_JSON.failures=0`, runner exit 0. All earlier chapters, client movement/animation, sword replication, locked-chapter admission and PvP checks passed alongside the new chapter. Held W + Q measured **16.6447 studs server**, **16.5799 studs client**, largest rendered-frame step **8.1248 studs**. Low-FPS/lag and physical-device qualification remain open. The production build was checked to exclude injected test bridge/stage hooks; whitespace checks passed.
- Automated chapter checks use server repositioning and accelerated encounter clocks/damage. They test state transitions and real client attack/animation/replication paths, not a human walking the full route, visual fidelity or balanced difficulty.

### 2026-09-29 animation phases 5–6 (locomotion clips, directional dashes)

- **Portable:** `check.py` passed: 13 clips, 29 Luau files and the build.
- **Engine:** **20/20**, including:
  - directional dash reach, i-frames and facing (camera-relative sidestep included)
  - an animator benchmark: **0.099 ms per rig per frame** (1.19 ms for 12 rigs), now a regression check with a 4 ms limit
- **Two-client, four runs of the same dash logic:**
  1. W+Q failed the no-frame-jump guard: a 12.80-stud step against a 12-stud limit.
  2. W+Q failed on distance: the client saw 7.36 studs while the server travelled 16.53 and finished. The new A+Q check failed in the same run.
  3. **19/19**, with the worst client frame at 0.069 s (about 15 FPS) and a 10.93-stud step inside a 0.066 s frame.
  4. **19/19**, exit 0, with the worst frame at 0.019 s and the largest step 3.60 studs. The sidestep travelled 10.27 studs camera-left and stayed facing the camera (dot 0.9985).
- **Investigation:** the server always travelled the full 16.4–16.6 studs. The large steps are client position snaps at the physics ownership handoff, not frame hitches, and they appear only in runs where the four Studio instances drop to about 15 FPS. The benchmark rules out the new animator as the cause.
- **Classification:** this is the pre-existing replication behaviour noted on 2026-09-16, not a regression. The thresholds were not loosened. The dash test now reports frame times so future failures are attributable.
- **Still unqualified:** sustained low-FPS and network-lag dash smoothness remain a real, unqualified risk.
- No visual review of the new clips has taken place.

### 2026-09-30 Tanjiro profile and Studio import pipeline

- `python scripts/check.py`: **42 clips**, two profiles, **6/6 Python authoring tests**, **18/18 core tests**, **30 compiled Luau files**, place build passed. Import coverage includes preserved edits after regeneration, backups, actual XML retiming, dry runs, malformed exports, missing/duplicate timing gates, invalid numeric poses, loop closure and incompatible profile mappings.
- New engine coverage samples Tanjiro's actual clip poses at server Hit time and checks guard after an expired combo. New two-client coverage observes Tanjiro and Giyu stance/combo/guard selection on both clients. Fixtures use anchored Physics-state humanoids to isolate clip selection from locomotion. Both suites compile; these additions have **not run**.
- First `run-in-roblox` engine attempt: **exit 1**, timeout waiting for Studio. No PASS/FAIL test output. Studio updated to `0.741.19.7411056`; its log reports `Cannot open place file for reading.: iostream stream error` for the runner's temporary place.
- Read-only diagnostics found installed version `version-76e1a02649ad4f35`, while `HKCU/Software/Roblox/RobloxStudio/ContentFolder` still names removed `version-6b0e880a1a144428`. This is an observed mismatch, not a proven sole cause of the timeout. Registry was not edited.
- Retry after the update: **exit 1** before test execution; creation of `C:/Users/aadit/AppData/Local/Roblox/Plugins/run_in_roblox-50312.rbxmx` denied (OS error 5). Stopping the identified orphaned first-test Studio process (PID 16816, start 2026-09-30 11:30:58 Dubai) was also denied. No further launches were attempted. The full multiplayer runner was prepared but not launched through the same blocked plugin path.
- Previous **22/22 engine** and **20/20 two-client** results belong to the preceding checkpoint, not this change. Human visual review, an actual Studio editor save/import round-trip, physical-device controls and sustained low-FPS/lag qualification remain pending.

### 2026-09-29 animation phases 7–8 (draw/sheathe state machine, sword path, attacks)

- **Portable:** `check.py` passed: 36 clips, 29 Luau files and the build.
- **Engine:** **22/22**, with two new checks:
  - the server weapon timing (noto chosen out of combat, busy only until Seat, joint swap at Release, fast sheathe in combat, a draw cancelling a noto, iai chaining into a cast with the windup replicated)
  - auto-sheathe, story weapon locks, combo variants, and idle-only light flinches

  The animator benchmark held at 0.100 ms per rig.
- **Two-client:** the final run was **20/20**, exit 0.
  - The sword test now toggles from the current state, because auto-sheathe may already have run, and waits for the clip-timed swap.
  - A new observer test has player 2 watch player 1 draw: the blade slid 2.59 studs along its axis, travelled 9.39 studs, the largest step was 3.03, it ended 0.27 studs from the hand, and the worst frame was 0.067 s.
- **Threshold corrections, and why:** the first two-client run failed two new checks whose thresholds were wrong.
  - The sidestep reach limit of 12 + 0.5 was below the stop-time overshoot seen on every front dash (16.4–16.6 against 16). It is now +1.
  - The sword "no jump" check compared the largest step with the straight-line hip-to-hand distance (2.05). The path is deliberately longer, so the check now compares against the total distance travelled; a teleport would still fail it.
  - The behaviour under test was correct in that run (slid 2.68, ended 0.27 from the hand).
- No visual review has taken place.

### 2026-10-04 Tanjiro and Asakusa qualification

- Portable validation passed: 44 clips, two profiles, six Python authoring tests, eighteen core tests, 31 Luau compilations and build. Current engine run: **25/25**, exit 0. New coverage includes sampled Tanjiro poses, city/clinic route and floor casts, civilian restraint ownership/range/timing/retry, and nonlethal defense ownership/hit/time/cleanup. The twelve-rig animation benchmark was 3.415 ms/frame in this run.
- Initial focused multiplayer run: **0/2**. Rescue acting was not observed, and the next check inherited its unfinished mission. Exit setup now explicitly clears any earlier mission. One further launch failed at the harness level when two clients did not join; Studio logged a memory-allocation error. It executed no chapter checks.
- Subsequent focused results: **1/2** at a later direct restraint input (both client clips were observed); **1/2** at fixed-delay cutscene readiness; **1/2** at a Water hit after reaching the clinic. The exit check passed in each. The fixture now pins repositioned actors, waits for a fresh gold window and bounded replicated camera/UI readiness, and pins/suppresses the target AI only while testing the remote Water hit. Server gameplay thresholds are unchanged. These are fixture corrections; they do not establish movement balance or a manual playthrough.
- The Windows computer-use helper could not connect its native pipe (OS error 2), so no new visual/editor round-trip evidence is available. Automated routes reposition actors and accelerate later beats, damage and timers. Physical controls, full human traversal, appearance, pacing and difficulty remain unverified.

- A further **1/2** focused diagnostic found the first Water input was rejected at seven studs with clear line of sight while `sheathe_noto` began. This was a gameplay idle-timer race, not hit geometry. Refreshing weapon activity at encounter start/retry prevents dialogue time from immediately sheathing the sword. The new engine regression and final engine suite passed **25/25** (2.502 ms for twelve rigs).
- Focused two-client Asakusa after the fix: **2/2**, exit 0, `RUNTIME_JSON.failures=0`. All fifteen stages, restraint client clips, Water attacks, private ownership, nonlethal/time requirements, 190 XP once, chapter-six unlock, restored hub fighter/loadout, camera/UI and actor/map/slot cleanup passed.
- Final full regression: **14 passed / 9 failed**, exit 1. First failure was virtual E not advancing the prologue at server test line 150. Because that run did not unlock chapter two, subsequent chapter start/exit assertions failed on locked/absent missions. The cause of the first input failure remains unconfirmed; next session should inspect scene readiness, server dialogue gating and client input/remote receipt. The user requested handoff, so no further implementation or test launch was started.
- Full-run profile, movement, sword and PvP checks passed. W+Q measured 16.1127 studs server / 15.3623 client, largest step 7.6875 studs and worst frame 0.0686 seconds. Side dash: 11.5086 studs, facing dot 0.99905. Observer sword draw: 2.72-stud axial slide, largest step 2.61 of 9.33 travelled, 0.27-stud final hand gap. No thresholds were loosened. Focused Asakusa 2/2 remains a separate passing result; the full suite is not green.
