# Current status

Updated: 2026-09-16

## Active checkpoint

Playable development build implemented, tested with two real Studio clients, and uploaded to a **new private Roblox experience**. Full requested production game remains in progress. [Deployment target and access status](DEPLOYMENT.md): universe `10766590718`, place `139004028759819`.

## Confirmed environment

- Windows / PowerShell; Python 3.11, Node, Git and authenticated GitHub CLI available.
- Roblox Studio installed locally.
- Remote: https://github.com/aaaditt/demon-slayer-roblox.git (public, initially empty).
- Owner enabled unrestricted access after the initial checkpoint; Git writes now work without escalation.
- User confirmed Infinity Castle (2025) as minimum movie cast.

## Next work

1. Finish release settings after the owner signs into Creator Dashboard. The browser opened at Roblox's login screen; a sign-in request is pending. No public access or live save test has passed yet.
2. Finish visual/device QA and gameplay review; fix issues found. Desktop hub and all five menu tabs have now been inspected with actual mouse navigation.
3. Add canonical boss mechanics, exploration objectives, full story scenes and supporting NPC roles.
4. Produce authored character models, weapon rigs, per-technique animation/VFX and audio.
5. Audit technique names, individual character usage, passives and variants against primary episode/movie references. The catalog is broad but not a completed scene audit.
6. Test real published DataStore behavior, adversarial multiplayer inputs, performance and balance.

## Latest validation

`python scripts/check.py` passed again on 2026-09-16: catalog integrity, 17 Luau files compiled, eight pure core tests, Rojo place build. Fresh runs in Studio 0.739: engine smoke 7/7 passed; real two-client baseline 8/8 passed. An earlier expanded run passed those eight checks but failed the new synthetic menu click; that diagnostic remains opt-in and unresolved. All five tabs passed subsequent actual desktop mouse clicks. See QA.md for evidence and limits. Live DataStore and physical-device usability remain unverified.

## Content inventory

81 cast records, 44 selectable character definitions, 210 technique definitions, 19 location concepts, 22 campaign chapter definitions. See RESEARCH.md for source limitations and CONTENT_INVENTORY.md for every move. These numbers describe data coverage, not authored assets or completed canon reconstruction.

## Implemented systems

Server-authoritative action admission/combat, energy/cooldowns, basic combo, guard/parry, wall-aware dodge, status effects, procedural rigs and effects, private sequential story encounters, progression/mastery, opt-in arena rounds/scoring, save-lease protection, searchable character menu, loadout editor, world atlas, basic local combat audio with mute control, and input mappings. Studio saving is disabled by default; published saves use the configured DataStore.

## Working artifact

`build/WisteriaChronicles.rbxlx` (ignored generated file). Open in Studio and press Play. World geometry is created at runtime. GitHub Actions uploads a place artifact from each successful build.
