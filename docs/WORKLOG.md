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
