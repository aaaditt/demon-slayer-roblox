# Delivery plan

## Intended game

Third-person arena combat and a chronological, replayable story campaign. A wisteria hub connects training, character selection, unlocked missions, and opt-in PvP. Characters have complete researched technique libraries and a selectable four-slot loadout. All characters are available for fair PvP; campaign XP gives rank/mastery and unlocks chapters, not paid combat power.

## Milestones and acceptance

1. **Research and durable project setup** — sourced roster, known forms, demon abilities, anime locations, spoiler/unknown flags, GitHub checkpoints, continuation documents.
2. **Combat foundation** — server-validated hits, telegraphs, basic combo, guard/parry, dodge, energy/cooldowns, statuses, character selection and move loadouts; pure logic tests and a compilable place.
3. **Playable campaign and PvP** — procedural hub and themed locations, mission progression, boss AI, training targets, opt-in arena scoring, persistence, desktop/touch/gamepad controls.
4. **Character and audiovisual production** — authored R15 characters, distinct weapon rigs, per-technique animation clips, VFX and sound, cinematic encounters, navigation, accessibility and performance refinement.
5. **Release qualification** — actual Studio solo and multi-client tests, phone/controller checks, exploit testing, balance sessions, datastore failure testing, publish to an owner-controlled Roblox experience and run live multiplayer QA.

## World route

Kamado mountain → Mount Sagiri → Fujikasane Final Selection → first mission town → Asakusa → Tsuzumi Mansion → Mount Natagumo → Butterfly Mansion → Mugen Train → Entertainment District → Swordsmith Village → Hashira Training → Infinity Castle → dawn finale (later-story spoiler). Optional Twelve Kizuki archive encounters cover ranks whose combat is not shown.

## Combat design

Four equipped techniques chosen from each character's library; Q dodge; F guard; basic attack combo; energy regenerates outside recovery. A readable windup precedes powerful attacks. Each technique defines shape, reach, startup, recovery, damage, energy, cooldown, movement, effect color, and status. All numeric timings/damage are original game balancing, not canon claims. Shared combat primitives allow the entire catalog to function while authored move-specific choreography is produced.

## Quality boundaries

- Do not invent missing numbered forms or unshown Lower Moon Blood Demon Arts as canon.
- Research inventory, playable mechanical adaptation, and final authored asset are separate completion states.
- Local compilation and unit tests cannot substitute for Roblox multiplayer testing.
- DataStore failures must not overwrite a prior save with fallback defaults.
- No copied anime footage, music, dialogue scripts, or extracted commercial-game assets in the repository.


## Story-first continuation (2026-09-17)

Owner review found missing visible locomotion, a teleport-like dash and an opening with no house or narrative. Prioritize a chronological story experience and readable movement before more roster breadth or public release settings. The current work builds the Kamado prologue and repairs shared movement/sword handling. See STORY_PRODUCTION.md for the part-by-part route, acceptance boundaries and next Sagiri session. The remaining full game objective is unchanged.
