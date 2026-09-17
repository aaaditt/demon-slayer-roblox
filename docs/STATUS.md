# Current status

Updated: 2026-09-17

## Active checkpoint

Story-first revision implemented following owner playtest feedback. Chapter one now has a staged Kamado mountain prologue, an enterable home, family NPCs, charcoal errands, Saburo's shelter, Nezuko carrying, Giyu's intervention, dialogue and camera scenes. Shared locomotion, timed directional dashes and sword drawing are implemented. The held-W-plus-Q regression now passes in two-client Studio testing.

The full game is not finished. Chapters 2-22 remain encounter previews. The new v0.2.0 development download contains this revision. The existing private Roblox cloud place still contains the earlier upload; it has not been overwritten. [Deployment target](DEPLOYMENT.md): universe `10766590718`, place `139004028759819`.

## Confirmed environment

- Windows / PowerShell; Python 3.11, Node, Git and authenticated GitHub CLI available.
- Roblox Studio installed locally.
- Remote: https://github.com/aaaditt/demon-slayer-roblox.git (public, initially empty).
- Owner enabled unrestricted access after the initial checkpoint; Git writes now work without escalation.
- User confirmed Infinity Castle (2025) as minimum movie cast.

## Next work

1. Play the new opening from Journey -> 01 A Trail in the Snow and collect owner feedback on movement, pacing and the story scenes.
2. Continue the chronological story with the road/temple encounter and Mount Sagiri training; see [session roadmap](STORY_PRODUCTION.md).
3. Replace shared procedural characters and choreography with authored character-specific assets, starting with Tanjiro, Nezuko and Giyu.
4. Expand all later story arcs, canonical boss mechanics, exploration and supporting NPC roles. Keep all nine Hashira, protagonists, Muzan, Upper/Lower Moons, PvP and progression in scope.
5. Test touch/controller hardware, small-screen layout, adversarial multiplayer input, performance, balance and real published DataStores.
6. Finish public-release settings only after story/gameplay review and owner dashboard access. The earlier public-access check did not pass.

## Latest validation

2026-09-17: `python scripts/check.py` passes catalog/story integrity, 20 Luau files, all eight portable tests and the place build. Expanded Studio engine checks passed 10/10. Final expanded real two-client integration passed 12/12, including actual joint motion through walk/jump/fall/landing, held W + Q via keyboard events, sword replication, E to advance dialogue, every prologue scene/objective, one-time rewards, private-stage checks, camera cleanup and existing PvP behavior. The final dash measured 16.81 studs on the server and 16.99 on the client after settling. Earlier dash checks failed and are documented in QA.md.

Inspected actual Studio screenshots of the opening house/family scene, dialogue and revised framing. This is automated runtime and screenshot review, not a human full-route playthrough. Physical touch/controller, sustained low-FPS/lag behavior, authored animation quality and live DataStore behavior remain unverified.

## Content inventory

81 cast records, 44 selectable character definitions, 210 technique definitions, 19 location concepts, 22 campaign chapter definitions. See RESEARCH.md for source limitations and CONTENT_INVENTORY.md for every move. These numbers describe data coverage, not authored assets or completed canon reconstruction.

## Implemented systems

Server-authoritative action admission/combat, energy/cooldowns, basic combo, guard/parry, wall-aware dodge, status effects, procedural rigs and effects, a staged opening prologue plus private sequential encounter previews, progression/mastery, opt-in arena rounds/scoring, save-lease protection, searchable character menu, loadout editor, world atlas, basic local combat audio with mute control, and input mappings. Studio saving is disabled by default; published saves use the configured DataStore.

## Working artifact

Download [v0.2.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.2.0-dev.1), which includes the place and SHA-256 checksum. It corresponds to source checkpoint `68d3421`; its [GitHub Actions run passed](https://github.com/aaaditt/demon-slayer-roblox/actions/runs/35244084052). The uploaded place is 445,153 bytes; SHA-256 `9ab5e890b7ff381316fc0432a7ed1de236f0635c7d16b7c60e2462fa4f3f3d90` matches GitHub's asset digest.

Local output: `build/WisteriaChronicles.rbxlx` (ignored generated file). Open in Studio and press Play. World geometry is created at runtime. GitHub Actions also uploads a place artifact from each successful build. The release is a development checkpoint; public Roblox access still awaits dashboard setup after browser sign-in.
