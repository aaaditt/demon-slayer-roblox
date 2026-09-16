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
