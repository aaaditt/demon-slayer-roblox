# Current status

Updated: 2026-09-15

## Active checkpoint

Playable development build implemented and tested with two real Studio clients. Full requested production game remains in progress.

## Confirmed environment

- Windows / PowerShell; Python 3.11, Node, Git and authenticated GitHub CLI available.
- Roblox Studio installed locally.
- Remote: https://github.com/aaaditt/demon-slayer-roblox.git (public, initially empty).
- Owner enabled unrestricted access after the initial checkpoint; Git writes now work without escalation.
- User confirmed Infinity Castle (2025) as minimum movie cast.

## Next work

1. Finish visual/device QA and gameplay review; fix issues found.
2. Add canonical boss mechanics, exploration objectives, full story scenes and supporting NPC roles.
3. Produce authored character models, weapon rigs, per-technique animation/VFX and audio.
4. Audit technique names, individual character usage, passives and variants against primary episode/movie references. The catalog is broad but not a completed scene audit.
5. Test real published DataStore behavior, adversarial multiplayer inputs, performance and balance.
6. Publish to an owner-controlled Roblox experience after its place/universe and settings are available. No Roblox deployment target is currently configured.

## Latest validation

`python scripts/check.py` passed: catalog integrity, 17 Luau files compiled, eight pure core tests, Rojo place build. Studio engine smoke: 7/7 passed. Real two-client Studio integration: 8/8 passed. See QA.md for exact assertions and limits. Live DataStore and device usability are not yet verified.

## Content inventory

81 cast records, 44 selectable character definitions, 210 technique definitions, 19 location concepts, 22 campaign chapter definitions. See RESEARCH.md for source limitations and CONTENT_INVENTORY.md for every move. These numbers describe data coverage, not authored assets or completed canon reconstruction.

## Implemented systems

Server-authoritative action admission/combat, energy/cooldowns, basic combo, guard/parry, wall-aware dodge, status effects, procedural rigs and effects, private sequential story encounters, progression/mastery, opt-in arena rounds/scoring, save-lease protection, searchable character menu, loadout editor, world atlas and input mappings. Studio saving is disabled by default; published saves use the configured DataStore.

## Working artifact

`build/WisteriaChronicles.rbxlx` (ignored generated file). Open in Studio and press Play. World geometry is created at runtime. GitHub Actions uploads a place artifact from each successful build.
