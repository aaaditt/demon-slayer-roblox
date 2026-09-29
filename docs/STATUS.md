# Current status

Updated: 2026-09-29

## Active checkpoint

Three chronological story chapters are implemented: the Kamado prologue, Sagiri training and Final Selection. The newest chapter has an original wisteria/forest set, demon encounters, a Hand Demon with animated extra arms and attack/recovery windows, a patrol, ore/crow induction and a return to Sagiri for the reunion, black sword and Nezuko's travel box. Story combat uses a temporary Water kit and preserves the saved hub fighter/loadout. Shared locomotion, directional dashes and sword drawing remain implemented.

The full game is not finished. Chapters 4-22 remain encounter previews. The v0.3.0 download contains the first two chapters; the local 0.4.0 build adds Final Selection, with validation/release preparation in progress. The private Roblox cloud place still contains the earlier upload; it has not been overwritten. [Deployment target](DEPLOYMENT.md): universe `10766590718`, place `139004028759819`.

## Confirmed environment

- Windows / PowerShell; Python 3.11, Node, Git and authenticated GitHub CLI available.
- Roblox Studio installed locally.
- Remote: https://github.com/aaaditt/demon-slayer-roblox.git (public, initially empty).
- Current continuation has unrestricted workspace and network access; earlier Studio/Git operations used sandbox approvals.
- User confirmed Infinity Castle (2025) as minimum movie cast.

## Next work

1. Review Journey -> 01 A Trail in the Snow, -> 02 The Mountain Trial and -> 03 Final Selection for movement, navigation, encounter difficulty and scene pacing.
2. Build the first town investigation with Kazumi, Nezuko's box and the Swamp Demon rescue; see [session roadmap](STORY_PRODUCTION.md).
3. Replace shared procedural characters and choreography with authored character-specific assets, starting with Tanjiro, Nezuko and Giyu.
4. Expand all later story arcs, canonical boss mechanics, exploration and supporting NPC roles. Keep all nine Hashira, protagonists, Muzan, Upper/Lower Moons, PvP and progression in scope.
5. Test touch/controller hardware, small-screen layout, adversarial multiplayer input, performance, balance and real published DataStores.
6. Finish public-release settings only after story/gameplay review and owner dashboard access. The earlier public-access check did not pass.

## Latest validation

2026-09-19: `python scripts/check.py` passed expanded catalog/story/loadout/challenge validation, 24 Luau files, all eleven portable tests and the place build. The final engine suite passed 14/14 and the final full two-client regression passed 16/16 (runner exit 0). This includes Selection, the earlier chapters, held W + Q, sword replication and PvP. The focused Selection suite also passed 2/2 after fixing an NPC collision obstruction and waiting for deferred death events in the harness. See QA.md for intermediate failures and exact test limits.

Earlier Studio screenshot review covers the opening house/family scene and dialogue. The Sagiri and Selection capture attempts did not obtain a visible test window; no new visual inspection is claimed. Automated route checks reposition the player and accelerate clocks/hits; they are not a human full-route playthrough or a difficulty assessment. Physical touch/controller, sustained low-FPS/lag behavior, authored animation quality and live DataStore behavior remain unverified.

2026-09-29: rebuilt the unchanged runtime source for delivery. Catalog validation, all eleven core tests, 24 Luau compilations and the production place build passed again; whitespace checks passed. The Studio results above are from September 19, not a new manual playthrough.

## Content inventory

82 cast records (including Kanata), 44 selectable character definitions, 210 technique definitions, 19 location concepts, 22 campaign chapter definitions. See RESEARCH.md for source limitations and CONTENT_INVENTORY.md for every move. These numbers describe data coverage, not authored assets or completed canon reconstruction.

## Implemented systems

Server-authoritative action admission/combat, energy/cooldowns, basic combo, guard/parry, wall-aware dodge, status effects, procedural rigs/effects, three staged chapters with private training/encounters and story map transitions plus later encounter previews, progression/mastery, opt-in arena rounds/scoring, save-lease protection, searchable character menu, loadout editor, world atlas, basic local combat audio with mute control, and input mappings. Studio saving is disabled by default; published saves use the configured DataStore. Within-chapter persistence and continuation of the new gear into a staged chapter four are not implemented.

## Working artifact

Download [v0.3.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.3.0-dev.1), which includes the place and SHA-256 checksum. It corresponds to source checkpoint `d41ac26`; its [GitHub Actions run passed](https://github.com/aaaditt/demon-slayer-roblox/actions/runs/35375934094). The place is 501,252 bytes; SHA-256 `06d8194664886bb8fc486ac56a8fca94c480b75388c09e74708cb62f4293d3ad`.

Local output: `build/WisteriaChronicles.rbxlx` (ignored generated file). Open in Studio and press Play. World geometry is created at runtime. GitHub Actions also uploads a place artifact from each successful build. The release is a development checkpoint; public Roblox access still awaits dashboard setup after browser sign-in.
