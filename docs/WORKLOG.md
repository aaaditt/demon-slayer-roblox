# Work log

## 2026-09-15 — Project initialization

- Inspected the empty workspace and empty remote; confirmed GitHub authentication and Roblox Studio installation.
- Cloned the repository. Initial sandbox attempt failed writing `.git/config`; an escalated retry succeeded.
- Confirmed Infinity Castle (2025) as the requested film baseline.
- Started source research with the official anime character pages, official episode pages, community technique references, and Roblox security documentation.
- Added the delivery plan, continuation rules, status, README, and ignore rules.
- Result: versionable project foundation; no playable game or completed runtime validation yet.

## 2026-09-15 — Research catalog and combat rules

- Resumed after the owner enabled unrestricted workspace access; reread all continuation documents.
- Installed local pinned Rojo 7.7.0 and Luau 0.738 binaries, plus the optional run-in-roblox runner. Tool binaries remain ignored.
- Researched official cast/story pages and community technique sections. Direct Fandom access failed; indexed search excerpts supplied secondary references. Recorded this limitation and the pending primary-scene audit.
- Added 81 cast records (44 selectable), 210 move entries, 19 location concepts, and 22 chronological encounter chapters. Added source, adaptation, spoiler, animation-production, and unrevealed-form metadata.
- Added generated Luau content and Markdown inventory, Rojo project mapping, pinned bootstrap, content validation, and pure combat/profile/lease rules.
- Initial rules test caught a Lua `and/or` nil-expression bug that retained a released lease; replaced it with an explicit conditional. The regression test remains.
- Result: data/rules foundation; server/client/world implementation is next. No Studio playtest claimed.
- Validation passed: catalog integrity, 4 Luau files compiled, all 8 core tests, and Rojo place build. The structural place has no gameplay bootstrap yet.

## 2026-09-15 — Playable game systems and Studio integration

- Implemented original R6 character/weapon geometry, nighttime wisteria hub, duel arena, and private themed rooms for the location catalog.
- Implemented server cast admission, cooldowns, energy, basic combo, line-of-sight hit geometry, wall-aware dashes, guard/parry, status handling, cancellation, NPC pursuit/technique selection, and movement anomaly checks.
- Implemented character/loadout selection, chronological mission waves/rewards/unlocks, respawns, arena rounds/scoring, save leases, and 5 Hz player snapshots.
- Built Journey, Characters, Techniques, Codex, Settings, HUD/cooldown UI, bounded local VFX, procedural joint poses, camera setup and keyboard/controller/touch bindings.
- Added engine and two-client Studio integration tests. Engine smoke passed 7/7.
- First multiplayer run failed because the legacy runner re-executed its plugin inside child test DataModels. Fixed the isolated test wrapper and closed only the orphan processes belonging to that test; the user's other open Studio project was preserved.
- Corrected multiplayer suite passed 8/8 with real clients, including camera, movement, remote admission, progression, PvP damage/scoring and respawn checks. Runtime test code is injected only into the temporary test copy.
- Corrected world signs/window orientation and prevented mouse clicks on UI buttons from also triggering basic attacks.
- Added checksum-pinned cross-platform tool bootstrap, CI validation/artifact workflow, setup instructions, architecture map, and QA evidence with explicit limits.
- Result: a locally playable development game. Authored art/choreography, full canonical environments/story/boss mechanics, live persistence QA, device polish and Roblox publishing are not complete.

## 2026-09-15/16 — Desktop review and new Roblox experience

- Owner explicitly selected **Create a new Roblox experience**. Created **Demon Slayer: Wisteria Chronicles**, universe `10766590718`, start place `139004028759819`; Studio confirmed successful upload and Private audience on 2026-09-15 at 19:38 UTC. Added target IDs, links, access status, and update instructions in deploy/roblox.json and docs/DEPLOYMENT.md.
- Added character gameplay summaries in the source catalog and regenerated Content.luau; replaced implementation notes in the character menu with these summaries.
- Added bounded, throttled basic combat audio using bundled Roblox sounds and an in-game mute toggle. This is placeholder feedback, not an authored soundtrack or anime audio.
- Expanded the integration suite with a VirtualInput navigation diagnostic and optional 60-second visual-review pause. The expanded run was 8 passed / 1 failed (synthetic Characters click). A separate attempt timed out during client startup; raised the harness startup/response allowances.
- Actual desktop mouse clicks opened all five menu tabs and their client heading assertions passed. The synthetic event reached InputBegan but did not activate the button; retained the unresolved diagnostic as explicit opt-in rather than claiming it passed. Inspected the hub, rig, panels and skill bar visually.
- Studio auto-updated to 0.739. Identified an unrelated Rojo connection in the manual review window, disconnected it, discarded the contaminated window, reopened the fresh build, and verified Wisteria content before uploading. No other experience was overwritten.
- Fixed the legacy test runner's stale Studio ContentFolder registry path after the update. Downloaded tool binaries, local GUI helpers, screenshots and Studio logs remain ignored; no credentials were copied into the project.
- Validation on 2026-09-16: python scripts/check.py passed catalog/generation, 17 Luau compilations, all eight core tests and the place build. Earlier engine and baseline multiplayer results remain 7/7 and 8/8; the failed synthetic check is recorded separately in QA.md.
- After repairing the runner path, repeated the engine suite in Studio 0.739: 7 passed / 0 failed. Verified all four referenced built-in sound files exist in the installed content directory. Audibility and mixing are not claimed as verified.
- Repeated the two-client baseline in Studio 0.739 on 2026-09-16: all 8 checks passed, with RUNTIME_JSON failures = 0. The retained experimental VirtualInput check was explicitly disabled in this baseline run.
- Public access remains incomplete: unauthenticated playability returned ContextualPlayabilityUnrated / false. Creator Dashboard opened at Roblox's login screen on 2026-09-16; asked the owner to sign in in the browser, without requesting credentials. No public-play or live DataStore result is claimed.
- Remaining full-game production scope is preserved in STATUS.md and PLAN.md.

## 2026-09-16 — GitHub development release

- Committed and pushed the private-experience checkpoint as `5cecc68`. GitHub Actions run `35045353031` succeeded, including Linux validation and place artifact upload.
- Created GitHub prerelease [v0.1.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.1.0-dev.1) targeting that exact source commit. Uploaded `WisteriaChronicles.rbxlx` (388,496 bytes) and its SHA-256 checksum file.
- Place download SHA-256: `57911b1b6f49c0bdecde350750b07aeb045854aea4d7de8a17b5dfb87c938cb9`. This is the generated local release file's checksum, not a claim that Studio's cloud serialization is byte-identical.
- Added durable release links to README.md and STATUS.md. Browser login/public release settings, live persistence QA, and the full production backlog remain open.

## 2026-09-17 — Story-first opening and movement revision

- Owner reviewed the game and reported invisible movement/attack animation, a teleport-like dodge that did not work while moving, and an opening with no home or storyline. Prioritized those issues without reducing the full cast/campaign/PvP objective.
- Read the continuation documents and official episode 1/2 summaries. Replaced chapter one's misplaced temple demon with a ten-stage mountain prologue. All story actors, dialogue, shots, stage ordering and primary sources are in the catalog; Content.luau remains generated.
- Added an original enterable Kamado house, snowy paths, town market, Saburo shelter, mountain surroundings and objective markers. Added family NPCs, charcoal and Nezuko carry props, pre-training Tanjiro, non-graphic discovery, Giyu intervention, camera scenes and dialogue continuation/scene skip. The following 21 chapters are explicitly marked Encounter Preview in Journey.
- Added server-owned stage/interaction checks, cinematic movement/combat locks, scene cleanup, restoration of the selected hub fighter and one-time chapter rewards. Prologue death/leave/disconnect cleanup discards the attempt; within-chapter persistence remains future work.
- Reworked rig discovery to retry after descendant replication and follow player character lifecycle. Added interpolated idle/run/jump/fall/land/dodge/combat poses. Added scabbards, animated grips, bounded sword trails and replicated draw/sheathe state for single-blade sword rigs; R / D-pad right / Sword touch button toggles them. Sheathed attacks queue a draw before striking.
- Replaced instant dash displacement with bounded server-owned planar motion, ongoing collision sweeps and cancellation cleanup. Client direction prefers movement and resolves held WASD if Humanoid.MoveDirection has not updated.
- Portable validation passed: catalog plus story referential checks, 20 Luau compilations, eight core tests and place build. Expanded Studio engine suite passed 10/10. First expanded real two-client suite passed 11/12: locomotion joints, jump/fall/land, sword replication, all story stages, rewards/cleanup, camera exits and existing PvP checks passed; W+Q was admitted but dash distance failed. That result prompted the diagnostic work recorded below.
- Added STORY_PRODUCTION.md for the next sessions and documented the remaining source/animation/story gaps. No claim of entire-manga reading, final animation quality or completed later chapters.

- Investigated the dash failure with measured server/client motion. Strengthened the test after detecting that a weak client-displacement-only assertion could count ordinary walking. Added a brief ownership-release delay to preserve the final authoritative dash position; final measured travel was 16.81 studs server / 16.99 client. Largest rendered step was 10.67 studs under the multi-Studio load; low-FPS/lag smoothness remains a qualification item.
- Final real two-client suite passed **12/12**, including E-key dialogue continuation and the full prologue state sequence. Inspected actual opening screenshots; refined Tanjiro's green/checkered outfit, framing, lantern placement and cinematic HUD/nameplate clutter. A desktop interaction helper outlived the review pause; no full manual route/proximity playthrough is claimed.
- The existing Roblox cloud place has not been overwritten in this session. Preparing a new reproducible GitHub development artifact; later chapters, authored animation, device QA and live persistence remain open.
- Repeated the expanded engine suite on the final build, including the strengthened swept-dash wall-clearance assertion: **10/10 passed**. Final portable build and whitespace checks also passed.


## 2026-09-17 — Prologue checkpoint and development release

- Committed and pushed the story/movement checkpoint as `68d3421`. GitHub Actions run `35244084052` completed successfully.
- Created [v0.2.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.2.0-dev.1) targeting full commit `68d3421911eb921389da54fd9c82a14281c7da95`. The initial create request used a short SHA and was rejected with HTTP 422 / invalid target_commitish; retrying with the full SHA succeeded.
- Uploaded the production place (445,153 bytes) and checksum. GitHub's uploaded asset digest matches local SHA-256 `9ab5e890b7ff381316fc0432a7ed1de236f0635c7d16b7c60e2462fa4f3f3d90`. Test injection, tool binaries, screenshots, credentials and Studio logs are not included.
- Updated README, STATUS and DEPLOYMENT to link the new download and explicitly distinguish it from the unchanged Roblox cloud upload. Next implementation slice is the route to Sagiri and staged training; all later-story, character-art, PvP and production qualification objectives remain tracked.

## 2026-09-18 — Road to Sagiri and staged training

- Continued the owner's story-first request after reading the project continuation documents. Reviewed official episode 2/3/4 synopses for the temple axe encounter, mountain/sword/waterfall/breathing training, boulder hurdle and two-year lead-in to Final Selection. Dialogue, timing, layouts and gameplay remain explicitly original condensed adaptations; no entire-manga reading or exact choreography audit is claimed.
- Replaced chapter two's direct Sabito encounter with 13 staged objectives/scenes and eight exercises: temple survival, ordered descent/traps, sword repetitions, breathing, first Sabito spar, Makomo breathing lesson, rematch and a focused boulder cut. Added enterable temple/Urokodaki interiors, a raised forest course, waterfall, practice yard and split boulder. Added Urokodaki, Nezuko, Sabito and Makomo staging and simple mask/weapon props.
- Added reusable server training lifecycle, retry/heal behavior, nonlethal health floors, allowed basic-only story combat, a Focus action with server clock/distance/stillness validation, and per-cycle timing admission. Training enemies use basic pursuit/attacks; their chase stopping range now allows those attacks to reach the player. Exit/completion cancels pending attacks and removes temporary permissions/NPCs. Cinematic skip cannot bypass a lesson.
- Extended Story to handle intro/exercise/result phases and actor visibility/placement, retaining the prologue. Fixed duplicate carried/resting Nezuko staging. Added training progress/timer HUD, gold breathing window and keyboard/controller/touch bindings. Prevented hidden normal-sword trails from appearing alongside story weapons. Adjusted course warning bands to sit on the slope.
- Updated source catalog and regenerated content/inventory; version is 0.3.0. Expanded catalog validation and portable/engine/integration coverage. `python scripts/check.py` passed: 22 Luau files, ten core tests and place build. Studio engine suite passed **12/12**. Two real two-client runs passed **14/14**, with the final run additionally checking E-key breathing input. Existing prologue, movement, sword and PvP checks passed. Detailed evidence and acceleration limits are in QA.md.
- Studio launch and process inspection needed sandbox approval in this session. Added optional Sagiri screenshot pauses, but capture returned no visible window and the later attempts outlived the review; no new screenshot inspection or manual route playthrough is claimed.
- Two staged chapters are now implemented; twenty later chapters remain encounter previews. Next is Final Selection/Hand Demon, induction, Nichirin delivery and Nezuko's travel box. Authored character animation, full campaign, physical device/performance/balance testing and live persistence remain in scope. The Roblox cloud upload remains unchanged.

## 2026-09-18 — Sagiri checkpoint and download

- Committed and pushed implementation `d41ac26383da7cf71f2cf2f30ea7be05dcdb889d`. [GitHub Actions run 35375934094](https://github.com/aaaditt/demon-slayer-roblox/actions/runs/35375934094) completed successfully.
- Created [v0.3.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.3.0-dev.1) targeting that full source commit. Uploaded the production place (501,252 bytes) and SHA-256 file: `06d8194664886bb8fc486ac56a8fca94c480b75388c09e74708cb62f4293d3ad`. Build output remains ignored; tests only modify temporary copies.
- Updated README, STATUS and DEPLOYMENT with the new download. Git writes/push and release creation used sandbox approvals; an initial Actions-list request failed against the sandbox proxy and succeeded with network escalation. No credentials, downloaded tools or Studio logs were committed. Cloud publication remains unchanged; the next chronological slice is Final Selection.
- Verified GitHub reports both release files uploaded, the expected full target commit and matching place SHA-256 digest.

## 2026-09-19 — Final Selection and the return to Sagiri

- Continued the chronological story request after reading the continuation documents. Read official episode 4/5/6 summaries; referenced Bandai Namco's official black-blade prop description. Added original condensed dialogue and explicitly documented the limits of the synopsis-level research. The full cast/campaign/PvP objective is unchanged.
- Replaced chapter three's two-enemy preview with 13 stages: wisteria/guide briefing, first-night demons, candidate warning, Hand Demon, remaining-night patrol, survivors, ore selection, crow, reunion, sword delivery, box and first assignment. Added a separate Fujikasane set with clear connected paths and a return transition that replaces it with Sagiri within the private mission slot.
- Added a server encounter lifecycle with actual enemy defeats, ordered patrol spawns, minimum survival time, encounter retries and bounded defeat effects. The Hand Demon has six animated extra arms, a cinematic double for its introduction, alternating reach/sweep telegraphs, guarded damage rejection and exposed recovery windows. It stays planted during recovery and returns to server-owned pursuit afterward. These are original game mechanics, not exact canon choreography.
- Added temporary Water-form loadouts and server allowlisting without changing the saved hub fighter/loadout. Added borrowed/black sword handling, a removable fox mask, Corps belt/buttons, crow, Haganezuka appearance, reunion pose and Nezuko's wooden travel box. Kanata is now a cast record (82 total; 44 selectable fighters and 210 techniques unchanged). Increased encounter HUD height for wrapped boss instructions.
- Expanded validation and tests. Portable validation passed (24 Luau files, eleven core tests, place build). The engine suite passed **14/14**, including forest route sweeps, objective floors, boss windup damage, armor/recovery admission, evasion and retries; it passed again after the final planted-recovery change.
- First full two-client run: **15 passed / 1 failed**, because the new test checked completion before deferred humanoid death events. Added bounded waits and kept progression assertions. Second full run: **15/16**, failing a real client hit in boss recovery. A focused diagnostic reproduced **1 passed / 1 failed**: the attack was admitted, the boss was exposed, but line of sight was false near the hidden cinematic double.
- Disabled `Humanoid.EvaluateStateMachine` and queries/collision on story-only rigs so automatic humanoid simulation cannot restore invisible body collision. Added a runtime check of every cinematic part. Focused Selection/exit suite then passed **2/2**, including the full return, gear replication, saved loadout restoration and reward. Diagnostics also showed recovery drift, prompting the final planted-recovery fix.
- Final full two-client regression passed **16/16**, runner exit 0, after the final engine **14/14**. A real client strike damaged the exposed boss at distance 7 with clear line of sight; earlier chapters, movement/sword and PvP checks passed. Held W + Q measured 16.0197 studs server / 16.6963 client, largest rendered-frame displacement 9.7917. Test acceleration and visual/device limits remain as documented in QA.md.
- Window capture again returned no visible Studio test window; no new visual review or manual traversal is claimed. Physical devices, low-FPS/lag, difficulty and live persistence remain unverified. Automated tests reposition actors, accelerate clocks and most defeats, and do not prove a human played seven days or the entire route.
- Three staged chapters now exist; nineteen remain encounter previews. Next is the first assignment town, Kazumi, Nezuko's box in continuing gameplay and the Swamp Demon rescue. Authored art/acting/animation and the wider production backlog remain open. The Roblox cloud upload has not changed.

## 2026-09-29 — Final Selection checkpoint continuation

- Resumed the pending Final Selection checkpoint, reread continuation documents and reconciled the final September 19 runtime results with QA/STATUS. Source implementation is unchanged from those successful engine and two-client runs. Preparing a fresh production build and the versioned development download; no new manual Studio review or cloud upload is claimed.
- Fresh `python scripts/check.py` passed catalog validation, all eleven core tests, 24 Luau compilations and the production place build. `git diff --check` passed. Downloaded tools, generated place/test files and Studio logs remain ignored.

## 2026-09-29 — Final Selection download

- Committed and pushed implementation `e2f34d5d426149ca82fb47c88cfbf9d091800496`. [GitHub Actions run 36575304044](https://github.com/aaaditt/demon-slayer-roblox/actions/runs/36575304044) completed successfully, including generated-content freshness.
- Created [v0.4.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.4.0-dev.1) targeting that full source commit. Uploaded the production place (554,354 bytes) and checksum. GitHub reports both assets uploaded and the place digest matches local SHA-256 `acafe472dabc28725063d4414448351d0cdab8dd08bbbc5b5a3f42c88c90741a`.
- Updated README, STATUS and DEPLOYMENT with the verified download and unchanged Roblox cloud status. Three chapters are staged; the next implementation slice is Kazumi's town investigation and the Swamp Demon rescue. Full campaign, authored animation/art and production qualification remain tracked.

## 2026-09-29 — Northwest town investigation and swamp rescue

- Read the continuation files and official episodes 6/7/8; checked secondary indexed Kazumi material for the rescue/keepsake aftermath. Source limits and original condensed staging are recorded in RESEARCH.md. Added Kazumi (83 cast records; 44 playable fighters, 210 techniques and 22 chapter definitions remain).
- Replaced chapter four's encounter preview with thirteen stages: arrival, Kazumi, lane evidence, scent, house rescue, three-body ambush, Nezuko intervention, portal, depths, return/last body, keepsake, farewell and Asakusa assignment. Added original town streets, enterable houses and a separate walkable swamp interpretation.
- Added a server-owned pool emergence/telegraph/strike/recovery/submerge cycle, ambush hit/time requirements, actual body defeats, retries and encounter cleanup. Added horn props, kick/recoil/emergence poses, brief scripted actor movement, a Nezuko support lunge and closed/open box staging. Chapter four retains the black sword/uniform, temporarily equips Water forms 1/2/6/8 and preserves hub loadouts.
- Added engine and two-client chapter/exit coverage and a `--swamp-only` diagnostic. Portable validation passed: eleven core tests, 26 Luau compilations and production build. Initial Studio attempts hit an auto-update timeout and stale executable path; corrected the verified installation pointer before the permission change. First actual engine run: 15/16; the remaining failure concerns death completion after retry and is under investigation. No visual/human playthrough is claimed.
- The environment changed to workspace-only writes with read-only `.git` and restricted network during testing. Continue local implementation/verification and record any commit/push failure; do not claim a release or cloud upload until verified.
- Focused two-client town/exit run passed **2/2**, with zero runtime failures, including all thirteen stages, real Water strikes, Nezuko client joint motion, map/box state, one reward and cleanup. The engine diagnostic reproduced 15/16 and confirmed `RunService:IsRunning()=false`, so its death assertion was invalid in edit mode; lethal health is now checked there and actual death progression remains required by the running integration test. The corrected engine suite passed **16/16**. Full regression is running; source/portable checks remain passing.
- Attempted the authorized checkpoint with an explicit `git add` file list. It failed: `Unable to create .../.git/index.lock: Permission denied`. The environment marks `.git` read-only and disallows escalation. No chapter-four commit, push, GitHub Actions run or development release is claimed; source and the generated production place remain local. Complete the pending checkpoint/push when Git write access is restored.
- Final full two-client regression passed **18/18**, `RUNTIME_JSON.failures=0`, runner exit 0. All four chapters, held W + Q, locomotion/sword replication, locked-chapter rejection and PvP passed. Dash measurements were 16.6447 studs server / 16.5799 client, largest frame step 8.1248. Final engine result remains 16/16 and portable checks 11/11; no new visual or human-route review occurred.
- Local production artifact: 595,414 bytes, SHA-256 `7fcb85158a39120d8c5c2e316702702f9fdfd65488f72c213829c36c4a2750ec`, with checksum file. Verified it excludes the injected test bridge/stage hooks. Whitespace checks passed. Updated README, STATUS, SETUP, QA, production roadmap and deployment notes to distinguish this local build from the unchanged v0.4.0 download and cloud upload. Next implementation is Asakusa; the pending Git checkpoint is first when access returns.

## 2026-09-29 — Fresh-session handoff requested by owner

- Added `docs/HANDOFF.md` with the exact saved HEAD/local artifact, changed-file inventory, completed and intermediate test results, Studio update notes, canon/production limits, pending Git/CI/release commands and Asakusa next steps. Linked it from README and STATUS so a fresh session's normal startup reads discover it.
- Initially recorded the prior Git block; a late workspace check then found chapter-four commit `b0ed8d7f6f994de6adfc18d4d32ce19898d2b512` created by another process at 18:02:35 Dubai, with local `origin/main` matching it. Updated HANDOFF/STATUS to supersede the earlier uncommitted-state assumption. New R15-related modifications appeared in Rig, Animator and Story; this writer left them untouched. The 11 core / 16 engine / 18 two-client results apply to the earlier tested chapter-four implementation, not those new rig edits. Current CI/new-release state was not independently verified here.
- User can start a fresh session in the same project and ask it to read HANDOFF.md and continue. This handoff writer performed documentation changes only, with no new source edit, test run, commit, release or Roblox upload. Reconcile any concurrent session's later changes first. The one-off catalog authoring helpers are stale and must not be rerun.

## 2026-09-29 — Animation foundation, phase 1: blocky R15 rig

- Owner requested full character animation work (walk, front/side dashes, sword draw/look/sheathe, sword attacks) as a base model that each character then specializes. Owner decisions: Animation Editor KeyframeSequence clips (stored in the repo and sampled offline; uploads optional), a rig with elbows/knees, directional dashes, and all three sheathe styles. The plan and tracker are in docs/ANIMATION.md.
- Committed the pending chapter four as `b0ed8d7` and pushed after `check.py` passed. The concurrent handoff session saw this commit and the R15 edits as unknown; both came from this session. Its HANDOFF.md, STATUS and README notes are preserved and reconciled.
- Rebuilt `Rig.create` as a 15-part blocky R15 rig with the same 5-stud silhouette. Joints: Root, Waist, Neck, shoulders, elbows, wrists, hips, knees and ankles. Settings: `HipHeight = 2`, `RigType = R15`, skin-coloured hands in place of the cuffs. `Rig.torsoFrame` converts classic accessory offsets, so belts follow the hips and haori/checks follow the chest. Migrated Story carry, uniform, crow, Hand Demon arms, story weapons, the interim animator and tests.
- Results: `check.py` passed (11 core, 26 Luau, build). The Studio engine suite passed **16/16**, including a new check of all R15 joints and floor contact for both soles on every playable character. The full two-client regression passed **18/18**, runner exit 0. No visual review of the new rig is claimed yet.

## 2026-09-29 — Animation foundation, phase 2: nichirin katana and saya

- Added `swordPresets.nichirin_base`, sourced `characters[id].sword` overrides (Tanjiro wheel, Giyu hex, Rengoku flame, Kanao flower) and the `sword_guides` source. `check.py` validates fields, colours, the tsuba enum, dimensions and sources.
- `Rig.buildSword` builds a data-driven katana:
  - kashira, samegawa tsuka with a diamond ito wrap and menuki, fuchi, a shaped tsuba (round/square/hex/wheel/flame/flower/bar), habaki
  - a three-segment curved blade (nichirin spine plus hamon edge) with a wedge kissaki and trail attachments
  - a matching curved saya with koiguchi, kojiri, kurikata and sageo
- Two joints hold the sword: `SwordHip` (LowerTorso) and `SwordHand` (RightHand). `Rig.draw` enables exactly one. The blade now physically rests in the saya; the transparency hack and the client grip lerp are gone. Needle and serpent variants use the same builder with a thinner or straight blade and a stronger curve.
- First engine run: 16/17. A diagnostic showed `WeldConstraint` pieces desyncing when joints moved the tsuka; switched the sword to classic `Weld`. A second run found the kissaki extending past the saya; lengthened the saya to cover it.
- Final results: `check.py` passed. Engine **17/17** (new containment and sourced-fittings check for all 19 sword users). Two-client **18/18**, exit 0; the sword test now asserts the replicated joint swap and that the tsuka is in the hand only when drawn. No visual review yet.

## 2026-09-29 — Animation foundation, phases 3–4: clip pipeline and layered player

- `scripts/generate_animations.py` (run by `check.py`):
  - Turns JSON clips into Animation Editor KeyframeSequence `.rbxmx`, with R15 pose trees, Weight-0 structural parents, easing tokens and KeyframeMarkers.
  - Supports mirroring.
  - Validates joints, times, loop closure, markers and attack `Hit`/`End` markers, and parses every `.rbxmx`, including Studio-saved ones.
  - Writes `AnimationIndex.luau` and a hash manifest, and never regenerates a file that was edited in Studio.
  - Rojo maps `assets/animations` to `ReplicatedStorage.Animations`; CI freshness now covers the index and assets.
- Proof clips: `base/idle_sheathed` (2.4 s breathing loop, left hand on the saya) and `base/idle_drawn` (a guard stance adapted to blocky proportions; see ANIMATION.md deviations).
- `MotionMath.luau` (pure): Roblox pose easing, keyframe bracketing, attack time-warp, fades and dash classification. `Motion.luau` loads and samples KeyframeSequences and dispatches markers.
- `Animator.luau` rewritten to write `Motor6D.Transform`:
  - base locomotion cross-fade
  - a fading action stack
  - a turn-lean overlay
  - legacy procedural fallback per unauthored pose
  - marker-driven sword grip and trail

  Combat replicates `PoseWindup` so attacks can be time-warped.
- Results:
  - Core **16/16** (five new motion tests).
  - Engine **18/18**. The new check loads the Rojo-built sequences, verifies every pose names a rig part, and confirms that sampled poses match the authored angles and interpolate.
  - Two-client **18/18**, exit 0. The joint checks now read `Transform`; a new assertion checks that a standing player plays `base/idle_*` and that its waist breathes.
- Not done:
  - asset-ID playback (deferred)
  - visual review of the two proof clips

## 2026-09-29 — Animation phases 5–6: locomotion clips and directional dashes

- **Locomotion clips:**
  - `walk_sheathed` (1.0 s, authored at 8 studs/s)
  - `run_sheathed` and `run_drawn` (0.62 s at 22 studs/s; the drawn run trails the blade low)
  - `jump`, `fall` (loop), `land_light` (0.18 s) and `land_heavy` (0.35 s after a fall of more than 25 studs)
- **Animator:**
  - walk state
  - stride-matched playback rate
  - heavy-landing detection from peak height
  - one-shot restarts
  - the `drawnMask: "lower"` action mask
  - `MotionState` reports the new states
- **Dashes:**
  - `Combat:dodge(actor, direction, facing)` classifies front/back/left/right with `MotionMath.dashDirection` and uses per-direction reach and i-frames from `Config`. Side and back dashes keep facing via `Combat:move(..., keepFacing)`.
  - The client sends the camera facing only with movement input. `Game` validates it as planar.
  - Clips: `dash_front`, `dash_left`, `dash_back`, and `dash_right` mirrored from `dash_left`.
  - Design note: default AutoRotate makes body-relative side dashes impossible, hence camera-relative classification.
- **Tests:**
  - an engine directional-dash check
  - the animator benchmark (`Animator.track` exposed for tests)
  - a live A+Q sidestep check
  - frame-time diagnostics in the dash test
- **Results:** engine **20/20**; two-client final **19/19**, exit 0. Two earlier two-client runs failed intermittently at the dash ownership handoff under about 15 FPS load (see QA.md); investigated and classified as the pre-existing replication behaviour, with thresholds unchanged.
- **Not done:** visual review of any clip.
