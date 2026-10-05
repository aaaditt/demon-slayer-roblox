# Continuation update — 2026-10-05, verified movement checkpoint

**Full regression now passes 25/25**, runner exit 0, `RUNTIME_JSON.failures=0`. Final Studio engine suite **26/26**, exit 0. Portable checks **6 authoring / 19 core / 32 Luau compilations**, 44 clips/two profiles and build pass. Delivery commit/CI references are in WORKLOG.md. Read current STATUS/PLAN before making changes; the October 4 handoff below is historical.

## Implemented and diagnosed

- Prologue E waits until eligible and remains a real key/server-handler test. All five routes unlock naturally; fallback test seeds cannot hide a sequential-progression failure.
- Server-owned physics caused intermittent client catch-up (14.17-stud frame). Waiting 0.15 s for ownership and removing the rotation write did not resolve it. Raw client ownership made movement even but closed the old server timer prematurely; that incomplete experiment was not shipped.
- Production now keeps player movement client-simulated with server-created constraints and `src/client/MotionDriver.luau` tapering at the approved endpoint. Server origin, direction, speed, reach, timers and collision parameters remain private and authoritative. Swept position validation runs every tick and before network actions, casts and damage. Rejected movement restores the verified position under server ownership, cancels its cast token/constraint and dodge immunity. NPCs stay server-simulated.
- A bounded **0.5 s** endpoint-receipt grace gives no additional reach or i-frames. Vertical limits include the initial jump apex; grace cannot permit upward flight. Movement attacks wait for audited completion. No new network action is exposed.
- Focused candidate **8/8** includes three real W+Q attempts and an actual 40-stud client-side sideways teleport that the server corrects. Final full W+Q: **15.9524 studs server / 14.2956 client**, largest frame **3.3333 studs** at 0.0665 s. Full A+Q, profiles, sword paths, all five chapters, rewards/cleanup and PvP pass. All prior dash thresholds remain intact.
- An intermediate full run was 24/25 because the old single-frame programmatic jump fixture missed an animation phase. It now waits for ground and holds real virtual Space for 0.15 s with normal controls; all jump/fall/landing phases are still required. Original missing phase was not logged, so no animator defect is claimed. Final fixture passes.

## Next work

1. Confirm clean Git status and latest delivery in WORKLOG. Do not restart the resolved prologue or ownership experiments. Commands remain `python scripts/check.py`, engine `--script tests/studio.spec.luau`, and `python scripts/prepare_studio_test.py` followed by the normal multiplayer runner. `--dash-only` selects eight focused checks. Run Studio suites sequentially.
2. Visually review base/Tanjiro motion, sword handling, held WASD+Q and all five chapters; complete an actual Animation Editor save/export/import round-trip. Current tools lack the native `node_repl` entry point required by the installed computer-use skill; browser CUA explicitly disables native apps. No visual/editor session was attempted. This is a tool limitation, not a permission block.
3. Then continue **Tsuzumi Mansion**, Zenitsu/Inosuke and rotating-room encounters with primary references. Expand Nezuko/Giyu motion alongside story work. Chapters **6–22 remain previews**; keep the full cast, Infinity Castle (2025 minimum), later arcs, PvP and progression objective.
4. Qualify physical devices, human traversal/balance, sustained latency/low-FPS behavior, live saves and release. Automated routing teleports fixtures and accelerates selected clocks; it does not prove appearance or difficulty. Native UI limitations do not justify claiming these checks passed.

## Artifacts

Local production place: `build/WisteriaChronicles.rbxlx`, **3,377,746 bytes**, SHA-256 `4d7b1b965604544c2c7c4d0db90fe5e44e99c72952bf91a2455a9bea15f9949c`. Checksum refreshed. Build/tools/logs stay ignored; shipping tree excludes test injection. Local evidence: `build/engine-motion-final-20261005.log`, `build/dash-verified-20261005.log`, `build/full-motion-final-20261005.log`. Intermediate experiments/failures remain in WORKLOG/QA and ignored logs.

No new release or Roblox cloud upload. Last downloadable release remains v0.4.0-dev.1 (chapters 1–3); private place remains the earlier upload. GitHub pushes do not update Roblox.

The original October 4 handoff below is superseded by this update wherever it describes failures or next tasks.

---

# Fresh-session handoff — 2026-10-04

The user requested a fresh-session handoff because the session allowance is nearly exhausted. **Preserve this checkpoint and continue from here; do not restart completed implementation.** Source checkpoint **`5ad7b51` is committed and pushed** to `origin/main`; [portable CI passed](https://github.com/aaaditt/demon-slayer-roblox/actions/runs/37200299789). A following documentation commit records delivery. Full Studio regression remains unresolved as described below.

Workspace: `C:\Aadit\Personal\code-ide\antigravity\demon-slayer-roblox`. Read README.md, STATUS.md, PLAN.md, latest WORKLOG.md, RESEARCH.md and ANIMATION.md. Follow AGENTS.md. Implementation, research, testing, commits and pushes to the configured GitHub repository are authorized.

## Saved work

- Build **0.6.0**: five staged chapters, including the new fifteen-stage **Lights of Asakusa**. Streets/stall, Muzan and civilian emergency, Tamayo/Yushiro, enterable clinic/garden, Yahaba, Susamaru defense, Nezuko acting and departure are implemented. Chapters **6-22 remain encounter previews**.
- Two motion profiles and **44 bundled R15 clips**: six Tanjiro stance/walk/combo/guard overrides, shared base motion and two civilian rescue clips. Server and observers share `MotionProfile.luau` resolution.
- Checked `scripts/import_animation.py`, stronger XML/profile validation, backups and preservation of Studio edits. Actual Animation Editor save/export/import round-trip remains pending; detailed instructions are in ANIMATION.md.
- Civilian restraint uses four stationary gold-window Focus inputs, validated on the server. No sword/basic/technique damage is admitted there. Susamaru's protected phase needs three hits and twenty seconds before Tamayo's result scene. Arrow/Temari attacks use existing shared techniques; canonical boss physics/choreography remain unfinished.
- Fixed a runtime bug: the idle timer could expire during dialogue and immediately auto-sheathe on the first battle input. `Encounter:reset` refreshes `weaponSince`; inherited swamp resets get the same fix. An engine regression uses an expired timer and enabled weapon permission.
- Added map/challenge/clip/observer/route/exit tests and `--asakusa-only`. All test seeds/remotes stay inside the injected test copy. Catalog remains source of truth; do not hand-edit generated Content or AnimationIndex.

## Actual results

- Final `python scripts/check.py`: **6 Python authoring tests, 18 core tests, 31 Luau compilations**, catalog/44 clips/two profiles and production build passed.
- Final engine suite after the idle-timer fix: **25 passed / 0 failed**, exit 0. Twelve-rig animator benchmark: **2.502 ms/frame**.
- Focused two-client Asakusa route/exit: **2 passed / 0 failed**, exit 0, `RUNTIME_JSON.failures=0`. All fifteen stages, real Water attacks, both rescue clips, private ownership, health floor, reward once, chapter-six unlock, saved kit restoration, camera/UI and actor/map cleanup passed.
- **Full regression finished: 14 passed / 9 failed, runner exit 1.** First failure: `tests/multiplayer.server.luau:150`, **E did not advance cinematic dialogue** in the prologue. The prologue never unlocked chapter two, and the later chapter-start/exit tests failed on locked or absent missions. Treat those later failures as dependent until the first issue is resolved; do not claim all nine are separate gameplay bugs or that the suite passed. The actual cause of the E-input failure remains unconfirmed.
- Passing full-suite checks include both clients' Tanjiro/Giyu stance/combo/guard observations, locomotion, W+Q, A+Q, sword replication/draw path, roster/loadout remotes, cutscene exit, locked-chapter rejection and PvP/respawn. W+Q measured 16.1127 studs server, 15.3623 client, largest frame displacement 7.6875 at about 15 FPS. The focused Asakusa **2/2** result remains valid independently of this failed full run.
- Intermediate failures and corrections are in QA/WORKLOG: stale mission after a failure, fixed-delay camera readiness, a gold-window/physics fixture race, and the actual auto-sheathe bug. Tests now anchor repositioned fixtures, wait for replicated camera state and a fresh gold window, and suppress enemy AI only for a deterministic remote-hit assertion. Gameplay acceptance thresholds were not weakened.
- One launch failed before tests when Studio reported memory allocation failure; the runner cleaned its own processes. No unrelated applications/system settings were changed.
- Windows computer-use initialized on retry, but `list_apps` failed: native pipe unavailable, OS error 2. **No new screenshots, manual route review or Animation Editor round-trip.** Automated routes reposition actors and accelerate later clocks/damage; they do not prove appearance, difficulty or human traversal.

## Next session, in order

1. Inspect `git status --short`, `git log -3 --oneline` and the last WORKLOG entry. Source checkpoint `5ad7b51` was pushed and its portable CI passed; a documentation commit follows it. No source edits were left pending after that checkpoint. GitHub and Studio writes now work; the installed Studio content registry path was already correct on October 4. No test Studio processes remained after the full suite exited.
2. **First next task: diagnose the prologue E-input failure and rerun full regression.** Inspect server line 150 and the client `sceneKey` handler (virtual E press, then a fixed wait). **Strong timing candidate:** the revised client `story` readiness check returns as soon as the camera/UI are ready, replacing an unconditional 0.4-second wait. The prologue immediately sends E, potentially before `Story:continue` allows input at scene age 0.6 seconds. Instrument the scene age and actual StoryContinue receipt; if confirmed, wait for eligibility before sending the real key without weakening the server gate. Also check input focus/nextRequest. Improve failure isolation so a prologue failure does not obscure all later chapter results, while preserving the real sequential-unlock assertion. Do not treat focused Asakusa success as full regression success. Full suite commands:

   ```powershell
   python scripts/prepare_studio_test.py
   .tools/run-in-roblox/run-in-roblox.exe --place build/WisteriaChronicles.rbxlx --script build/run-multiplayer.luau
   ```

   Focused diagnostic: add `--asakusa-only` to preparation. After implementation changes run `python scripts/check.py`; engine command uses `--script tests/studio.spec.luau`. Run Studio suites sequentially. Edit-mode engine checks cannot prove Humanoid death progression; running multiplayer does. Never weaken dash thresholds to hide low-FPS ownership snaps.
3. Visually review base/Tanjiro motion, draw/sheathe, held WASD+Q and all five chapters; complete one actual editor round-trip. Refine observed navigation, acting, pacing and difficulty. Computer-use needs a working native helper first; no permission block should be assumed from September's historical failures.
4. Then build **Tsuzumi Mansion**, Zenitsu/Inosuke introductions and rotating-room encounters using primary references. Continue Nezuko/Giyu animation profiles alongside story production.
5. Keep the full objective: all nine Hashira, protagonists, Muzan, Upper/Lower Moons, Infinity Castle (2025 minimum), all story locations, PvP and progression. Authored likenesses, weapons, per-technique choreography, later arcs, sound, physical devices, live saves and release qualification remain open.

## Artifact and boundaries

Local production place: `build/WisteriaChronicles.rbxlx`, 3,372,157 bytes, SHA-256 `9cf06c489cdf5c512c9b1650be90522cb0aaa17ea4735587b8db8c92c0145b56`; checksum beside it. Shipping build excludes test bridges/hooks. Build output, tools, logs and credentials must never be committed.

Last verified downloadable release: [v0.4.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.4.0-dev.1), chapters 1-3. Build current source for chapter five. No new Roblox upload occurred; private target remains universe `10766590718`, place `139004028759819`. Public access and live saves remain unverified. A GitHub push does not update Roblox automatically.
