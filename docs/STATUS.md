# Current status

Updated: 2026-09-18

## Active checkpoint

Two chronological story chapters are implemented. The Kamado prologue continues into The Mountain Trial: an enterable temple and Urokodaki home, axe encounter, trapped mountain descent, sword and breathing practice, Sabito/Makomo scenes, rematch and the boulder test. Training uses server-checked objectives, timed breathing input, nonlethal retries and visible practice weapons. Shared locomotion, directional dashes and sword drawing remain implemented.

The full game is not finished. Chapters 3-22 remain encounter previews. The v0.3.0 development download contains both staged chapters. The private Roblox cloud place still contains the earlier upload; it has not been overwritten. [Deployment target](DEPLOYMENT.md): universe `10766590718`, place `139004028759819`.

## Confirmed environment

- Windows / PowerShell; Python 3.11, Node, Git and authenticated GitHub CLI available.
- Roblox Studio installed locally.
- Remote: https://github.com/aaaditt/demon-slayer-roblox.git (public, initially empty).
- Current session uses a workspace-write sandbox; Studio launch, Windows process inspection and Git/network writes may require tool approval.
- User confirmed Infinity Castle (2025) as minimum movie cast.

## Next work

1. Review Journey -> 01 A Trail in the Snow and -> 02 The Mountain Trial for movement, navigation, lesson difficulty and scene pacing.
2. Continue with Final Selection exploration/Hand Demon mechanics, Corps induction, Nichirin delivery and Nezuko's travel box; see [session roadmap](STORY_PRODUCTION.md).
3. Replace shared procedural characters and choreography with authored character-specific assets, starting with Tanjiro, Nezuko and Giyu.
4. Expand all later story arcs, canonical boss mechanics, exploration and supporting NPC roles. Keep all nine Hashira, protagonists, Muzan, Upper/Lower Moons, PvP and progression in scope.
5. Test touch/controller hardware, small-screen layout, adversarial multiplayer input, performance, balance and real published DataStores.
6. Finish public-release settings only after story/gameplay review and owner dashboard access. The earlier public-access check did not pass.

## Latest validation

2026-09-18: `python scripts/check.py` passes expanded catalog/story/challenge validation, 22 Luau files, all ten portable tests and the place build. Expanded Studio engine checks passed 12/12. Two expanded two-client runs passed 14/14, covering all training exercise kinds, server damage/skill limits, trap/retry behavior, ordered markers, focus windows, boulder splitting, one-time reward/unlock, exit cleanup and existing story/movement/PvP behavior. The final run also verified real E-key events reaching the breathing action. Exact results and test limits are recorded in QA.md.

Earlier Studio screenshot review covers the opening house/family scene and dialogue. The Sagiri screenshot attempt did not obtain a visible test window; no new visual inspection is claimed. Automated route checks reposition the player and accelerate training clocks/hits; they are not a human full-route playthrough or a difficulty assessment. Physical touch/controller, sustained low-FPS/lag behavior, authored animation quality and live DataStore behavior remain unverified.

## Content inventory

81 cast records, 44 selectable character definitions, 210 technique definitions, 19 location concepts, 22 campaign chapter definitions. See RESEARCH.md for source limitations and CONTENT_INVENTORY.md for every move. These numbers describe data coverage, not authored assets or completed canon reconstruction.

## Implemented systems

Server-authoritative action admission/combat, energy/cooldowns, basic combo, guard/parry, wall-aware dodge, status effects, procedural rigs/effects, two staged chapters with private training exercises plus later encounter previews, progression/mastery, opt-in arena rounds/scoring, save-lease protection, searchable character menu, loadout editor, world atlas, basic local combat audio with mute control, and input mappings. Studio saving is disabled by default; published saves use the configured DataStore. Within-chapter persistence is not implemented.

## Working artifact

Download [v0.3.0-dev.1](https://github.com/aaaditt/demon-slayer-roblox/releases/tag/v0.3.0-dev.1), which includes the place and SHA-256 checksum. It corresponds to source checkpoint `d41ac26`; its [GitHub Actions run passed](https://github.com/aaaditt/demon-slayer-roblox/actions/runs/35375934094). The place is 501,252 bytes; SHA-256 `06d8194664886bb8fc486ac56a8fca94c480b75388c09e74708cb62f4293d3ad`.

Local output: `build/WisteriaChronicles.rbxlx` (ignored generated file). Open in Studio and press Play. World geometry is created at runtime. GitHub Actions also uploads a place artifact from each successful build. The release is a development checkpoint; public Roblox access still awaits dashboard setup after browser sign-in.
