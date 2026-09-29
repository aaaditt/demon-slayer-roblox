# Current status

Updated: 2026-09-29

Fresh-session starting point: [HANDOFF.md](HANDOFF.md). Its "unknown concurrent R15 edits" were the animation session's phase 1 (see [ANIMATION.md](ANIMATION.md)): the blocky R15 rig is now committed and validated (engine 16/16, two-client 18/18). Chapter four is commit `b0ed8d7`, pushed. Character animation production follows ANIMATION.md.

## Active checkpoint

Four chronological story chapters are implemented: the Kamado prologue, Sagiri training, Final Selection and the northwest town investigation. Chapter four adds lantern streets, an accessible rescue house, Kazumi, Nezuko's intervention and a separate swamp space. Three demon bodies rise, telegraph strikes and expose themselves before sinking. The rescue continues through the last body, a keepsake and farewell. The box, black sword and uniform continue into this chapter; a temporary Water kit preserves the saved hub fighter/loadout. Its local build, engine and two-client checks passed before the newer rig edits described above. The earlier Git block was followed by a commit from another process; verify subsequent delivery instead of assuming it remains uncommitted.

The full game is not finished. Chapters 5-22 remain encounter previews. The v0.4.0 download includes the first three staged chapters; the local 0.5.0 build adds chapter four. The private Roblox cloud place still contains the earlier upload; it has not been overwritten. [Deployment target](DEPLOYMENT.md): universe `10766590718`, place `139004028759819`.

## Confirmed environment

- Windows / PowerShell; Python 3.11, Node, Git and authenticated GitHub CLI available.
- Roblox Studio installed locally.
- Remote: https://github.com/aaaditt/demon-slayer-roblox.git (public, initially empty).
- Current continuation permits workspace writes but marks `.git` read-only, restricts network and disables approval escalation. Earlier Studio/Git operations used broader access.
- User confirmed Infinity Castle (2025) as minimum movie cast.

## Next work

1. Continue character animation production (ANIMATION.md; phases 1-8 done: R15 rig, nichirin sword, clip pipeline, layered player, locomotion, camera-relative dashes, draw/sheathe with procedural sword path and auto-sheathe, 23 attack/defence/reaction clips. Next, phases 9-10: per-character profiles and the Studio workflow; then a human visual review of every clip). Verify chapter-four CI/release state. Review all four staged chapters for movement, navigation, encounter difficulty and scene pacing.
2. Build Asakusa, Muzan and the civilian emergency, then Tamayo/Yushiro; see [session roadmap](STORY_PRODUCTION.md).
3. Replace shared procedural characters and choreography with authored character-specific assets, starting with Tanjiro, Nezuko and Giyu.
4. Expand all later story arcs, canonical boss mechanics, exploration and supporting NPC roles. Keep all nine Hashira, protagonists, Muzan, Upper/Lower Moons, PvP and progression in scope.
5. Test touch/controller hardware, small-screen layout, adversarial multiplayer input, performance, balance and real published DataStores.
6. Finish public-release settings only after story/gameplay review and owner dashboard access. The earlier public-access check did not pass.

## Latest validation

2026-09-29 chapter four: catalog validation, eleven core tests, 26 Luau compilations and production build passed. The corrected engine suite passed 16/16; full two-client regression passed 18/18, with `RUNTIME_JSON.failures=0` and runner exit 0. The focused town/exit suite also passed 2/2. Coverage includes all thirteen new stages, real Water strikes, client-observed Nezuko kick motion, map/box replication, one completion reward, cleanup, all earlier chapters, held W + Q, swords and PvP. An edit-mode engine death assertion initially failed because simulation was stopped; the edit test now verifies lethal health, while actual death progression is required by the running integration suite. No visual/manual chapter review is claimed.

2026-09-19: `python scripts/check.py` passed expanded catalog/story/loadout/challenge validation, 24 Luau files, all eleven portable tests and the place build. The final engine suite passed 14/14 and the final full two-client regression passed 16/16 (runner exit 0). This includes Selection, the earlier chapters, held W + Q, sword replication and PvP. The focused Selection suite also passed 2/2 after fixing an NPC collision obstruction and waiting for deferred death events in the harness. See QA.md for intermediate failures and exact test limits.

Earlier Studio screenshot review covers the opening house/family scene and dialogue. The Sagiri and Selection capture attempts did not obtain a visible test window; no new visual inspection is claimed. Automated route checks reposition the player and accelerate clocks/hits; they are not a human full-route playthrough or a difficulty assessment. Physical touch/controller, sustained low-FPS/lag behavior, authored animation quality and live DataStore behavior remain unverified.

Earlier on 2026-09-29, chapter three's unchanged source was rebuilt for its 0.4.0 release: eleven core tests, 24 Luau compilations and build passed. Its Studio evidence was from September 19. Chapter four's newer September 29 results are listed first above.

## Content inventory

83 cast records (including Kazumi), 44 selectable character definitions, 210 technique definitions, 19 location concepts, 22 campaign chapter definitions. See RESEARCH.md for source limitations and CONTENT_INVENTORY.md for every move. These numbers describe data coverage, not authored assets or completed canon reconstruction.

## Implemented systems

Server-authoritative action admission/combat, energy/cooldowns, basic combo, guard/parry, wall-aware dodge, status effects, procedural rigs/effects, four staged chapters with private training/encounters and story map transitions plus later encounter previews, progression/mastery, opt-in arena rounds/scoring, save-lease protection, searchable character menu, loadout editor, world atlas, basic local combat audio with mute control, and input mappings. Studio saving is disabled by default; published saves use the configured DataStore. Within-chapter persistence, authored acting and a full underwater swimming/oxygen system are not implemented.

## Working artifact

Download [v0.4.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.4.0-dev.1), which includes the place and SHA-256 checksum. It corresponds to source checkpoint `e2f34d5`; its [GitHub Actions run passed](https://github.com/aaaditt/demon-slayer-roblox/actions/runs/36575304044). The place is 554,354 bytes; SHA-256 `acafe472dabc28725063d4414448351d0cdab8dd08bbbc5b5a3f42c88c90741a`. Both uploaded assets, the full source target and the matching GitHub place digest were verified on September 29.

Last verified local 0.5.0 output: `build/WisteriaChronicles.rbxlx` (ignored generated file), 595,414 bytes, SHA-256 `7fcb85158a39120d8c5c2e316702702f9fdfd65488f72c213829c36c4a2750ec`; checksum file is beside it. This has chapter four and predates the newer rig edits. Open in Studio, press Play and choose Journey -> 04 Beneath the Town after chapter three. No injected test bridge/stage hooks are present. The earlier staging attempt failed, but chapter-four commit `b0ed8d7` subsequently appeared with matching local `origin/main`; verify current CI/new-release state. No new cloud upload was observed.
